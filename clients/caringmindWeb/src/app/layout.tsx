// 1.0.1 Import necessary modules and assets
import './globals.css';
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { Toaster } from "@/components/ui/toaster";
import { Analytics } from '@/components/Analytics';

// 1.0.2 Configure the Inter font with Latin subset
const inter = Inter({ subsets: ['latin'] });

// 1.0.3 Metadata configuration for Next.js application
export const metadata: Metadata = {
  metadataBase: new URL('https://caringmind.xyz'),
  title: {
    default: 'CaringMind - Your Digital Wellness Companion',
    template: '%s | CaringMind',
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
    'social navigation',
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
      alt: 'CaringMind - Digital Wellness Companion',
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

// 1.0.4 Root layout component
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
      <head>
        {/* 1.0.5 Add viewport settings directly in the <head> */}
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
        <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)" />
        <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)" />
      </head>
      <body className="min-h-screen bg-background antialiased">
        {children}
        <Toaster />
        <Analytics />
      </body>
    </html>
  );
}
