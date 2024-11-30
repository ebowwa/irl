"use client";

import { Shield, HelpCircle } from "lucide-react";
import { motion } from "framer-motion";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

export default function FAQPage() {
  const faqs = [
    {
      category: "General",
      questions: [
        {
          question: "What is Mahdi?",
          answer: "Mahdi is your digital life advocate - an AI-powered platform that helps protect your digital wellbeing, enhance emotional intelligence, and support personal growth. Available on iOS and Apple Watch, it acts as your guardian in the digital world."
        },
        {
          question: "How does Mahdi protect me?",
          answer: "Mahdi uses advanced AI to detect and prevent digital manipulation attempts, monitor your digital wellbeing, and provide real-time guidance for better decision-making. It analyzes patterns in your digital interactions to identify potential risks before they affect you."
        },
        {
          question: "Is Mahdi available in my country?",
          answer: "Mahdi is currently available in select countries during our initial rollout. Join our waitlist to be notified when we launch in your region and get early access opportunities."
        }
      ]
    },
    {
      category: "Features & Capabilities",
      questions: [
        {
          question: "What features does the Apple Watch app offer?",
          answer: "The Apple Watch app provides real-time emotional state monitoring, quick access to wellbeing insights, and immediate alerts for potential digital threats. It seamlessly integrates with your iPhone for a comprehensive protection experience."
        },
        {
          question: "How does the emotional intelligence feature work?",
          answer: "Mahdi's emotional intelligence system analyzes various signals including text patterns, interaction dynamics, and behavioral indicators to help you understand your emotional responses and those of others. It provides personalized insights and growth recommendations."
        },
        {
          question: "Can Mahdi help with specific mental health issues?",
          answer: "While Mahdi supports emotional wellbeing and personal growth, it is not a replacement for professional mental health care. It can complement your mental health journey by providing additional insights and support tools."
        }
      ]
    },
    {
      category: "Privacy & Security",
      questions: [
        {
          question: "How does Mahdi protect my privacy?",
          answer: "Your privacy is our top priority. All data is encrypted end-to-end, processed locally on your device when possible, and we never share your personal information with third parties. You have full control over your data and can delete it at any time."
        },
        {
          question: "What data does Mahdi collect?",
          answer: "Mahdi collects only the data necessary to provide its core services, including interaction patterns and emotional indicators. All data collection is transparent and configurable through the app's privacy settings."
        }
      ]
    },
    {
      category: "Support & Community",
      questions: [
        {
          question: "How can I get help if I need it?",
          answer: "We offer 24/7 support through our in-app chat, email support, and comprehensive help center. Our community forums also provide peer support and shared experiences."
        },
        {
          question: "Is there a community aspect to Mahdi?",
          answer: "Yes! Mahdi features optional community features where you can connect with others on similar growth journeys, share experiences, and support each other - all while maintaining your privacy preferences."
        }
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <div className="relative py-24 px-4 bg-gradient-to-b from-purple-50 to-white">
        <div className="max-w-4xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center justify-center gap-4 mb-8"
          >
            <div className="p-4 rounded-2xl bg-white shadow-lg">
              <HelpCircle className="w-8 h-8 text-purple-600" />
            </div>
          </motion.div>
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            Frequently Asked Questions
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Find answers to common questions about Mahdi and how it can help protect and enhance your digital life.
          </p>
        </div>
      </div>

      {/* FAQ Content */}
      <div className="max-w-4xl mx-auto px-4 pb-24">
        {faqs.map((category, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="mb-12"
          >
            <h2 className="text-2xl font-bold text-gray-900 mb-6">{category.category}</h2>
            <Accordion type="single" collapsible className="space-y-4">
              {category.questions.map((faq, faqIndex) => (
                <AccordionItem
                  key={faqIndex}
                  value={`${index}-${faqIndex}`}
                  className="bg-white border border-gray-200 rounded-xl overflow-hidden"
                >
                  <AccordionTrigger className="px-6 py-4 hover:bg-gray-50 transition-colors">
                    <span className="text-left font-medium text-gray-900">{faq.question}</span>
                  </AccordionTrigger>
                  <AccordionContent className="px-6 py-4 text-gray-600">
                    {faq.answer}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </motion.div>
        ))}

        {/* Support Section */}
        <div className="mt-16 p-8 bg-purple-50 rounded-2xl">
          <div className="text-center">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">Still have questions?</h3>
            <p className="text-gray-600 mb-8">
              We're here to help! Reach out to our support team or join our community.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="px-8 py-3 bg-purple-600 text-white rounded-full hover:bg-purple-700 transition-colors">
                Contact Support
              </button>
              <button className="px-8 py-3 bg-white border-2 border-purple-200 text-purple-600 rounded-full hover:bg-purple-50 transition-colors">
                Join Community
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}