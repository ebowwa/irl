"use client";

import { HeroSection } from "@/components/sections/landing/HeroSection";
import { SocialFeatures } from "@/components/sections/landing/SocialFeatures";
import { TikTokProof } from "@/components/sections/landing/TikTokProof";
import { WearablesShop } from "@/components/sections/landing/WearablesShop";
import { Features } from "@/components/sections/landing/Features";
import { Footer } from "@/components/layout/Footer";

export function LandingPage() {
  return (
    <main className="min-h-screen">
      <div className="relative">
        {/* Animated background noise */}
        <div className="fixed inset-0 -z-10">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0)_0%,rgba(247,237,255,0.8)_100%)]" />
          <div className="absolute inset-0 bg-grid opacity-20" />
          <div className="absolute top-1/4 -left-48 w-96 h-96 bg-purple-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob" />
          <div className="absolute top-1/3 -right-48 w-96 h-96 bg-pink-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000" />
          <div className="absolute -bottom-48 left-1/2 transform -translate-x-1/2 w-96 h-96 bg-indigo-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000" />
        </div>

        {/* Content */}
        <div className="relative z-10">
          <HeroSection />
          <SocialFeatures />
          <TikTokProof />
          <WearablesShop />
          <Features />
          <Footer />
        </div>
      </div>
    </main>
  );
}