# External File Storage - SharePoint Connector
This connector allows access to Share Point Files and Folder.
A proper App Registration with Sites.ReadWrite.All permission is needed.

Legacy REST file and folder operations use SharePoint ResourcePath endpoints so legal names containing `#` or `%` are addressed unambiguously. Existing URL-based SharePoint Client APIs remain unchanged; the connector uses separate decoded-path APIs.

For REST accounts, **REST Base Folder Path Format** defaults to **URL**, including existing accounts. Percent-encoded base folders such as `/sites/ProjectX/Shared%20Documents` are decoded once before the ResourcePath request is constructed. Choose **Decoded Path** when a folder name literally contains a percent sequence, for example `Reports%20Archive`. Raw spaces, `#`, and non-encoded percent characters can also be used in decoded paths. The site prefix is decoded from the SharePoint site URL, but paths and filenames supplied to file operations are never unescaped. Microsoft Graph accounts are unaffected by this setting.
