import { defineConfig } from 'vite'
import type { Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import * as fs from 'fs'
import * as path from 'path'

// Vite plugin that provides /api/write-files endpoint
// Writes generated Haskell files to the NeSyCat-HaskTorch repo
function fileWritePlugin(): Plugin {
  const repoRoot = path.resolve(__dirname, '..')

  return {
    name: 'file-writer',
    configureServer(server) {
      server.middlewares.use('/api/write-files', (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405
          res.end('Method not allowed')
          return
        }

        let body = ''
        req.on('data', (chunk: Buffer) => { body += chunk.toString() })
        req.on('end', () => {
          try {
            const { files } = JSON.parse(body) as { files: { path: string; content: string }[] }
            const written: string[] = []

            for (const file of files) {
              // Validate path is within allowed directories
              const allowed = ['C_Domain/', 'D_Grammatical/']
              if (!allowed.some((dir) => file.path.startsWith(dir))) {
                res.statusCode = 400
                res.end(`Path not allowed: ${file.path}`)
                return
              }

              const fullPath = path.join(repoRoot, file.path)

              // Ensure directory exists
              const dir = path.dirname(fullPath)
              if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true })
              }

              fs.writeFileSync(fullPath, file.content, 'utf-8')
              written.push(file.path)
            }

            res.setHeader('Content-Type', 'application/json')
            res.end(JSON.stringify({ success: true, written }))
          } catch (err) {
            res.statusCode = 500
            res.end(String(err))
          }
        })
      })
    },
  }
}

export default defineConfig({
  plugins: [react(), tailwindcss(), fileWritePlugin()],
  server: {
    port: 5174,
  },
})
