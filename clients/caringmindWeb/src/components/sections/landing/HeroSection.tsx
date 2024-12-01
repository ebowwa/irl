"use client";

import { motion } from "framer-motion";
import { Shield, TrendingUp } from "lucide-react";
import { WaitlistDialog } from "@/components/sections/waitlist/WaitlistDialog";
import { DemoModal } from "@/components/sections/DemoModal";
import { useState } from "react";
import { useLocation } from "@/hooks/use-location";

export function HeroSection() {
  const [showWaitlist, setShowWaitlist] = useState(false);
  const [showDemo, setShowDemo] = useState(false);
  const { location, isLoading } = useLocation();

  return (
    <div className="relative min-h-screen">
      {/* Background with extended gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-purple-50/50 via-white to-transparent" />
      
      {/* Animated background elements */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0)_0%,rgba(247,237,255,0.8)_100%)]" />
        <div className="absolute inset-0 bg-grid opacity-20" />
        <div className="absolute top-1/4 -left-48 w-96 h-96 bg-purple-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob" />
        <div className="absolute top-1/3 -right-48 w-96 h-96 bg-pink-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000" />
        <div className="absolute -bottom-48 left-1/2 transform -translate-x-1/2 w-96 h-96 bg-indigo-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center justify-center min-h-screen px-4 text-center">
        {/* Logo Animation */}
        <div className="relative w-32 h-32 mb-8">
          <div className="absolute inset-0 bg-gradient-to-r from-purple-100 to-pink-50 rounded-full animate-pulse" />
          <div className="absolute inset-4 bg-white rounded-full shadow-lg flex items-center justify-center">
            <Shield className="w-12 h-12 text-purple-600" />
          </div>
        </div>

        {!isLoading && location && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full text-purple-900/90 font-medium mb-6"
          >
            <TrendingUp className="w-4 h-4" />
            <span>Trending in {location.city}</span>
          </motion.div>
        )}

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-4xl mx-auto mb-24" // Increased bottom margin
        >
          <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-purple-600 via-pink-500 to-indigo-600 text-transparent bg-clip-text leading-[1.2] md:leading-[1.2] tracking-tight px-4">
            Your Digital Wellness Companion
          </h1>
          
          <p className="text-xl md:text-2xl text-gray-600 mb-12 max-w-3xl mx-auto px-4">
            Caringmind stands by your side, nurturing your digital wellbeing, supporting your growth, and helping you navigate life's complexities with compassion.
          </p>

          {/* Call-to-Action Buttons 
          TODO: The `See How it works` should lead to the dialog demo view in which we show some of the value
          - i.e. the truth false game & negotiation
          - maybe have a web app to the negotation to promote the service overall and hope for app conversions
          */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16">
            <button
              onClick={() => setShowWaitlist(true)}
              className="px-8 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-full font-medium hover:from-purple-700 hover:to-pink-700 transform hover:scale-105 transition-all shadow-lg hover:shadow-xl"
            >
              Join Waitlist
            </button>
            <button
              onClick={() => setShowDemo(true)}
              className="px-8 py-3 bg-white/80 backdrop-blur-sm border-2 border-purple-200 text-purple-600 rounded-full hover:bg-purple-50 transition-all"
            >
              See How It Works
            </button>
          </div>

          {/* Demo Modal */}
          <DemoModal 
            isOpen={showDemo}
            onClose={() => setShowDemo(false)}
          />

          {/* Stats with gradient background */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-b from-transparent via-white/50 to-white rounded-3xl" />
            <div className="relative flex flex-wrap items-center justify-center gap-8 md:gap-16 p-8">
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="text-center"
              >
                <p className="text-4xl font-bold text-purple-600">98%</p>
                <p className="text-gray-600">Feel Supported</p>
              </motion.div>
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="text-center"
              >
                <p className="text-4xl font-bold text-pink-500">2.5M+</p>
                <p className="text-gray-600">Lives Improved</p>
              </motion.div>
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
                className="text-center"
              >
                <p className="text-4xl font-bold text-indigo-600">4.9★</p>
                <p className="text-gray-600">User Trust</p>
              </motion.div>
            </div>
          </div>
        </motion.div>
      </div>

      <WaitlistDialog open={showWaitlist} onOpenChange={setShowWaitlist} />
    </div>
  );
}