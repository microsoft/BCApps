// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

codeunit 3328 "PA Email Inbox Row Delete"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Email Inbox";
    Permissions = tabledata "Email Inbox" = rd;

    trigger OnRun()
    begin
        // Error boundary needed to skip records if the trigger chain fails for whatever reason.
        Rec.Delete(true);
    end;
}
