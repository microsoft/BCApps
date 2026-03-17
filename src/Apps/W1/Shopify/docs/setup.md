# Setup

## Prerequisites

- Business Central development environment with NAV Server instance (NST) running
- VS Code with the AL Language extension
- Access to the NAV repository with enlistment modules loaded (via `dispatch`)

## Project structure

```
Shopify/
  App/                          -- Main app source
    app.json                    -- App ID: ec255f57-31d0-4ca2-b751-f2fa7c745abb
    src/                        -- 28 modules, ~640 AL files
  Test/                         -- Test app source
    app.json                    -- Test app ID: 32f586f0-69fd-41bb-8e97-98c869856360
  Shopify.code-workspace        -- VS Code workspace (App + Test folders)
```

The workspace file at `Shopify.code-workspace` opens both the main app and test app as workspace folders.

## App identity

- **App name**: `Shopify Connector`
- **Test app name**: `Shopify Connector Test`
- **Publisher**: Microsoft
- **ID range**: 30100--30460
- **Platform/Application version**: 29.0.0.0
- **Namespace**: `Microsoft.Integration.Shopify`
- **Object prefix**: `Shpfy`
- **CountryCode**: W1

## Compile and publish

The Shopify Connector lives inside the BCApps submodule. Use the NAV repo's build infrastructure via `dispatch`:

```bash
# Compile the main app
dispatch 'Build-Application -Name "Shopify Connector" -CountryCode W1'

# Compile the test app
dispatch 'Build-Application -Name "Shopify Connector Test" -CountryCode W1'
```

After compiling, publish to the running NST:

```bash
# Publish main app
dispatch 'Publish-Application -Name "Shopify Connector" -CountryCode W1'

# Publish test app (depends on main app being published first)
dispatch 'Publish-Application -Name "Shopify Connector Test" -CountryCode W1'
```

For details on compile/publish commands and flags, see `Eng/Docs/al-workflow.md` in the NAV repo root.

## Running tests

```bash
dispatch 'Run-Tests -Name "Shopify Connector Test" -CountryCode W1'
```

For test runner options and filtering, see `Eng/Docs/al-testing.md` in the NAV repo root.

## Configuration

### app.json settings

- **dependencies**: None (no external app dependencies)
- **internalsVisibleTo**: `Shopify Connector Test` -- the test app can access internal members
- **target**: `OnPrem` (also runs in SaaS)
- **features**: `NoImplicitWith`, `TranslationFile`
- **resourceExposurePolicy**: Source included in symbols, debugging allowed

### ID ranges

All objects (tables, codeunits, pages, enums) use IDs in the range 30100--30460.

### Key app.json fields for extensions

Third-party extensions that extend the Shopify Connector should:

- Add a dependency on app ID `ec255f57-31d0-4ca2-b751-f2fa7c745abb` (Shopify Connector)
- Use enum extensions to add new mapping strategies
- Subscribe to integration events published by sync codeunits
