import type { GeneratedFile } from '../codegen'

export async function writeGeneratedFiles(files: GeneratedFile[]): Promise<{ success: boolean; written: string[]; error?: string }> {
  try {
    const res = await fetch('/api/write-files', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ files }),
    })
    if (!res.ok) {
      const text = await res.text()
      return { success: false, written: [], error: text }
    }
    return await res.json()
  } catch (err) {
    return { success: false, written: [], error: String(err) }
  }
}
