"use client";

export interface LocationData {
  city: string;
  region: string;
  country: string;
  countryCode: string;
}

export interface LocationResponse {
  ip: string;
  city: string;
  region: string;
  country_name: string;
  country_code: string;
}

export class LocationService {
  private static instance: LocationService;
  
  private constructor() {}
  
  public static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  public async getUserLocation(): Promise<LocationData> {
    try {
      const response = await fetch('https://ipapi.co/json/');
      if (!response.ok) {
        throw new Error('Failed to fetch location');
      }
      
      const data = await response.json() as LocationResponse;
      
      return {
        city: data.city,
        region: data.region,
        country: data.country_name,
        countryCode: data.country_code
      };
    } catch (error) {
      console.error('Error fetching location:', error);
      throw error;
    }
  }
}

export const locationService = LocationService.getInstance();