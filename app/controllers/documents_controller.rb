class DocumentsController < ApplicationController
  before_action :require_login
  before_action :set_docs, only: [ :show ]

  def index
    @documents = current_team.documents
  end

  def show
  end

  private

  def set_docs
    @document = current_team.documents.find(params[:id])
  end
end
