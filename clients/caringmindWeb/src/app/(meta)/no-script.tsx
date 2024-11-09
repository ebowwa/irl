/**
 * Prob more of a component
 */
"use client";

export function NoScript(): JSX.Element {
  return (
    <noscript>
      <style type="text/css">
        {`
        * {
          overflow: hidden;
          margin: 0;
          padding: 0;
        }
        #root {
          display: none;
        }
      `}
      </style>
      <div className="grid h-screen w-screen scroll-smooth bg-background text-foreground antialiased">
        <div className="flex min-h-screen flex-col items-center justify-center gap-5 p-6 text-center">
          <h1 className="text-3xl font-bold tracking-tighter sm:text-5xl xl:text-6xl">
            Enable JavaScript
          </h1>
          <p className="mx-auto max-w-prose text-muted-foreground md:text-xl/relaxed">
            This site requires JavaScript to function properly. Please enable
            JavaScript in your browser and refresh the page.
          </p>
        </div>
      </div>
    </noscript>
  );
}
