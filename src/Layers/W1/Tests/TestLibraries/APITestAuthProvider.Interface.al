// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

/// <summary>
/// Provides authentication configuration for API test requests.
/// </summary>
interface "API Test Auth Provider"
{
    /// <summary>
    /// Configures authentication for an API test request.
    /// </summary>
    /// <param name="TargetURL">The final request URL after URL overrides have been applied.</param>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(TargetURL: Text; var Authentication: Codeunit "API Test Auth Context");
}
