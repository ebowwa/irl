/** @type {import('next').NextConfig} */
const nextConfig = {
  // Remove the output: 'export' line unless you specifically need static exports
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: { 
    unoptimized: true,
    // Add domains if you're fetching images from external sources
    domains: [] 
  },
};

module.exports = nextConfig;