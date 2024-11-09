// src/lib/constants/index.ts
import { constants_keywords } from "./keywords";
export const MAX_IMAGE_SIZE = 1024 * 1024; // 1MB
export const MAX_IMAGES=4
// export const EXAMPLE_PATH = "gemini-pro-vision-playground";
export const CMS_NAME = "un-automated";
export const HOME_OG_IMAGE_URL = "https://og-image.vercel.app/Next.js%20Blog%20Starter%20Example.png?theme=light&md=1&fontSize=100px&images=https%3A%2F%2Fassets.vercel.com%2Fimage%2Fupload%2Ffront%2Fassets%2Fdesign%2Fnextjs-black-logo.svg";
export const NEXT_SITE_TITLE = "un-automated";
export const NEXT_SITE_DESCRIPTION = "Un-Automated.com: Empowering individuals to turn their passions into income, with tools and resources to help anyone start selling online, regardless of their background or experience.";
export const cardImage = HOME_OG_IMAGE_URL;
export const robots = "follow, index";
export const favicon = "/caringmind_icon_v1.ico"; //https://favicon.io/favicon-converter/

export const referrer = 'origin-when-cross-origin';
export const keywords = [...constants_keywords,'Vercel', 'Supabase', 'Next.js', 'Stripe', 'Subscription', CMS_NAME];
export const authors = [{ name: 'Ebowwa', url: 'https://x.com/innitEBOWWA' }];
export const creator = 'Ebowwa';
export const publisher = 'Ebowwa';

export const twitterCard = 'summary_large_image';
export const twitterSite = '@innitEBOWWA';
export const twitterCreator = '@innitEBOWWA';
export const ogType = 'website';

export const route = {
  baseUrl: process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000',
  postRoute: 'blog' // Update this with your desired route for blog posts i.e. app/blog therefore `blog`
};