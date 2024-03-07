import { resolve } from 'path'
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        participant: resolve(__dirname, 'participant/index.html'),
        experimenter: resolve(__dirname, 'experimenter/index.html'),
      },
    },
  },
})