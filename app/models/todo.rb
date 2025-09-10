class Todo < ApplicationRecord
  enumerize :priority, in: { low: 0, medium: 1, high: 2 }
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }

  after_destroy_commit -> { broadcast_remove_to :todos }
end
