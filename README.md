AI Knowledge Base / Support Portal

# 0) One‑liner & Goal

**Build an AI‑augmented, multi‑tenant knowledge base** where teams upload/search docs and chat with an AI that answers from their own content. Monetize with quotas/Stripe. Ship with logging, rate limits, and tests.

---

# 1) User roles & multi‑tenancy

* **Tenant (Team)**: isolated data per team (Row‑level scoping by `team_id`).
* **Roles per team**:

  * **Owner**: billing, member management, quota settings.
  * **Admin**: everything but billing.
  * **Member**: CRUD own docs, ask AI, view team docs if allowed.
  * **Viewer (optional)**: read‑only.
* **Auth**: email/password (Devise or `has_secure_password`), session or JWT.
* **Authorization**: Pundit/CanCanCan or custom `before_action` checks.

---

# 2) Core features (MVP → Pro)

**MVP**

1. Teams & members (invite via email).
2. Docs: upload/edit, automatic chunking + embeddings.
3. AI Q\&A: “Ask AI” returns answer + cited snippets from team docs.
4. Usage quotas: N Q\&A requests/day per team.
5. Admin dashboard: docs, users, usage logs.
6. Basic observability: request logs (latency/tokens), job status.

**Pro (Phase 2)**
7\) Streaming responses, retry/cancel.
8\) Stripe plans (Free/Pro) with higher quotas; webhook to grant entitlements.
9\) Rate limiting & abuse protections.
10\) Evals/guardrails: schema validation, moderation, prompt‑injection checks.
11\) Export/archive docs; audit logs.

---

# 3) Data model (Rails)

```text
Team(id, name, plan, quota_daily, quota_reset_at, created_at, updated_at)

Membership(id, team_id, user_id, role [owner|admin|member|viewer], created_at)
  idx: [team_id, user_id] unique

User(id, email, password_digest, name, last_sign_in_at, created_at, updated_at)
  idx: email unique

Doc(id, team_id, title, source_type [upload|url|manual], body(text), tokens(int),
    visibility [team|private], created_at, updated_at)
  idx: team_id, idx: [team_id, title]

DocChunk(id, doc_id, team_id, position(int), content(text), token_count(int),
         embedding(vector[1536] via pgvector), created_at, updated_at)
  idx: [team_id, doc_id], ivfflat index on embedding (pgvector)
  note: duplicate team_id for scoping without join

Question(id, team_id, user_id, content(text), status [queued|answering|done|error],
         latency_ms(int), token_input(int), token_output(int), cost_cents(int),
         created_at, updated_at)

Answer(id, question_id, team_id, content(text), model_name, confidence(float),
       created_at, updated_at)

AnswerCitation(id, answer_id, doc_chunk_id, score(float), start_idx(int), end_idx(int))

UsageEvent(id, team_id, user_id, kind [ask|embed|other], tokens_in(int), tokens_out(int),
           cost_cents(int), latency_ms(int), meta(jsonb), created_at)
  idx: team_id, created_at

ApiKey(id, team_id, name, token_digest, created_at)
  (for service-to-service or future external access)

BillingAccount(id, team_id, stripe_customer_id, plan [free|pro], quota_daily_override(int),
               current_period_end(datetime), created_at, updated_at)

JobRun(id, team_id, kind [embedding|retrieval|answer], status [queued|running|done|error],
       duration_ms(int), error_text(text), meta(jsonb), created_at)
```

**Indexes to add**

* `add_index :doc_chunks, :embedding, using: :ivfflat, opclass: :vector_l2_ops` (after setting `pgvector`)
* `add_index :usage_events, [:team_id, :created_at]`
* Unique constraints on memberships, emails.

---

# 4) AI pipeline (RAG) – services & jobs

**Services (plain POROs)**

* `Chunker` – splits `Doc.body` into chunks (e.g., \~800–1000 tokens, overlap 100).
* `Embedder` – calls embeddings API; returns vector (1536 or provider size).
* `Retriever` – given user query → embed → PG `ORDER BY embedding <-> query_vec LIMIT k` (k=8).
* `Answerer` – builds prompt with top chunks + instructions, calls LLM, returns structured JSON (see schema below).
* `Moderation` – optional: check query & answer for policy violations/PII.
* `CostTracker` – estimate \$ using model pricing \* tokens; store in `UsageEvent`.

**Background jobs**

* `DocIngestJob(doc_id)` → Chunker → Embedder (bulk) → create `DocChunk`s; log as JobRun.
* `QuestionAnswerJob(question_id)` → Retriever → Answerer → create `Answer` + `AnswerCitation`s; track tokens/cost; status transitions.

**Prompt skeleton (system)**

```
You are a helpful assistant that answers ONLY from the provided team documents.
If the answer is not in the context, say "I don't know based on the docs."
Cite sources with [doc_title#chunk_position] after each relevant sentence.
Return JSON matching the schema.
```

**JSON schema (what you parse)**

```json
{
  "answer": "string",
  "citations": [
    {"doc_id": 123, "chunk_position": 4, "snippet": "…", "confidence": 0.73}
  ],
  "confidence": 0.0
}
```

---

# 5) API surface (v1) – JSON

Base path: `/api/v1` (JWT or session cookie). All endpoints scoped by current\_user’s team.

**Auth**

* `POST /auth/sign_up` → email, password → user + membership (owner if first user).
* `POST /auth/sign_in` → returns session/JWT.
* `POST /teams/:team_id/invite` (owner/admin) → send invite email link (optional now).

**Docs**

* `GET /docs` → list (filters: q, created\_since)
* `POST /docs` → `{ title, body | file, visibility }` → enqueue `DocIngestJob`
* `GET /docs/:id` → show doc + ingest status
* `PUT /docs/:id` → update body (re‑ingest)
* `DELETE /docs/:id`

**Q\&A**

* `POST /questions` → `{ content }` → create Question(status=queued) → enqueue `QuestionAnswerJob`
* `GET /questions/:id` → `{ status, answer, citations, latency_ms }`
* `POST /questions/stream` (Server‑Sent Events) → push tokens (Phase 2)

**Admin / Usage**

* `GET /admin/usage` (owner/admin) → grouped totals by day: tokens, cost, asks.
* `GET /admin/users` (owner/admin)
* `POST /admin/quota` (owner) → set team daily quota override
* `POST /admin/api_keys` → create API key (future)

**Billing**

* `POST /billing/create_portal` (owner) → Stripe portal URL
* Webhooks: `/billing/stripe/webhook` → update `BillingAccount.plan`, `quota_daily_override`, `current_period_end`

**Rate limiting**

* Rack middleware or Redis: e.g., `N per day` per team (`UsageEvent.kind = ask` count since midnight UTC).
* On limit breach: 429 with reset timestamp.

---

# 6) Controller flow examples

**QuestionsController#create**

```ruby
def create
  authorize! :create, Question
  guard_quota!
  q = current_team.questions.create!(user: current_user, content: params[:content], status: "queued")
  QuestionAnswerJob.perform_later(q.id)
  render json: { id: q.id, status: q.status }
end
```

**QuestionAnswerJob**

```ruby
def perform(id)
  q = Question.find(id)
  q.update!(status: "answering", started_at: Time.current)
  vec = Embedder.call(q.content)
  chunks = Retriever.call(team: q.team, query_vec: vec, k: 8)
  result = Answerer.call(query: q.content, chunks: chunks)
  Answer.create!(question: q, team: q.team, content: result.answer, confidence: result.confidence)
  result.citations.each { |c| AnswerCitation.create!(...) }
  UsageEvent.create!(team: q.team, user: q.user, kind: "ask", tokens_in: result.tokens_in, tokens_out: result.tokens_out, cost_cents: result.cost)
  q.update!(status: "done", latency_ms: (Time.current - q.started_at) * 1000)
rescue => e
  q.update!(status: "error")
  JobRun.create!(team: q.team, kind: "answer", status: "error", error_text: e.message)
  raise
end
```

---

# 7) Migrations & setup checklist

1. **Add pgvector**

   * `enable_extension 'vector'`
   * `add_column :doc_chunks, :embedding, :vector, limit: 1536`
   * After data: create IVFFlat index (`rails db:execute` with `lists=100`).
2. **Doc chunking**

   * store `position` & `token_count`, add `idx: [:doc_id, :position]`
3. **Foreign keys & null constraints**

   * FK on all `*_id` fields; `null: false` where sensible.
4. **Seeds**

   * 1 team, 1 owner, 2 members, 3 sample docs.

---

# 8) Quotas, pricing & Stripe

* **Free plan**: `quota_daily = 50` questions/day, `max_doc_size = 1 MB`.
* **Pro plan**: `quota_daily = 500` questions/day, `max_doc_size = 10 MB`.
* On each `Question`: check remaining quota (`UsageEvent.where(kind: 'ask', created_today) < quota_daily`).
* Stripe:

  * Product `pro_monthly` with metered or tiered pricing optional later.
  * Webhook updates `BillingAccount` and sets `quota_daily_override`.
  * Show “Upgrade” in UI when near limit (80% alert).

---

# 9) Observability & security

* **Logging**: JSON logs for `/questions#create` and job runs (tokens/latency/vec\_count).
* **Metrics**: store p50/p95 latency, error rates (simple SQL or push to CloudWatch).
* **Secrets**: Rails credentials for AI keys/Stripe DB creds.
* **Security**:

  * Validate file types/size on uploads.
  * Sanitize HTML; escape user content in prompts.
  * Prompt‑injection guard: strip links/HTML, clamp chunk size, add “refuse if outside context” instruction.
  * CORS restricted to your front‑end origin.

---

# 10) Tests (RSpec)

* **Models**: `Doc` (validations), `DocChunk` (position/order), `Question/Answer` relations.
* **Services**: unit tests for `Chunker`, `Retriever` SQL, `Answerer` prompt assembly (mock API).
* **Requests**: happy path & unauthorized for docs/questions.
* **Rate limit**: simulate >quota requests → 429.
* **Billing webhook**: signature verification + plan switch.

---

# 11) React front‑end (outline)

* **Pages**:

  * Auth (login/register)
  * Docs (list/create/upload; show ingest status)
  * Ask AI (chat UI, streaming; show citations inline with `[title#pos]` chips)
  * Dashboard (usage graph, remaining quota)
  * Admin (members, billing upgrade, API keys)
* **Components**: ChatPanel (SSE), CitationList, UsageMeter, DocUploader.
* **States**: user, team, quota, question queue.

---

# 12) Build milestones & acceptance criteria

**Milestone 1 (Week 2)**:

* Create team, invite user, create/edit doc, click “Summarize” → summary saved.
* App deployed to EC2/Render.
* **AC**: 2 users in one team can sign in and see same docs; AI calls succeed & rate‑limited (manual check ok).

**Milestone 2 (Week 4)**:

* Async ingest pipeline: uploading/editing a doc creates chunks + embeddings.
* Ask AI returns answer with 2+ citations.
* Admin shows usage counts; AWS budget alert set.
* **AC**: RAG works with your sample docs; latency < 5s p95 on small corpus.

**Milestone 3 (Week 8)**:

* React client live, streaming answers, Stripe plan toggles quota.
* **AC**: Free user hits 50/day cap → 429; upgrading to Pro raises cap without redeploy.

**Milestone 4 (Week 12)**:

* Logs/metrics available; tests passing; basic evals/guardrails enabled.
* **AC**: Demo script runs start‑to‑finish; README + architecture diagram up to date.

---

# 13) Environment variables (example)

```
RAILS_MASTER_KEY=...
DATABASE_URL=...
REDIS_URL=redis://...
OPENAI_API_KEY=...         # or ANTHROPIC_API_KEY, etc.
EMBEDDINGS_MODEL=text-embedding-3-small
CHAT_MODEL=gpt-4o-mini
STRIPE_PUBLIC_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
APP_HOST=https://yourapp.example
```

---

# 14) Stretch ideas (pick later)

* **Doc Connectors**: Google Drive/Notion import.
* **Semantic cache**: cache answers by (team, query\_vec hash).
* **Feedback loop**: thumbs up/down to collect eval data.
* **SSE w/ tool calling**: follow‑ups fetch missing context automatically.
* **RBAC fine‑grained**: per‑folder permissions.

---

## TL;DR build order

1. Teams/users/auth → Docs CRUD → “Summarize” (direct LLM).
2. Chunk/Embed docs (pgvector) → Q\&A RAG with citations.
3. Quotas + rate limit → Admin usage → React client (chat/stream).
4. Stripe plans → Observability → Tests → Guardrails/Evals → ECS/CloudFront if you want.
