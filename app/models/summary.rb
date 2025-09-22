class Summary < ApplicationRecord
  belongs_to :document
  belongs_to :team
end
