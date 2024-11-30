"use client";

import { motion } from "framer-motion";
import { MessageCircle, Shield, Brain } from "lucide-react";
import Image from "next/image";

export function SocialFeatures() {
  return (
    <section className="py-24 bg-white">
      <div className="max-w-6xl mx-auto px-4">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
          >
            <div className="relative aspect-square rounded-2xl overflow-hidden shadow-2xl">
              <Image
                src="https://images.unsplash.com/photo-1516726817505-f5ed825624d8?w=800&h=800&q=80"
                alt="Social Protection"
                fill
                className="object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-purple-900/50 to-transparent" />
              <div className="absolute bottom-0 left-0 right-0 p-8">
                <div className="flex items-center gap-4 text-white">
                  <MessageCircle className="w-8 h-8" />
                  <div>
                    <p className="font-semibold">Real-time Protection</p>
                    <p className="text-sm opacity-80">Always by your side</p>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="space-y-8"
          >
            <h2 className="text-4xl font-bold text-gray-900">
              Your Social Guardian Angel
            </h2>
            <p className="text-xl text-gray-600">
              Navigate social interactions with confidence, backed by AI-powered insights and real-time protection.
            </p>
            
            <div className="space-y-6">
              <div className="flex items-start gap-4">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <Shield className="w-6 h-6 text-purple-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    Manipulation Detection
                  </h3>
                  <p className="text-gray-600">
                    Advanced algorithms detect subtle signs of manipulation in conversations.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <Brain className="w-6 h-6 text-purple-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    Emotional Intelligence
                  </h3>
                  <p className="text-gray-600">
                    Understand emotional undertones and navigate complex social situations.
                  </p>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}