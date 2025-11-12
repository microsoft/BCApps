// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using System.IO;

/// <summary>
/// Prepares positive pay detail records from check ledger entries for export processing.
/// This codeunit converts check ledger entry data into the standardized positive pay detail format.
/// </summary>
/// <remarks>
/// The Export Pre-Mapping Detail Positive Pay codeunit is responsible for creating positive pay detail records
/// from check ledger entries during the export process. It handles both regular checks and voided checks,
/// applying appropriate record type codes and indicators. The codeunit processes check ledger entries in batches
/// and provides progress feedback to users during large exports. It also provides extensibility through
/// integration events for custom field mapping and validation requirements.
/// </remarks>
codeunit 1704 "Exp. Pre-Mapping Det Pos. Pay"
{
    Permissions = TableData "Positive Pay Detail" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckLedgerEntryView: Text;
        LineNo: Integer;
    begin
        OnGetFiltersBeforePreparingPosPayDetails(CheckLedgerEntryView);
        CheckLedgerEntry.SetView(CheckLedgerEntryView);
        CheckLedgerEntry.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, Rec."Entry No.", LineNo);

        // Reset filters and set it on the Data Exch. Voided Entry No.
        CheckLedgerEntry.Reset();
        CheckLedgerEntry.SetView(CheckLedgerEntryView);
        CheckLedgerEntry.SetRange("Data Exch. Voided Entry No.", Rec."Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, Rec."Entry No.", LineNo);
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Preprocessing line no. #1######.';
#pragma warning restore AA0470

    local procedure PreparePosPayDetails(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; var LineNo: Integer)
    var
        Window: Dialog;
    begin
        if CheckLedgerEntry.FindSet() then begin
            Window.Open(ProgressMsg);
            repeat
                LineNo += 1;
                Window.Update(1, LineNo);
                PreparePosPayDetail(CheckLedgerEntry, DataExchangeEntryNo, LineNo);
            until CheckLedgerEntry.Next() = 0;
            Window.Close();
        end;
    end;

    local procedure PreparePosPayDetail(CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; LineNo: Integer)
    var
        BankAccount: Record "Bank Account";
        PosPayDetail: Record "Positive Pay Detail";
    begin
        BankAccount.Get(CheckLedgerEntry."Bank Account No.");

        PosPayDetail.Init();
        PosPayDetail."Data Exch. Entry No." := DataExchangeEntryNo;
        PosPayDetail."Entry No." := LineNo;
        PosPayDetail."Account Number" := BankAccount."Bank Account No.";
        if DataExchangeEntryNo = CheckLedgerEntry."Data Exch. Voided Entry No." then begin
            // V for Void legend
            PosPayDetail."Record Type Code" := 'V';
            PosPayDetail."Void Check Indicator" := 'V';
        end else begin
            // O for Open legend
            PosPayDetail."Record Type Code" := 'O';
            PosPayDetail."Void Check Indicator" := '';
        end;
        PosPayDetail."Check Number" := CheckLedgerEntry."Check No.";
        PosPayDetail.Amount := CheckLedgerEntry.Amount;
        PosPayDetail.Payee := CheckLedgerEntry.Description;
        PosPayDetail."Issue Date" := CheckLedgerEntry."Check Date";
        if BankAccount."Currency Code" <> '' then
            PosPayDetail."Currency Code" := BankAccount."Currency Code";

        OnPreparePosPayDetailOnBeforeInsert(CheckLedgerEntry, PosPayDetail);
        PosPayDetail.Insert(true);
    end;

    /// <summary>
    /// Integration event that allows retrieval of custom filters before preparing positive pay details.
    /// </summary>
    /// <param name="CheckLedgerEntryView">Returns the filter view to be applied to check ledger entries.</param>
    /// <remarks>
    /// This integration event allows external code to specify custom filtering criteria for check ledger entries
    /// before they are processed into positive pay details. Subscribers can set specific date ranges, account filters,
    /// or other criteria to control which checks are included in the export.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnGetFiltersBeforePreparingPosPayDetails(var CheckLedgerEntryView: Text)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of positive pay detail records before insertion.
    /// </summary>
    /// <param name="CheckLedgerEntry">The source check ledger entry being processed.</param>
    /// <param name="PositivePayDetail">The positive pay detail record being created, available for modification.</param>
    /// <remarks>
    /// This integration event enables customization of positive pay detail records after standard field mapping
    /// but before the record is inserted. Subscribers can add custom field mappings, perform additional validation,
    /// or modify field values based on specific business requirements.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnPreparePosPayDetailOnBeforeInsert(CheckLedgerEntry: Record "Check Ledger Entry"; var PositivePayDetail: Record "Positive Pay Detail")
    begin
    end;
}

