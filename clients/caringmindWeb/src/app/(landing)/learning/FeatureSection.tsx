import { CompassIcon, ClapperboardIcon, BadgeIcon } from './icons';

export function FeatureSection() {
  return (
    <section className="py-16 md:py-24">
      <div className="container px-4 md:px-6">
        <div className="grid gap-8 md:grid-cols-3">
          <div className="space-y-2">
            <CompassIcon className="h-8 w-8 text-primary" />
            <h3 className="text-xl font-semibold">Explore Courses</h3>
            <p className="text-muted-foreground">
              Browse our extensive library of courses across a wide range of subjects and skill levels.
            </p>
          </div>
          <div className="space-y-2">
            <ClapperboardIcon className="h-8 w-8 text-primary" />
            <h3 className="text-xl font-semibold">Learn from Experts</h3>
            <p className="text-muted-foreground">
              Learn from industry-leading instructors who are passionate about sharing their knowledge.
            </p>
          </div>
          <div className="space-y-2">
            <BadgeIcon className="h-8 w-8 text-primary" />
            <h3 className="text-xl font-semibold">Earn Certificates</h3>
            <p className="text-muted-foreground">
              Complete courses and earn certificates to showcase your skills and achievements.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}