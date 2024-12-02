'use client';

import { useAnalytics } from '@/hooks/use-analytics';
import GoogleAnalytics from './GoogleAnalytics';

export function Analytics() {
  useAnalytics();
  return <GoogleAnalytics />;
}
