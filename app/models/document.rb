class Document < ApplicationRecord
  belongs_to :team
  has_many :summaries, dependent: :destroy
end
