# External File Storage - SharePoint Connector
This connector allows access to Share Point Files and Folder.

By default the connector uses the Microsoft Graph API. In Microsoft Graph mode a proper App Registration with either the Sites.ReadWrite.All or Sites.Selected Microsoft Graph application permission is needed.

Sites.ReadWrite.All grants the app read and write access to all site collections. Sites.Selected limits access to specific site collections. When using Sites.Selected, a SharePoint administrator must also grant the app the write role for each site that the connector will access. The administrator can create these site-specific grants using Microsoft Graph PowerShell, Microsoft 365 CLI, or a Microsoft Graph API call.

When the account uses the legacy REST API ("Use legacy REST API"), the app acquires a token for the SharePoint Online resource (Office 365 SharePoint Online) instead of Microsoft Graph, so the app registration must be granted SharePoint API permissions rather than Microsoft Graph permissions. Grant the permission that matches the authentication type: the application permission Sites.FullControl.All for Certificate (client-credentials, app-only) authentication, or the delegated permission AllSites.Manage for Client Secret (authorization-code) authentication.

Legacy REST file and folder operations use SharePoint ResourcePath endpoints so legal names containing `#` or `%` are addressed unambiguously. Existing URL-based SharePoint Client APIs remain unchanged; the connector uses separate decoded-path APIs.

For REST accounts, **REST Base Folder Path Format** defaults to **URL**, including existing accounts. Percent-encoded base folders such as `/sites/ProjectX/Shared%20Documents` are decoded once before the ResourcePath request is constructed. Choose **Decoded Path** when a folder name literally contains a percent sequence, for example `Reports%20Archive`. Raw spaces, `#`, and non-encoded percent characters can also be used in decoded paths. The site prefix is decoded from the SharePoint site URL, but paths and filenames supplied to file operations are never unescaped. Microsoft Graph accounts are unaffected by this setting.