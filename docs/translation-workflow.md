# Translation Workflow

This document describes the automated translation workflow for the CaringMind project.

## Overview

The translation system automatically generates translations for all supported languages using the English content as the source. It utilizes the local LLM endpoint for translations, ensuring high-quality and context-aware translations.

## Directory Structure

```
public/
  └── locales/
      ├── en/              # Source translations (English)
      │   ├── common.json
      │   ├── home.json
      │   └── ...
      ├── es/              # Spanish translations
      │   ├── common.json
      │   ├── home.json
      │   └── ...
      └── [lang]/          # Other language translations
```

## Usage

### Adding New Content

1. Add new translations to the appropriate English (en) JSON file
2. Run the translation script:
   ```bash
   pnpm translate
   ```

### Development Workflow

To automatically translate while developing:
```bash
pnpm translate:watch
```
This will watch the English translation files and generate translations when changes are detected.

### Building with Translations

To build the application with fresh translations:
```bash
pnpm build:with-translations
```

## Supported Languages

Currently supported languages:
- English (en) - Source
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Japanese (ja)
- Korean (ko)
- Chinese (zh)

To add a new language:
1. Add the language code to `SUPPORTED_LANGUAGES` in `scripts/translate.ts`
2. Run the translation script

## Translation Process

1. The system reads all JSON files from the English (en) directory
2. For each supported language:
   - Creates language directory if it doesn't exist
   - Translates new or modified content
   - Preserves existing translations
   - Maintains JSON structure and formatting

## Best Practices

1. Always add new content in English first
2. Use clear, context-rich keys in translation files
3. Run `pnpm translate` before committing changes
4. Use namespaced files for different sections of the application
5. Keep translation files modular and organized

## Quality Assurance

1. The translation script preserves:
   - JSON structure
   - Variable placeholders
   - Formatting
   - Special characters

2. Manual review process:
   - Review generated translations
   - Check context accuracy
   - Verify placeholder preservation
   - Test in application

## Troubleshooting

If translations are not working:

1. Check the LLM endpoint is running:
   ```bash
   curl http://localhost:11434/api/health
   ```

2. Verify JSON syntax:
   ```bash
   pnpm lint
   ```

3. Clear translated files and regenerate:
   ```bash
   rm -rf public/locales/*/!(en)
   pnpm translate
   ```

## Adding New Languages

To add support for a new language:

1. Add the language code to `SUPPORTED_LANGUAGES` in `scripts/translate.ts`:
   ```typescript
   const SUPPORTED_LANGUAGES = [...existing, 'new-code'];
   ```

2. Run the translation script:
   ```bash
   pnpm translate
   ```

3. Verify the new translations in the application
