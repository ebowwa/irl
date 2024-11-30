"use client";

import { motion } from "framer-motion";
import { TrendingUp, Heart, MessageCircle, Share2 } from "lucide-react";
import Image from "next/image";

export function TikTokProof() {
  const tikTokPosts = [
    {
      username: "@lifewithMahdi",
      content: "How I caught a manipulator using Mahdi's voice analysis 🚩 #toxicitycheck",
      views: "2.4M",
      likes: "458K",
      comments: "12.3K",
      shares: "89K",
      thumbnail: "https://images.unsplash.com/photo-1633984726552-3ed7f5f0c734?w=800&h=1000&q=80"
    },
    {
      username: "@mentalhealthcheck",
      content: "POV: Your bestie is going through it but Mahdi helps you understand their emotions 💕 #realtalk",
      views: "1.8M",
      likes: "392K",
      comments: "8.7K",
      shares: "45K",
      thumbnail: "https://images.unsplash.com/photo-1516726817505-f5ed825624d8?w=800&h=1000&q=80"
    },
    {
      username: "@squadgoals",
      content: "When your whole friend group uses Mahdi to vibe check the new person 👀 #boundaries",
      views: "3.1M",
      likes: "687K",
      comments: "15.2K",
      shares: "92K",
      thumbnail: "https://images.unsplash.com/photo-1521310192545-4ac7951413f0?w=800&h=1000&q=80"
    }
  ];

  return (
    <section className="py-24 bg-gradient-to-b from-white to-purple-50">
      <div className="max-w-6xl mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-red-50 rounded-full text-red-600 font-medium mb-6">
            <TrendingUp className="w-4 h-4" />
            <span>Trending on TikTok</span>
          </div>
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            The Talk of TikTok
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            See how Gen Z is using Mahdi to level up their digital life
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8">
          {tikTokPosts.map((post, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
              className="bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-xl transition-all group"
            >
              <div className="relative aspect-[9/16] bg-black">
                <Image
                  src={post.thumbnail}
                  alt={post.content}
                  fill
                  className="object-cover opacity-90 group-hover:scale-105 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
                <div className="absolute bottom-0 left-0 right-0 p-4 text-white">
                  <p className="font-bold mb-1">{post.username}</p>
                  <p className="text-sm mb-3">{post.content}</p>
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-1">
                      <Heart className="w-4 h-4" />
                      <span className="text-sm">{post.likes}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <MessageCircle className="w-4 h-4" />
                      <span className="text-sm">{post.comments}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Share2 className="w-4 h-4" />
                      <span className="text-sm">{post.shares}</span>
                    </div>
                  </div>
                </div>
                <div className="absolute top-4 right-4 bg-black/50 px-2 py-1 rounded-lg text-white text-sm">
                  {post.views} views
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-16 text-center"
        >
          <button className="px-8 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-full font-medium hover:from-purple-700 hover:to-pink-700 transform hover:scale-105 transition-all shadow-lg hover:shadow-xl">
            Join the Conversation
          </button>
        </motion.div>
      </div>
    </section>
  );
}