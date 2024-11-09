"use client";

import { ThemeProvider, useTheme } from "next-themes";
import { PropsWithChildren, useEffect, useState } from "react";

export function Providers({ children }: PropsWithChildren) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem={true}>
      {children}
    </ThemeProvider>
  );
}

function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  return (
    <button
      onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
      className="px-4 py-2 bg-gray-200 dark:bg-gray-800 rounded-md"
    >
      Toggle {theme === "dark" ? "Light" : "Dark"} Mode
    </button>
  );
}

export default function Home() {
  return (
    <Providers>
      <div className="flex flex-col items-center justify-center min-h-screen py-2">
        <ThemeToggle />
        <p className="mt-4 text-center">
          Toggle the theme to see the difference!
        </p>
      </div>
    </Providers>
  );
}