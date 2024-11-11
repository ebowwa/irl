/**
 * v0 by Vercel.
 * @see https://v0.dev/t/73Qt7kYAL8F
 * Documentation: https://v0.dev/docs#integrating-generated-code-into-your-nextjs-app
 */
import Link from "next/link";

export interface SiteMapItem {
  title: string;
  links: { label: string; href: string }[];
}

export interface SiteMapProps {
  siteMap: SiteMapItem[];
}

export default function SiteMap({ siteMap }: SiteMapProps) {
  return (
    <main className="flex flex-col items-center justify-center py-12 md:py-24">
      <div className="container max-w-4xl px-4 md:px-0">
        <div className="mb-8 space-y-2">
          <h1 className="text-3xl font-bold tracking-tight md:text-4xl">
            Site Map
          </h1>
          <p className="text-gray-500 dark:text-gray-400">
            This site is built with Typescript and Nextjs 14. All code within this site is modular, self-encapsulating, and easily portable. Everything that can be within this app is run locally on the client-side. As a developer expanding my tool belt, I&apos;m excited to share this
            work in progress. Please feel free to explore and provide feedback.
          </p>
        </div>
        <div className="space-y-6">
          {siteMap.map((section, index) => (
            <div key={index} className="grid gap-2">
              <h2 className="text-xl font-semibold">{section.title}</h2>
              <ul className="grid gap-1 pl-4 text-gray-500 dark:text-gray-400">
                {section.links.map((link, linkIndex) => (
                  <li key={linkIndex}>
                    <Link href={link.href}>{link.label}</Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
