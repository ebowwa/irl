// components/SuccessStories.tsx
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import Image from 'next/image';

type Story = {
  name: string
  username: string
  joinedDate: string
  avatar: string
  description: string
  testimonial: string
}

type SuccessStoriesContent = {
  title: string
  description: string
  stories: Story[]
}

const content: SuccessStoriesContent = {
  title: "Success Stories",
  description: "Our affiliates have earned thousands of dollars by referring customers to Vercel. Here are a few of their stories:",
  stories: [
    {
      name: "John Doe",
      username: "@johndoe",
      joinedDate: "January 2022",
      avatar: "/placeholder.svg",
      description:
        "John Doe is a web developer who specializes in building fast, performant websites. He's been using Vercel to deploy his projects, and he's been so impressed with the platform that he decided to become an affiliate.",
      testimonial:
        "Vercel has been a game-changer for my workflow. Not only is it the best platform for hosting my sites, but now I'm earning money every time I recommend it to my clients. Thanks, Vercel!",
    },
    {
      name: "Mary Smith",
      username: "@marys_adventures",
      joinedDate: "March 2023",
      avatar: "/placeholder.svg",
      description:
        "Mary is a blogger who writes about travel and adventure. She has a large following on social media, and she's always looking for ways to monetize her content. She discovered Vercel's affiliate program and decided to give it a try.",
      testimonial:
        "I've been using Vercel to host my blog, and I couldn't be happier with the performance. Now I'm earning extra income by sharing the platform with my readers. It's a win-win!",
    },
  ],
}

export function SuccessStories() {
  return (
    <div className="grid gap-4">
      <div className="grid gap-1">
        <h3 className="text-xl font-bold">{content.title}</h3>
        <p className="text-gray-500 dark:text-gray-400">{content.description}</p>
      </div>
      <div className="grid gap-4">
        {content.stories.map((story, index) => (
          <Card key={index}>
            <CardHeader className="pb-0">
              <CardTitle>{story.name}</CardTitle>
              <CardDescription>{story.description}</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4">
              <div className="flex items-center space-x-2">
                <Image
                  alt="Avatar"
                  className="rounded-full"
                  height="40"
                  src={story.avatar}
                  style={{
                    aspectRatio: "40/40",
                    objectFit: "cover",
                  }}
                  width="40"
                />
                <div className="grid gap-0.5">
                  <p className="text-sm font-semibold">{story.username}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">Joined: {story.joinedDate}</p>
                </div>
              </div>
              <div className="grid gap-2">
                <p className="text-sm">{story.testimonial}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}