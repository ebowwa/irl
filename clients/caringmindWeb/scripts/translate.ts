import fs from 'fs';
import path from 'path';
import { config } from 'dotenv';

config(); // Load environment variables

const LOCALES_DIR = path.join(process.cwd(), 'public', 'locales');
const SUPPORTED_LANGUAGES = ['es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh']; // Add more as needed

interface TranslationObject {
  [key: string]: string | TranslationObject;
}

async function translateText(text: string, targetLang: string): Promise<string> {
  try {
    const response = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama3.2:1b',
        prompt: `Translate the following English text to ${targetLang} maintaining any formatting and placeholders: "${text}"`,
        stream: false,
      }),
    });

    const data = await response.json();
    return data.response;
  } catch (error) {
    console.error(`Translation failed for "${text}" to ${targetLang}:`, error);
    return text; // Return original text if translation fails
  }
}

async function translateObject(obj: TranslationObject, targetLang: string): Promise<TranslationObject> {
  const translated: TranslationObject = {};

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      translated[key] = await translateText(value, targetLang);
    } else {
      translated[key] = await translateObject(value, targetLang);
    }
  }

  return translated;
}

async function processNamespace(namespace: string) {
  const englishFile = path.join(LOCALES_DIR, 'en', `${namespace}.json`);

  if (!fs.existsSync(englishFile)) {
    console.error(`English file not found: ${englishFile}`);
    return;
  }

  const englishContent = JSON.parse(fs.readFileSync(englishFile, 'utf8'));

  for (const lang of SUPPORTED_LANGUAGES) {
    const targetDir = path.join(LOCALES_DIR, lang);
    const targetFile = path.join(targetDir, `${namespace}.json`);

    // Create language directory if it doesn't exist
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    // Get existing translations if they exist
    let existingTranslations: TranslationObject = {};
    if (fs.existsSync(targetFile)) {
      existingTranslations = JSON.parse(fs.readFileSync(targetFile, 'utf8'));
    }

    // Translate only new or modified content
    const translatedContent = await translateObject(englishContent, lang);

    // Write the updated translations
    fs.writeFileSync(
      targetFile,
      JSON.stringify(translatedContent, null, 2),
      'utf8'
    );

    console.log(`✓ Updated ${lang} translations for ${namespace}`);
  }
}

async function main() {
  // Get all namespaces from the English directory
  const namespaces = fs.readdirSync(path.join(LOCALES_DIR, 'en'))
    .filter(file => file.endsWith('.json'))
    .map(file => file.replace('.json', ''));

  console.log('Found namespaces:', namespaces);

  for (const namespace of namespaces) {
    console.log(`\nProcessing namespace: ${namespace}`);
    await processNamespace(namespace);
  }
}

// Add command line interface
if (require.main === module) {
  main().catch(console.error);
}

export { translateText, translateObject, processNamespace };
