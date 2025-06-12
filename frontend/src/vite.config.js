import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite'
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  root: './',
  build: {
    outDir: "../dist",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        participant: resolve(__dirname, 'participant/index.html'),
        experimenter: resolve(__dirname, 'experimenter/index.html'),
      },
    },
  },
  publicDir: './public'
})