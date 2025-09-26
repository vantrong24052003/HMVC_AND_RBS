import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  build: {
    rollupOptions: {
      input: {
        'javascript/application': 'app/frontend/javascript/application.js'
      }
    }
  }
})
