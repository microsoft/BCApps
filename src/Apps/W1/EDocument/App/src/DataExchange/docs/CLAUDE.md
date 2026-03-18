# Data exchange

Alternative format path that uses BC's Data Exchange Framework instead of code-based codeunits. This is the configuration-driven approach to e-document XML generation and parsing.

## Root files

`EDocDataExchangeImpl.Codeunit.al` implements the "E-Document" interface by delegating to Data Exchange Definitions rather than building XML directly. `EDocServiceDataExchDef.Table.al` links an e-document service to specific Data Exchange Definition codes for each document type and direction (import vs export). The page (`EDocServiceDataExchSub.Page.al`) surfaces this configuration on the service card.

## PEPPOL Data Exchange Definition subfolder

The `PEPPOL Data Exchange Definition/` subfolder contains pre-mapping codeunits and event subscribers that run before and after the Data Exchange Framework processes the XML. These handle edge cases where the generic framework's column-to-field mapping is not sufficient -- for example, mapping PEPPOL's nested party structures to flat BC fields.

## When to use which approach

Microsoft's own guidance notes that the Data Exchange Definitions shipped here "likely can't be used as is" -- they are templates. In practice, most country localizations implement the code-based approach (a codeunit in `src/Format/` or their own app) because it gives full control over XML structure and is easier to debug.

The Data Exchange approach works best when an organization needs to support a non-standard format variation without deploying custom AL code, or when the XML structure closely matches BC's field layout. For complex mappings with nested structures and conditional logic, the code-based path is more maintainable.
