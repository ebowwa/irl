// src/components/blog/post-preview.tsx
import DateFormatter from '../components/date-formatter'
import CoverImage from '../components/cover-image'
import Link from 'next/link'
import styles from '../styles/Tags.module.css' // Import the CSS module for tags

type Props = {
  title: string
  coverImage: string
  date: string
  excerpt: string
  slug: string
  tags: string[] // Added tags array
}

const PostPreview = ({
  title,
  coverImage,
  date,
  excerpt,
  slug,
  tags, // Added tags
}: Props) => {
  return (
    <div>
      <div className="mb-5">
        <CoverImage 
          title={title}
          githubPath={coverImage}
          slug={slug}
        />
      </div>
      <h3 className="text-3xl mb-3 leading-snug">
        <Link
          as={`/blog/${slug}`}
          href={`/blog/[slug]`}
          className="hover:underline"
        >
          {title}
        </Link>
      </h3>
      <div className="text-lg mb-4">
        <DateFormatter dateString={date} />
      </div>
      <p className="text-lg leading-relaxed mb-4">{excerpt}</p>
      {/* Display tags as styled bubbles */}
      <div className={styles.tagContainer}>
        {tags.map(tag => (
          <span key={tag} className={styles.tagBubble}>{tag}</span>
        ))}
      </div>
    </div>
  )
}

export default PostPreview