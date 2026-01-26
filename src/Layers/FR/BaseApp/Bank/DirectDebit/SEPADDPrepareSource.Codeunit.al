// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;

/// <summary>
/// Prepares direct debit collection entry data for SEPA XML export by copying and organizing
/// eligible entries into a temporary structure for XMLPort processing.
/// </summary>
codeunit 1232 "SEPA DD-Prepare Source"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.CopyFilters(Rec);
        CopyLines(DirectDebitCollectionEntry, Rec);
    end;

    var
        HasErrorsErr: Label 'The file export has one or more errors. For each of the lines to be exported, resolve any errors that are displayed in the File Export Errors FactBox.';

    /// <summary>
    /// Copies eligible direct debit collection entries to a temporary table for processing.
    /// Filters entries by status (New or File Created) and populates the target temporary table.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source direct debit collection entries with applied filters.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary table to receive the filtered entries.</param>
    local procedure CopyLines(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
        if not FromDirectDebitCollectionEntry.IsEmpty() then begin
            FromDirectDebitCollectionEntry.SetFilter(Status, '%1|%2',
              FromDirectDebitCollectionEntry.Status::New, FromDirectDebitCollectionEntry.Status::"File Created");
            if FromDirectDebitCollectionEntry.FindSet() then
                repeat
                    ToDirectDebitCollectionEntry := FromDirectDebitCollectionEntry;
                    ToDirectDebitCollectionEntry.Insert();
                until FromDirectDebitCollectionEntry.Next() = 0
        end else
            CreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    /// <summary>
    /// Creates temporary collection entries when no source entries are found.
    /// Allows customization through integration events for alternative data population strategies.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source entry record used as template for temporary entries.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary table to populate with generated entries.</param>
    local procedure CreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        SEPADDCheckLine: Codeunit "SEPA DD-Check Line";
        AppliesToEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry, IsHandled);
        if IsHandled then
            exit;

        ToDirectDebitCollectionEntry.Reset();
        DirectDebitCollection.Get(FromDirectDebitCollectionEntry.GetRangeMin("Direct Debit Collection No."));
        PaymentHeader.Get(DirectDebitCollection.Identifier);
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        if PaymentLine.FindSet() then
            repeat
                ToDirectDebitCollectionEntry.Init();
                ToDirectDebitCollectionEntry."Entry No." := PaymentLine."Line No.";
                ToDirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
                ToDirectDebitCollectionEntry.DeletePaymentFileErrors();
                if SEPADDCheckLine.CheckPaymentLine(ToDirectDebitCollectionEntry, PaymentLine, AppliesToEntryNo) then begin
                    ToDirectDebitCollectionEntry.Validate("Customer No.", PaymentLine."Account No.");
                    ToDirectDebitCollectionEntry.Validate("Applies-to Entry No.", AppliesToEntryNo);
                    ToDirectDebitCollectionEntry."Transfer Date" := PaymentHeader."Posting Date";
                    ToDirectDebitCollectionEntry."Currency Code" := PaymentLine."Currency Code";
                    ToDirectDebitCollectionEntry.Validate("Transfer Amount", PaymentLine."Credit Amount");
                    ToDirectDebitCollectionEntry.Validate("Mandate ID", PaymentLine."Direct Debit Mandate ID");
                    OnCreateTempCollectionEntriesOnBeforeInsert(ToDirectDebitCollectionEntry, PaymentHeader, PaymentLine);
                    ToDirectDebitCollectionEntry.Insert();
                    SEPADDCheckLine.CheckCollectionEntry(ToDirectDebitCollectionEntry);
                end;
            until PaymentLine.Next() = 0;

        if DirectDebitCollection.HasPaymentFileErrors() then begin
            Commit();
            Error(HasErrorsErr);
        end;

        OnAfterCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    /// <summary>
    /// Integration event raised after creating temporary collection entries.
    /// Allows subscribers to modify or enhance the temporary entries after creation.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source entry record used as template.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary entry that was created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before creating temporary collection entries.
    /// Allows subscribers to provide custom logic for temporary entry creation.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source entry record used as template.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary entry to be created.</param>
    /// <param name="isHandled">Set to true if the subscriber handles the entry creation completely.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempCollectionEntriesOnBeforeInsert(var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; PaymentHeader: Record "Payment Header"; PaymentLine: Record "Payment Line")
    begin
    end;
}

