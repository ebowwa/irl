// locationService.ts
"use client";

export interface LocationData {
  city: string;
  region: string;
  country: string;
  countryCode: string;
}

interface IpApiResponse {
  city: string;
  region: string;
  country: string;
  countryCode: string;
}

interface IpInfoResponse {
  city: string;
  region: string;
  country: string;
  country_code: string;
}

export class LocationService {
  private static instance: LocationService;
  private readonly BACKUP_APIS = [
    'https://ipapi.co/json/',
    'https://ip-api.com/json/',
    'https://ipinfo.io/json'
  ];
  
  private constructor() {}
  
  public static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  private async fetchWithTimeout(url: string, timeout = 5000): Promise<Response> {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        signal: controller.signal
      });
      clearTimeout(id);
      return response;
    } catch (error) {
      clearTimeout(id);
      throw error;
    }
  }

  private normalizeLocationData(data: any): LocationData {
    // Handle different API response formats
    return {
      city: data.city || data.name || 'Unknown City',
      region: data.region || data.region_name || data.state || 'Unknown Region',
      country: data.country || data.country_name || 'Unknown Country',
      countryCode: data.country_code || data.countryCode || 'UN'
    };
  }

  public async getUserLocation(): Promise<LocationData> {
    let lastError: Error | null = null;

    // Try each API in sequence until one works
    for (const api of this.BACKUP_APIS) {
      try {
        const response = await this.fetchWithTimeout(api);
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        return this.normalizeLocationData(data);
      } catch (error) {
        console.warn(`Failed to fetch location from ${api}:`, error);
        lastError = error instanceof Error ? error : new Error('Unknown error');
        continue; // Try next API
      }
    }

    // If we get here, all APIs failed
    throw lastError || new Error('Trending Results Failed');
  }
}

export const locationService = LocationService.getInstance();
