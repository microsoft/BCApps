// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

/// <summary>
/// Prepares general journal line data for SEPA credit transfer XML export by copying and organizing
/// eligible journal entries into a temporary structure for XMLPort processing.
/// </summary>
codeunit 1222 "SEPA CT-Prepare Source"
{
    TableNo = "Gen. Journal Line";

    var
        DescriptionTxt: Label '%1; %2', Comment = '%1=Vendor Invoice No., %2=Bill No.';

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.CopyFilters(Rec);
        CopyJnlLines(GenJnlLine, Rec);
    end;

    /// <summary>
    /// Copies eligible general journal lines to a temporary table for SEPA credit transfer processing.
    /// Processes journal lines and applies customization through integration events.
    /// </summary>
    /// <param name="FromGenJnlLine">Source general journal lines with applied filters.</param>
    /// <param name="TempGenJnlLine">Target temporary table to receive the processed journal lines.</param>
    local procedure CopyJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if FromGenJnlLine.FindSet() then begin
            GenJnlBatch.Get(FromGenJnlLine."Journal Template Name", FromGenJnlLine."Journal Batch Name");

            repeat
                TempGenJnlLine := FromGenJnlLine;
                OnCopyJnlLinesOnBeforeTempGenJnlLineInsert(FromGenJnlLine, TempGenJnlLine, GenJnlBatch);
                TempGenJnlLine.Insert();
            until FromGenJnlLine.Next() = 0
        end else
            CreateTempJnlLines(FromGenJnlLine, TempGenJnlLine);
    end;

    /// <summary>
    /// Creates temporary journal lines when no source lines are found.
    /// Allows customization through integration events for alternative data population strategies.
    /// </summary>
    /// <param name="FromGenJnlLine">Source journal line record used as template for temporary lines.</param>
    /// <param name="TempGenJnlLine">Target temporary table to populate with generated journal lines.</param>
    local procedure CreateTempJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        PaymentOrder: Record "Payment Order";
        PurchInvHeader: Record "Purch. Inv. Header";
        CarteraDoc: Record "Cartera Doc.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        TempGenJnlLine.Reset();
        PaymentOrder.Get(FromGenJnlLine.GetFilter("Document No."));
        CarteraDoc.Reset();
        CarteraDoc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.");
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrder."No.");
        if CarteraDoc.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine."Journal Template Name" := '';
                TempGenJnlLine."Journal Batch Name" := '';
                TempGenJnlLine."Line No." := CarteraDoc."Entry No.";
                TempGenJnlLine."Posting Date" := CarteraDoc."Due Date";
                TempGenJnlLine."Due Date" := CarteraDoc."Due Date";
                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Vendor;
                TempGenJnlLine."Account No." := CarteraDoc."Account No.";
                TempGenJnlLine."Recipient Bank Account" := CarteraDoc."Cust./Vendor Bank Acc. Code";
                TempGenJnlLine."Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
                TempGenJnlLine."Bal. Account No." := PaymentOrder."Bank Account No.";
                TempGenJnlLine."Bill No." := CarteraDoc."Document No.";
                TempGenJnlLine."Document No." := PaymentOrder."No.";
                if PurchInvHeader.Get(CarteraDoc."Document No.") then
                    TempGenJnlLine.Description := StrSubstNo(DescriptionTxt, PurchInvHeader."Vendor Invoice No.", CarteraDoc.Description);
                TempGenJnlLine."External Document No." := CarteraDoc."Original Document No.";
                TempGenJnlLine."Currency Code" := CarteraDoc."Currency Code";
                TempGenJnlLine.Amount := CarteraDoc."Remaining Amount";
                OnCreateTempJnlLinesOnBeforeTempGenJnlLineInsert(TempGenJnlLine, CarteraDoc);
                TempGenJnlLine.Insert();
                OnCreateTempJnlLinesOnAfterTempGenJnlLineInsert(TempGenJnlLine, CarteraDoc);
            until CarteraDoc.Next() = 0;

        OnAfterCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine);
    end;

    /// <summary>
    /// Integration event raised after creating temporary journal lines.
    /// Allows subscribers to modify or enhance the temporary lines after standard processing.
    /// </summary>
    /// <param name="FromGenJnlLine">Source journal line record used as template.</param>
    /// <param name="TempGenJnlLine">Target temporary journal line that was created or modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised before creating temporary journal lines.
    /// Allows subscribers to provide custom logic for temporary line creation.
    /// </summary>
    /// <param name="FromGenJnlLine">Source journal line record used as template.</param>
    /// <param name="TempGenJnlLine">Target temporary journal line to be created.</param>
    /// <param name="IsHandled">Set to true if the subscriber handles the line creation completely.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting temporary journal lines during the copy process.
    /// Allows subscribers to modify journal line data or apply custom transformations.
    /// </summary>
    /// <param name="FromGenJournalLine">Source journal line being processed.</param>
    /// <param name="TempGenJournalLine">Target temporary journal line to be inserted.</param>
    /// <param name="GenJournalBatch">Journal batch context for the operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCopyJnlLinesOnBeforeTempGenJnlLineInsert(var FromGenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJnlLinesOnBeforeTempGenJnlLineInsert(var TempGenJnlLine: Record "Gen. Journal Line"; CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJnlLinesOnAfterTempGenJnlLineInsert(var TempGenJnlLine: Record "Gen. Journal Line"; CarteraDoc: Record "Cartera Doc.")
    begin
    end;
}

