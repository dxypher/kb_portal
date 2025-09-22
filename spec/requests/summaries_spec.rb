require "rails_helper"

RSpec.describe "Summaries", type: :request do
  describe "POST /docs/:id/summaries" do
    it "creates a summary for the current team's document" do
      team = create(:team)
      user = create(:user, password: "password123", password_confirmation: "password123")
      create(:membership, user: user, team: team)
      doc = create(:document, team: team, body: "This is a test document.")

      # Log in through SessionsController
      post login_path, params: { email: user.email, password: "password123" }
      expect(response).to redirect_to(root_path)

      # Hit the summarize route
      expect {
        post document_summaries_path(doc)
      }.to change { Summary.count }.by(1)

      summary = Summary.last
      expect(summary.document).to eq(doc)
      expect(summary.team).to eq(team)
      expect(summary.content).to include("Fake summary")

      # Should redirect back to the doc page
      expect(response).to redirect_to(document_path(doc))
    end
  end
end
