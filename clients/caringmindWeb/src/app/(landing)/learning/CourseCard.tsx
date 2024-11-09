import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { ClockIcon } from './icons';

interface CourseCardProps {
  title: string;
  description: string;
  duration: string;
  href: string;
}

export function CourseCard({ title, description, duration, href }: CourseCardProps) {
  return (
    <Card>
      <CardContent className="space-y-2">
        <img src="/placeholder.svg" width={300} height={200} alt="Course Thumbnail" className="mx-auto mt-2 rounded-t-md" />
        <h3 className="text-xl font-semibold">{title}</h3>
        <p className="text-muted-foreground">{description}</p>
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-1 text-sm text-muted-foreground">
            <ClockIcon className="h-4 w-4" />
            <span>{duration}</span>
          </div>
          <Link
            href={href}
            className="inline-flex h-8 items-center justify-center rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
            prefetch={false}
          >
            Enroll
          </Link>
        </div>
      </CardContent>
    </Card>
  );
}