"use client";

import { useState, useEffect } from 'react';
import { LocationData, locationService } from '@/lib/services/location';

export function useLocation() {
  const [location, setLocation] = useState<LocationData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;

    async function fetchLocation() {
      try {
        const data = await locationService.getUserLocation();
        if (mounted) {
          setLocation(data);
        }
      } catch (err) {
        if (mounted) {
          console.error('Location fetch error:', err);
          setError(err instanceof Error ? err.message : 'Failed to fetch location');
          // Provide a fallback location
          setLocation({
            city: 'Global',
            region: '',
            country: '',
            countryCode: 'GLOBAL'
          });
        }
      } finally {
        if (mounted) {
          setIsLoading(false);
        }
      }
    }

    fetchLocation();

    return () => {
      mounted = false;
    };
  }, []);

  return { location, isLoading, error };
}