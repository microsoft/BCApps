// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;

codeunit 7000081 "Cartera General Ledger"
{

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', true, true)]
    local procedure OnAfterCopyGLEntryFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."Bill No." := GenJournalLine."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"CV Ledger Entry Buffer", 'OnAfterCopyFromVendLedgerEntry', '', true, true)]
    local procedure OnAfterCopyFromVendLedgerEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        CVLedgerEntryBuffer."Bill No." := VendorLedgerEntry."Bill No.";
        CVLedgerEntryBuffer."Document Situation" := VendorLedgerEntry."Document Situation";
        CVLedgerEntryBuffer."Applies-to Bill No." := VendorLedgerEntry."Applies-to Bill No.";
        CVLedgerEntryBuffer."Document Status" := VendorLedgerEntry."Document Status";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed CV Ledg. Entry Buffer", 'OnAfterCopyFromGenJnlLine', '', true, true)]
    local procedure OnAfterCopyFromGenJnlLine(var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line")
    begin
        DtldCVLedgEntryBuffer."Bill No." := GenJnlLine."Bill No.";
        DtldCVLedgEntryBuffer."Applies-to Bill No." := GenJnlLine."Applies-to Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed CV Ledg. Entry Buffer", 'OnBeforeCreateDtldCVLedgEntryBuf', '', true, true)]
    local procedure OnBeforeCreateDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextDtldBufferEntryNo: Integer; var IsHandled: Boolean; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        DtldCVLedgEntryBuf.SetRange("Bill No.", NewDtldCVLedgEntryBuf."Bill No.");
        DtldCVLedgEntryBuf.SetRange("Document Situation", NewDtldCVLedgEntryBuf."Document Situation");
        DtldCVLedgEntryBuf.SetRange("Document Status", NewDtldCVLedgEntryBuf."Document Status");
    end;
}