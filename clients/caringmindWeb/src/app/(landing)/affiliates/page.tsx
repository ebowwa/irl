// pages/index.tsx
import { Header } from "@/components/(sections)/affiliate/Header"
import { HowItWorks } from "@/components/(sections)/affiliate/HowItWorks"
import { Benefits } from "@/components/(sections)/affiliate/Benefits"
import { SuccessStories } from "@/components/(sections)/affiliate/SuccessStories"
import { CTA } from "@/components/(sections)/affiliate/CTA"

export default function Home() {
  return (
    <>
      <Header />
      <main className="w-full py-12">
        <div className="container grid gap-12 px-4 md:gap-16 md:px-6">
          <HowItWorks />
          <Benefits />
          <SuccessStories />
          <CTA />
        </div>
      </main>
    </>
  )
}