// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Utilities;

/// <summary>
/// Report that summarizes G/L deferral activity by account and period.
/// Provides detailed analysis of deferred amounts and recognition patterns for G/L transactions.
/// </summary>
report 1700 "Deferral Summary - G/L"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Deferral Summary - G/L';
#if not CLEAN27
    DefaultRenderingLayout = Word;
#else
    DefaultRenderingLayout = Excel;
#endif
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(GLAccount; "G/L Account")
        {
            RequestFilterFields = "No.";
            // RDLC only
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            // RDLC only
            column(PostedDeferralTableCaption; TableCaption + ': ' + PostedDeferralFilter)
            {
            }
            // RDLC only
            column(PostedDeferralFilter; PostedDeferralFilter)
            {
            }
            // RDLC only
            column(EmptyString; '')
            {
            }
            // RDLC only
            column(DeferralSummaryGLCaption; DeferralSummaryGLCaptionLbl)
            {
            }
            // RDLC only
            column(PageCaption; PageCaptionLbl)
            {
            }
            // RDLC only
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            // RDLC only
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            // RDLC only
            column(GLBalCaption; GLBalCaptionLbl)
            {
            }
            // RDLC only
            column(RemAmtDefCaption; RemAmtDefCaptionLbl)
            {
            }
            // RDLC only
            column(TotAmtDefCaption; TotAmtDefCaptionLbl)
            {
            }
            // RDLC only
            column(BalanceAsOfDateCaption; BalanceAsOfDateCaptionLbl + Format(BalanceAsOfDateFilter))
            {
            }
            column(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
            {
            }
            // RDLC only
            column(AccountNoCaption; AccountNoLbl)
            {
            }
            // RDLC only
            column(AmtRecognizedCaption; AmtRecognizedLbl)
            {
            }
            dataitem("Posted Deferral Header"; "Posted Deferral Header")
            {
                DataItemLink = "Account No." = field("No.");
                DataItemLinkReference = GLAccount;
                DataItemTableView = sorting("Deferral Doc. Type", "Account No.", "Posting Date", "Gen. Jnl. Document No.", "Document Type", "Document No.", "Line No.") order(ascending) where("Deferral Doc. Type" = const("G/L"));

                column(No_GLAcc; "Account No.")
                {
                    IncludeCaption = true;
                }
                column(AccountName; AccountName)
                {
                }
                column(NumOfPeriods; "No. of Periods")
                {
                    IncludeCaption = true;
                }
                column(DocumentType; "Document Type")
                {
                }
                column(GLDocTypeString; GLDocTypeString)
                {
                }
                column(DeferralStartDate; Format("Start Date"))
                {
                }
                column(AmtRecognized; AmtRecognized)
                {
                }
                column(RemainingAmtDeferred; RemainingAmtDeferred)
                {
                }
                column(TotalAmtDeferred; "Amount to Defer (LCY)")
                {
                }
                column(PostingDate; Format(PostingDate))
                {
                }
                column(DeferralAccount; DeferralAccount)
                {
                }
                column(Amount; "Amount to Defer (LCY)")
                {
                }
                column(GenJnlDocNo; "Gen. Jnl. Document No.")
                {
                }
                column(GLDocType; GLDocType)
                {
                }

                trigger OnAfterGetRecord()
                var
                    GLEntry: Record "G/L Entry";
                    LinesFound: Boolean;
                begin
                    PreviousAccount := WorkingAccount;
                    if GLAccount.Get("Account No.") then begin
                        AccountName := GLAccount.Name;
                        WorkingAccount := GLAccount."No.";
                    end;

                    AmtRecognized := 0;
                    RemainingAmtDeferred := 0;

                    PostedDeferralLine.SetRange("Deferral Doc. Type", "Deferral Doc. Type");
                    PostedDeferralLine.SetRange("Gen. Jnl. Document No.", "Gen. Jnl. Document No.");
                    PostedDeferralLine.SetRange("Account No.", "Account No.");
                    PostedDeferralLine.SetRange("Document Type", "Document Type");
                    PostedDeferralLine.SetRange("Document No.", "Document No.");
                    PostedDeferralLine.SetRange("Line No.", "Line No.");
                    if PostedDeferralLine.Find('-') then begin
                        repeat
                            DeferralAccount := PostedDeferralLine."Deferral Account";
                            if PostedDeferralLine."Posting Date" <= BalanceAsOfDateFilter then
                                AmtRecognized := AmtRecognized + PostedDeferralLine."Amount (LCY)"
                            else
                                RemainingAmtDeferred := RemainingAmtDeferred + PostedDeferralLine."Amount (LCY)";
                        until (PostedDeferralLine.Next() = 0);

                        LinesFound := true;
                    end;

                    if HideZeroRemainingAmounts and (RemainingAmtDeferred = 0) and
                        (LinesFound and (not "Posted Deferral Header".DeferralEndsInAccountingPeriod(BalanceAsOfDateFilter, PeriodStartDate, PeriodEndDate))) then
                        CurrReport.Skip();

                    LineCount += 1;

                    if GLEntry.Get("Entry No.") then begin
                        GLDocType := GLEntry."Document Type";
                        GLDocTypeString := Format(GLEntry."Document Type");
                        PostingDate := GLEntry."Posting Date";
                    end;

                    if (PreviousAccount <> WorkingAccount) then begin
                        if PrintOnlyOnePerPage then begin
                            PostedDeferralHeaderPage.Reset();
                            PostedDeferralHeaderPage.SetRange("Account No.", "Account No.");
                            if PostedDeferralHeaderPage.FindFirst() then
                                PageGroupNo := PageGroupNo + 1;
                        end;

                        SumAmtRecognized := 0;
                        SumRemainingAmtDeferred := 0;
                        SumTotalAmtDeferred := 0;
                    end;

                    SumAmtRecognized += AmtRecognized;
                    SumRemainingAmtDeferred += RemainingAmtDeferred;
                    SumTotalAmtDeferred += "Amount to Defer (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    PageGroupNo := 1;
                end;
            }
            dataitem(Totals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(SumAmtRecognized; SumAmtRecognized)
                {
                }
                column(SumRemainingAmtDeferred; SumRemainingAmtDeferred)
                {
                }
                column(SumTotalAmtDeferred; SumTotalAmtDeferred)
                {
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Deferral Summary - G/L';
        AboutText = 'Review how deferrals affect G/L across time periods. Use this report to analyze how deferral entries impact the general ledger over time and to reconcile deferred balances.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPageperGLAcc; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per G/L Acc.';
                        ToolTip = 'Specifies if each G/L account information is printed on a new page if you have chosen two or more G/L accounts to be included in the report.';
                    }
                    field(BalAsOfDateFilter; BalanceAsOfDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance as of:';
                        ToolTip = 'Specifies the end date that the balance is calculated on.';
                    }
                    field(HideZeroRemainingAmounts; HideZeroRemainingAmounts)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Hide Zero Remaining Amounts';
                        ToolTip = 'Specifies whether to hide Posted Deferral Headers where the Remaining Amount is zero, unless it reaches zero in the current Accounting Period, based on the Balance as of date. This requires Accounting Periods to be configured.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if BalanceAsOfDateFilter = 0D then
                BalanceAsOfDateFilter := WorkDate();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Deferral Summary G/L Excel';
            Type = Excel;
            LayoutFile = './Finance/Deferral/DeferralSummaryGL.xlsx';
        }
        layout(Word)
        {
            Caption = 'Deferral Summary G/L Word';
            Type = Word;
            LayoutFile = './Finance/Deferral/DeferralSummaryGL.docx';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Deferral Summary G/L RDLC';
            Type = RDLC;
            LayoutFile = './Finance/Deferral/DeferralSummaryGL.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DeferralSummaryGLLabel = 'Deferral Summary G/L';
        DeferralSummaryGLPrint = 'Deferral Summary G/L (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DeferralSummaryGLAnalysis = 'Deferral Summary G/L (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        BalAsOfDateCaption = 'Balance as of:';
        DataRetrieved = 'Data retrieved:';
        PostingDateCaption = 'Posting Date';
        DocNoCaption = 'Document No.';
        DescCaption = 'Description';
        EntryNoCaption = 'Entry No.';
        NoOfPeriodsCaption = 'No. of Periods';
        DeferralAccountCaption = 'Deferral Account';
        DocTypeCaption = 'Document Type';
        DefStartDateCaption = 'Deferral Start Date';
        AcctNameCaption = 'Account Name';
        AmountRecognizedCaption = 'Amt. Recognized';
        RemAmountDefCaption = 'Remaining Amt. Deferred';
        TotalAmountDefCaption = 'Total Amt. Deferred';
        // About the report labels
        AboutTheReportLabel = 'About the report';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        PostedDeferralFilter := "Posted Deferral Header".GetFilters();
        if HideZeroRemainingAmounts then
            "Posted Deferral Header".CalculatePeriodFilter(BalanceAsOfDateFilter, PeriodStartDate, PeriodEndDate);
    end;

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        PlatformEmptyErr: Label 'The report couldn''t be generated, because it was empty. Adjust your filters and try again.';
    begin
        if LineCount = 0 then
            Error(PlatformEmptyErr);
    end;

    var
        PostedDeferralHeaderPage: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        GLDocType: Enum "Gen. Journal Document Type";
        PostedDeferralFilter: Text;
        PrintOnlyOnePerPage: Boolean;
        PageGroupNo: Integer;
        BalanceAsOfDateFilter: Date;
        PostingDate: Date;
        AmtRecognized: Decimal;
        RemainingAmtDeferred: Decimal;
        AccountName: Text[100];
        WorkingAccount: Code[20];
        PreviousAccount: Code[20];
        DeferralAccount: Code[20];
        GLDocTypeString: Text;
        SumAmtRecognized: Decimal;
        SumRemainingAmtDeferred: Decimal;
        SumTotalAmtDeferred: Decimal;
        HideZeroRemainingAmounts: Boolean;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        LineCount: Integer;
        // RDLC Only layout field captions. To be removed in a future release along with the RDLC layout.
        PageCaptionLbl: Label 'Page';
        BalanceCaptionLbl: Label 'This also includes general ledger accounts that only have a balance.';
        PeriodCaptionLbl: Label 'This report also includes closing entries within the period.';
        GLBalCaptionLbl: Label 'Balance';
        DeferralSummaryGLCaptionLbl: Label 'Deferral Summary - GL';
        RemAmtDefCaptionLbl: Label 'Remaining Amt. Deferred';
        TotAmtDefCaptionLbl: Label 'Total Amt. Deferred';
        BalanceAsOfDateCaptionLbl: Label 'Balance as of: ';
        AccountNoLbl: Label 'Account No.';
        AmtRecognizedLbl: Label 'Amt. Recognized';

    /// <summary>
    /// Initializes report parameters for the GL deferral summary report.
    /// </summary>
    /// <param name="NewPrintOnlyOnePerPage">Whether to print each account on a separate page</param>
    /// <param name="NewBalanceAsOfDateFilter">Balance as of date filter for calculations</param>
    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewBalanceAsOfDateFilter: Date)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        BalanceAsOfDateFilter := NewBalanceAsOfDateFilter;
    end;
}