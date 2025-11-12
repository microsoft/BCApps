// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Setup;
using System.IO;

/// <summary>
/// Launches and orchestrates the positive pay export process for check ledger entries.
/// This codeunit serves as the main entry point for positive pay file generation and export operations.
/// </summary>
/// <remarks>
/// The Export Launcher Positive Pay codeunit coordinates the entire positive pay export workflow from start to finish.
/// It validates bank account setup, creates data exchange entries, processes check ledger entries, and generates
/// output files in the required format. The codeunit handles both header, detail, and footer record generation
/// through the data exchange framework. It also manages the integration with bank export/import setup configurations
/// and provides progress feedback during large data exports. The export process creates audit trail records
/// and updates check ledger entries with export tracking information.
/// </remarks>
codeunit 1700 "Exp. Launcher Pos. Pay"
{
    Permissions = TableData "Check Ledger Entry" = rimd,
                  TableData "Data Exch." = rimd;
    TableNo = "Check Ledger Entry";

    trigger OnRun()
    begin
        PositivePayProcess(Rec, true);
    end;

    /// <summary>
    /// Executes the complete positive pay export process for the specified check ledger entries.
    /// </summary>
    /// <param name="CheckLedgerEntry">The check ledger entries to include in the positive pay export.</param>
    /// <param name="ShowDialog">Indicates whether to display progress dialogs to the user during processing.</param>
    /// <remarks>
    /// This procedure orchestrates the entire positive pay export workflow including validation, data preparation,
    /// file generation, and user feedback. It processes header, detail, and footer records through the data exchange
    /// framework and creates the final export file. The procedure also updates check ledger entries with export
    /// tracking information and creates audit trail records for compliance purposes.
    /// </remarks>
    [Scope('OnPrem')]
    procedure PositivePayProcess(var CheckLedgerEntry: Record "Check Ledger Entry"; ShowDialog: Boolean)
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CheckLedgerEntry2: Record "Check Ledger Entry";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        FileManagement: Codeunit "File Management";
        ExpWritingPosPay: Codeunit "Exp. Writing Pos. Pay";
        ExpExternalDataPosPay: Codeunit "Exp. External Data Pos. Pay";
        DataExchEntryCodeDetail: Integer;
        DataExchEntryCodeFooter: Integer;
        DataExchDefCode: Code[20];
        Filename: Text;
        HeaderArray: array[100] of Integer;
        DetailArray: array[100] of Integer;
        FooterArray: array[100] of Integer;
    begin
        CheckLedgerEntry2.CopyFilters(CheckLedgerEntry);
        CheckLedgerEntry2.FindFirst();

        BankAccount.Get(CheckLedgerEntry2."Bank Account No.");

        BankExportImportSetup.SetRange(Code, BankAccount."Positive Pay Export Code");
        if BankExportImportSetup.FindFirst() then begin
            DataExchDefCode := BankExportImportSetup."Data Exch. Def. Code";
            Filename := FileManagement.ServerTempFileName('txt');

            ProcessHeaders(BankAccount, DataExchDefCode, HeaderArray, Filename);
            ProcessDetails(CheckLedgerEntry2, DataExchDefCode, DataExchEntryCodeDetail, DetailArray, Filename);
            ProcessFooters(BankAccount, DataExchDefCode, FooterArray, Filename, DataExchEntryCodeDetail, DataExchEntryCodeFooter);

            ExpWritingPosPay.ExportPositivePay(DataExchEntryCodeDetail, DataExchEntryCodeFooter, Filename, FooterArray);

            // This should only be called from a test codeunit, calling CreateExportFile MUST pass in a FALSE parameter
            DataExchDef.Get(DataExchDefCode);
            if DataExchDef."Ext. Data Handling Codeunit" > 0 then begin
                DataExch.Get(DataExchEntryCodeDetail);
                if DataExchDef."Ext. Data Handling Codeunit" = CODEUNIT::"Exp. External Data Pos. Pay" then
                    ExpExternalDataPosPay.CreateExportFile(DataExch, ShowDialog)
                else
                    CODEUNIT.Run(DataExchDef."Ext. Data Handling Codeunit", DataExch);
            end;

            if DataExchDef."User Feedback Codeunit" > 0 then begin
                DataExch.Get(DataExchEntryCodeDetail);
                CODEUNIT.Run(DataExchDef."User Feedback Codeunit", DataExch);
            end;

            // Clean up the work tables.
            ExpWritingPosPay.CleanUpPositivePayWorkTables(HeaderArray, DetailArray, FooterArray);
        end;
    end;

    local procedure UpdateCheckLedger(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExchEntryCodeDetail: Integer)
    var
        CheckLedgerEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry2.CopyFilters(CheckLedgerEntry);
        CheckLedgerEntry2.SetFilter(
          "Entry Status",
          '%1|%2|>%3',
          CheckLedgerEntry2."Entry Status"::Printed,
          CheckLedgerEntry2."Entry Status"::Posted,
          CheckLedgerEntry2."Entry Status"::"Test Print");
        CheckLedgerEntry2.SetRange("Positive Pay Exported", false);
        CheckLedgerEntry2.ModifyAll("Data Exch. Entry No.", DataExchEntryCodeDetail, true);

        CheckLedgerEntry2.SetFilter(
          "Entry Status",
          '%1|%2|%3',
          CheckLedgerEntry2."Entry Status"::Voided,
          CheckLedgerEntry2."Entry Status"::"Financially Voided",
          CheckLedgerEntry2."Entry Status"::"Test Print");
        CheckLedgerEntry2.ModifyAll("Data Exch. Voided Entry No.", DataExchEntryCodeDetail, true);
    end;

    local procedure ProcessHeaders(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20]; var HeaderArray: array[100] of Integer; Filename: Text)
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        HdrCount: Integer;
    begin
        HdrCount := 0;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Header);
        if DataExchLineDef.FindSet() then
            repeat
                // Insert the Data Exchange Header records
                DataExch."Entry No." := 0;
                DataExch."Data Exch. Def Code" := DataExchDefCode;
                DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
                DataExch.Insert();
                Commit();

                HdrCount := HdrCount + 1;
                HeaderArray[HdrCount] := DataExch."Entry No.";

                // It is only here where we know the True DataExch."Entry No"..
                DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
                DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
                DataExchMapping.FindFirst();

                // Populate the Header/Detail/Footer work tables
                PositivePayExportMgt.PreparePosPayHeader(DataExch, BankAccount."Bank Account No.");
                if DataExchMapping."Pre-Mapping Codeunit" > 0 then
                    CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", DataExch);

                // Create the Entries and values in the Data Exch. Field table
                if DataExchMapping."Mapping Codeunit" > 0 then
                    CODEUNIT.Run(DataExchMapping."Mapping Codeunit", DataExch);

                DataExchDef.Get(DataExchDefCode);
                if DataExchDef."Reading/Writing Codeunit" = CODEUNIT::"Exp. Writing Pos. Pay" then
                    PositivePayExportMgt.ExportDataExchToFlatFile(DataExch."Entry No.", Filename, DataExchLineDef."Line Type", HdrCount);
            until DataExchLineDef.Next() = 0;
    end;

    local procedure ProcessDetails(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExchDefCode: Code[20]; var DataExchEntryCodeDetail: Integer; var DetailArray: array[100] of Integer; Filename: Text)
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        CurrentDataExchEntryCodeDetail: Integer;
        DetailCount: Integer;
    begin
        DetailCount := 0;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        if DataExchLineDef.FindSet() then begin
            repeat
                // Insert the Data Exchange Detail records
                DataExch."Entry No." := 0;
                DataExch."Data Exch. Def Code" := DataExchDefCode;
                DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
                DataExch.Insert();
                Commit();

                DetailCount := DetailCount + 1;
                DetailArray[DetailCount] := DataExch."Entry No.";

                // It is only here where we know the True DataExch."Entry No"..
                DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
                DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
                DataExchMapping.FindFirst();

                if DataExchEntryCodeDetail = 0 then
                    DataExchEntryCodeDetail := DataExch."Entry No.";
                CurrentDataExchEntryCodeDetail := DataExch."Entry No.";

                UpdateCheckLedger(CheckLedgerEntry, CurrentDataExchEntryCodeDetail);

                // Populate the Header/Detail/Footer work tables
                if DataExchMapping."Pre-Mapping Codeunit" > 0 then
                    CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", DataExch);

                // Create the Entries and values in the Data Exch. Field table
                if DataExchMapping."Mapping Codeunit" > 0 then
                    CODEUNIT.Run(DataExchMapping."Mapping Codeunit", DataExch);

                DataExchDef.Get(DataExchDefCode);
                if DataExchDef."Reading/Writing Codeunit" > 0 then
                    if DataExchDef."Reading/Writing Codeunit" = CODEUNIT::"Exp. Writing Pos. Pay" then
                        PositivePayExportMgt.ExportDataExchToFlatFile(DataExch."Entry No.", Filename, DataExchLineDef."Line Type", 0)
                    else
                        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

            until DataExchLineDef.Next() = 0;
            // When we are done, we need to set the Check Ledger record(s) Entry No back to the original.
            if DataExchEntryCodeDetail > 0 then
                UpdateCheckLedger(CheckLedgerEntry, DataExchEntryCodeDetail);
        end;
    end;

    local procedure ProcessFooters(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20]; var FooterArray: array[100] of Integer; Filename: Text; DataExchEntryCodeDetail: Integer; var DataExchEntryCodeFooter: Integer)
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        FooterCount: Integer;
    begin
        FooterCount := 0;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Footer);
        if DataExchLineDef.FindSet() then
            repeat
                // Insert the Data Exchange Footer records
                DataExch."Entry No." := 0;
                DataExch."Data Exch. Def Code" := DataExchDefCode;
                DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
                DataExch.Insert();
                Commit();

                FooterCount := FooterCount + 1;
                FooterArray[FooterCount] := DataExch."Entry No.";

                // It is only here where we know the True DataExch."Entry No"..
                DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
                DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
                DataExchMapping.FindFirst();

                // Populate the Header/Detail/Footer work tables
                if DataExchMapping."Pre-Mapping Codeunit" > 0 then
                    CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", DataExch);

                // Create the Entries and values in the Data Exch. Field table
                PositivePayExportMgt.PreparePosPayFooter(DataExch, DataExchEntryCodeDetail, BankAccount."Bank Account No.");
                if DataExchMapping."Mapping Codeunit" > 0 then
                    CODEUNIT.Run(DataExchMapping."Mapping Codeunit", DataExch);

                DataExchDef.Get(DataExchDefCode);
                if DataExchDef."Reading/Writing Codeunit" = CODEUNIT::"Exp. Writing Pos. Pay" then
                    PositivePayExportMgt.ExportDataExchToFlatFile(DataExch."Entry No.", Filename, DataExchLineDef."Line Type", 0);
                DataExchEntryCodeFooter := DataExch."Entry No.";
            until DataExchLineDef.Next() = 0;
    end;
}

