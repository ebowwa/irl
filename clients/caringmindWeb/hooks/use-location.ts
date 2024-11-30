"use client";

import { useState, useEffect } from 'react';
import { LocationData, locationService } from '@/lib/services/location';

export function useLocation() {
  const [location, setLocation] = useState<LocationData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchLocation() {
      try {
        const data = await locationService.getUserLocation();
        setLocation(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch location');
      } finally {
        setIsLoading(false);
      }
    }

    fetchLocation();
  }, []);

  return { location, isLoading, error };
}