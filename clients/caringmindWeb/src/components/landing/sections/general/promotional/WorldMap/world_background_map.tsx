// src/components/landing/sections/general/world_background_map.tsx
import Link from "next/link";
import data from "@public/raw_data/world_background_map.json";

export default function HomePage() {
  return (
    <div className="relative w-full h-[400px] lg:h-[500px] overflow-hidden rounded-lg">
      <img
        alt="World Map"
        className="absolute inset-0 w-full h-full object-cover opacity-20"
        height={1080}
        src="/placeholder.svg"
        style={{
          aspectRatio: "1920/1080",
          objectFit: "cover",
        }}
        width={1920}
      />
      <div className="absolute inset-0 flex justify-between items-center bg-white/70 px-4 py-6 shadow-md rounded-lg overflow-hidden">
        <div className="flex flex-col items-center justify-center">
          <UsersIcon className="text-[#555] mb-2 h-8 w-8" />
          <div className="text-3xl font-semibold">{data.worldPopulation}</div>
          <div className="text-sm text-gray-600 mt-1">{data.worldPopulationLabel}</div>
        </div>
        <div className="flex flex-col items-center justify-center">
          <BoltIcon className="text-[#555] mb-2 h-8 w-8" />
          <div className="text-3xl font-semibold">{data.energyUsage}</div>
          <div className="text-sm text-gray-600 mt-1">{data.energyUsageLabel}</div>
        </div>
        <div className="flex flex-col items-center justify-center">
          <GlobeIcon className="text-[#555] mb-2 h-8 w-8" />
          <div className="text-3xl font-semibold">{data.internetSize}</div>
          <div className="text-sm text-gray-600 mt-1">{data.internetSizeLabel}</div>
        </div>
        <div className="flex flex-col items-center justify-center">
          <BookOpenIcon className="text-[#555] mb-2 h-8 w-8" />
          <div className="text-3xl font-semibold">{data.wordsRegistered}</div>
          <div className="text-sm text-gray-600 mt-1">{data.wordsRegisteredLabel}</div>
        </div>
        <Link className="text-indigo-600 hover:text-indigo-800 transition duration-150 ease-in-out" href="#">
          {data.viewNetworkMapLabel}
          <ArrowRightIcon className="inline-block ml-1" />
        </Link>
      </div>
    </div>
  );
}

function ArrowRightIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M5 12h14" />
      <path d="m12 5 7 7-7 7" />
    </svg>
  );
}

function BoltIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
      <circle cx="12" cy="12" r="4" />
    </svg>
  );
}

function BookOpenIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
      <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
    </svg>
  );
}

function GlobeIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20" />
      <path d="M2 12h20" />
    </svg>
  );
}

function UsersIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}