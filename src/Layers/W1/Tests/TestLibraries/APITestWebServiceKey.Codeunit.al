// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System.Security.AccessControl;

/// <summary>
/// Creates a web service key for the current user with a 24-hour expiry.
/// Started in a background session when possible, so the key is committed without committing the caller's transaction.
/// </summary>
codeunit 131025 "API Test Web Service Key"
{
    Access = Internal;

    trigger OnRun()
    var
        IdentityManagement: Codeunit "Identity Management";
    begin
        IdentityManagement.CreateWebServicesKey(UserSecurityId(), CurrentDateTime() + 24 * 60 * 60 * 1000);
    end;
}
