// src/components/sections/PlaygroundLabs.tsx
import Link from "next/link";
import Image from 'next/image';
import { Input } from "@/components/ui/input";
import { SearchIcon } from "@/components/ui/icons/system";

export interface Playground {
  id: string;
  title: string;
  description: string;
  previewImageSrc: string;
  href: string;
}

export type PlaygroundLabsContent = {
  title: string;
  description: string;
  searchPlaceholder: string;
};

const content: PlaygroundLabsContent = {
  title: "AI Labs Playground",
  description: "Explore our playgrounds and experiment with the latest models and assistants.",
  searchPlaceholder: "Search playgrounds...",
};

interface PlaygroundLabsProps {
  playgrounds: Playground[];
}

export const PlaygroundLabs: React.FC<PlaygroundLabsProps> = ({ playgrounds }) => {
  return (
    <div className="w-full py-6">
      <div className="container px-4 flex flex-col gap-2 md:gap-4">
        <div className="space-y-2">
          <h1 className="text-3xl font-bold tracking-tighter sm:text-4xl md:text-5xl">
            {content.title}
          </h1>
          <p className="text-gray-500 md:text-xl/relaxed dark:text-gray-400">
            {content.description}
          </p>
        </div>
        <div className="relative w-full max-w-sm">
          <Input
            className="w-full"
            placeholder={content.searchPlaceholder}
            type="search"
          />
          <SearchIcon className="absolute inset-y-0 right-0 z-10 h-5 w-5 my-auto mx-3 pointer-events-none" />
        </div>
        <div className="grid gap-6 md:gap-8">
          {playgrounds.map((playground) => (
            <Link key={playground.id} className="flex gap-4" href={playground.href}>
              <div className="grid w-[200px] items-start justify-center">
                <Image
                  alt="Preview"
                  className="aspect-video overflow-hidden rounded-lg object-cover object-center"
                  height="112"
                  src={playground.previewImageSrc}
                  width="200"
                />
              </div>
              <div className="grid gap-1">
                <h2 className="text-xl font-bold tracking-tighter sm:text-2xl">
                  {playground.title}
                </h2>
                <p className="text-sm text-gray-500 leading-none md:text-base/relaxed dark:text-gray-400">
                  {playground.description}
                </p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
};