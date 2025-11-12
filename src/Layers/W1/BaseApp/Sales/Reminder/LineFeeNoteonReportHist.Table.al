// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Globalization;

table 1053 "Line Fee Note on Report Hist."
{
    Caption = 'Line Fee Note on Report Hist.';
    Permissions = TableData "Line Fee Note on Report Hist." = rimd,
                  tabledata "Reminder Terms" = R;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Cust. Ledger Entry No"; Integer)
        {
            Caption = 'Cust. Ledger Entry No';
            Editable = false;
            TableRelation = "Cust. Ledger Entry"."Entry No." where("Entry No." = field("Cust. Ledger Entry No"));
        }
        field(2; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Language;
        }
        field(4; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
        }
        field(5; "Reminder Level No"; Integer)
        {
            Caption = 'Reminder Level No';
        }
        field(6; ReportText; Text[200])
        {
            Caption = 'ReportText';
            Editable = false;
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Cust. Ledger Entry No", "Due Date", "Language Code", "Reminder Terms Code", "Reminder Level No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetLineFeeNoteOnReport(CustLedgerEntry: Record "Cust. Ledger Entry"; ReminderLevel: Record "Reminder Level"; LineFeeNoteOnReport: Text[150]; DueDate: Date): Text[200]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AdditionalFeePerLine: Decimal;
        CurrencyCode: Code[10];
        MarginalPerc: Decimal;
    begin
        CustLedgerEntry.CalcFields("Original Amount");
        AdditionalFeePerLine :=
          ReminderLevel.GetAdditionalFee(
            CustLedgerEntry."Original Amount", CustLedgerEntry."Currency Code", true, CustLedgerEntry."Posting Date");
        if AdditionalFeePerLine = 0 then
            exit;

        if CustLedgerEntry."Currency Code" = '' then begin
            GeneralLedgerSetup.Get();
            CurrencyCode := GeneralLedgerSetup."LCY Code";
        end else
            CurrencyCode := CustLedgerEntry."Currency Code";

        if CustLedgerEntry."Original Amount" > 0 then
            MarginalPerc := Round(AdditionalFeePerLine * 100 / CustLedgerEntry."Original Amount", 0.01);

        exit(StrSubstNo(LineFeeNoteOnReport, Format(Round(AdditionalFeePerLine, 0.01), 0, 9), CurrencyCode, DueDate, Format(MarginalPerc, 0, 9)));
    end;

    local procedure InsertRec(ReminderLevel: Record "Reminder Level"; CustLedgerEntryNo: Integer; DueDate: Date; LanguageCode: Code[10]; LineFeeNoteOnReport: Text[200])
    var
        LineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist.";
    begin
        if LineFeeNoteOnReport <> '' then begin
            LineFeeNoteOnReportHist.Init();
            LineFeeNoteOnReportHist."Cust. Ledger Entry No" := CustLedgerEntryNo;
            LineFeeNoteOnReportHist."Due Date" := DueDate;
            LineFeeNoteOnReportHist."Language Code" := LanguageCode;
            LineFeeNoteOnReportHist."Reminder Terms Code" := ReminderLevel."Reminder Terms Code";
            LineFeeNoteOnReportHist."Reminder Level No" := ReminderLevel."No.";
            LineFeeNoteOnReportHist.ReportText := LineFeeNoteOnReport;
            LineFeeNoteOnReportHist.Insert(true);
        end;
    end;

    local procedure InsertTransLineFeeNoteOnReport(CustLedgerEntry: Record "Cust. Ledger Entry"; ReminderTerms: Record "Reminder Terms"; ReminderLevel: Record "Reminder Level"; DueDate: Date)
    var
        ReminderTermsTranslation: Record "Reminder Terms Translation";
        Language: Codeunit Language;
        AddTextOnReport: Text[200];
        AddTextOnReportDefault: Text[200];
        DefaultLanguageCode: Code[10];
    begin
        // insert default language
        if ReminderTerms."Note About Line Fee on Report" <> '' then begin
            DefaultLanguageCode := Language.GetUserLanguageCode();
            if not ReminderTermsTranslation.Get(ReminderTerms.Code, DefaultLanguageCode) then begin
                AddTextOnReportDefault := GetLineFeeNoteOnReport(CustLedgerEntry, ReminderLevel,
                    ReminderTerms."Note About Line Fee on Report", DueDate);
                InsertRec(ReminderLevel, CustLedgerEntry."Entry No.", DueDate, Language.GetUserLanguageCode(), AddTextOnReportDefault);
            end;
        end;

        // insert Reminder Terms Translation records
        ReminderTermsTranslation.SetRange("Reminder Terms Code", ReminderLevel."Reminder Terms Code");
        if ReminderTermsTranslation.FindSet() then
            repeat
                AddTextOnReport :=
                  GetLineFeeNoteOnReport(CustLedgerEntry, ReminderLevel, ReminderTermsTranslation."Note About Line Fee on Report", DueDate);
                InsertRec(ReminderLevel,
                  CustLedgerEntry."Entry No.",
                  DueDate,
                  ReminderTermsTranslation."Language Code",
                  AddTextOnReport);

            until ReminderTermsTranslation.Next() = 0;
    end;

    procedure Save(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        DueDate: Date;
    begin
        if not Customer.Get(CustLedgerEntry."Customer No.") then
            exit;

        if Customer."Reminder Terms Code" = '' then
            exit;

        ReminderTerms.Get(Customer."Reminder Terms Code");
        if not ReminderTerms."Post Add. Fee per Line" then
            exit;

        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        if ReminderLevel.FindSet() then begin
            DueDate := CalcDate(ReminderLevel."Grace Period", CustLedgerEntry."Due Date");
            InsertTransLineFeeNoteOnReport(CustLedgerEntry, ReminderTerms, ReminderLevel, DueDate);
            while ReminderLevel.Next() <> 0 do begin
                DueDate := CalcDate(ReminderLevel."Grace Period", DueDate);
                InsertTransLineFeeNoteOnReport(CustLedgerEntry, ReminderTerms, ReminderLevel, DueDate);
            end;
        end;
    end;
}

