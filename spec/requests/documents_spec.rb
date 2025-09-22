require 'rails_helper'

RSpec.describe 'Documents', type: :request do
  describe 'GET /documents' do
    it "redirects to login when logged out" do
      get "/documents"
      expect(response).to have_http_status(:see_other).or have_http_status(:found)
      expect(response).to redirect_to(login_path)
    end

    it "lists only current team documents" do
      team_a = create(:team, name: "Acme")
      team_b = create(:team, name: "BetaCorp")
      user   = create(:user)
      create(:membership, user:, team: team_a)

      doc_a  = create(:document, team: team_a, title: "Acme Onboarding")
      doc_b  = create(:document, team: team_b, title: "Beta FAQ")

      post login_path, params: { email: user.email, password: 'password123' }
      expect(response).to redirect_to root_path

      get "/documents"
      expect(response).to be_successful
      expect(response.body).to include("Acme Onboarding")
      expect(response.body).not_to include("Beta FAQ")
    end
  end

  # describe "GET /docs/:id" do
  #   it "shows a team doc" do
  #     team   = create(:team)
  #     user   = create(:user)
  #     create(:membership, user:, team:)
  #     doc    = create(:doc, team:, title: "Team Doc")

  #     get "/docs/#{doc.id}", env: sign_in(user)

  #     expect(response).to be_successful
  #     expect(response.body).to include("Team Doc")
  #   end

  #   it "raises 404 when accessing another team's doc" do
  #     team_a = create(:team)
  #     team_b = create(:team)
  #     user   = create(:user)
  #     create(:membership, user:, team: team_a)

  #     other_doc = create(:doc, team: team_b)

  #     expect {
  #       get "/docs/#{other_doc.id}", env: sign_in(user)
  #     }.to raise_error(ActiveRecord::RecordNotFound)
  #     # If you rescue and render 404 instead, assert:
  #     # get "/docs/#{other_doc.id}", env: sign_in(user)
  #     # expect(response).to have_http_status(:not_found)
  #   end
  # end
end
