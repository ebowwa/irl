export interface VisitorData {
  visitorId: string;
  timestamp: number;
  page: string;
  referrer: string | null;
  userAgent: string;
  screenResolution: string;
  deviceType: string;
  location?: {
    city?: string;
    country?: string;
  };
}

class AnalyticsService {
  private static instance: AnalyticsService;
  private visitorId: string;

  private constructor() {
    // Generate or retrieve visitor ID
    const storedId = typeof window !== 'undefined' ? localStorage.getItem('visitorId') : null;
    this.visitorId = storedId || this.generateVisitorId();
    if (typeof window !== 'undefined' && !storedId) {
      localStorage.setItem('visitorId', this.visitorId);
    }
  }

  private generateVisitorId(): string {
    // Use crypto API to generate a random ID
    const array = new Uint32Array(4);
    crypto.getRandomValues(array);
    return Array.from(array, x => x.toString(16)).join('');
  }

  public static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  public async trackPageView(location?: { city?: string; country?: string }) {
    if (typeof window === 'undefined') return;

    const visitorData: VisitorData = {
      visitorId: this.visitorId,
      timestamp: Date.now(),
      page: window.location.pathname,
      referrer: document.referrer,
      userAgent: navigator.userAgent,
      screenResolution: `${window.screen.width}x${window.screen.height}`,
      deviceType: this.getDeviceType(),
      location,
    };

    try {
      await fetch('/api/analytics/track', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(visitorData),
      });
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

export const analyticsService = AnalyticsService.getInstance();
