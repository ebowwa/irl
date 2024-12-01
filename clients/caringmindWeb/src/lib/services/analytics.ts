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

// Backend configuration
const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:9090';
const ANALYTICS_ENDPOINT = '/analytics/track';

class AnalyticsService {
  private static instance: AnalyticsService;
  private visitorId: string;
  private sessionId: string;
  private lastPageView: string | null = null;
  private sessionStartTime: number;
  private readonly SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes
  private metadata: UserMetadata | null = null;

  private constructor() {
    this.sessionStartTime = Date.now();
    this.visitorId = this.getOrCreateVisitorId();
    this.sessionId = this.generateSessionId();
    this.initializeSession();
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

  private async initializeSession() {
    if (typeof window === 'undefined') return;

    // Fetch user metadata
    await this.fetchAndDisplayMetadata();

    // Track initial page view
    await this.trackPageView();

    // Set up session refresh on visibility change
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        const now = Date.now();
        if (now - this.sessionStartTime > this.SESSION_TIMEOUT) {
          // Start new session if previous one expired
          this.sessionId = this.generateSessionId();
          this.sessionStartTime = now;
          this.trackPageView();
          this.fetchAndDisplayMetadata();
        }
      }
    });
  }

  private async fetchAndDisplayMetadata() {
    try {
      const response = await fetch(`${BACKEND_URL}/analytics/user/${this.visitorId}`);
      const result = await response.json();
      
      if (result.success) {
        this.metadata = result.data;
        this.logUserMetadata();
      }
    } catch (error) {
      console.error('Failed to fetch user metadata:', error);
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

    console.group('🔍 User Analytics Data');
    console.log(
      `%c${this.metadata.is_first_visit ? '👋 First time visitor!' : `🔄 Visit #${this.metadata.visit_count}`}`,
      'font-size: 14px; font-weight: bold; color: #4CAF50;'
    );

    if (!this.metadata.is_first_visit) {
      console.log(
        '%cVisit History',
        'font-weight: bold; color: #2196F3;',
        `\n🕐 First visit: ${formatDate(this.metadata.first_visit)}\n🕒 Last visit: ${formatDate(this.metadata.last_visit)}\n⏱️ Total time: ${formatDuration(this.metadata.total_time_spent_seconds)}`
      );

      if (this.metadata.last_page) {
        console.log(
          '%cLast Session',
          'font-weight: bold; color: #9C27B0;',
          `\n📍 Last page: ${this.metadata.last_page}`
        );
      }

      if (this.metadata.city || this.metadata.country) {
        console.log(
          '%cLocation',
          'font-weight: bold; color: #FF9800;',
          `\n🌍 ${[this.metadata.city, this.metadata.country].filter(Boolean).join(', ')}`
        );
      }

      if (this.metadata.recent_events?.length) {
        console.log('%cRecent Activity', 'font-weight: bold; color: #E91E63;');
        this.metadata.recent_events.forEach(event => {
          console.log(`🔸 ${formatDate(event.timestamp)}: ${event.type}`);
          if (event.data) {
            try {
              console.log('  ', JSON.parse(event.data));
            } catch {
              console.log('  ', event.data);
            }
          }
        });
      }
    }
    console.groupEnd();
  }

  public static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  public async trackPageView(location?: { city?: string; country?: string }) {
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
      location,
    };

    await this.sendAnalytics(visitorData);
  }

  public async trackEvent(eventType: string, eventData?: any) {
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

  private async sendAnalytics(visitorData: VisitorData) {
    try {
      const response = await fetch(`${BACKEND_URL}${ANALYTICS_ENDPOINT}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(visitorData),
      });

      const result = await response.json();
      if (!result.success) {
        throw new Error(result.error || 'Failed to track analytics');
      }

      // Send to Google Analytics if available
      if (typeof window.gtag !== 'undefined') {
        window.gtag('event', visitorData.event_type || 'page_view', {
          page_location: visitorData.page,
          page_referrer: visitorData.referrer,
          screen_resolution: visitorData.screen_resolution,
          device_type: visitorData.device_type,
          visitor_id: visitorData.visitor_id,
          session_id: visitorData.session_id,
          ...(visitorData.location && {
            user_location_city: visitorData.location.city,
            user_location_country: visitorData.location.country,
          }),
          ...(visitorData.event_data && { event_data: visitorData.event_data }),
        });
      }

      // Send to Mixpanel if available
      if (typeof window.mixpanel !== 'undefined') {
        window.mixpanel.track(visitorData.event_type || 'page_view', visitorData);
      }

      if (process.env.NODE_ENV === 'development') {
        console.log('Analytics Event:', visitorData);
      }
    } catch (error) {
      console.error('Failed to track analytics:', error);
    }
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
