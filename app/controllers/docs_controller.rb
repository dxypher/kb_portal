class DocsController < ApplicationController
  before_action :require_login
  before_action :set_docs, only: [ :show ]

  def index
    @documents = current_team.docs
  end

  def show
  end

  private

  def set_docs
    @document = current_team.docs.find(params[:id])
  end
end
