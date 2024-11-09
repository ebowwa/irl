import React from 'react';
import Link from 'next/link';
import { Code } from 'lucide-react';

export function FullstackDevButton() {
  return (
    <Link href="#" passHref>
      <button className="group relative inline-flex items-center justify-center overflow-hidden rounded-lg bg-white px-8 py-3 font-medium text-primary transition-all duration-300 ease-out hover:ring-2 hover:ring-primary focus:outline-none focus:ring-2 focus:ring-primary">
        <span className="absolute inset-0 h-full w-0 bg-primary transition-all duration-300 ease-out group-hover:w-full opacity-10" />
        <span className="relative flex items-center gap-2">
          <Code className="h-6 w-6 text-primary group-hover:text-white" />
          <span>Fullstack Dev</span>
        </span>
      </button>
    </Link>
  )
}