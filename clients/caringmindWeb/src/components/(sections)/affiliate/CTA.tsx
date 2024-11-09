// components/CTA.tsx
import Link from "next/link"

type CTAContent = {
  title: string
  description: string
  buttonText: string
  buttonUrl: string
}

const content: CTAContent = {
  title: "Ready to get started?",
  description: "Sign up for the Variable Share Now Affiliate Program and start earning money today.",
  buttonText: "Sign Up",
  buttonUrl: "#",
}

export function CTA() {
  return (
    <div className="flex flex-col gap-2">
      <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">{content.title}</h2>
      <p className="max-w-[800px] text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
        {content.description}
      </p>
      <div className="flex flex-col gap-2 min-[400px]:flex-row">
        <Link
          className="inline-flex h-10 items-center justify-center rounded-md bg-gray-900 px-8 text-sm font-medium text-gray-50 shadow transition-colors hover:bg-gray-900/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-gray-950 disabled:pointer-events-none disabled:opacity-50 dark:bg-gray-50 dark:text-gray-900 dark:hover:bg-gray-50/90 dark:focus-visible:ring-gray-300"
          href={content.buttonUrl}
        >
          {content.buttonText}
        </Link>
      </div>
    </div>
  )
}