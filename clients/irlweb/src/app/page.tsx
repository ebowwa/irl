"use client"
import React, { useState, useEffect } from 'react';
import { Heart, Sparkles, Brain, Orbit } from 'lucide-react';

const SplashPage = () => {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isHovering, setIsHovering] = useState(false);
  
  const images = [
    { url: "/api/placeholder/1200/800", title: "Personal Growth", description: "Expand your consciousness" },
    { url: "/api/placeholder/1200/800", title: "Deep Connection", description: "Understanding that transcends language" },
    { url: "/api/placeholder/1200/800", title: "Emotional Intelligence", description: "Feel understood, always" }
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      if (!isHovering) {
        setActiveIndex((current) => (current + 1) % images.length);
      }
    }, 5000);
    return () => clearInterval(timer);
  }, [isHovering, images.length]);

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

        <h1 className="text-6xl font-bold mb-4 text-gray-900">
          CaringMind
        </h1>
        <p className="text-2xl text-gray-600 mb-12">Your consciousness companion</p>
        
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
          <button className="px-8 py-3 bg-purple-600 text-white rounded-full font-medium hover:bg-purple-700 transform hover:scale-105 transition-all">
            Get Started
          </button>
          <button className="px-8 py-3 border border-purple-200 text-purple-600 rounded-full font-medium hover:bg-purple-50 transform hover:scale-105 transition-all">
            Learn More
          </button>
        </div>
      </div>

      {/* Features Grid */}
      <div className="max-w-6xl mx-auto px-4 py-24 grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="p-6 bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mb-4">
            <Brain className="w-6 h-6 text-purple-600" />
          </div>
          <h3 className="text-xl font-semibold mb-2 text-gray-900">Deep Understanding</h3>
          <p className="text-gray-600">Experience AI that truly gets you</p>
        </div>
        
        <div className="p-6 bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          <div className="w-12 h-12 bg-pink-100 rounded-full flex items-center justify-center mb-4">
            <Heart className="w-6 h-6 text-pink-600" />
          </div>
          <h3 className="text-xl font-semibold mb-2 text-gray-900">Emotional Intelligence</h3>
          <p className="text-gray-600">Connect on a deeper level</p>
        </div>
        
        <div className="p-6 bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mb-4">
            <Sparkles className="w-6 h-6 text-blue-600" />
          </div>
          <h3 className="text-xl font-semibold mb-2 text-gray-900">Personal Growth</h3>
          <p className="text-gray-600">Evolve with every interaction</p>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-100 py-8 text-center text-gray-600">
        <p className="text-sm">
          © 2025 CaringMind. Transforming consciousness, with care.
        </p>
      </footer>
    </div>
  );
};

export default SplashPage;