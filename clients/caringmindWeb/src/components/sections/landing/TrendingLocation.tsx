"use client";

import { motion } from "framer-motion";
import { TrendingUp } from "lucide-react";
import { useLocation } from "@/hooks/use-location";

export function TrendingLocation() {
  const { location, isLoading } = useLocation();

  if (isLoading || !location) {
    return null;
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full text-gray-800 font-medium hover:bg-white/20 transition-colors"
    >
      <TrendingUp className="w-4 h-4" />
      <span>Trending in {location.city}</span>
    </motion.div>
  );
}