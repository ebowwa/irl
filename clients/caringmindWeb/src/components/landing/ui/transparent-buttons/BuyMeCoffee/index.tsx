/**
* This code was generated by v0 by Vercel.
* @see https://v0.dev/t/2X1Qk4Kgpft
* Documentation: https://v0.dev/docs#integrating-generated-code-into-your-nextjs-app
ADD next link and add kofi link
**/
import Link from 'next/link';

export function BuyMeACoffeeWhiteButton() {
  return (
    <Link href="https://Ko-fi.com/ebowwa" passHref>
    <button className="group relative inline-flex items-center justify-center overflow-hidden rounded-lg bg-white px-8 py-3 font-medium text-primary transition-all duration-300 ease-out hover:ring-2 hover:ring-primary focus:outline-none focus:ring-2 focus:ring-primary">
      <span className="absolute inset-0 h-full w-0 bg-primary transition-all duration-300 ease-out group-hover:w-full opacity-10" />
      <span className="relative flex items-center gap-2">
        <CoffeeIcon className="h-6 w-6 text-primary group-hover:text-white" />
        <span>Buy Me a Coffee</span>
      </span>
    </button>
    </Link>
  )
}

function CoffeeIcon(props) {
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
      <path d="M10 2v2" />
      <path d="M14 2v2" />
      <path d="M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1" />
      <path d="M6 2v2" />
    </svg>
  )
}