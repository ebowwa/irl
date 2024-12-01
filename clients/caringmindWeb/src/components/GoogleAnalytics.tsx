'use client'

import { useEffect } from 'react';
import Script from 'next/script';

// Extend Window interface to include dataLayer
declare global {
  interface Window {
    dataLayer: unknown[];
  }
}

const GA_MEASUREMENT_ID = 'G-ZF2GEYRMSS';

const GoogleAnalytics = () => {
  useEffect(() => {
    const handleLoad = () => {
      window.dataLayer = window.dataLayer || [];
      // Type the gtag function properly
      const gtag = (..._args: unknown[]): void => {
        window.dataLayer.push(_args);
      };
      gtag('js', new Date());
      gtag('config', GA_MEASUREMENT_ID);
    };

    if (document.readyState === 'complete') {
      handleLoad();
    } else {
      window.addEventListener('load', handleLoad);
      return () => window.removeEventListener('load', handleLoad);
    }
  }, []);

  return (
    <>
      <Script
        strategy="afterInteractive"
        src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
      />
    </>
  );
};

export default GoogleAnalytics;
