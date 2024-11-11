// components/tally/TallyHeader.tsx
import { Button } from "@/components/landing/ui/button";
import { FileIcon, PenIcon, CheckIcon }  from "@/components/landing/ui/icons";
import { useRouter } from 'next/navigation';

type TallyHeaderContent = {
  title: string;
  description: string;
  buttonText: string;
  buttonLink: string;
};

const content: TallyHeaderContent = {
  title: "The simplest way to embrace the changing world",
  description: "Sign up to get access to our Labs. No credit card required.",
  buttonText: "Access our Labs today for free",
  buttonLink: "/labs",
};

const TallyHeader: React.FC = () => {
  const router = useRouter();

  return (
    <header className="text-center py-16 px-8">
      <div className="flex justify-center space-x-4 mb-8">
        <PenIcon className="h-6 w-6 text-gray-500" />
        <CheckIcon className="h-6 w-6 text-green-500" />
        <FileIcon className="h-6 w-6 text-blue-500" />
      </div>
      <h2 className="text-4xl font-bold mb-4">{content.title}</h2>
      <p className="mb-8">{content.description}</p>
      <Button onClick={() => router.push(content.buttonLink)}>{content.buttonText}</Button>
    </header>
  );
};

export default TallyHeader;
