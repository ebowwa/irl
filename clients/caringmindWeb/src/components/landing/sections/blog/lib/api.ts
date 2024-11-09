// src/lib/blog/api.ts

import { z } from 'zod';
import rawData from '@public/raw_data/posts.json';
import PostType from '@/components/landing/sections/blog/lib/interfaces/post';

// Zod schema for individual post
const PostSchema = z.object({
  title: z.string(),
  excerpt: z.string(),
  coverImage: z.string(),
  date: z.string(),
  tags: z.string(),
  "ogImage.url": z.string(),
  content: z.string(),
});

// Zod schema for the array of posts
const PostsSchema = z.array(PostSchema);

// Validate and parse the raw data
const postsData = PostsSchema.parse(rawData);

// Helper function to generate URL-friendly slugs
function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[\s+]/g, '-')      // Replace spaces with hyphens
    .replace(/[^\w\-]+/g, '')     // Remove all non-word chars
    .replace(/\-\-+/g, '-')       // Replace multiple hyphens with a single hyphen
    .replace(/^-+/, '')           // Trim hyphens from the start
    .replace(/-+$/, '');          // Trim hyphens from the end
}

// Transform and map validated data to PostType array
const posts: PostType[] = postsData.map((post) => ({
  title: post.title,
  excerpt: post.excerpt,
  coverImage: post.coverImage,
  date: post.date.replace(/'/g, ''),
  tags: post.tags.split(',').map((tag) => tag.trim()),
  ogImage: {
    url: post['ogImage.url'],
  },
  content: post.content,
  slug: generateSlug(post.title),
}));

export { posts };

export const postList: {
  posts: PostType[];
} = {
  posts,
};

export function getPostById(id: number): PostType | undefined {
  try {
    return posts[id];
  } catch (error) {
    throw new Error(`Failed to retrieve post by ID: ${id}, error: ${error}`);
  }
}

export function getPostsByTag(tag: string): PostType[] {
  try {
    return posts.filter((post) => post.tags.includes(tag));
  } catch (error) {
    throw new Error(`Failed to retrieve posts by tag: ${tag}, error: ${error}`);
  }
}

export function getLatestPosts(limit: number = 5): PostType[] {
  try {
    return posts.slice(0, limit);
  } catch (error) {
    throw new Error(`Failed to retrieve the latest posts, limit: ${limit}, error: ${error}`);
  }
}

export function searchPosts(query: string): PostType[] {
  try {
    return posts.filter((post) =>
      post.title.toLowerCase().includes(query.toLowerCase()) ||
      post.content.toLowerCase().includes(query.toLowerCase())
    );
  } catch (error) {
    throw new Error(`Failed to search posts with query: ${query}, error: ${error}`);
  }
}

export function getAllPosts(): PostType[] {
  return posts;
}

export function getPostSlugs(): string[] {
  try {
    return posts.map((post) => post.slug);
  } catch (error) {
    throw new Error(`Failed to retrieve post slugs, error: ${error}`);
  }
}

// Function to find a post by its slug
export function getPostBySlug(slug: string): PostType | undefined {
  try {
    // Decode the slug to match the format stored in posts
    const decodedSlug = decodeURIComponent(slug);
    return posts.find((post) => post.slug === decodedSlug);
  } catch (error) {
    throw new Error(`Failed to retrieve post by slug: ${slug}, error: ${error}`);
  }
}