"use client"; // 1. Ensure this is the first line to designate a client-side component

import React, { useState, useEffect } from 'react';
import { Heart, Sparkles, Brain, Check } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import Image from 'next/image';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";

const WAITLIST_ENDPOINT = 'https://8bdb-2a09-bac5-661b-1232-00-1d0-c6.ngrok-free.app/waitlist/';
// TODO: 
// the endpoint should just be the route
// set a second definition for the url as base server
// handleSubmit currently fetches the WAITLIST_ENDPOINT and we need to be sure not to break this 

// 2. Define the form data interface without referral_source
interface FormData {
  name: string;
  email: string;
  comment: string;
}

const SplashPage: React.FC = () => {
  const { t, ready } = useTranslation(['home', 'common']);
  const [mounted, setMounted] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const [isHovering, setIsHovering] = useState(false);
  const [isWaitlistOpen, setIsWaitlistOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showThankYouDialog, setShowThankYouDialog] = useState(false);
  const { toast } = useToast();

  // 3. Initialize formData without referral_source
  const [formData, setFormData] = useState<FormData>({
    name: '',
    email: '',
    comment: ''
  });

  const images = [
    {
      url: "/api/placeholder/1200/800",
      title: ready ? t('home:carousel.personal_growth.title') : '',
      description: ready ? t('home:carousel.personal_growth.description') : ''
    },
    {
      url: "/api/placeholder/1200/800",
      title: ready ? t('home:carousel.deep_connection.title') : '',
      description: ready ? t('home:carousel.deep_connection.description') : ''
    },
    {
      url: "/api/placeholder/1200/800",
      title: ready ? t('home:carousel.emotional_intelligence.title') : '',
      description: ready ? t('home:carousel.emotional_intelligence.description') : ''
    }
  ];

  // 4. Capture referral_source from URL parameters or referrer
  useEffect(() => {
    // 4.1. Extract UTM and custom referral parameters from the URL
    const queryString = window.location.search;
    const urlParams = new URLSearchParams(queryString);
    const utmSource = urlParams.get('utm_source');
    const utmMedium = urlParams.get('utm_medium');
    const utmCampaign = urlParams.get('utm_campaign');
    const customReferral = urlParams.get('referral');

    let referral = '';

    if (utmSource) referral += `source:${utmSource};`;
    if (utmMedium) referral += `medium:${utmMedium};`;
    if (utmCampaign) referral += `campaign:${utmCampaign};`;
    if (customReferral) referral += `referral:${customReferral};`;

    if (referral) {
      // 4.2. Store referral_source in localStorage and cookies for persistence
      localStorage.setItem('referral_source', referral);
      document.cookie = `referral_source=${encodeURIComponent(referral)}; path=/; max-age=${60 * 60 * 24 * 30}`; // Expires in 30 days
    } else {
      // 4.3. If no UTM params, check document.referrer
      const referrer = document.referrer;
      if (referrer) {
        // Only set if referral_source is not already set
        const existingReferral = localStorage.getItem('referral_source');
        if (!existingReferral) {
          const refSource = `referrer:${referrer}`;
          localStorage.setItem('referral_source', refSource);
          document.cookie = `referral_source=${encodeURIComponent(refSource)}; path=/; max-age=${60 * 60 * 24 * 30}`;
        }
      } else {
        // 4.4. Try to retrieve referral_source from cookies if not present in URL or referrer
        const cookies = document.cookie.split(';').reduce((acc: { [key: string]: string }, cookie) => {
          const [key, value] = cookie.trim().split('=');
          acc[key] = value;
          return acc;
        }, {});

        if (cookies.referral_source) {
          localStorage.setItem('referral_source', decodeURIComponent(cookies.referral_source));
        }
      }
    }
  }, []); // 4.5. Empty dependency array, runs once on mount

  // 5. Set mounted to true after component mounts to avoid hydration mismatches
  useEffect(() => {
    setMounted(true);
  }, []);

  // 6. Handle image carousel autoplay with hover pause
  useEffect(() => {
    const timer = setInterval(() => {
      if (!isHovering) {
        setActiveIndex((current) => (current + 1) % images.length);
      }
    }, 5000);

    return () => clearInterval(timer);
  }, [isHovering, images.length]);

  // 7. Handle form input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // 8. Handle form submission, including referral_source
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    // 8.1. Retrieve referral_source from localStorage
    const storedReferralSource = localStorage.getItem('referral_source') || '';

    try {
      const response = await fetch(WAITLIST_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: formData.name,
          email: formData.email,
          comment: formData.comment,
          referral_source: storedReferralSource // 8.2. Include referral_source in the POST request
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to join waitlist');
      }

      // 8.3. Close the waitlist dialog and show the thank you dialog
      setIsWaitlistOpen(false);
      setShowThankYouDialog(true);

      // 8.4. Reset the form
      setFormData({ name: '', email: '', comment: '' });

      // 8.5. Optionally, remove the referral_source from localStorage and cookies after submission
      localStorage.removeItem('referral_source');
      document.cookie = `referral_source=; path=/; max-age=0`; // Deletes the cookie
    } catch {
      // 8.6. Show error toast if submission fails
      toast({
        title: "Error",
        description: "There was a problem joining the waitlist. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  // 9. Thank You Dialog Component
  const ThankYouDialog: React.FC = () => (
    <Dialog open={showThankYouDialog} onOpenChange={setShowThankYouDialog}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100 mb-4">
            <Check className="h-6 w-6 text-green-600" />
          </div>
          <DialogTitle className="text-center text-xl">Thank You for Joining!</DialogTitle>
          <DialogDescription className="text-center">
            <p className="mt-2">
              Thank you for your interest in our platform, {formData.name}! We&apos;re thrilled to have you join our waitlist.
            </p>
            <p className="mt-4">
              We&apos;ll keep you updated on our progress and notify you as soon as we launch. In the meantime, keep an eye on your inbox for exclusive updates and early access opportunities!
            </p>
          </DialogDescription>
        </DialogHeader>
        <div className="mt-6 flex justify-center">
          <Button 
            onClick={() => setShowThankYouDialog(false)}
            className="bg-purple-600 hover:bg-purple-700"
          >
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );

  // 10. Prevent rendering until the component is mounted and translations are ready
  if (!mounted || !ready) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-gray-50">
      {/* Hero Section */}
      <div className="relative h-screen flex flex-col items-center justify-center px-4">
        <div className="absolute inset-0 bg-gradient-to-b from-purple-50/50 to-transparent" />

        {/* Logo Animation */}
        <div className="relative w-32 h-32 mb-8">
          <div className="absolute inset-0 bg-gradient-to-r from-purple-100 to-pink-50 rounded-full animate-pulse" />
          <div className="absolute inset-4 bg-white rounded-full shadow-lg flex items-center justify-center">
            <Brain className="w-12 h-12 text-purple-600" />
          </div>
        </div>

        {/* Language Switcher */}
        <div className="absolute top-4 right-4">
          <LanguageSwitcher />
        </div>
        
        <h1 className="text-6xl font-bold mb-4 text-gray-900">
          {t('home:hero.title')}
        </h1>
        <p className="text-2xl text-gray-600 mb-12">{t('home:hero.subtitle')}</p>

        {/* Image Carousel */}
        <div
          className="relative w-full max-w-4xl h-96 mb-12 rounded-2xl overflow-hidden shadow-2xl"
          onMouseEnter={() => setIsHovering(true)}
          onMouseLeave={() => setIsHovering(false)}
        >
          {images.map((image, index) => (
            <div
              key={index}
              className={`absolute inset-0 transition-all duration-700 ease-in-out ${
                index === activeIndex ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-full'
              }`}
            >
              <Image
                src={image.url}
                alt={image.title}
                className="object-cover"
                fill
                priority={index === 0}
                sizes="(max-width: 1280px) 100vw, 1280px"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex flex-col justify-end p-8">
                <h3 className="text-3xl font-bold text-white mb-2">{image.title}</h3>
                <p className="text-xl text-gray-200">{image.description}</p>
              </div>
            </div>
          ))}

          <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
            {images.map((_, index) => (
              <button
                key={index}
                className={`w-2 h-2 rounded-full transition-all ${
                  index === activeIndex ? 'bg-white w-6' : 'bg-white/50'
                }`}
                onClick={() => setActiveIndex(index)}
              />
            ))}
          </div>
        </div>

        {/* Call-to-Action Buttons */}
        <div className="flex space-x-4">
          <Dialog open={isWaitlistOpen} onOpenChange={setIsWaitlistOpen}>
            <DialogTrigger asChild>
              <button className="px-8 py-3 bg-purple-600 text-white rounded-full font-medium hover:bg-purple-700 transform hover:scale-105 transition-all">
                {t('common:actions.get_started')}
              </button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-md">
              <DialogHeader>
                <DialogTitle>Join our Waitlist</DialogTitle>
                <DialogDescription>
                  Be among the first to experience our platform. We&apos;ll notify you as soon as we launch!
                </DialogDescription>
              </DialogHeader>
              {/* 11. Remove the referral_source input field as it's handled in the background */}
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Name</Label>
                  <Input
                    id="name"
                    name="name"
                    placeholder="Enter your name"
                    value={formData.name}
                    onChange={handleInputChange}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    placeholder="Enter your email"
                    value={formData.email}
                    onChange={handleInputChange}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="comment">What excites you most about our platform?</Label>
                  <Textarea
                    id="comment"
                    name="comment"
                    placeholder="Tell us what excites you..."
                    value={formData.comment}
                    onChange={handleInputChange}
                    className="h-24"
                  />
                </div>
                {/* 12. Optionally, display referral_source for debugging purposes */}
                {/* 
                <div className="space-y-2">
                  <Label htmlFor="referral_source_display">Referral Source</Label>
                  <Input
                    id="referral_source_display"
                    name="referral_source_display"
                    placeholder="Referral Source (auto)"
                    value={storedReferralSource}
                    readOnly
                  />
                </div>
                */}
                <div className="flex justify-end">
                  <Button type="submit" disabled={isSubmitting}>
                    {isSubmitting ? 'Submitting...' : 'Join Waitlist'}
                  </Button>
                </div>
              </form>
            </DialogContent>
          </Dialog>
          <button className="px-8 py-3 border border-purple-200 text-purple-600 rounded-full font-medium hover:bg-purple-50 transform hover:scale-105 transition-all">
            {t('common:actions.learn_more')}
          </button>
        </div>
      </div>

      {/* Features Grid Section */}
      <div className="max-w-6xl mx-auto px-4 py-24 grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="p-6 bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mb-4">
            <Brain className="w-6 h-6 text-purple-600" />
          </div>
          <h3 className="text-xl font-semibold mb-2 text-gray-900">
            {t('home:features.deep_understanding.title')}
          </h3>
          <p className="text-gray-600">
            {t('home:features.deep_understanding.description')}
          </p>
        </div>

        <div className="p-6 bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          <div className="w-12 h-12 bg-pink-100 rounded-full flex items-center justify-center mb-4">
            <Heart className="w-6 h-6 text-pink-600" />
          </div>
          <h3 className="text-xl font-semibold mb-2 text-gray-900">
            {t('home:features.emotional_intelligence.title')}
          </h3>
          <p className="text-gray-600">
            {t('home:features.emotional_intelligence.description')}
          </p>
        </div>

        <div className="p-6 bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mb-4">
            <Sparkles className="w-6 h-6 text-blue-600" />
          </div>
          <h3 className="text-xl font-semibold mb-2 text-gray-900">
            {t('home:features.personal_growth.title')}
          </h3>
          <p className="text-gray-600">
            {t('home:features.personal_growth.description')}
          </p>
        </div>
      </div>

      {/* Footer Section */}
      <footer className="bg-white border-t border-gray-100 py-8 text-center text-gray-600">
        <p className="text-sm">
          {t('common:footer.copyright')}
        </p>
      </footer>

      {/* Thank You Dialog */}
      <ThankYouDialog />
    </div>
  );
};

export default SplashPage;
