# Internationalization (i18n) in CaringMind

This document describes how internationalization is implemented in the CaringMind web application.

## Setup

The application uses the following packages for internationalization:
- `i18next`: Core internationalization framework
- `react-i18next`: React bindings for i18next
- `i18next-http-backend`: Load translations using HTTP
- `i18next-browser-languagedetector`: Detect user language preferences

## Directory Structure

```
public/
  └── locales/
      ├── en/
      │   └── translation.json
      └── es/
          └── translation.json
src/
  ├── i18n.ts                    # i18n configuration
  └── components/
      ├── LanguageSwitcher.tsx   # Language selection component
      └── Header.tsx             # Example of i18n usage
```

## Usage

### Basic Translation

```typescript
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t } = useTranslation();
  return <h1>{t('welcome')}</h1>;
}
```

### Changing Languages

The LanguageSwitcher component allows users to switch between available languages:

```typescript
import { useTranslation } from 'react-i18next';

function LanguageSwitcher() {
  const { i18n } = useTranslation();

  const changeLanguage = (lng: string) => {
    i18n.changeLanguage(lng);
  };
}
```

## Adding New Languages

1. Create a new folder in `/public/locales/` with the language code (e.g., `fr/`)
2. Add a `translation.json` file with the translations
3. Add the language code to `supportedLngs` in `src/i18n.ts`

## Translation Structure

The translation files follow this structure:

```json
{
  "welcome": "Welcome to CaringMind",
  "navigation": {
    "home": "Home",
    "about": "About",
    "services": "Services",
    "contact": "Contact"
  }
}
```

## Features

- 🌐 Automatic language detection
- 💾 Language preference persistence
- 🔄 Dynamic translation loading
- ⚡ Fallback language support
- 📱 Mobile-friendly language switching
- 🔍 SEO-friendly implementation

## Best Practices

1. Use translation keys that are descriptive and organized hierarchically
2. Keep translation files modular and organized by feature/section
3. Always provide translations for all supported languages
4. Use variables for dynamic content: `t('greeting', { name: 'John' })`
5. Include context in translation keys when necessary

## Error Handling

The system automatically falls back to English if:
- A translation key is missing
- The requested language is not supported
- Translation files fail to load

## Performance Considerations

- Translations are loaded on demand
- Language preferences are cached in localStorage
- Bundle size impact is minimized through code splitting
