'use client';

import { useEffect, useCallback, useRef } from 'react';
import { usePathname } from 'next/navigation';
import { analyticsService } from '@/lib/services/analytics';
import { useLocation } from '@/hooks/use-location';

const STORAGE_KEY = 'analytics_page_visits';
const SESSION_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
const DEBOUNCE_DELAY = 1000;

interface PageVisit {
  pathname: string;
  timestamp: number;
  visitCount: number;
}

interface PageVisits {
  [key: string]: PageVisit;
}

const getStoredVisits = (): PageVisits => {
  if (typeof window === 'undefined') return {};
  
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return {};
    
    const visits: PageVisits = JSON.parse(stored);
    const now = Date.now();
    
    // Clean up expired entries
    Object.keys(visits).forEach(key => {
      if (now - visits[key].timestamp > SESSION_EXPIRY) {
        delete visits[key];
      }
    });
    
    return visits;
  } catch {
    return {};
  }
};

const updateStoredVisits = (pathname: string, visits: PageVisits) => {
  if (typeof window === 'undefined') return;
  
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(visits));
  } catch {
    // Handle storage errors silently
  }
};

export function useAnalytics() {
  const pathname = usePathname();
  const { location } = useLocation();
  const timeoutRef = useRef<NodeJS.Timeout>();
  const visitsRef = useRef<PageVisits>(getStoredVisits());

  const trackPageView = useCallback(() => {
    const now = Date.now();
    const currentVisit = visitsRef.current[pathname];
    
    // Check if this is a new visit or if the previous visit has expired
    const isNewVisit = !currentVisit || (now - currentVisit.timestamp > SESSION_EXPIRY);
    
    if (isNewVisit) {
      // Track only new visits or expired sessions
      if (location) {
        analyticsService.trackPageView({
          city: location.city,
          country: location.country
        });
      } else {
        analyticsService.trackPageView();
      }
      
      // Update visit information
      visitsRef.current[pathname] = {
        pathname,
        timestamp: now,
        visitCount: (currentVisit?.visitCount || 0) + 1
      };
      
      // Store the updated visits
      updateStoredVisits(pathname, visitsRef.current);
    } else {
      // Just update the timestamp for existing visits
      visitsRef.current[pathname].timestamp = now;
      updateStoredVisits(pathname, visitsRef.current);
    }
  }, [pathname, location]);

  useEffect(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(trackPageView, DEBOUNCE_DELAY);

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [trackPageView]);

  return null;
}
