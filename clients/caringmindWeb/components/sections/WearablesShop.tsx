"use client";

import { motion } from "framer-motion";
import { Watch, Headphones, CircleDollarSign, Star, ShoppingCart, Circle } from "lucide-react";
import Image from "next/image";

export function WearablesShop() {
  const wearables = [
    {
      name: "O1 Ring",
      description: "Premium smart ring with advanced bio-sensing and emotional tracking",
      price: "$299",
      rating: "4.9",
      reviews: "2.3K",
      image: "https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=800&h=1000&q=80",
      icon: Circle,
      color: "from-purple-600 to-indigo-600",
      features: [
        "24/7 Emotional State Monitoring",
        "Stress Detection",
        "Sleep Analysis",
        "7-day Battery Life"
      ]
    },
    {
      name: "O1 Necklace",
      description: "Elegant pendant with voice pattern analysis and manipulation detection",
      price: "$349",
      rating: "4.8",
      reviews: "1.8K",
      image: "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=800&h=1000&q=80",
      icon: Circle,
      color: "from-pink-600 to-rose-600",
      features: [
        "Voice Analysis",
        "Manipulation Detection",
        "Mood Tracking",
        "14-day Battery Life"
      ]
    },
    {
      name: "O1-Lite Necklace",
      description: "Streamlined pendant focused on essential protection features",
      price: "$249",
      rating: "4.7",
      reviews: "956",
      image: "https://images.unsplash.com/photo-1599643477256-e05a8e3c0f86?w=800&h=1000&q=80",
      icon: Circle,
      color: "from-blue-600 to-cyan-600",
      features: [
        "Basic Voice Analysis",
        "Stress Detection",
        "21-day Battery Life",
        "Water Resistant"
      ]
    },
    {
      name: "Apple Watch Integration",
      description: "Transform your Apple Watch into a powerful emotional intelligence tool",
      price: "$99",
      rating: "4.9",
      reviews: "3.2K",
      image: "https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=800&h=1000&q=80",
      icon: Watch,
      color: "from-gray-600 to-gray-800",
      features: [
        "Real-time Emotional Analysis",
        "Health Data Integration",
        "Custom Watch Faces",
        "Siri Integration"
      ]
    },
    {
      name: "AirPods Integration",
      description: "Enhanced AirPods features for audio analysis and protection",
      price: "$79",
      rating: "4.8",
      reviews: "2.1K",
      image: "https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=800&h=1000&q=80",
      icon: Headphones,
      color: "from-white to-gray-200",
      features: [
        "Live Voice Analysis",
        "Emotional Tone Detection",
        "Conversation Insights",
        "Spatial Audio Support"
      ]
    }
  ];

  return (
    <section className="py-24 bg-gradient-to-b from-purple-50 to-white">
      <div className="max-w-6xl mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-purple-100 rounded-full text-purple-600 font-medium mb-6">
            <CircleDollarSign className="w-4 h-4" />
            <span>Pre-order Now</span>
          </div>
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            AI-Powered Wearables
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Enhance your digital protection with our cutting-edge wearable technology
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8">
          {wearables.map((wearable, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
              className="bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-xl transition-all group"
            >
              <div className="relative aspect-[4/5] bg-black">
                <Image
                  src={wearable.image}
                  alt={wearable.name}
                  fill
                  className="object-cover opacity-90 group-hover:scale-105 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
                <div className="absolute top-4 right-4 flex items-center gap-1 bg-black/50 px-2 py-1 rounded-lg text-white text-sm">
                  <Star className="w-4 h-4 text-yellow-400" />
                  <span>{wearable.rating}</span>
                  <span className="text-gray-300">({wearable.reviews})</span>
                </div>
                <div className="absolute bottom-0 left-0 right-0 p-4 text-white">
                  <div className="flex justify-between items-end mb-2">
                    <h3 className="text-xl font-bold">{wearable.name}</h3>
                    <p className="text-xl font-bold">{wearable.price}</p>
                  </div>
                  <p className="text-sm text-gray-200 mb-3">{wearable.description}</p>
                  <ul className="space-y-1 mb-4">
                    {wearable.features.map((feature, i) => (
                      <li key={i} className="text-sm flex items-center gap-2">
                        <div className="w-1 h-1 bg-white rounded-full" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <button className="w-full py-2 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-medium hover:from-purple-700 hover:to-pink-700 transition-all flex items-center justify-center gap-2">
                    <ShoppingCart className="w-4 h-4" />
                    Pre-order Now
                  </button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}