This module provides the tools needed to manage an extension.

Use this module to do the following:
- Install and uninstall extensions, with the option to use UI events
- Upload and deploy an extension
- Publish or unpublish extensions (publishing is available only in the client)
- Download a per-tenant extension source
- Check whether an extension is installed, which version, and whether its the latest
- Refresh and retrieve the extension deployment status and information
- Enable or disable http client requests
- Retrieve an extension's logo

The Extension Settings card supports editing extension settings and the same
per-extension lifecycle actions as Extension Management, including Uninstall.
New and Delete are not available because creating or deleting a settings record
does not install or uninstall an extension.

Marketplace installation skips an already-installed app before opening the wizard.
The installation page also checks installed state when reopened after a session
refresh, so returning from post-install setup does not restart installation.
