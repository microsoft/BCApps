This module provides functionality for integrating with GitHub Codespaces through the GitHub API.

Use this module to:
- Create new GitHub Codespaces for existing repositories
- Create repositories from GitHub templates
- Create repositories from templates and automatically launch Codespaces
- Manage Codespace configurations and settings

This module enables developers to programmatically create development environments directly from Business Central, streamlining the development workflow by providing instant access to cloud-based development environments.

**Prerequisites**
- Valid GitHub personal access token or GitHub App authentication
- Appropriate permissions to create repositories and Codespaces in the target organization
- Access to GitHub Codespaces (available with GitHub Pro, Team, or Enterprise plans)

**Authentication**
This module requires GitHub authentication to interact with the GitHub API. You must provide a valid authentication token with the necessary scopes:
- `repo` scope for repository operations
- `codespace` scope for Codespace operations
- `repo:status` for repository status information

For more information about GitHub Codespaces, see the [GitHub Codespaces documentation](https://docs.github.com/en/codespaces).