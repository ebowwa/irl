// src/components/blog/more-stories.tsx
import PostPreview from './post-preview'
import type Post from '@/components/(sections)/blog/lib/interfaces/post'

// Define the type for the props expected by MoreStories
type Props = {
  posts: Post[]
}

// MoreStories component that uses Props
const MoreStories = ({ posts }: Props) => {
  return (
    <section>
      <h2 className="mb-8 text-5xl md:text-7xl font-bold tracking-tighter leading-tight">
        More Stories
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 md:gap-x-16 lg:gap-x-32 gap-y-20 md:gap-y-32 mb-32">
        {posts.map((post) => (
          <PostPreview
            key={post.slug}
            title={post.title}
            coverImage={post.coverImage}
            date={post.date}
            slug={post.slug}
            excerpt={post.excerpt}
            tags={post.tags} // Assuming PostPreview handles tags
          />
        ))}
      </div>
    </section>
  )
}

export default MoreStories