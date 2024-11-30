'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { analyticsService } from '@/lib/services/analytics';
import { useLocation } from '@/hooks/use-location';

export function useAnalytics() {
  const pathname = usePathname();
  const { location } = useLocation();

  useEffect(() => {
    // Track page view whenever the pathname changes
    if (location) {
      analyticsService.trackPageView({
        city: location.city,
        country: location.country
      });
    } else {
      analyticsService.trackPageView();
    }
  }, [pathname, location]);

  return null;
}
