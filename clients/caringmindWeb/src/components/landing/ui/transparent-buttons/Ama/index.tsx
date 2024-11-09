// @/components/AskMeAnythingButton.tsx
import Link from 'next/link';

export function AskMeAnythingButton() {
  return (
    <Link href="https://docs.google.com/forms/d/e/1FAIpQLSeaFid_fvg0WSeYvLz6zwU7xjGV0az_qaLSiF1yx7d3sXpB8Q/viewform?usp=sf_link" passHref>
      <button className="group relative inline-flex items-center justify-center overflow-hidden rounded-lg bg-white px-8 py-3 font-medium text-primary transition-all duration-300 ease-out hover:ring-2 hover:ring-primary focus:outline-none focus:ring-2 focus:ring-primary">
        <span className="absolute inset-0 h-full w-0 bg-primary transition-all duration-300 ease-out group-hover:w-full opacity-10" />
        <span className="relative flex items-center gap-2">
          <QuestionIcon className="h-6 w-6 text-primary group-hover:text-white" />
          <span>Ask Me Anything</span>
        </span>
      </button>
    </Link>
  );
}

function QuestionIcon(props) {
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
      <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}