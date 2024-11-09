// src/app/blog/[slug]/page.tsx
import { Metadata } from "next";
import { notFound } from "next/navigation";
import { getAllPosts, getPostBySlug } from "@/components/(sections)/blog/lib/api";
import { CMS_NAME } from "@/lib/constants";
import markdownToHtml from "@/components/(sections)/blog/lib/markdownToHtml";
import Container from "@/components/(sections)/blog/sections/container";
import Header from "@/components/(sections)/blog/sections/header";
import { PostBody } from "@/components/(sections)/blog/sections/post-body";
import { PostHeader } from "@/components/(sections)/blog/sections/post-header";

export default async function Post({ params }: Params) {
  try {
    const post = await getPostBySlug(params.slug);

    if (!post) {
      throw new Error("Post not found");
    }

    const content = await markdownToHtml(post.content || "");

    return (
      <main>
        <Container>
          <Header />
          <article className="mb-32">
            <PostHeader
              title={post.title}
              coverImage={post.coverImage}
              date={post.date}
              tags={post.tags} 
            />
            <PostBody content={content} />
          </article>
        </Container>
      </main>
    );
  } catch (error) {
    console.error(error); // Add logging for debugging purposes
    return notFound();
  }
}

type Params = {
  params: {
    slug: string;
  };
};

export function generateMetadata({ params }: Params): Metadata {
  try {
    const post = getPostBySlug(params.slug);

    if (!post) {
      throw new Error("Post not found");
    }

    const title = `${post.title} | Next.js Blog Example with ${CMS_NAME}`;

    return {
      title,
      openGraph: {
        title,
        images: [post.ogImage.url],
      },
    };
  } catch (error) {
    console.error(error); // Add logging for debugging purposes
    return notFound();
  }
}

export async function generateStaticParams() {
  try {
    const posts = await getAllPosts();

    if (!posts) {
      throw new Error("No posts found");
    }

    return posts.map((post) => ({
      slug: post.slug,
    }));
  } catch (error) {
    console.error(error); // Add logging for debugging purposes
    return [];
  }
}