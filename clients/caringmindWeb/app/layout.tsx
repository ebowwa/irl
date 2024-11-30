import './globals.css';
import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import { Toaster } from "@/components/ui/toaster";

const inter = Inter({ subsets: ['latin'] });

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#000000' }
  ]
};

export const metadata: Metadata = {
  metadataBase: new URL('https://caringmind.ai'),
  title: {
    default: 'CaringMind - Your Digital Wellness Companion',
    template: '%s | CaringMind'
  },
  description: 'CaringMind protects your digital wellbeing, advocates for your growth, and helps you navigate life\'s complexities with AI-powered insights.',
  keywords: [
    'digital wellness',
    'AI companion',
    'emotional intelligence',
    'digital wellbeing',
    'voice analysis',
    'mental health',
    'personal growth',
    'wellness tracking',
    'social navigation'
  ],
  authors: [{ name: 'CaringMind AI' }],
  creator: 'CaringMind AI',
  publisher: 'CaringMind AI',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://caringmind.ai',
    title: 'CaringMind - Your Digital Wellness Companion',
    description: 'AI-powered companion for your digital wellbeing and personal growth',
    siteName: 'CaringMind',
    images: [{
      url: 'https://caringmind.ai/og-image.jpg',
      width: 1200,
      height: 630,
      alt: 'CaringMind - Digital Wellness Companion'
    }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'CaringMind - Your Digital Wellness Companion',
    description: 'AI-powered companion for your digital wellbeing and personal growth',
    creator: '@CaringMindAI',
    images: ['https://caringmind.ai/twitter-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  manifest: '/site.webmanifest',
  icons: {
    icon: [
      { url: '/favicon.ico' },
      { url: '/icon.svg', type: 'image/svg+xml' },
      { url: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/icon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [
      { url: '/apple-icon.png', sizes: '180x180', type: 'image/png' },
    ],
    other: [
      { rel: 'mask-icon', url: '/safari-pinned-tab.svg', color: '#6366f1' },
    ],
  },
  verification: {
    google: 'google-site-verification-code',
    yandex: 'yandex-verification-code',
    yahoo: 'yahoo-verification-code',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html 
      lang="en" 
      suppressHydrationWarning
      className={inter.className}
    >
      <body className="min-h-screen bg-background antialiased">
        {children}
        <Toaster />
      </body>
    </html>
  );
}