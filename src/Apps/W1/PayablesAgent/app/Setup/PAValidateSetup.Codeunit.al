// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

/// <summary>
/// Validates that a desired setup configuration is valid before persisting it. 
/// </summary>
codeunit 3310 "PA Validate Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = rid;

    var
        PayablesAgentSetup: Record "Payables Agent Setup";

    procedure ConfigureSetupToValidate(NewPayablesAgentSetup: Record "Payables Agent Setup")
    begin
        PayablesAgentSetup := NewPayablesAgentSetup;
    end;

    trigger OnRun()
    var
        TempEmailInbox: Record "Email Inbox" temporary;
        TempFilters: Record "Email Retrieval Filters" temporary;
        Email: Codeunit "Email";
    begin
        TempFilters."Unread Emails" := true;
        TempFilters."Earliest Email" := PayablesAgentSetup."Last Sync At";
        TempFilters."Max No. of Emails" := 1;
        Email.RetrieveEmails(PayablesAgentSetup."Email Account Id", "Email Connector"::"Microsoft 365", TempEmailInbox, TempFilters);
    end;
}
