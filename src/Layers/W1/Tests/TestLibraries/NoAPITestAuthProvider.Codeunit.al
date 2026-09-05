// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

/// <summary>
/// Leaves API test requests configured with the transport's default authentication behavior.
/// </summary>
codeunit 131024 "No API Test Auth Provider" implements "API Test Auth Provider"
{
    /// <summary>
    /// Leaves the authentication context unchanged.
    /// </summary>
    /// <param name="TargetURL">The final request URL after URL overrides have been applied.</param>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(TargetURL: Text; var Authentication: Codeunit "API Test Auth Context")
    begin
    end;
}
