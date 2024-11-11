"use client"
import React, { useState, useEffect } from 'react';
import { Heart, Sparkles, Brain, X } from 'lucide-react';
import { useTranslation } from 'react-i18next';
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

const SplashPage = () => {
  const { t, ready } = useTranslation(['home', 'common']);
  const [mounted, setMounted] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const [isHovering, setIsHovering] = useState(false);
  const [isWaitlistOpen, setIsWaitlistOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { toast } = useToast();

  // Handle client-side mounting
  useEffect(() => {
    setMounted(true);
  }, []);

  // Form state
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    interests: ''
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

  useEffect(() => {
    const timer = setInterval(() => {
      if (!isHovering) {
        setActiveIndex((current) => (current + 1) % images.length);
      }
    }, 5000);
    return () => clearInterval(timer);
  }, [isHovering, images.length]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const response = await fetch('http://127.0.0.1:9090/waitlist/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: formData.name,
          email: formData.email,
          interests: formData.interests
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to join waitlist');
      }

      toast({
        title: "Success!",
        description: "You've been added to our waitlist. We'll be in touch soon!",
      });

      setIsWaitlistOpen(false);
      setFormData({ name: '', email: '', interests: '' });
    } catch (error) {
      toast({
        title: "Error",
        description: "There was a problem joining the waitlist. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Don't render anything until client-side mounted and translations are ready
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
              <img
                src={image.url}
                alt={image.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex flex-col justify-end p-8">
                <h3 className="text-3xl font-bold text-white mb-2">{image.title}</h3>
                <p className="text-xl text-gray-200">{image.description}</p>
              </div>
            </div>
          ))}

          {/* Carousel Controls */}
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

        {/* CTA Buttons */}
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
                  Be among the first to experience our platform. We'll notify you as soon as we launch!
                </DialogDescription>
              </DialogHeader>
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
                  <Label htmlFor="interests">What excites you most about our platform?</Label>
                  <Textarea
                    id="interests"
                    name="interests"
                    placeholder="Tell us what interests you..."
                    value={formData.interests}
                    onChange={handleInputChange}
                    className="h-24"
                  />
                </div>
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

      {/* Features Grid */}
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

      {/* Footer */}
      <footer className="bg-white border-t border-gray-100 py-8 text-center text-gray-600">
        <p className="text-sm">
          {t('common:footer.copyright')}
        </p>
      </footer>
    </div>
  );
};

export default SplashPage;