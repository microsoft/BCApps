// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Intercompany.Inbox;
using System.Threading;

codeunit 791 "IC Inbox Outbox Subs. Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        ICInboxTransaction.Get(Rec."Record ID to Process");
        Codeunit.Run(Codeunit::"IC Inbox Outbox Subscribers", ICInboxTransaction)
    end;
}
