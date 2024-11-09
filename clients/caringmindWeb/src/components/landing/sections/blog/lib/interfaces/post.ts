// src/interfaces/post.ts
type PostType = {
    slug: string
    title: string
    date: string
    coverImage: string
    // Removed the author field
    excerpt: string
    ogImage: {
      url: string
    }
    content: string
    // Added tags as an array of strings
    tags: string[]
  }
  
  export default PostType