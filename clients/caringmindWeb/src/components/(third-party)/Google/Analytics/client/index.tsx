"use client"
/**
Client-Side Integration: If you need to integrate Google Analytics directly into your client-side React components, this snippet is essential. It ensures that the Google Analytics script is loaded and configured correctly on the client side.

Real-Time Tracking: This approach is suitable for real-time tracking of user interactions on the client side, such as page views, button clicks, and form submissions.
 */
import { useEffect } from 'react';
import Script from 'next/script';

const GA_MEASUREMENT_ID = 'G-ZF2GEYRMSS';
// TODO: need to make this configurable to the env or a constants not hard coded into this single script
const GoogleAnalytics = () => {
  useEffect(() => {
    const handleLoad = () => {
      (window as any).dataLayer = (window as any).dataLayer || [];
      function gtag(...args: any[]) {
        (window as any).dataLayer.push(arguments);
      }
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