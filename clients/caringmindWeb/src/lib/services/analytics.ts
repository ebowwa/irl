// Constants
const FALLBACK_MODE = process.env.NODE_ENV === 'development';
const ANALYTICS_ENDPOINT = '/analytics/track';
const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL;

// Headers to bypass ngrok warning
const DEFAULT_HEADERS = {
  'Accept': 'application/json',
  'ngrok-skip-browser-warning': 'true'
};

class AnalyticsService {
  private static instance: AnalyticsService;
  private visitorId: string;
  private sessionId: string;
  private lastPageView: string | null = null;
  private sessionStartTime: number;
  private readonly SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes
  private metadata: UserMetadata | null = null;
  private initialized: boolean = false;

  private constructor() {
    this.sessionStartTime = Date.now();
    this.visitorId = this.getOrCreateVisitorId();
    this.sessionId = this.generateSessionId();
    
    if (typeof window !== 'undefined') {
      this.initialize();
    }
  }

  private async initialize() {
    if (this.initialized) return;
    this.initialized = true;

    try {
      if (!BACKEND_URL) {
        if (FALLBACK_MODE) {
          console.warn('Analytics: Backend URL not configured');
        }
        return;
      }

      await this.fetchAndDisplayMetadata();
      await this.trackPageView();

      // Set up session refresh
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') {
          const now = Date.now();
          if (now - this.sessionStartTime > this.SESSION_TIMEOUT) {
            this.sessionId = this.generateSessionId();
            this.sessionStartTime = now;
            this.refreshSession();
          }
        }
      });

      if (FALLBACK_MODE) {
        console.log('Analytics initialized successfully! 📊');
      }
    } catch (error) {
      if (FALLBACK_MODE) {
        console.warn('Analytics initialization error:', error);
      }
    }
  }

  private async fetchAndDisplayMetadata() {
    try {
      const response = await fetch(`${BACKEND_URL}/analytics/user/${this.visitorId}`, {
        headers: DEFAULT_HEADERS
      });
      
      const result = await response.json();
      
      if (!result.success) {
        throw new Error(result.error || 'Failed to fetch metadata');
      }

      this.metadata = result.data;
      if (FALLBACK_MODE) {
        this.logUserMetadata();
      }
      return result.data;
    } catch (error) {
      if (FALLBACK_MODE) {
        console.warn('Analytics: Error fetching metadata');
      }
      return null;
    }
  }

  private async sendAnalytics(visitorData: VisitorData) {
    try {
      const response = await fetch(`${BACKEND_URL}${ANALYTICS_ENDPOINT}`, {
        method: 'POST',
        headers: {
          ...DEFAULT_HEADERS,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(visitorData),
      });

      const result = await response.json();
      if (!result.success) {
        throw new Error(result.error || 'Failed to track analytics');
      }

      if (FALLBACK_MODE) {
        console.log('Analytics Event:', visitorData);
      }
    } catch (error) {
      if (FALLBACK_MODE) {
        console.warn('Analytics: Error sending analytics');
      }
    }
  }

  private logUserMetadata() {
    if (!this.metadata) return;

    const formatDate = (dateStr?: string) => {
      if (!dateStr) return 'N/A';
      return new Date(dateStr).toLocaleString();
    };

    const formatDuration = (seconds?: number) => {
      if (!seconds) return 'N/A';
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      return `${hours}h ${minutes}m`;
    };

    console.group('%c🔍 CaringMind User Analytics', 'font-size: 16px; font-weight: bold; color: #2196F3;');
    
    // Visitor Status
    const isFirstVisit = !localStorage.getItem('visitorId');
    console.log(
      `%c${isFirstVisit ? '👋 Welcome, First Time Visitor!' : `🔄 Welcome Back! (Visit #${this.metadata.visit_count})`}`,
      'font-size: 14px; font-weight: bold; color: #4CAF50;'
    );

    if (!isFirstVisit && this.metadata.visit_count > 0) {
      // Visit History
      console.group('%c📅 Visit History', 'color: #2196F3; font-weight: bold;');
      console.log(
        `%c🕐 First Visit:%c ${formatDate(this.metadata.first_visit)}`,
        'color: #666;', 'color: #000; font-weight: bold;'
      );
      console.log(
        `%c🕒 Last Visit:%c ${formatDate(this.metadata.last_visit)}`,
        'color: #666;', 'color: #000; font-weight: bold;'
      );
      console.log(
        `%c⏱️ Total Time:%c ${formatDuration(this.metadata.total_time_spent_seconds)}`,
        'color: #666;', 'color: #000; font-weight: bold;'
      );
      console.groupEnd();

      // Location Info
      if (this.metadata.city || this.metadata.country) {
        console.group('%c📍 Location', 'color: #FF9800; font-weight: bold;');
        console.log(
          `%c🌍 ${[this.metadata.city, this.metadata.country].filter(Boolean).join(', ')}`,
          'color: #000; font-weight: bold;'
        );
        console.groupEnd();
      }

      // Recent Activity
      if (this.metadata.recent_events?.length) {
        console.group('%c🎯 Recent Activity', 'color: #E91E63; font-weight: bold;');
        this.metadata.recent_events.forEach(event => {
          console.log(
            `%c${formatDate(event.timestamp)}:%c ${event.type}`,
            'color: #666;', 'color: #000; font-weight: bold;'
          );
          if (event.data) {
            try {
              console.log('  ', JSON.parse(event.data));
            } catch {
              console.log('  ', event.data);
            }
          }
        });
        console.groupEnd();
      }
    }

    console.groupEnd();
  }

  private async refreshSession() {
    await this.fetchAndDisplayMetadata();
    await this.trackPageView();
  }

  // Public method to track page views
  public async trackPageView(locationData?: { city?: string; country?: string }) {
    if (typeof window === 'undefined') return;

    const currentPage = window.location.pathname;
    if (this.lastPageView === currentPage) return; // Don't track same page twice
    this.lastPageView = currentPage;

    const visitorData: VisitorData = {
      visitor_id: this.visitorId,
      session_id: this.sessionId,
      timestamp: Date.now(),
      page: currentPage,
      referrer: document.referrer,
      user_agent: navigator.userAgent,
      screen_resolution: `${window.screen.width}x${window.screen.height}`,
      device_type: this.getDeviceType(),
      location: locationData,
    };

    await this.sendAnalytics(visitorData);
  }

  private async trackEvent(eventType: string, eventData?: any) {
    if (typeof window === 'undefined') return;

    const visitorData: VisitorData = {
      visitor_id: this.visitorId,
      session_id: this.sessionId,
      timestamp: Date.now(),
      page: window.location.pathname,
      referrer: document.referrer,
      user_agent: navigator.userAgent,
      screen_resolution: `${window.screen.width}x${window.screen.height}`,
      device_type: this.getDeviceType(),
      event_type: eventType,
      event_data: eventData,
    };

    await this.sendAnalytics(visitorData);
  }

  private getOrCreateVisitorId(): string {
    if (typeof window === 'undefined') return '';
    
    const storedId = localStorage.getItem('visitorId');
    if (storedId) return storedId;
    
    const newId = this.generateId();
    localStorage.setItem('visitorId', newId);
    return newId;
  }

  private generateSessionId(): string {
    if (typeof window === 'undefined') return '';
    
    const currentSession = sessionStorage.getItem('sessionId');
    if (currentSession) return currentSession;
    
    const newSession = this.generateId();
    sessionStorage.setItem('sessionId', newSession);
    return newSession;
  }

  private generateId(): string {
    const array = new Uint32Array(4);
    crypto.getRandomValues(array);
    return Array.from(array, x => x.toString(16)).join('');
  }

  private getDeviceType(): string {
    const ua = navigator.userAgent;
    if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
      return 'tablet';
    }
    if (/Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(ua)) {
      return 'mobile';
    }
    return 'desktop';
  }

  public static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }
}

declare global {
  interface Window {
    gtag?: (command: string, action: string, params: any) => void;
    mixpanel?: {
      track: (event: string, properties: any) => void;
    };
  }
}

export const analyticsService = AnalyticsService.getInstance();

export interface VisitorData {
  visitor_id: string;
  session_id: string;
  timestamp: number;
  page: string;
  referrer: string | null;
  user_agent: string;
  screen_resolution: string;
  device_type: string;
  location?: {
    city?: string;
    country?: string;
  };
  event_type?: string;
  event_data?: any;
}

interface UserMetadata {
  is_first_visit: boolean;
  first_visit?: string;
  last_visit?: string;
  visit_count: number;
  total_time_spent_seconds?: number;
  last_page?: string;
  device_type?: string;
  city?: string;
  country?: string;
  recent_events?: Array<{
    type: string;
    data: string;
    timestamp: string;
  }>;
}
