require 'rails_helper'

RSpec.describe 'Docs', type: :request do
  describe 'GET /docs' do
    it "redirects to login when logged out" do
      get "/docs"
      expect(response).to have_http_status(:see_other).or have_http_status(:found)
      expect(response).to redirect_to(login_path)
    end

    it "lists only current team docs" do
      team_a = create(:team, name: "Acme")
      team_b = create(:team, name: "BetaCorp")
      user   = create(:user)
      create(:membership, user: user, team: team_a)

      create(:doc, team: team_a, title: "Acme Onboarding")
      create(:doc, team: team_b, title: "Beta FAQ")

      post login_path, params: { email: user.email, password: "password123" }
      get "/docs"

      expect(response).to be_successful
      expect(response.body).to include("Acme Onboarding")
      expect(response.body).not_to include("Beta FAQ")
    end
  end

  describe "GET /docs/:id" do
    it "shows a team doc" do
      team = create(:team)
      user = create(:user, password: "password123", password_confirmation: "password123")
      create(:membership, user:, team:)
      doc  = create(:doc, team:, title: "Team Doc")

      post login_path, params: { email: user.email, password: "password123" }
      get "/docs/#{doc.id}"

      expect(response).to be_successful
      expect(response.body).to include("Team Doc")
    end

    it "raises 404 when accessing another team's doc" do
      team_a = create(:team)
      team_b = create(:team)
      user   = create(:user, password: "password123", password_confirmation: "password123")
      create(:membership, user:, team: team_a)

      other_doc = create(:doc, team: team_b)

      post login_path, params: { email: user.email, password: "password123" }
      get "/docs/#{other_doc.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "logging out" do
    it "clears access to /docs" do
      team = create(:team)
      user = create(:user, password: "password123", password_confirmation: "password123")
      create(:membership, user: user, team: team)

      # Log the user in through the actual session controller
      post login_path, params: { email: user.email, password: "password123" }
      expect(response).to redirect_to(root_path)

      # Verify access works while logged in
      get "/docs"
      expect(response).to be_successful

      # Now logout
      delete logout_path
      expect(response).to redirect_to(root_path)

      # Try /docs again → should bounce to login
      get "/docs"
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Please login to continue.")
    end
  end
end
