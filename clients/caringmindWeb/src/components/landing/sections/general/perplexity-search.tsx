/**
 * v0 by Vercel.
 * @see https://v0.dev/t/tswvUJam489
 * Documentation: https://v0.dev/docs#integrating-generated-code-into-your-nextjs-app
 */
import { Input } from "@/components/landing/ui/input";
import { Button } from "@/components/landing/ui/button";
import { Badge } from "@/components/landing/ui/badge";
import { MicroscopeIcon, ArrowRightIcon } from "@/components/landing/ui/icons";

export default function PerplexitySearch() {
    return (
        <div key="1" className="bg-[#f0f0f0] min-h-screen flex flex-col items-center justify-center text-[#333] p-4">
          <h1 className="text-5xl font-bold mb-12">Where knowledge begins</h1>
          <div className="relative mb-8">
            <Input
              className="pl-10 pr-20 py-3 rounded-full w-[600px] bg-white shadow-md border border-gray-300 focus:outline-none focus:border-[#333]"
              placeholder="Ask anything..."
            />
            <MicroscopeIcon className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-600" />
            <Button className="absolute right-1 top-1/2 transform -translate-y-1/2 bg-[#f5f5f5] text-[#333] rounded-full px-4">
              Copilot
            </Button>
          </div>
          <div className="flex space-x-4 mb-4">
            <Button className="px-4 py-2 rounded-full" variant="ghost">
              Focus
            </Button>
            <Button className="px-4 py-2 rounded-full" variant="ghost">
              Attach
            </Button>
          </div>
          <div className="flex items-center space-x-2">
            <ArrowRightIcon className="text-gray-600" />
            <Button className="px-4 py-2 rounded-full bg-[#f5f5f5]" variant="ghost">
              Try Copilot
            </Button>
            <Badge className="px-4 py-2 rounded-full bg-[#ff6b6b]" variant="secondary">
              How to pick ripe watermelon?
            </Badge>
            <Badge className="px-4 py-2 rounded-full bg-[#4299e1]" variant="secondary">
              The history of film
            </Badge>
            <Badge className="px-4 py-2 rounded-full bg-[#48bb78]" variant="secondary">
              Why do zebras have stripes?
            </Badge>
            <Badge className="px-4 py-2 rounded-full bg-[#9f7aea]" variant="secondary">
              The history of Studio 54
            </Badge>
          </div>
        </div>
  );
}

