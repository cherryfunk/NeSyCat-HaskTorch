import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import { injectThemeVars } from './lib/theme'
import './index.css'

injectThemeVars()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
