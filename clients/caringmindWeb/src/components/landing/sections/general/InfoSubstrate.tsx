/**
 * v0 by Vercel.
 * @see https://v0.dev/t/szCzIPymNbg
 * Documentation: https://v0.dev/docs#integrating-generated-code-into-your-nextjs-app
 */
import React from 'react';
import infoSubstrateData from '@public/html/infoSubstrateData.json';

const InfoSubstrate: React.FC = () => {
  const { title, description, sections, informationalSubstrate } = infoSubstrateData;

  return (
    <>
      <section className="w-full bg-white py-12 md:py-24 lg:py-32">
        <div className="container mx-auto px-4 md:px-6">
          <div className="mx-auto max-w-4xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl md:text-6xl">{title}</h1>
            <p className="mt-4 text-lg text-gray-600">{description}</p>
          </div>
          <div className="mt-10 grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
            {sections.map((section, index) => (
              <div key={index} className="rounded-lg bg-white shadow-lg p-6">
                <h2 className="text-2xl font-bold text-gray-900">{section.title}</h2>
                <div className="mt-4 space-y-4">
                  {section.items.map((item, itemIndex) => (
                    <div key={itemIndex}>
                      <h3 className="text-xl font-semibold text-gray-900">{item.title}</h3>
                      <p className="text-gray-600">{item.description}</p>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
      <section className="w-full bg-white py-12 md:py-24 lg:py-32">
        <div className="container mx-auto px-4 md:px-6">
          <div className="mx-auto max-w-4xl">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900">{informationalSubstrate.category}</h2>
            <div className="mt-8 overflow-x-auto">
              <table className="w-full table-auto border-collapse text-left">
                <thead>
                  <tr className="bg-gray-100">
                    <th className="px-4 py-3 font-medium text-gray-900">Concept</th>
                    <th className="px-4 py-3 font-medium text-gray-900">Description</th>
                    <th className="px-4 py-3 font-medium text-gray-900">Empirical Evidence</th>
                    <th className="px-4 py-3 font-medium text-gray-900">Implications</th>
                    <th className="px-4 py-3 font-medium text-gray-900">Connections</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-gray-200">
                    <td className="px-4 py-3 text-gray-700">{informationalSubstrate.concept}</td>
                    <td className="px-4 py-3 text-gray-700">{informationalSubstrate.description}</td>
                    <td className="px-4 py-3 text-gray-700">{informationalSubstrate.evidence}</td>
                    <td className="px-4 py-3 text-gray-700">{informationalSubstrate.implications}</td>
                    <td className="px-4 py-3 text-gray-700">{informationalSubstrate.connections}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};

export default InfoSubstrate;