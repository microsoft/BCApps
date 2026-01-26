// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

report 11566 "SR G/L Acc Sheet Posting Info"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/FinancialReports/SRGLAccSheetPostingInfo.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Account Sheet with Posting Info';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = where("Account Type" = const(Posting));
            RequestFilterFields = "No.", "Income/Balance", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodGlJourDateFilter; Text001 + GlJourDateFilter)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(LayoutPostingInfo; Text002)
            {
            }
            column(NewPagePerAccNo; NewPagePerAccNo)
            {
            }
            column(Name_GLAccount; "G/L Account".Name)
            {
            }
            column(CurrencyCode_GLAccount; "G/L Account"."Source Currency Code")
            {
            }
            column(No_GLAccount; "G/L Account"."No.")
            {
            }
            column(StartBalanceTxt; StartBalanceTxt)
            {
            }
            column(FcyAcyBalance; FcyAcyBalance)
            {
                AutoFormatExpression = "G/L Account"."Source Currency Code";
                AutoFormatType = 1;
            }
            column(GlBalance; GlBalance)
            {
                AutoFormatType = 1;
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(GLAccountSheetCaption; GLAccountSheetCaptionLbl)
            {
            }
            column(GLEntryEntryNoCaption; "G/L Entry".FieldCaption("Entry No."))
            {
            }
            column(CCCaption; CCCaptionLbl)
            {
            }
            column(COCaption; COCaptionLbl)
            {
            }
            column(IDCaption; IDCaptionLbl)
            {
            }
            column(ScCaption; ScCaptionLbl)
            {
            }
            column(SCaption; SCaptionLbl)
            {
            }
            column(CCaption; CCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(BalAccCaption; BalAccCaptionLbl)
            {
            }
            column(TextCaption; TextCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(PostDateCaption; PostDateCaptionLbl)
            {
            }
            column(GlobalDimension1Filter_GLAccount; "Global Dimension 1 Filter")
            {
            }
            column(BusinessUnitFilter_GLAccount; "Business Unit Filter")
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                DataItemTableView = sorting("G/L Account No.", "Posting Date");
                column(DebitAmount_GLEntry; "Debit Amount")
                {
                }
                column(CreditAmount_GLEntry; "Credit Amount")
                {
                }
                column(CurrencyCode_GLEntry; "G/L Account"."Source Currency Code")
                {
                }
                column(GlBalanceExclAmount; GlBalance - Amount)
                {
                    AutoFormatType = 1;
                }
                column(FcyAcyBalanceExclFcyAcyAmt; FcyAcyBalance - FcyAcyAmt)
                {
                    AutoFormatExpression = "G/L Account"."Source Currency Code";
                    AutoFormatType = 1;
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }
                column(GlobalDimension1Code_GLEntry; "Global Dimension 1 Code")
                {
                }
                column(GlobalDimension2Code_GLEntry; "Global Dimension 2 Code")
                {
                }
                column(UserID_GLEntry; "User ID")
                {
                }
                column(SourceCode_GLEntry; "Source Code")
                {
                }
                column(SystemExclCreatedEntry; "System-Created Entry")
                {
                }
                column(PriorExclYearEntry; "Prior-Year Entry")
                {
                }
                column(BalAccountNo_GLEntry; "Bal. Account No.")
                {
                }
                column(BalAccType; BalAccType)
                {
                }
                column(Description_GLEntry; Description)
                {
                }
                column(DocumentNo_GLEntry; "Document No.")
                {
                }
                column(PostingDateFormatted; Format("Posting Date"))
                {
                }
                column(GlBalanceGLEntry; GlBalance)
                {
                    AutoFormatType = 1;
                }
                column(TransferCaption; TransferCaptionLbl)
                {
                }
                column(PostingDate_GLEntry; "Posting Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Posting Date" = ClosingDate("Posting Date")) and WithoutClosingEntries then
                        CurrReport.Skip();

                    GlBalance := GlBalance + Amount;
                    Entryno := Entryno + 1;

                    if "Bal. Account No." <> '' then
                        BalAccType := CopyStr(Format("Bal. Account Type"), 1, 1)
                    else
                        BalAccType := '';
                end;

                trigger OnPreDataItem()
                begin
                    Entryno := 0;
                end;
            }
            dataitem(GlAccTotal; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(GlBalanceGlAccTotal; GlBalance)
                {
                    AutoFormatType = 1;
                }
                column(GLEntryDebitAmount; "G/L Entry"."Debit Amount")
                {
                }
                column(FcyAcyBalanceGlAccTotal; FcyAcyBalance)
                {
                    AutoFormatExpression = "G/L Account"."Source Currency Code";
                    AutoFormatType = 1;
                }
                column(Exrate; Exrate)
                {
                    DecimalPlaces = 2 : 3;
                }
                column(EndBalanceCaption; EndBalanceCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Exrate := CalcExrate(FcyAcyBalance, GlBalance, "G/L Account"."Source Currency Code");
                end;
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                column(GlBalance_GenJournalLine; GlBalance)
                {
                    AutoFormatType = 1;
                }
                column(ProvCredit; ProvCredit)
                {
                }
                column(ProvDebit; ProvDebit)
                {
                }
                column(JournalBatchName_GenJournalLine; "Journal Batch Name")
                {
                }
                column(Description_GenJournalLine; Description)
                {
                }
                column(DocumentNo_GenJournalLine; "Document No.")
                {
                }
                column(PostingDateFormatted_GenJournalLine; Format("Posting Date"))
                {
                }
                column(ShortcutDimension2Code_GenJournalLine; "Shortcut Dimension 2 Code")
                {
                }
                column(ShortcutDimension1Code_GenJournalLine; "Shortcut Dimension 1 Code")
                {
                }
                column(SumofGLEntryCreditAmountProvCredit; "G/L Entry"."Credit Amount" + ProvCredit)
                {
                }
                column(SumofGLEntryDebitAmountProvDebit; "G/L Entry"."Debit Amount" + ProvDebit)
                {
                }
                column(FcyAcyBalance_GenJournalLine; FcyAcyBalance)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(TemporaryPostingsCaption; TemporaryPostingsCaptionLbl)
                {
                }
                column(ProvisionalEndBalanceCaption; ProvisionalEndBalanceCaptionLbl)
                {
                }
                column(LineNo_GenJournalLine; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ProvEntry := false;
                    ProvDebit := 0;
                    ProvCredit := 0;

                    if ("Account Type" = "Account Type"::"G/L Account") and ("Account No." = "G/L Account"."No.") then begin
                        ProvEntry := true;
                        GlBalance := GlBalance + "Amount (LCY)" - "VAT Amount (LCY)";

                        if "Amount (LCY)" < 0 then
                            ProvCredit := -("Amount (LCY)" - "VAT Amount (LCY)")
                        else
                            ProvDebit := "Amount (LCY)" - "VAT Amount (LCY)";
                    end;

                    if ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") and ("Bal. Account No." = "G/L Account"."No.") then begin
                        ProvEntry := true;

                        GlBalance := GlBalance - "Amount (LCY)" - "Bal. VAT Amount (LCY)";

                        if "Amount (LCY)" < 0 then
                            ProvDebit := -("Amount (LCY)" + "Bal. VAT Amount (LCY)")
                        else
                            ProvCredit := "Amount (LCY)" + "Bal. VAT Amount (LCY)";

                        "Bal. Account No." := "Account No.";

                        Amount := -Amount;
                        "Amount (LCY)" := -"Amount (LCY)";
                    end;

                    if Correction then begin
                        TempProvDebit := ProvDebit;
                        ProvDebit := -ProvCredit;
                        ProvCredit := -TempProvDebit;
                    end;

                    if not ProvEntry then
                        CurrReport.Skip();

                    Entryno := Entryno + 1;

                    if ("Posting Date" = ClosingDate("Posting Date")) and WithoutClosingEntries then
                        CurrReport.Skip();

                    if "Bal. Account No." <> '' then
                        BalAccType := CopyStr(Format("Bal. Account Type"), 1, 1)
                    else
                        BalAccType := '';
                end;

                trigger OnPreDataItem()
                begin
                    if not ProvEntryExist then
                        CurrReport.Break();

                    // Filter set in function SetGenJourLineFilter()
                    CopyFilters(GenJourLine2);
                end;
            }

            trigger OnAfterGetRecord()
            var
                GLAccountSourceCurrency: Record "G/L Account Source Currency";
            begin
                if NewPagePerAcc then
                    NewPagePerAccNo := NewPagePerAccNo + 1;
                GlBalance := 0;
                FcyAcyBalance := 0;

                if StartDate > 0D then begin
                    SetRange("Date Filter", 0D, ClosingDate(StartDate - 1));
                    CalcFields("Net Change", "Additional-Currency Net Change");
                    GlBalance := "Net Change";
                    SetFilter("Date Filter", GlJourDateFilter);
                end;

                GlEntry2.SetCurrentKey("G/L Account No.", "Posting Date");
                GlEntry2.SetRange("G/L Account No.", "No.");
                CopyFilter("Global Dimension 1 Filter", GlEntry2."Global Dimension 1 Code");
                CopyFilter("Global Dimension 2 Filter", GlEntry2."Global Dimension 2 Code");

                if GlJourDateFilter <> '' then
                    GlEntry2.SetFilter("Posting Date", GlJourDateFilter);
                CalcFields("Balance at Date");
                GLAccountSourceCurrency."G/L Account No." := "No.";
                GLAccountSourceCurrency."Currency Code" := "Gen. Journal Line"."Currency Code";
                GLAccountSourceCurrency.SetFilter("Date Filter", GlJourDateFilter);
                GLAccountSourceCurrency.CalcFields("Source Curr. Balance at Date");
                CheckProvEntry();

                if ("Balance at Date" = 0) and
                   (GLAccountSourceCurrency."Source Curr. Balance at Date" = 0) and
                   (not GlEntry2.FindFirst()) and
                   (not ProvEntryExist) and
                   (not ShowAllAccounts)
                then
                    CurrReport.Skip();

                if not (NotFirstPage and NewPagePerAcc) then
                    NotFirstPage := true;
            end;

            trigger OnPreDataItem()
            begin
                NewPagePerAccNo := 1;
                if GlJourDateFilter <> '' then
                    if GetRangeMin("Date Filter") <> 0D then begin
                        StartDate := GetRangeMin("Date Filter");
                        StartBalanceTxt := Text000 + Format(StartDate);
                    end;

                SetGenJourLineFilter();
                Clear(GlBalance);
                Clear(FcyAcyBalance);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPagePerAcc; NewPagePerAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Account';
                        ToolTip = 'Specifies if you want to print a new page for each account.';
                    }
                    field(ShowAllAccounts; ShowAllAccounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Accounts w/o Balance or Net Change';
                        ToolTip = 'Specifies if you want to print the accounts without a balance on the report.';
                    }
                    field(WithoutClosingEntries; WithoutClosingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without Closing Entries';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print the report without closing entries.';
                    }
                    field(JourName1; JourName1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Journal 1';
                        Lookup = true;
                        ToolTip = 'Specifies the first general journal batch that you want to include in the report.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GlJourName) = ACTION::LookupOK then
                                JourName1 := GlJourName.Name;
                        end;
                    }
                    field(JourName2; JourName2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Journal 2';
                        Lookup = true;
                        ToolTip = 'Specifies the second general journal batch that you want to include in the report.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GlJourName) = ACTION::LookupOK then
                                JourName2 := GlJourName.Name;
                        end;
                    }
                    field(JourName3; JourName3)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Journal 3';
                        Lookup = true;
                        ToolTip = 'Specifies the third general journal batch that you want to include in the report.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GlJourName) = ACTION::LookupOK then
                                JourName3 := GlJourName.Name;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GenJourTemplate.SetRange(Type, GenJourTemplate.Type::General);
            GenJourTemplate.SetRange(Recurring, false);
            if GenJourTemplate.FindFirst() then;
            GlJourName.FilterGroup(2);
            GlJourName.SetRange("Journal Template Name", GenJourTemplate.Name);
            GlJourName.FilterGroup(0);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GlJourDateFilter := "G/L Account".GetFilter("Date Filter");

        GLSetup.Get();
    end;

    var
        GlEntry2: Record "G/L Entry";
        GenJourTemplate: Record "Gen. Journal Template";
        GLSetup: Record "General Ledger Setup";
        GenJourLine2: Record "Gen. Journal Line";
        GlJourName: Record "Gen. Journal Batch";
        Text000: Label 'Start Balance on ';
        Text001: Label 'Period: ';
        Text002: Label 'Layout Posting Info';
        GlJourDateFilter: Text[30];
        NotFirstPage: Boolean;
        StartBalanceTxt: Text[80];
        StartDate: Date;
        NewPagePerAcc: Boolean;
        WithoutClosingEntries: Boolean;
        BalAccType: Text[1];
        Entryno: Integer;
        GlBalance: Decimal;
        FcyAcyAmt: Decimal;
        FcyAcyBalance: Decimal;
        Exrate: Decimal;
        ProvDebit: Decimal;
        ProvCredit: Decimal;
        TempProvDebit: Decimal;
        JourName1: Code[10];
        JourName2: Code[10];
        JourName3: Code[10];
        ProvEntry: Boolean;
        ProvEntryExist: Boolean;
        ShowAllAccounts: Boolean;
        NewPagePerAccNo: Integer;
        PageCaptionLbl: Label 'Page';
        GLAccountSheetCaptionLbl: Label 'G/L Account Sheet';
        CCCaptionLbl: Label 'CC';
        COCaptionLbl: Label 'CO';
        IDCaptionLbl: Label 'ID';
        ScCaptionLbl: Label 'Sc';
        SCaptionLbl: Label 'S';
        CCaptionLbl: Label 'C';
        BalanceCaptionLbl: Label 'Balance';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        BalAccCaptionLbl: Label 'Bal. Acc.';
        TextCaptionLbl: Label 'Text';
        DocNoCaptionLbl: Label 'Doc. No.';
        PostDateCaptionLbl: Label 'Post Date';
        TransferCaptionLbl: Label 'Transfer';
        EndBalanceCaptionLbl: Label 'End Balance';
        TemporaryPostingsCaptionLbl: Label 'Temporary Postings';
        ProvisionalEndBalanceCaptionLbl: Label 'Provisional End Balance';

    [Scope('OnPrem')]
    procedure CalcExrate(FcyAmt: Decimal; LcyAmt: Decimal; Curr: Code[10]): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if FcyAmt <> 0 then begin
            CurrExchRate.SetRange("Currency Code", Curr);
            if CurrExchRate.FindLast() then
                exit(Round(LcyAmt * CurrExchRate."Exchange Rate Amount" / FcyAmt, 0.001))
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure SetGenJourLineFilter()
    begin
        GenJourLine2.SetCurrentKey(
          "Journal Template Name", "Journal Batch Name", "Posting Date", Clearing, "Debit Bank", "Account No.", "Currency Code");
        GenJourLine2.SetRange("Journal Template Name", GenJourTemplate.Name);
        GenJourLine2.SetFilter("Journal Batch Name", '%1|%2|%3', JourName1, JourName2, JourName3);

        if "G/L Account".GetFilter("Date Filter") <> '' then
            if "G/L Account".GetRangeMax("Date Filter") <> 0D then
                GenJourLine2.SetRange("Posting Date", 0D, "G/L Account".GetRangeMax("Date Filter"));

        "G/L Account".CopyFilter("Global Dimension 1 Filter", GenJourLine2."Shortcut Dimension 1 Code");
        "G/L Account".CopyFilter("Global Dimension 2 Filter", GenJourLine2."Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure CheckProvEntry()
    begin
        ProvEntryExist := false;
        GenJourLine2.SetRange("Account No.", "G/L Account"."No.");
        GenJourLine2.SetRange("Account Type", "G/L Account"."Account Type");
        if GenJourLine2.FindFirst() then
            ProvEntryExist := true;
        GenJourLine2.SetRange("Account No.");
        GenJourLine2.SetRange("Account Type");
        if ProvEntryExist then
            exit;

        GenJourLine2.SetRange("Bal. Account No.", "G/L Account"."No.");
        GenJourLine2.SetRange("Bal. Account Type", "G/L Account"."Account Type");
        if GenJourLine2.FindFirst() then
            ProvEntryExist := true;

        GenJourLine2.SetRange("Bal. Account No.");
        GenJourLine2.SetRange("Bal. Account Type");
    end;
}
