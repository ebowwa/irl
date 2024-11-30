"use client";

import { motion } from "framer-motion";
import { Shield, Brain, Heart, Lock } from "lucide-react";

export function Features() {
  const features = [
    {
      icon: Shield,
      title: "Digital Protection",
      description: "Advanced AI algorithms detect and prevent digital manipulation attempts in real-time."
    },
    {
      icon: Brain,
      title: "Emotional Intelligence",
      description: "Understand and navigate complex social situations with AI-powered insights."
    },
    {
      icon: Heart,
      title: "Wellbeing Focus",
      description: "Continuous monitoring and suggestions to maintain your digital wellness."
    },
    {
      icon: Lock,
      title: "Privacy First",
      description: "Your data stays private with our advanced encryption and security measures."
    }
  ];

  return (
    <section className="py-24 bg-white">
      <div className="max-w-6xl mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Protecting Your Digital Life
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Experience comprehensive digital protection powered by advanced AI
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
              className="bg-gradient-to-br from-purple-50 to-white p-8 rounded-2xl shadow-lg hover:shadow-xl transition-all"
            >
              <div className="flex items-start gap-4">
                <div className="p-3 bg-purple-100 rounded-lg">
                  <feature.icon className="w-6 h-6 text-purple-600" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-gray-600">
                    {feature.description}
                  </p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}