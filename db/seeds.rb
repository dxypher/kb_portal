# Team(id, name, plan, quota_daily, quota_reset_at, created_at, updated_at)

# Membership(id, team_id, user_id, role [owner|admin|member|viewer], created_at)
#   idx: [team_id, user_id] unique

# User(id, email, password_digest, name, last_sign_in_at, created_at, updated_at)
#   idx: email unique

# Doc(id, team_id, title, source_type [upload|url|manual], body(text), tokens(int),
#     visibility [team|private], created_at, updated_at)
#   idx: team_id, idx: [team_id, title]

team = Team.find_or_create_by(name: 'Acme') do |t|
  t.plan = "free"
  t.quota_daily = 100
end

owner = User.find_or_create_by(email: 'owner@acme.com') do |u|
  u.name = 'Alice Owner'
  u.password = 'password'
end

member = User.find_or_create_by(email: 'member@acme.com') do |u|
  u.name = 'Bob Member'
  u.password = 'password'
end

Membership.find_or_create_by(team: team, user: owner) do |m|
  m.role = 'owner'
end

Membership.find_or_create_by(team: team, user: member) do |m|
  m.role = 'member'
end

docs = [
  {
    title: "Onboarding Guide",
    source_type: "manual",
    body: "Welcome to Acme Inc! Here's everything you need to get started.",
    visibility: "team",
    tokens: 150
  },
  {
    title: "FAQ",
    source_type: "manual",
    body: "Frequently asked questions about Acme Inc products and policies.",
    visibility: "team",
    tokens: 90
  }
]

docs.each do |attrs|
  doc = Doc.find_or_initialize_by(team: team, title: attrs[:title])
  doc.update!(attrs)
end
