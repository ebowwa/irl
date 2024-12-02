'use client'

import Script from 'next/script'
import { useEffect } from 'react'

// Declare gtag as a function
declare global {
  interface Window {
    dataLayer: any[]
    gtag?: (...args: any[]) => void  // Make gtag optional with ?
  }
}

const GA_MEASUREMENT_ID = 'G-KMV4Y9H0SX'

const GoogleAnalytics = () => {
  useEffect(() => {
    window.dataLayer = window.dataLayer || []
    function gtag(...args: any[]) {
      window.dataLayer.push(arguments)
    }
    window.gtag = gtag
    window.gtag('js', new Date())
    window.gtag('config', GA_MEASUREMENT_ID)
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
            function gtag(){dataLayer.push(arguments);}
            window.gtag = gtag;
            gtag('js', new Date());
            gtag('config', '${GA_MEASUREMENT_ID}');
          `,
        }}
      />
    </>
  )
}

export default GoogleAnalytics
