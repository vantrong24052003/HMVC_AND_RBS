class Todo < ApplicationRecord
  enumerize :priority, in: { low: 0, medium: 1, high: 2 }
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }

  # create todo to list, option target: "todos" is the id of the list in the view (index.html.erb)
  after_create_commit -> { broadcast_append_to :todos, target: "todos" }

  # update todo in list, option target: "todos" is the id of the list in the view (index.html.erb)
  after_update_commit -> { broadcast_replace_to :todos }

  # remove todo from list
  after_destroy_commit -> { broadcast_remove_to :todos }
end
