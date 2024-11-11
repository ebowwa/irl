// "use client" directive for Next.js to enable client-side rendering
"use client";

import React, { useState, useEffect } from 'react';
import { Heart, Sparkles, Brain } from 'lucide-react';
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

// Define the endpoint for the waitlist API
const WAITLIST_ENDPOINT = 'https://2157-2601-646-a201-db60-00-2386.ngrok-free.app/waitlist/';

// Functional component for the Splash Page
const SplashPage = () => {
  // Translation hook for internationalization
  const { t, ready } = useTranslation(['home', 'common']);
  
  // State to determine if the component has been mounted on the client-side
  const [mounted, setMounted] = useState(false);
  
  // State to manage the active index of the image carousel
  const [activeIndex, setActiveIndex] = useState(0);
  
  // State to determine if the user is hovering over the carousel
  const [isHovering, setIsHovering] = useState(false);
  
  // State to control the visibility of the waitlist dialog
  const [isWaitlistOpen, setIsWaitlistOpen] = useState(false);
  
  // State to indicate if the form is in the process of being submitted
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // Toast hook for displaying notifications
  const { toast } = useToast();

  // Form state to manage user inputs
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    comment: '' // Renamed from 'interests' to 'comment' to align with backend
  });

  // Array of images for the carousel with corresponding titles and descriptions
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

  /**
   * Effect hook to set the 'mounted' state to true after the component mounts on the client-side.
   * This prevents server-side rendering issues with certain components or behaviors.
   */
  useEffect(() => {
    setMounted(true);
  }, []);

  /**
   * Effect hook to handle the automatic cycling of the image carousel.
   * The carousel advances every 5 seconds unless the user is hovering over it.
   */
  useEffect(() => {
    const timer = setInterval(() => {
      if (!isHovering) {
        setActiveIndex((current) => (current + 1) % images.length);
      }
    }, 5000); // Change image every 5 seconds

    // Cleanup function to clear the interval when the component unmounts or dependencies change
    return () => clearInterval(timer);
  }, [isHovering, images.length]);

  /**
   * Handler for input changes in the form fields.
   * It updates the corresponding field in the formData state.
   * @param e - The change event from the input or textarea.
   */
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  /**
   * Handler for form submission.
   * It sends a POST request to the waitlist endpoint with the form data.
   * @param e - The form submission event.
   */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); // Prevent the default form submission behavior
    setIsSubmitting(true); // Indicate that the submission is in progress

    try {
      // Send a POST request to the waitlist endpoint with the form data
      const response = await fetch(WAITLIST_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: formData.name,
          email: formData.email,
          comment: formData.comment // Updated field name to 'comment'
        }),
      });

      // If the response is not OK, throw an error to be caught in the catch block
      if (!response.ok) {
        throw new Error('Failed to join waitlist');
      }

      // Display a success toast notification to the user
      toast({
        title: "Success!",
        description: "You&apos;ve been added to our waitlist. We&apos;ll be in touch soon!",
      });

      // Close the waitlist dialog
      setIsWaitlistOpen(false);

      // Reset the form fields
      setFormData({ name: '', email: '', comment: '' }); // Reset 'comment' field
    } catch {
      // Display an error toast notification to the user
      toast({
        title: "Error",
        description: "There was a problem joining the waitlist. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false); // Indicate that the submission has completed
    }
  };

  /**
   * Conditional rendering to ensure that the component only renders on the client-side
   * and that translations are ready.
   */
  if (!mounted || !ready) {
    return null; // Render nothing until conditions are met
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-gray-50">
      {/* Hero Section */}
      <div className="relative h-screen flex flex-col items-center justify-center px-4">
        {/* Background gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-purple-50/50 to-transparent" />

        {/* Logo Animation */}
        <div className="relative w-32 h-32 mb-8">
          {/* Pulsing gradient circle */}
          <div className="absolute inset-0 bg-gradient-to-r from-purple-100 to-pink-50 rounded-full animate-pulse" />
          {/* Inner white circle with Brain icon */}
          <div className="absolute inset-4 bg-white rounded-full shadow-lg flex items-center justify-center">
            <Brain className="w-12 h-12 text-purple-600" />
          </div>
        </div>

        {/* Language Switcher positioned at the top-right corner */}
        <div className="absolute top-4 right-4">
          <LanguageSwitcher />
        </div>
        
        {/* Main Hero Title */}
        <h1 className="text-6xl font-bold mb-4 text-gray-900">
          {t('home:hero.title')}
        </h1>
        {/* Hero Subtitle */}
        <p className="text-2xl text-gray-600 mb-12">{t('home:hero.subtitle')}</p>

        {/* Image Carousel */}
        <div
          className="relative w-full max-w-4xl h-96 mb-12 rounded-2xl overflow-hidden shadow-2xl"
          onMouseEnter={() => setIsHovering(true)} // Pause carousel on hover
          onMouseLeave={() => setIsHovering(false)} // Resume carousel when not hovering
        >
          {/* Map through images to display each slide */}
          {images.map((image, index) => (
            <div
              key={index}
              className={`absolute inset-0 transition-all duration-700 ease-in-out ${
                index === activeIndex ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-full'
              }`}
            >
              {/* Image component from Next.js */}
              <Image
                src={image.url}
                alt={image.title}
                className="object-cover"
                fill
                priority={index === 0} // Preload the first image
                sizes="(max-width: 1280px) 100vw, 1280px"
              />
              {/* Overlay with gradient and text */}
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex flex-col justify-end p-8">
                <h3 className="text-3xl font-bold text-white mb-2">{image.title}</h3>
                <p className="text-xl text-gray-200">{image.description}</p>
              </div>
            </div>
          ))}

          {/* Carousel Indicators */}
          <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
            {images.map((_, index) => (
              <button
                key={index}
                className={`w-2 h-2 rounded-full transition-all ${
                  index === activeIndex ? 'bg-white w-6' : 'bg-white/50'
                }`}
                onClick={() => setActiveIndex(index)} // Navigate to the selected slide
              />
            ))}
          </div>
        </div>

        {/* Call-to-Action Buttons */}
        <div className="flex space-x-4">
          {/* Waitlist Dialog */}
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
              {/* Waitlist Form */}
              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Name Field */}
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
                {/* Email Field */}
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
                {/* Comment Field */}
                <div className="space-y-2">
                  <Label htmlFor="comment">What excites you most about our platform?</Label>
                  <Textarea
                    id="comment"
                    name="comment" // Updated name attribute to 'comment'
                    placeholder="Tell us what excites you..."
                    value={formData.comment} // Updated value binding to 'comment'
                    onChange={handleInputChange}
                    className="h-24"
                  />
                </div>
                {/* Submit Button */}
                <div className="flex justify-end">
                  <Button type="submit" disabled={isSubmitting}>
                    {isSubmitting ? 'Submitting...' : 'Join Waitlist'}
                  </Button>
                </div>
              </form>
            </DialogContent>
          </Dialog>
          {/* Learn More Button */}
          <button className="px-8 py-3 border border-purple-200 text-purple-600 rounded-full font-medium hover:bg-purple-50 transform hover:scale-105 transition-all">
            {t('common:actions.learn_more')}
          </button>
        </div>
      </div>

      {/* Features Grid Section */}
      <div className="max-w-6xl mx-auto px-4 py-24 grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Feature 1 */}
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

        {/* Feature 2 */}
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

        {/* Feature 3 */}
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
    </div>
  );
};

export default SplashPage;
