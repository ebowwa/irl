// src/components/dom/Layout.tsx
'use client'

import { useRef } from 'react'
// const Scene = dynamic(() => import('@/components/three/assets/canvas/Scene'), { ssr: false })

interface LayoutProps {
  children: React.ReactNode;
}

const Layout = ({ children }: LayoutProps) => {
  const ref = useRef<HTMLDivElement>(null)

  return (
    <div
      ref={ref}
      style={{
        position: 'relative',
        width: ' 100%',
        height: '100%',
        overflow: 'auto',
        touchAction: 'auto',
      }}
    >
      {children}
      {/* Scene component temporarily commented out
      <Scene
        style={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
          pointerEvents: 'none',
        }}
        eventSource={ref}
        eventPrefix='client'
      />
      */}
    </div>
  )
}

export { Layout }
