// components/Benefits.tsx

type Benefit = {
  text: string
}

type BenefitsContent = {
  title: string
  benefits: Benefit[]
  commissionTitle: string
  commissionDescription: string
}

const content: BenefitsContent = {
  title: "Benefits",
  benefits: [
    { text: "High conversion rates" },
    { text: "Recurring commissions" },
    { text: "Access to exclusive events" },
    { text: "Support from the Vercel team" },
  ],
  commissionTitle: "Commission Rates",
  commissionDescription: "You'll earn a 10% commission on all customers you refer to Vercel.",
}

export function Benefits() {
  return (
    <div className="grid gap-4">
      <div className="grid gap-1">
        <h3 className="text-xl font-bold">{content.title}</h3>
        <ul className="list-disc list-inside grid gap-2 text-gray-500 md:grid-cols-2 dark:text-gray-400">
          {content.benefits.map((benefit, index) => (
            <li key={index}>{benefit.text}</li>
          ))}
        </ul>
      </div>
      <div className="grid gap-1">
        <h3 className="text-xl font-bold">{content.commissionTitle}</h3>
        <p className="text-gray-500 dark:text-gray-400">{content.commissionDescription}</p>
      </div>
    </div>
  )
}