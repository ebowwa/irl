'use client'

import Script from 'next/script'
import { useEffect } from 'react'

// Declare gtag as a function with the correct type signature
declare global {
  interface Window {
    dataLayer: any[]
    gtag?: (command: string, action: string, params: any) => void
  }
}

const GA_MEASUREMENT_ID = 'G-KMV4Y9H0SX'

const GoogleAnalytics = () => {
  useEffect(() => {
    window.dataLayer = window.dataLayer || []
    function gtag(command: string, action: string, params: any) {
      window.dataLayer.push(arguments)
    }
    window.gtag = gtag
    window.gtag('js', new Date().toString(), {})
    window.gtag('config', GA_MEASUREMENT_ID, {})
  }, [])

  return (
    <>
      <Script
        strategy="afterInteractive"
        src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
      />
      <Script
        id="google-analytics"
        strategy="afterInteractive"
        dangerouslySetInnerHTML={{
          __html: `
            window.dataLayer = window.dataLayer || [];
            function gtag(command, action, params){
              dataLayer.push(arguments);
            }
            window.gtag = gtag;
            gtag('js', new Date().toString(), {});
            gtag('config', '${GA_MEASUREMENT_ID}', {});
          `,
        }}
      />
    </>
  )
}

export default GoogleAnalytics
