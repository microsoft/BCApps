// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000080 "CRT Bank Account"
{
    var
        CarteraSetup: Record "Cartera Setup";
        CannotChangeDueToPostedBillGroupsErr: Label 'You cannot change %1 because there are one or more posted bill groups for this bank account.', Comment = '%1 = Field caption';
        CannotChangeDueToPostedPmtOrdersErr: Label 'You cannot change %1 because there are one or more posted payment orders for this bank account.', Comment = '%1 = Field caption';

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", OnAfterValidateEvent, 'No.', false, false)]
    local procedure NoOnAfterValidate(var Rec: Record "Bank Account"; var xRec: Record "Bank Account"; CurrFieldNo: Integer)
    begin
        Rec."Operation Fees Code" := Rec."No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", OnAfterValidateEvent, 'Currency Code', false, false)]
    local procedure CurrencyCodeOnAfterValidate(var Rec: Record "Bank Account"; var xRec: Record "Bank Account"; CurrFieldNo: Integer)
    var
        PostedBillGr: Record "Posted Bill Group";
        PostedPmtOrd: Record "Posted Payment Order";
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.");
            PostedBillGr.SetRange("Bank Account No.", Rec."No.");
            if not PostedBillGr.IsEmpty() then
                Error(CannotChangeDueToPostedBillGroupsErr, Rec.FieldCaption("Currency Code"));
            PostedPmtOrd.SetCurrentKey("Bank Account No.");
            PostedPmtOrd.SetRange("Bank Account No.", Rec."No.");
            if not PostedPmtOrd.IsEmpty() then
                Error(CannotChangeDueToPostedPmtOrdersErr, Rec.FieldCaption("Currency Code"));
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", OnAfterDeleteEvent, '', false, false)]
    local procedure CurrencyCodeOnAfterDelete(var Rec: Record "Bank Account")
    var
        Suffix: Record Suffix;
        DocumentMove: Codeunit "Document-Move";
    begin
        DocumentMove.MoveBankAccDocs(Rec);

        if CarteraSetup.ReadPermission then begin
            Suffix.SetRange("Bank Acc. Code", Rec."No.");
            Suffix.DeleteAll();
        end;
    end;
}