// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6990 "EA Agent Card Notif. Handler"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure OpenExpenseAgentSetup(Notification: Notification)
    begin
        Page.Run(Page::"Expense Agent Setup");
    end;
}
