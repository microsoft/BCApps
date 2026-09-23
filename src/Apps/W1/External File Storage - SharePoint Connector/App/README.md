# External File Storage - SharePoint Connector
This connector provides access to SharePoint files and folders.

## Microsoft Entra permissions

The connector supports the Microsoft Graph API and the legacy SharePoint REST API. Configure the app registration with permissions for the API used by the account.

| Connector mode | Authentication type | Least-privileged permission for full connector functionality | Tenant-wide alternative |
| --- | --- | --- | --- |
| Microsoft Graph (default) | Client Secret or Certificate | Microsoft Graph application permission `Sites.Selected` and a `write` role granted for each site that the connector accesses | Microsoft Graph application permission `Sites.ReadWrite.All` |
| Legacy SharePoint REST API | Certificate | SharePoint application permission `Sites.Selected` and a `write` role granted for each site that the connector accesses | SharePoint application permission `Sites.ReadWrite.All` |
| Legacy SharePoint REST API | Client Secret | SharePoint delegated permission `AllSites.Write`; access is also limited by the signed-in user's SharePoint permissions | Not applicable |

The connector requires write access because it can upload, copy, move, and delete files and folders. It does not require permission to administer sites or manage permissions.

`Sites.Selected` grants no access by itself. A SharePoint administrator must also grant the app the `write` role on every site that the connector will access. The administrator can create the site-specific grants using Microsoft Graph PowerShell, Microsoft 365 CLI, or Microsoft Graph. The app or administrator that creates these grants needs separate permission to manage site permissions; the connector app does not need that elevated permission.

For more information, see [Overview of Selected Permissions in OneDrive and SharePoint](https://learn.microsoft.com/graph/permissions-selected-overview) and [Understanding Resource Specific Consent for Microsoft Graph and SharePoint Online](https://learn.microsoft.com/sharepoint/dev/sp-add-ins-modernize/understanding-rsc-for-msgraph-and-sharepoint-online).
