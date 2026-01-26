// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

codeunit 5005273 "Iss. Delivery Remind. printed"
{
    Permissions = TableData "Issued Deliv. Reminder Header" = rimd;
    TableNo = "Issued Deliv. Reminder Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnRunOnBeforeModify(Rec);
        Rec.Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeModify(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
    end;
}

