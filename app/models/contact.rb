class Contact < ApplicationRecord
  has_many :notes, dependent: :destroy

  validates :first_name, :last_name, presence: true
end
