// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Token Refresh Shop (ID 30432).
/// Per-shop worker for the "Shpfy Token Refresh" backstop. Run via Codeunit.Run so that a failure
/// for one shop is isolated in its own transaction and does not abort the whole backstop run.
/// </summary>
codeunit 30432 "Shpfy Token Refresh Shop"
{
    Access = Internal;
    TableNo = "Shpfy Shop";

    trigger OnRun()
    var
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
        Store: Text;
    begin
        Store := Rec.GetStoreName();
        if Store <> '' then
            AuthenticationMgt.EnsureValidAccessToken(Store);
    end;
}
