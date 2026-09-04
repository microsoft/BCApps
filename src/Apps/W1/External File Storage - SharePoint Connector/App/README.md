# External File Storage - SharePoint Connector
This connector allows access to Share Point Files and Folder.

By default the connector uses the Microsoft Graph API. In Microsoft Graph mode a proper App Registration with either the Sites.ReadWrite.All or Sites.Selected Microsoft Graph application permission is needed.

Sites.ReadWrite.All grants the app read and write access to all site collections. Sites.Selected limits access to specific site collections. When using Sites.Selected, a SharePoint administrator must also grant the app the write role for each site that the connector will access. The administrator can create these site-specific grants using Microsoft Graph PowerShell, Microsoft 365 CLI, or a Microsoft Graph API call.

When the account uses the legacy REST API ("Use legacy REST API"), the app acquires a SharePoint resource token instead and requires the corresponding SharePoint (Office 365 SharePoint) permissions rather than Microsoft Graph permissions.