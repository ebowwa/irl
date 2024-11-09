import Link from "next/link";

export function HeroSection() {
  return (
    <section className="bg-gradient-to-r from-primary to-primary-foreground py-20 md:py-32">
      <div className="container px-4 md:px-6">
        <div className="grid gap-6 md:grid-cols-2 md:items-center">
          <div className="space-y-4">
            <h1 className="text-4xl font-bold text-background md:text-5xl">
              Unlock Your Potential with Our E-Learning Platform
            </h1>
            <p className="text-background/80 md:text-lg">
              Explore a vast library of courses, learn from industry experts, and achieve your learning goals.
            </p>
            <Link
              href="#"
              className="inline-flex h-10 items-center justify-center rounded-md bg-background px-6 text-sm font-medium text-primary shadow-sm transition-colors hover:bg-background/90 focus:outline-none focus:ring-2 focus:ring-background focus:ring-offset-2"
              prefetch={false}
            >
              Get Started
            </Link>
          </div>
          <img
            src="/placeholder.svg"
            width={600}
            height={400}
            alt="Hero Image"
            className="mx-auto rounded-lg shadow-lg"
          />
        </div>
      </div>
    </section>
  );
}