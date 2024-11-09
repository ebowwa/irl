// components/HowItWorks.tsx

type Step = {
  title: string
  description: string
}

type HowItWorksContent = {
  title: string
  body: string
  steps: Step[]
}

const content: HowItWorksContent = {
  title: "How it Works",
  body: "The process is simple. You sign up, get a unique link, share it with your network, and earn money for every customer who signs up.",
  steps: [
    {
      title: "1. Sign Up",
      description: "Register for the program and get access to your dashboard.",
    },
    {
      title: "2. Share",
      description: "Share your unique link with your network, on your website, or in your app.",
    },
    {
      title: "3. Earn",
      description: "You'll earn money for every customer who signs up for Vercel using your link.",
    },
  ],
}

export function HowItWorks() {
  return (
    <div className="grid gap-12">
      <div className="flex flex-col gap-2">
        <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">{content.title}</h2>
        <p className="max-w-[800px] text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
          {content.body}
        </p>
      </div>
      <div className="grid gap-4">
        {content.steps.map((step, index) => (
          <div key={index} className="grid gap-1">
            <h3 className="text-xl font-bold">{step.title}</h3>
            <p className="text-gray-500 dark:text-gray-400">{step.description}</p>
          </div>
        ))}
      </div>
    </div>
  )
}