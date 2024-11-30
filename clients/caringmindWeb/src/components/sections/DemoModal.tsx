"use client";

import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { motion, AnimatePresence } from "framer-motion";
import { Brain, Shield, Heart } from "lucide-react";
import ReactPlayer from "react-player";

interface DemoModalProps {
  isOpen: boolean;
  onClose: () => void;
  userIp: string;
}

export function DemoModal({ isOpen, onClose, userIp }: DemoModalProps) {
  const [step, setStep] = useState(0);
  const [videoPlaying, setVideoPlaying] = useState(false);

  useEffect(() => {
    if (!isOpen) {
      setStep(0);
      setVideoPlaying(false);
    }
  }, [isOpen]);

  const steps = [
    {
      icon: <Brain className="w-8 h-8 text-indigo-600" />,
      title: "Welcome to caringmind",
      description: "Experience the future of emotional intelligence and personal growth.",
      video: "https://www.youtube.com/watch?v=demo-video-1"
    },
    {
      icon: <Shield className="w-8 h-8 text-purple-600" />,
      title: "Digital Defense",
      description: "See how caringmind protects you from manipulation in real-time.",
      video: "https://www.youtube.com/watch?v=demo-video-2"
    },
    {
      icon: <Heart className="w-8 h-8 text-pink-600" />,
      title: "Emotional Growth",
      description: "Discover your path to deeper emotional intelligence.",
      video: "https://www.youtube.com/watch?v=demo-video-3"
    }
  ];

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl p-0 bg-white/95 backdrop-blur-xl overflow-hidden">
        <DialogTitle className="sr-only">
          {steps[step].title}
        </DialogTitle>
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="p-6"
          >
            <div className="flex items-center gap-4 mb-6">
              {steps[step].icon}
              <div>
                <h2 className="text-2xl font-bold text-gray-900">{steps[step].title}</h2>
                <p className="text-gray-600">{steps[step].description}</p>
              </div>
            </div>

            <div className="relative aspect-video rounded-lg overflow-hidden mb-6">
              <ReactPlayer
                url={steps[step].video}
                width="100%"
                height="100%"
                playing={videoPlaying}
                onPlay={() => setVideoPlaying(true)}
                onPause={() => setVideoPlaying(false)}
                controls
              />
            </div>

            <div className="flex justify-between items-center">
              <div className="flex gap-2">
                {steps.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setStep(index)}
                    className={`w-2 h-2 rounded-full transition-all ${
                      index === step ? 'w-8 bg-indigo-600' : 'bg-gray-300'
                    }`}
                    aria-label={`Go to step ${index + 1}`}
                  />
                ))}
              </div>
              <div className="flex gap-4">
                {step > 0 && (
                  <button
                    onClick={() => setStep(step - 1)}
                    className="px-4 py-2 text-gray-600 hover:text-gray-900"
                  >
                    Previous
                  </button>
                )}
                {step < steps.length - 1 ? (
                  <button
                    onClick={() => setStep(step + 1)}
                    className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
                  >
                    Next
                  </button>
                ) : (
                  <button
                    onClick={onClose}
                    className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
                  >
                    Get Started
                  </button>
                )}
              </div>
            </div>
          </motion.div>
        </AnimatePresence>
      </DialogContent>
    </Dialog>
  );
}