class DocsController < ApplicationController
  before_action :require_login

  def index
    @documents = Doc.all
  end
end
