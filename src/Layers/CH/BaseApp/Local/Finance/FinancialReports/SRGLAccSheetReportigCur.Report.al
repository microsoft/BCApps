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

report 11565 "SR G/L Acc Sheet Reportig Cur"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/FinancialReports/SRGLAccSheetReportigCur.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Account Sheet with with Reporting Currency';
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
            column(GlJourDateFilter; Text001 + GlJourDateFilter)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(LayoutReportingCurr; Text002)
            {
            }
            column(NewPagePerAccNo; NewPagePerAccNo)
            {
            }
            column(Name_GLAcc; Name)
            {
            }
            column(CurrencyCode_GLAcc; "Source Currency Code")
            {
            }
            column(No_GLAcc; "G/L Account"."No.")
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
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(GLAccSheetCaption; GLAccSheetCaptionLbl)
            {
            }
            column(BalACYCaption; BalACYCaptionLbl)
            {
            }
            column(AmountACYCaption; AmountACYCaptionLbl)
            {
            }
            column(ExrateCaption; ExrateCaptionLbl)
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
            column(DateFilter_GLAcc; "Date Filter")
            {
            }
            column(GlobalDim1Filter_GLAcc; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_GLAcc; "Global Dimension 2 Filter")
            {
            }
            column(BusinessUnitFilter_GLAcc; "Business Unit Filter")
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                DataItemTableView = sorting("G/L Account No.", "Posting Date");
                column(DebitAmt_GLEntry; "Debit Amount")
                {
                }
                column(CreditAmt_GLEntry; "Credit Amount")
                {
                }
                column(GlBalanceAmount; GlBalance - Amount)
                {
                    AutoFormatType = 1;
                }
                column(FcyAcyBalanceFcyAcyAmt; FcyAcyBalance - FcyAcyAmt)
                {
                    AutoFormatExpression = "G/L Account"."Source Currency Code";
                    AutoFormatType = 1;
                }
                column(PostingDate_GLEntry; Format("Posting Date"))
                {
                }
                column(DocNo_GLEntry; "Document No.")
                {
                }
                column(Desc_GLEntry; Description)
                {
                }
                column(GLEntryGlBalance; GlBalance)
                {
                    AutoFormatType = 1;
                }
                column(FcyAcyAmt; FcyAcyAmt)
                {
                    AutoFormatExpression = "G/L Account"."Source Currency Code";
                    AutoFormatType = 1;
                }
                column(Exrate; Exrate)
                {
                    DecimalPlaces = 2 : 3;
                }
                column(GLEntryFcyAcyBalance; FcyAcyBalance)
                {
                    AutoFormatExpression = "G/L Account"."Source Currency Code";
                    AutoFormatType = 1;
                }
                column(BalAccNo_GLEntry; "Bal. Account No.")
                {
                }
                column(BalAccType; BalAccType)
                {
                }
                column(TransferCaption; TransferCaptionLbl)
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }
                column(GLAccNo_GLEntry; "G/L Account No.")
                {
                }
                column(GlobalDim1Code_GLEntry; "Global Dimension 1 Code")
                {
                }
                column(GlobalDim2Code_GLEntry; "Global Dimension 2 Code")
                {
                }
                column(BusinessUnitCode_GLEntry; "Business Unit Code")
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

                    FcyAcyAmt := "Additional-Currency Amount";
                    FcyAcyBalance := FcyAcyBalance + "Additional-Currency Amount";

                    Exrate := CalcExrate("Additional-Currency Amount", Amount, GLSetup."Additional Reporting Currency");
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
                column(GlAccTotalGlBalance; GlBalance)
                {
                    AutoFormatType = 1;
                }
                column(GLEntryCreditAmt; "G/L Entry"."Credit Amount")
                {
                }
                column(GLEntryDebitAmt; "G/L Entry"."Debit Amount")
                {
                }
                column(GlAccTotalFcyAcyBalance; FcyAcyBalance)
                {
                    AutoFormatExpression = "G/L Account"."Source Currency Code";
                    AutoFormatType = 1;
                }
                column(GlAccTotalExrate; Exrate)
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
                column(GlBalance_GenJnlLine; GlBalance)
                {
                    AutoFormatType = 1;
                }
                column(ProvCredit_GenJnlLine; ProvCredit)
                {
                }
                column(ProvDebit_GenJnlLine; ProvDebit)
                {
                }
                column(Desc_GenJnlLine; Description)
                {
                }
                column(DocNo_GenJnlLine; "Document No.")
                {
                }
                column(PostingDate_GenJnlLine; Format("Posting Date"))
                {
                }
                column(GenJnlLineFcyAcyBalance; FcyAcyBalance)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(GenJnlLineFcyAcyAmt; FcyAcyAmt)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(GenJnlLineExrate; Exrate)
                {
                    DecimalPlaces = 2 : 3;
                }
                column(BalAccNo_GenJnlLine; "Bal. Account No.")
                {
                }
                column(GenJnlLineBalAccType; BalAccType)
                {
                }
                column(GLEntryCrAmtProvCredit; "G/L Entry"."Credit Amount" + ProvCredit)
                {
                }
                column(GLEntryDtAmtProvDebit; "G/L Entry"."Debit Amount" + ProvDebit)
                {
                }
                column(TempPostingsCaption; TempPostingsCaptionLbl)
                {
                }
                column(ProvisionalEndBalanceCaption; ProvisionalEndBalanceCaptionLbl)
                {
                }
                column(JnlTempName_GenJnlLine; "Journal Template Name")
                {
                }
                column(JnlBatchName_GenJnlLine; "Journal Batch Name")
                {
                }
                column(LineNo_GenJnlLine; "Line No.")
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

                    FcyAcyAmt := 0;
                    FcyAcyBalance := 0;
                    Exrate := 0;
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
                    FcyAcyBalance := "Additional-Currency Net Change";

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
        Text002: Label 'Layout Reporting Currency';
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
        PageNoCaptionLbl: Label 'Page';
        GLAccSheetCaptionLbl: Label 'G/L Account Sheet';
        BalACYCaptionLbl: Label 'Bal. ACY';
        AmountACYCaptionLbl: Label 'Amount ACY';
        ExrateCaptionLbl: Label 'Exrate';
        BalanceCaptionLbl: Label 'Balance';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        BalAccCaptionLbl: Label 'Bal. Acc.';
        TextCaptionLbl: Label 'Text';
        DocNoCaptionLbl: Label 'Doc. No.';
        PostDateCaptionLbl: Label 'Post Date';
        TransferCaptionLbl: Label 'Transfer';
        EndBalanceCaptionLbl: Label 'End Balance';
        TempPostingsCaptionLbl: Label 'Temporary Postings';
        ProvisionalEndBalanceCaptionLbl: Label 'Provisional End Balance';

    [Scope('OnPrem')]
    procedure CalcExrate(FcyAmt: Decimal; LcyAmt: Decimal; CurrencyCode: Code[10]): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if FcyAmt <> 0 then begin
            CurrExchRate.SetRange("Currency Code", CurrencyCode);
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
