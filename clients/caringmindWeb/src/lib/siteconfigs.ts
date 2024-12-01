// Constants
export const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL;
export const WAITLIST_API = '/waitlist/';

// Combine them for the full waitlist endpoint
export const getWaitlistEndpoint = () => {
  if (!BACKEND_URL) {
    throw new Error('Backend URL is not configured. Please set NEXT_PUBLIC_BACKEND_URL in your environment variables.');
  }
  return `${BACKEND_URL}${WAITLIST_API}`;
};
