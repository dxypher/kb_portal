class SummariesController < ApplicationController
  before_action :require_login
  before_action :set_document

  def create
    content = Ai::Client.chat(prompt: @document.body)

    summary = @document.summaries.create!(
      team: current_team,
      content: content,
      llm_name: "fake-v1",
      tokens_in: 0,
      tokens_out: 0,
      latency_ms: 0
    )

    redirect_to @document, notice: "Summary created!"
  end

  private

  def set_document
    @document = current_team.documents.find(params[:document_id])
  end
end
