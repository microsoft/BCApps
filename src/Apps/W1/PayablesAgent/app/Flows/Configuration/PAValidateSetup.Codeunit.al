// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

codeunit 3310 "PA Validate Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = rid;

    var
        DesiredSetup: Codeunit "PA Setup";

    procedure ConfigureSetupToValidate(var PASetup: Codeunit "PA Setup")
    begin
        DesiredSetup := PASetup;
    end;

    trigger OnRun()
    var
        TempEmailInbox: Record "Email Inbox" temporary;
        TempFilters: Record "Email Retrieval Filters" temporary;
        Email: Codeunit "Email";
    begin
        TempFilters."Unread Emails" := true;
        TempFilters."Earliest Email" := DesiredSetup.GetLastSyncAt();
        TempFilters."Max No. of Emails" := 1;
        Email.RetrieveEmails(DesiredSetup.GetEmailAccountId(), "Email Connector"::"Microsoft 365", TempEmailInbox, TempFilters);
    end;
}
