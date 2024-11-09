import { CourseCard } from "./CourseCard";

export function PopularCoursesSection() {
  return (
    <section className="bg-muted py-16 md:py-24">
      <div className="container px-4 md:px-6">
        <div className="space-y-4 text-center">
          <h2 className="text-3xl font-bold md:text-4xl">Explore Our Most Popular Courses</h2>
          <p className="text-muted-foreground md:text-lg">
            Discover the courses that have captured the attention of our learners.
          </p>
        </div>
        <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <CourseCard
            title="Introduction to Web Development"
            description="Learn the fundamentals of web development, including HTML, CSS, and JavaScript."
            duration="12 hours"
            href="/learn-basic-web-development"
          />
          <CourseCard
            title="Data Science Fundamentals"
            description="Dive into the world of data science and learn essential skills for data analysis and visualization."
            duration="20 hours"
            href="/courses/data-science"
          />
          <CourseCard
            title="Mastering Digital Marketing"
            description="Learn the essential strategies and techniques for effective digital marketing campaigns."
            duration="18 hours"
            href="/courses/digital-marketing"
          />
        </div>
      </div>
    </section>
  );
}