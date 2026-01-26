// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Prepares general journal line data for SEPA credit transfer XML export by copying and organizing
/// eligible journal entries into a temporary structure for XMLPort processing.
/// </summary>
codeunit 1222 "SEPA CT-Prepare Source"
{
    TableNo = "Gen. Journal Line";

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
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentDocNo: Code[20];
        AppliedDocNoList: Text;
        DescriptionLen: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        PaymentDocNo := FromGenJnlLine.GetFilter("Document No.");
        PaymentHeader.Get(PaymentDocNo);
        PaymentLine.Reset();
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        if PaymentLine.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine."Journal Template Name" := '';
                TempGenJnlLine."Journal Batch Name" := Format(DATABASE::"Payment Header");
                TempGenJnlLine."Document No." := PaymentHeader."No.";
                TempGenJnlLine."Line No." := PaymentLine."Line No.";
                TempGenJnlLine."Account No." := PaymentLine."Account No.";
                TempGenJnlLine."Account Type" := PaymentLine."Account Type";
                case PaymentLine."Account Type" of
                    PaymentLine."Account Type"::Vendor:
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    PaymentLine."Account Type"::Customer:
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Refund;
                end;
                TempGenJnlLine.Amount := PaymentLine.Amount;
                TempGenJnlLine."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type";
                TempGenJnlLine."Applies-to Doc. No." := PaymentLine."Applies-to Doc. No.";
                TempGenJnlLine."Applies-to ID" := PaymentLine."Applies-to ID";
                TempGenJnlLine."Bal. Account Type" := PaymentHeader."Account Type";
                TempGenJnlLine."Bal. Account No." := PaymentHeader."Account No.";
                TempGenJnlLine."Currency Code" := PaymentLine."Currency Code";
                TempGenJnlLine."Posting Date" := PaymentLine."Posting Date";
                TempGenJnlLine."Recipient Bank Account" := PaymentLine."Bank Account Code";

                DescriptionLen := MaxStrLen(TempGenJnlLine.Description);
                AppliedDocNoList := PaymentLine.GetAppliedDocNoList(DescriptionLen);
                TempGenJnlLine.Description := CopyStr(AppliedDocNoList, 1, DescriptionLen);
                if StrLen(AppliedDocNoList) > DescriptionLen then
                    TempGenJnlLine."Message to Recipient" :=
                      CopyStr(AppliedDocNoList, DescriptionLen + 1, MaxStrLen(TempGenJnlLine."Message to Recipient"));
                OnCreateTempJnlLinesOnBeforeInsertTempGenJnlLine(TempGenJnlLine, PaymentLine);
                TempGenJnlLine.Insert();
            until PaymentLine.Next() = 0;

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
    local procedure OnCreateTempJnlLinesOnBeforeInsertTempGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; var PaymentLine: Record "Payment Line")
    begin
    end;
}

