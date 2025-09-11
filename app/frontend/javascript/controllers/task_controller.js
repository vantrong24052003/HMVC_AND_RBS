import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    console.log("Task controller connected")
  }

  addTask() {
    const allTasks = this.listTarget.querySelectorAll('.task-item')
    let maxIndex = -1

    allTasks.forEach((task) => {
      const index = parseInt(task.getAttribute('data-task-index')) || 0
      if (index > maxIndex) maxIndex = index
    })

    const idx = maxIndex + 1
    const html = this.createTaskHTML(idx)

    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  removeTask(event) {
    const taskItem = event.target.closest('.task-item')
    const destroyInput = taskItem.querySelector('input[name*="[_destroy]"]')

    if (destroyInput) {
      destroyInput.value = "1"
    }

    taskItem.style.display = 'none'
  }

  createTaskHTML(idx) {
    return `
      <div class="border border-gray-200 bg-gray-50 rounded-md p-4 task-item" data-task-index="${idx}">
        <div class="flex justify-between items-start mb-3">
          <h4 class="text-sm font-medium text-gray-700">Task #${idx + 1}</h4>
          <button type="button" data-action="click->task#removeTask" class="text-red-600 hover:text-red-800 text-sm font-medium">
            Xóa
          </button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Tiêu đề</label>
            <input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white" type="text" name="todo[tasks_attributes][${idx}][title]">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Mô tả</label>
            <input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white" type="text" name="todo[tasks_attributes][${idx}][description]">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Độ ưu tiên</label>
            <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white" name="todo[tasks_attributes][${idx}][priority]">
              <option value="0">Low</option>
              <option value="1">Medium</option>
              <option value="2">High</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Trạng thái</label>
            <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white" name="todo[tasks_attributes][${idx}][status]">
              <option value="0">Pending</option>
              <option value="1">Progress</option>
              <option value="2">Done</option>
            </select>
          </div>
        </div>
        <input type="hidden" name="todo[tasks_attributes][${idx}][_destroy]" value="0">
      </div>
    `
  }
}
