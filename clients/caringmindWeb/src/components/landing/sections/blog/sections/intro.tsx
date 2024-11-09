import { CMS_NAME } from "@/lib/constants";

export function Intro() {
  return (
    <section className="max-w-3xl mx-auto flex-col md:flex-row flex items-center md:justify-between mt-10 mb-10 md:mb-6 px-4 md:px-0">
      <div>
        <h1 className="text-3xl md:text-5xl font-bold tracking-tighter leading-tight md:pr-8">
          Empowering Businesses with Nature-Inspired AI Solutions
        </h1>
        <p className="text-base md:text-lg mt-3 md:pr-8">
          Unlock the power of nature-inspired AI to drive your business forward. Discover how our cutting-edge models can optimize your operations, boost profits, and keep you ahead of the competition.
        </p>
      </div>
      <h4 className="text-center md:text-left text-base mt-4 md:pl-8">
        A personal blog by a developer advocate.
      </h4>
    </section>
  );
}