// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;

codeunit 7000098 "CRT Reversal Entry"
{
    var
        EntryCannotBeReversedErr: Label 'The entry cannot be reversed';
        CannotReverseCarteraInvoiceErr: Label 'You can not reverse entries that sent invoices to Cartera.';

    [EventSubscriber(ObjectType::Table, Database::"Reversal Entry", 'OnBeforeCheckGLAcc', '', false, false)]
    local procedure OnBeforeCheckGLAcc(var GLEntry: Record "G/L Entry")
    var
        GLRegDoc: Codeunit "G/L Reg.-Docs.";
        CarteraDoc: Record "Cartera Doc.";
        CarteraSetup: Record "Cartera Setup";
    begin
        if not CarteraSetup.ReadPermission then
            exit;

        if (GLEntry."Bill No." <> '') or GLRegDoc.CheckPostedDocsInPostedBGPO(GLEntry) then
            Error(EntryCannotBeReversedErr);

        if GLEntry."Document Type" <> GLEntry."Document Type"::Invoice then
            exit;

        CarteraDoc.SetCurrentKey(Type, "Document No.");
        CarteraDoc.SetRange("Document No.", GLEntry."Document No.");
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        if CarteraDoc.FindFirst() then
            Error(CannotReverseCarteraInvoiceErr);
    end;
}