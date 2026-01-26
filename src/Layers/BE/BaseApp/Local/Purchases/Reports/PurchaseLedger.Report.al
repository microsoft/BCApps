// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11301 "Purchase Ledger"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/PurchaseLedger.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Purchase Ledger';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Gen. Journal Template"; "Gen. Journal Template")
        {
            DataItemTableView = sorting(Name) where(Type = const(Purchases));
            RequestFilterFields = Name;
            column(Name_GenJournalTemplate; Name)
            {
            }
            dataitem(PeriodLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PrintHeader; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLinkReference = PeriodLoop;
                    DataItemTableView = sorting("Journal Templ. Name", "Document No.", "VAT Reporting Date");
                    column(ReportFilter; ReportFilter)
                    {
                    }
                    column(TodayFormatted; Format(Today, 0, 4))
                    {
                    }
                    column(CompanyName; COMPANYPROPERTY.DisplayName())
                    {
                    }
                    column(GenJournalTemplateName; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                    }
                    column(Startpage; Startpage)
                    {
                    }
                    column(CreditAmount_GLEntry; "Credit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(DebitAmount_GLEntry; "Debit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(VATDetailBase; VATDetail.Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATDetailAmount; VATDetail.Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(AddCurrencyCreditAmount_GLEntry; "Add.-Currency Credit Amount")
                    {
                        AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(AddCurrencyDebitAmount_GLEntry; "Add.-Currency Debit Amount")
                    {
                        AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(GLAccountNo_GLEntry; "G/L Account No.")
                    {
                    }
                    column(FormattedPrnDate; Format(PrnDate))
                    {
                    }
                    column(PrnDocno; PrnDocno)
                    {
                    }
                    column(GLPostingDescription; GLPostingDescription)
                    {
                    }
                    column(VATBusPostingGroup_GLEntry; "VAT Bus. Posting Group")
                    {
                    }
                    column(VATProdPostingGroup_GLEntry; "VAT Prod. Posting Group")
                    {
                    }
                    column(CurrencyCode; CurrencyCode)
                    {
                    }
                    column(CurrencyAmount; CurrencyAmount)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    column(PurchaseLedgerCaption; PurchaseLedgerCaptionLbl)
                    {
                    }
                    column(PurchaseLedgerSummaryCaption2; PurchaseLedgerSummaryCaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaption)
                    {
                    }
                    column(DocumentNoCaption; DocumentNoCaptionLbl)
                    {
                    }
                    column(GLAccountNo_GLEntryCaption; FieldCaption("G/L Account No."))
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(DebitAmount_GLEntryCaption; FieldCaption("Debit Amount"))
                    {
                    }
                    column(CreditAmount_GLEntryCaption; FieldCaption("Credit Amount"))
                    {
                    }
                    column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
                    {
                    }
                    column(CurrencyAmountCaption; CurrencyAmountCaptionLbl)
                    {
                    }
                    column(AddCurrencyDebitAmount_GLEntryCaption; FieldCaption("Add.-Currency Debit Amount"))
                    {
                    }
                    column(AddCurrencyCreditAmount_GLEntryCaption; FieldCaption("Add.-Currency Credit Amount"))
                    {
                    }
                    column(GLEntryVATProdPostingGroupCaption; FieldCaption("VAT Prod. Posting Group"))
                    {
                    }
                    column(VATBaseCaption; VATBaseCaptionLbl)
                    {
                    }
                    column(VATAmountCaption; VATAmountCaptionLbl)
                    {
                    }
                    column(GLEntryVATBusPostingGroupCaption; FieldCaption("VAT Bus. Posting Group"))
                    {
                    }
                    column(TransferCaption; TransferCaptionLbl)
                    {
                    }
                    column(TobeTransferredCaption; ToBeTransferredCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if (not UseAmtsInAddCurr) and
                           ("Debit Amount" = 0) and
                           ("Credit Amount" = 0) and
                           ("VAT Bus. Posting Group" = '') and
                           ("VAT Prod. Posting Group" = '')
                        then
                            CurrReport.Skip();

                        if ExcludeDeferrals and
                            ("Source Code" in [SourceCodeSetup."General Deferral", SourceCodeSetup."Sales Deferral", SourceCodeSetup."Purchase Deferral"]) then
                            CurrReport.Skip();

                        if OldName <> "Journal Templ. Name" then begin
                            OldDate := 0D;
                            OldName := "Journal Templ. Name";
                        end;

                        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date" then begin
                            if OldDate <> "Posting Date" then begin
                                OldDate := "Posting Date";
                                PrnDate := "Posting Date";
                            end else
                                PrnDate := 0D;
                        end else
                            if OldDate <> "VAT Reporting Date" then begin
                                OldDate := "VAT Reporting Date";
                                PrnDate := "VAT Reporting Date";
                            end else
                                PrnDate := 0D;

                        if OldDocno <> "Document No." then begin
                            OldDocno := "Document No.";
                            PrnDocno := "Document No.";
                        end else
                            PrnDocno := '';

                        if not GLAccount.Get("G/L Account No.") then
                            GLAccount.Init();
                        GLPostingDescription := Description;

                        CurrencyCode := '';
                        CurrencyAmount := 0;

                        if VendorLedgerEntry.Get("Entry No.") then begin
                            GLPostingDescription := VendorLedgerEntry."Vendor No.";
                            CurrencyCode := VendorLedgerEntry."Currency Code";
                            VendorLedgerEntry.CalcFields(Amount);
                            CurrencyAmount := VendorLedgerEntry.Amount;
                            if CurrencyCode = '' then
                                CurrencyAmount := 0;
                            if Vendor.Get(VendorLedgerEntry."Vendor No.") then
                                GLPostingDescription := GLPostingDescription + ' ' + Vendor.Name;
                        end;

                        if not UseAmtsInAddCurr then begin
                            Clear(VATDetail.Base);
                            Clear(VATDetail.Amount);

                            if OldTransactionNo <> "Transaction No." then begin
                                MultipleVATEntries := 0;
                                OldTransactionNo := "Transaction No.";
                            end;

                            if ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '') then begin
                                VATDetail.SetCurrentKey("Transaction No.");
                                VATDetail.SetRange("Transaction No.", "Transaction No.");
                                if MultipleVATEntries > 0 then begin
                                    if VATDetail.Next() <> 0 then
                                        MultipleVATEntries := MultipleVATEntries + 1;
                                end else
                                    if VATDetail.Find('-') then
                                        MultipleVATEntries := MultipleVATEntries + 1;
                            end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        "G/L Entry".SetRange("Journal Templ. Name", "Gen. Journal Template".Name);
                        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date" then
                            "G/L Entry".SetRange("Posting Date", PeriodStartDate, PeriodEndDate)
                        else
                            "G/L Entry".SetRange("VAT Reporting Date", PeriodStartDate, PeriodEndDate);
                    end;
                }
                dataitem(Loop1; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        GLEntry.SetCurrentKey("Journal Templ. Name", "VAT Reporting Date", "Document No.");
                        GLEntry.SetRange("Journal Templ. Name", "Gen. Journal Template".Name);
                        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date" then
                            GLEntry.SetRange("Posting Date", PeriodStartDate, PeriodEndDate)
                        else
                            GLEntry.SetRange("VAT Reporting Date", PeriodStartDate, PeriodEndDate);
                        if GLEntry.IsEmpty() then
                            CurrReport.Break();
                    end;
                }
                dataitem(Loop2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    PrintOnlyIfDetail = true;
                    column(Loop2PageNumber; Startpage + PeriodLoop.Number)
                    {
                    }
                    column(Loop2ReportFilter; ReportFilter)
                    {
                    }
                    column(Loop2CompanyName; COMPANYPROPERTY.DisplayName())
                    {
                    }
                    column(Loop2GenJournalTemplateName; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(Loop2UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                    }
                    column(Loop2PageCaption; PageCaptionLbl)
                    {
                    }
                    column(Loop2PurchaseLedgerCaption; PurchaseLedgerCaptionLbl)
                    {
                    }
                    column(PurchaseLedgerSummaryCaption; PurchaseLedgerSummaryCaptionLbl)
                    {
                    }
                    column(Loop2TodayFormatted; Format(Today, 0, 4))
                    {
                    }
                    dataitem("<G/L Entry2>"; "G/L Entry")
                    {
                        DataItemLinkReference = "Gen. Journal Template";
                        DataItemTableView = sorting("Journal Templ. Name", "G/L Account No.", "VAT Reporting Date", "Document Type");
                        column(GLEntry2GLAccountNo; "G/L Account No.")
                        {
                        }
                        column(GLEntry2Description; Description)
                        {
                        }
                        column(GLEntry2DebitAmount; "Debit Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(GLEntry2CreditAmount; "Credit Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(GLEntry2AddCurrencyDebitAmount; "Add.-Currency Debit Amount")
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(GLEntry2AddCurrencyCreditAmount; "Add.-Currency Credit Amount")
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(GLEntry2GLAccountNoCaption; FieldCaption("G/L Account No."))
                        {
                        }
                        column(GLEntry2DescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(GLEntry2DebitAmountCaption; FieldCaption("Debit Amount"))
                        {
                        }
                        column(GLEntry2CreditAmountCaption; FieldCaption("Credit Amount"))
                        {
                        }
                        column(GLEntry2AddCurrencyCreditAmountCaption; FieldCaption("Add.-Currency Credit Amount"))
                        {
                        }
                        column(GLEntry2AddCurrencyDebitAmountCaption; FieldCaption("Add.-Currency Debit Amount"))
                        {
                        }
                        column(GLEntry2TotalCaption; TotalCaptionLbl)
                        {
                        }
                        column(GLEntry2EntryNo; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not GLAccount.Get("G/L Account No.") then
                                GLAccount.Init();

                            Description := GLAccount.Name;

                            if (not UseAmtsInAddCurr) and
                               ("Debit Amount" = 0) and
                               ("Credit Amount" = 0)
                            then
                                CurrReport.Skip();

                            if ExcludeDeferrals and
                                ("Source Code" in [SourceCodeSetup."General Deferral", SourceCodeSetup."Sales Deferral", SourceCodeSetup."Purchase Deferral"]) then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            CopyFilters("G/L Entry");
                        end;
                    }
                    dataitem("VAT Entry"; "VAT Entry")
                    {
                        DataItemLinkReference = "Gen. Journal Template";
                        DataItemTableView = sorting("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Document Type", "VAT Reporting Date");

                        trigger OnAfterGetRecord()
                        begin
                            Clear(VATSumBuffer);
                            if "Document Type" <> "Document Type"::"Credit Memo" then begin
                                VATSumBuffer."Base Invoices" := -Base;
                                VATSumBuffer."VAT Amount Invoices" := -Amount;
                                VATSumBuffer."Add.-Curr. Base Invoices" := -"Additional-Currency Base";
                                VATSumBuffer."Add.-Curr. VAT Amount Invoices" := -"Additional-Currency Amount";
                            end else begin
                                VATSumBuffer."Base CM" := Base;
                                VATSumBuffer."VAT Amount CM" := Amount;
                                VATSumBuffer."Add.-Curr. Base CM" := "Additional-Currency Base";
                                VATSumBuffer."Add.-Curr. VAT Amount CM" := "Additional-Currency Amount";
                            end;
                            VATSumBuffer."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
                            VATSumBuffer."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                            VATSumBuffer.InsertLine();
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Journal Templ. Name", "Gen. Journal Template".Name);
                            if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date" then
                                "G/L Entry".CopyFilter("Posting Date", "Posting Date")
                            else
                                "G/L Entry".CopyFilter("VAT Reporting Date", "VAT Reporting Date");
                            VATSumBuffer.DeleteAll();
                        end;
                    }
                    dataitem(VATSummary; "Integer")
                    {
                        DataItemLinkReference = "Gen. Journal Template";
                        DataItemTableView = sorting(Number);
                        column(VATSumBufferVATAmountCM; VATSumBuffer."VAT Amount CM")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferBaseCM; VATSumBuffer."Base CM")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferVATAmountInvoices; -VATSumBuffer."VAT Amount Invoices")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferBaseInvoices; -VATSumBuffer."Base Invoices")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferVATProdPostingGroup; VATSumBuffer."VAT Prod. Posting Group")
                        {
                        }
                        column(VATSumBufferVATBusPostingGroup; VATSumBuffer."VAT Bus. Posting Group")
                        {
                        }
                        column(VATPostingDescription; VATPostingDescription)
                        {
                        }
                        column(VATSumBufferAddCurrBaseCM; VATSumBuffer."Add.-Curr. Base CM")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferAddCurrVATAmountCM; VATSumBuffer."Add.-Curr. VAT Amount CM")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferAddCurrVATAmountInvoices; -VATSumBuffer."Add.-Curr. VAT Amount Invoices")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferAddCurrBaseInvoices; -VATSumBuffer."Add.-Curr. Base Invoices")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(CreditMemosCaption; CreditMemosCaptionLbl)
                        {
                        }
                        column(InvoicesCaption; InvoicesCaptionLbl)
                        {
                        }
                        column(AddCurrVATAmountCaption; AddCurrVATAmountCaptionLbl)
                        {
                        }
                        column(VATSummaryVATAmountCaption; VATAmountCaptionLbl)
                        {
                        }
                        column(AddCurrBaseCaption; AddCurrBaseCaptionLbl)
                        {
                        }
                        column(PurchaseLedgerVATEntrySummaryCaption; PurchaseLedgerVATEntrySummaryCaptionLbl)
                        {
                        }
                        column(BaseCaption; BaseCaptionLbl)
                        {
                        }
                        column(VATBusPostingGroupCaption; VATBusPostingGroupCaptionLbl)
                        {
                        }
                        column(VATProdPostingGroupCaption; VATProdPostingGroupCaptionLbl)
                        {
                        }
                        column(VATPostingDescriptionCaption; VATPostingDescriptionCaptionLbl)
                        {
                        }
                        column(BaseCaption1; BaseCaptionLbl)
                        {
                        }
                        column(VATSummaryNumber; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            VATBusPostGroup: Record "VAT Business Posting Group";
                            VATProdPostGroup: Record "VAT Product Posting Group";
                            VATPostSetup: Record "VAT Posting Setup";
                        begin
                            VATSumBuffer.GetLine(Number);
                            if not UseAmtsInAddCurr then begin
                                if VATBusPostGroup.Get(VATSumBuffer."VAT Bus. Posting Group") then;
                                if VATProdPostGroup.Get(VATSumBuffer."VAT Prod. Posting Group") then;
                                if VATPostSetup.Get(VATSumBuffer."VAT Bus. Posting Group", VATSumBuffer."VAT Prod. Posting Group") then
                                    VATPostingDescription :=
                                      VATBusPostGroup.Description + ' - ' +
                                      VATProdPostGroup.Description + ' - ' +
                                      Format(VATPostSetup."VAT %") + '%'
                                else
                                    VATPostingDescription := '';
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, VATSumBuffer.Count);
                        end;
                    }
                    dataitem("VAT Statement Line"; "VAT Statement Line")
                    {
                        DataItemLinkReference = "Gen. Journal Template";
                        DataItemTableView = sorting("Statement Template Name", "Statement Name", "Line No.") where(Print = const(true));
                        column(VatAddCurrText; VatAddCurrText)
                        {
                        }
                        column(RowNo_VATStatementLine; "Row No.")
                        {
                        }
                        column(Description_VATStatementLine; Description)
                        {
                        }
                        column(NetAmountLCY; NetAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(TotalAmount; TotalAmount)
                        {
                            AutoFormatType = 1;
                        }
                        column(NetAmountLCYTotalAmount; NetAmountLCY - TotalAmount)
                        {
                            AutoFormatType = 1;
                        }
                        column(TotalAmountAddCurr; TotalAmountAddCurr)
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(NetAmountLCYTotalAmountCaption; CashDiscountCaptionLbl)
                        {
                        }
                        column(TotalAmountCaption; TotalAmountCaptionLbl)
                        {
                        }
                        column(NetAmountLCYCaption; NetAmountLCYCaptionLbl)
                        {
                        }
                        column(Description_VATStatementLineCaption; FieldCaption(Description))
                        {
                        }
                        column(RowNo_VATStatementLineCaption; FieldCaption("Row No."))
                        {
                        }
                        column(PurchaseLedgerVATStatementsCaption; PurchaseLedgerVATStatementsCaptionLbl)
                        {
                        }
                        column(StatementName_VATStatementLine; "Statement Name")
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            Dummy: Decimal;
                        begin
                            VATStmt.CalcLineTotal(
                              "VAT Statement Line", TotalAmount, Dummy,
                              NetAmountLCY, "Gen. Journal Template".Name, 0);
                            if UseAmtsInAddCurr then
                                VATStmtAddCurr.CalcLineTotal(
                                  "VAT Statement Line", TotalAmountAddCurr, Dummy,
                                  Dummy, "Gen. Journal Template".Name, 0);

                            if "Print with" = "Print with"::"Opposite Sign" then begin
                                TotalAmount := -TotalAmount;
                                NetAmountLCY := -NetAmountLCY;
                                TotalAmountAddCurr := -TotalAmountAddCurr;
                            end;

                            if (TotalAmount = 0) and
                               (NetAmountLCY = 0) and
                               (TotalAmountAddCurr = 0)
                            then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(VATStmt);
                            Clear(VATStmtAddCurr);
                            SetRange("Statement Template Name", GLSetup."VAT Statement Template Name");
                            SetRange("Statement Name", GLSetup."VAT Statement Name");
                            if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date" then
                                "G/L Entry".CopyFilter("Posting Date", "Date Filter")
                            else
                                "G/L Entry".CopyFilter("VAT Reporting Date", "Date Filter");

                            VATStatementName.Get(GLSetup."VAT Statement Template Name", GLSetup."VAT Statement Name");
                            VATStmt.InitializeRequest(
                              VATStatementName, "VAT Statement Line", Selection::"Open and Closed",
                              PeriodSelection::"Within Period", false, false);
                            if UseAmtsInAddCurr then begin
                                VATStmtAddCurr.InitializeRequest(
                                  VATStatementName, "VAT Statement Line", Selection::"Open and Closed",
                                  PeriodSelection::"Within Period", false, true);
                                VatAddCurrText := Text11302;
                            end;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    PeriodStartDate := NormalDate(PeriodEndDate) + 1;
                    PeriodEndDate := ClosingDate(CalcDate(PeriodLength, PeriodStartDate) - 1);
                    ReportFilter := Text11300 + Format(PeriodStartDate) + ' ... ' + Format(PeriodEndDate);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, NoOfPeriods);
                    PeriodEndDate := StartDate - 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(OldDocno);
                Clear(PrnDocno);
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of periods to be included in the report. The length of the periods is determined by the length of the periods in the Accounting Period table.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(Startpage; Startpage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Page Number';
                        ToolTip = 'Specifies the first page number of the report.';
                    }
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in';
                        ToolTip = 'Specifies if you want the amounts to be shown in the local currency with additional VAT information.';
                    }
                    field(ExcludeDeferralEntries; ExcludeDeferrals)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exclude Deferral Entries';
                        ToolTip = 'Specifies if you want to exclude deferral ledger entries from the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then
                StartDate := WorkDate();
            if NoOfPeriods = 0 then
                NoOfPeriods := 1;
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
            Startpage := 1;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
        GLSetup.TestField("VAT Statement Template Name");
        GLSetup.TestField("VAT Statement Name");
        SourceCodeSetup.Get();
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date" then
            DateCaption := PrnDateCaptionLbl
        else
            DateCaption := VATDateCaptionLbl;
    end;

    var
        Text11300: Label 'Date Filter : ';
        Text11301: Label 'Journal Template Name: ';
        Text11302: Label 'Add.-Curr. VAT Amount';
        VATStatementName: Record "VAT Statement Name";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        VATSumBuffer: Record "VAT Summary Buffer" temporary;
        VATDetail: Record "VAT Entry";
        SourceCodeSetup: Record "Source Code Setup";
        VATStmt: Report "VAT Statement";
        VATStmtAddCurr: Report "VAT Statement";
        OldName: Code[10];
        OldDate: Date;
        OldDocno: Code[20];
        PrnDate: Date;
        PrnDocno: Code[20];
        CurrencyCode: Code[10];
        CurrencyAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountAddCurr: Decimal;
        ReportFilter: Text[250];
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        NetAmountLCY: Decimal;
        UseAmtsInAddCurr: Boolean;
        VatAddCurrText: Text[30];
        VATPostingDescription: Text[250];
        StartDate: Date;
        NoOfPeriods: Integer;
        PeriodLength: DateFormula;
        Startpage: Integer;
        MultipleVATEntries: Integer;
        OldTransactionNo: Integer;
        GLPostingDescription: Text;
        DateCaption: Text;
        ExcludeDeferrals: Boolean;
        PageCaptionLbl: Label 'Page';
        PurchaseLedgerCaptionLbl: Label 'Purchase Ledger';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        CurrencyAmountCaptionLbl: Label 'Amount Currency';
        DescriptionCaptionLbl: Label 'Description';
        DocumentNoCaptionLbl: Label 'Document No.';
        VATBaseCaptionLbl: Label 'VAT Base';
        TransferCaptionLbl: Label 'Transfer';
        ToBeTransferredCaptionLbl: Label 'To be Transferred';
        TotalCaptionLbl: Label 'Total';
        PurchaseLedgerSummaryCaptionLbl: Label 'Purchase Ledger Summary';
        CreditMemosCaptionLbl: Label 'Credit Memos';
        InvoicesCaptionLbl: Label 'Invoices';
        AddCurrVATAmountCaptionLbl: Label 'Add.-Curr. VAT Amount';
        AddCurrBaseCaptionLbl: Label 'Add.-Curr. Base';
        PurchaseLedgerVATEntrySummaryCaptionLbl: Label 'Purchase Ledger - VAT Entry Summary';
        VATBusPostingGroupCaptionLbl: Label 'VAT Bus. Posting Group';
        VATProdPostingGroupCaptionLbl: Label 'VAT Prod. Posting Group';
        VATPostingDescriptionCaptionLbl: Label 'VAT Posting Setup Description';
        BaseCaptionLbl: Label 'Base';
        VATAmountCaptionLbl: Label 'VAT Amount';
        CashDiscountCaptionLbl: Label 'Cash Discount';
        TotalAmountCaptionLbl: Label 'Amount VAT Statement';
        NetAmountLCYCaptionLbl: Label 'Amount G/L Account';
        PurchaseLedgerVATStatementsCaptionLbl: Label 'Purchase Ledger - VAT Statements';
        VATDateCaptionLbl: Label 'VAT Date';
        PrnDateCaptionLbl: Label 'Posting Date';

    protected var
        PeriodStartDate: Date;
        PeriodEndDate: Date;

}
