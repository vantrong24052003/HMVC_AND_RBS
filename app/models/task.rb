class Task < ApplicationRecord
  belongs_to :todo

  enumerize :priority, in: { low: 0, medium: 1, high: 2 }
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }

  validates :title, presence: true
  validates :description, presence: true
end
