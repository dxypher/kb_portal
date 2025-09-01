class DocsController < ApplicationController
  def index
    @documents = Doc.all
  end
end
