// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6996 "Exp. Preview Posting Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::"Expense Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertExpenseLedgEntry(var Rec: Record "Expense Ledger Entry"; RunTrigger: Boolean)
    var
        ExpensePreviewPostInstance: Codeunit "Expense Preview Post Instance";
    begin
        ExpensePreviewPostInstance.InsertExpenseLedgerEntry(Rec, RunTrigger);
    end;

    procedure TryBindPostingPreviewHandler(): Boolean
    begin
        exit(BindSubscription(this));
    end;

    procedure TryUnbindPostingPreviewHandler(): Boolean
    begin
        exit(UnbindSubscription(this));
    end;
}