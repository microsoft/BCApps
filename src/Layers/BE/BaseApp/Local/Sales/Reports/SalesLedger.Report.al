// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11300 "Sales Ledger"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SalesLedger.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Ledger';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Gen. Journal Template"; "Gen. Journal Template")
        {
            DataItemTableView = sorting(Name) where(Type = const(Sales));
            RequestFilterFields = Name;
            column(Name_GenJnlTemp; Name)
            {
            }
            dataitem(PeriodLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PrintHeader; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(ReportFilter; ReportFilter)
                    {
                    }
                    column(CompanyName; COMPANYPROPERTY.DisplayName())
                    {
                    }
                    column(GenJnlTempName; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(TodayFormatted; Format(Today, 0, 4))
                    {
                    }
                    column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                    }
                    column(Startpage; Startpage)
                    {
                    }
                    column(PageNoCaption; PageNoCaptionLbl)
                    {
                    }
                    column(SalesLedgCaption; SalesLedgCaptionLbl)
                    {
                    }
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLinkReference = PeriodLoop;
                    DataItemTableView = sorting("Journal Templ. Name", "Document No.", "Posting Date");
                    column(ReportFilter_GLEntry; ReportFilter)
                    {
                    }
                    column(VATSumBUfferAddHeader; UseAmtsInAddCurr)
                    {
                    }
                    column(CreditAmt_GLEntry; "Credit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(DebitAmt_GLEntry; "Debit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(VATDetailBase; VATDetail.Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATDetailAmt; VATDetail.Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(AddCurrCreditAmt_GLEntry; "Add.-Currency Credit Amount")
                    {
                        AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(AddCurrDebitAmt_GLEntry; "Add.-Currency Debit Amount")
                    {
                        AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(GLAccNo_GLEntry; "G/L Account No.")
                    {
                    }
                    column(PrnDate; Format(PrnDate))
                    {
                    }
                    column(PrnDocno; PrnDocno)
                    {
                    }
                    column(GLPostingDescription; GLPostingDescription)
                    {
                    }
                    column(VATBusPostGroup_GLEntry; "VAT Bus. Posting Group")
                    {
                    }
                    column(VATProdPostGroup_GLEntry; "VAT Prod. Posting Group")
                    {
                    }
                    column(PostingDate; Format(PrnDate))
                    {
                    }
                    column(DocNo; PrnDocno)
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
                    column(SalesLedgCaption_GLEntry; SalesLedgCaptionLbl)
                    {
                    }
                    column(PostDateCaption; PostDateCaptionLbl)
                    {
                    }
                    column(DocNoCaption; DocNoCaptionLbl)
                    {
                    }
                    column(DescCaption_GLEntry; FieldCaption(Description))
                    {
                    }
                    column(DebitAmtCaption_GLEntry; FieldCaption("Debit Amount"))
                    {
                    }
                    column(CreditAmtCaption_GLEntry; FieldCaption("Credit Amount"))
                    {
                    }
                    column(CurrCodeCaption; CurrCodeCaptionLbl)
                    {
                    }
                    column(AmtCurrencyCaption; AmtCurrencyCaptionLbl)
                    {
                    }
                    column(AddCurrDebitAmtCaption_GLEntry; FieldCaption("Add.-Currency Debit Amount"))
                    {
                    }
                    column(AddCurrCreditAmtCaption_GLEntry; FieldCaption("Add.-Currency Credit Amount"))
                    {
                    }
                    column(GLAccNoCaption_GLEntry; FieldCaption("G/L Account No."))
                    {
                    }
                    column(PrnDateCaption; PrnDateCaptionLbl)
                    {
                    }
                    column(VATProdPostGroupCaption_GLEntry; FieldCaption("VAT Prod. Posting Group"))
                    {
                    }
                    column(VATBaseCaption; VATBaseCaptionLbl)
                    {
                    }
                    column(VATAmtCaption; VATAmtCaptionLbl)
                    {
                    }
                    column(VATBusPostGroupCaption_GLEntry; FieldCaption("VAT Bus. Posting Group"))
                    {
                    }
                    column(TransferCaption; TransferCaptionLbl)
                    {
                    }
                    column(TobeTransferredCaption; TobeTransferredCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(EntryNo_GLEntry; "Entry No.")
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

                        if OldDate <> "Posting Date" then begin
                            OldDate := "Posting Date";
                            PrnDate := "Posting Date";
                        end else
                            PrnDate := 0D;

                        if OldDocno <> "Document No." then begin
                            OldDocno := "Document No.";
                            PrnDocno := "Document No.";
                        end else
                            PrnDocno := '';

                        if not GLAccount.Get("G/L Account No.") then
                            GLAccount.Init();
                        GLPostingDescription := GLAccount.Name;

                        CurrencyCode := '';
                        CurrencyAmount := 0;

                        if CustLedgerEntry.Get("Entry No.") then begin
                            GLPostingDescription := CustLedgerEntry."Customer No.";
                            CurrencyCode := CustLedgerEntry."Currency Code";
                            CustLedgerEntry.CalcFields(Amount);
                            CurrencyAmount := CustLedgerEntry.Amount;
                            if CurrencyCode = '' then
                                CurrencyAmount := 0;
                            if Customer.Get(CustLedgerEntry."Customer No.") then
                                GLPostingDescription := GLPostingDescription + ' ' + Customer.Name;
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
                        "G/L Entry".SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
                    end;
                }
                dataitem(Loop1; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        GLEntry.SetCurrentKey("Journal Templ. Name", "Posting Date", "Document No.");
                        GLEntry.SetRange("Journal Templ. Name", "Gen. Journal Template".Name);
                        GLEntry.SetRange("Posting Date", PeriodStartDate, PeriodEndDate);

                        if GLEntry.IsEmpty() then
                            CurrReport.Break();
                    end;
                }
                dataitem(Loop2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    PrintOnlyIfDetail = true;
                    column(ReportFilter_Loop2; ReportFilter)
                    {
                    }
                    column(TodayFormatted_Loop2; Format(Today, 0, 4))
                    {
                    }
                    column(GenJnlTempName_Loop2; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(UseAmtsInAddCurrSum; UseAmtsInAddCurr)
                    {
                    }
                    column(SalesLedgSummaryCaption_Loop2; SalesLedgSummaryCaptionLbl)
                    {
                    }
                    dataitem("<G/L Entry2>"; "G/L Entry")
                    {
                        DataItemLinkReference = "Gen. Journal Template";
                        DataItemTableView = sorting("Journal Templ. Name", "G/L Account No.", "Posting Date", "Document Type");
                        column(GLAccNo_GLEntry2; "G/L Account No.")
                        {
                        }
                        column(Desc_GLEntry2; Description)
                        {
                        }
                        column(DebitAmt_GLEntry2; "Debit Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(CreditAmt_GLEntry2; "Credit Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(AddCurrDebitAmt_GLEntry2; "Add.-Currency Debit Amount")
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AddCurrCreditAmt_GLEntry2; "Add.-Currency Credit Amount")
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(GLAccNoCaption_GLEntry2; FieldCaption("G/L Account No."))
                        {
                        }
                        column(DescCaption_GLEntry2; FieldCaption(Description))
                        {
                        }
                        column(DebitAmtCaption_GLEntry2; FieldCaption("Debit Amount"))
                        {
                        }
                        column(CreditAmtCaption_GLEntry2; FieldCaption("Credit Amount"))
                        {
                        }
                        column(AddCurrCreditAmtCaption_GLEntry2; FieldCaption("Add.-Currency Credit Amount"))
                        {
                        }
                        column(AddCurrDebitAmtCaption_GLEntry2; FieldCaption("Add.-Currency Debit Amount"))
                        {
                        }
                        column(TotalCaption_GLEntry2; TotalCaptionLbl)
                        {
                        }
                        column(EntryNo_GLEntry2; "Entry No.")
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
                        DataItemTableView = sorting("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Document Type", "Posting Date");
                        column(UseAmtsInAddCurrVATSum; UseAmtsInAddCurr)
                        {
                        }
                        column(SalesLedgVATEntrySummaryCaption; SalesLedgVATEntrySummaryCaptionLbl)
                        {
                        }
                        column(VATBusPostGroupCaption; VATBusPostGroupCaptionLbl)
                        {
                        }
                        column(VATProdPostGroupCaption; VATProdPostGroupCaptionLbl)
                        {
                        }
                        column(BaseCaption; BaseCaptionLbl)
                        {
                        }
                        column(VATAmtCaption_GLEntry2; VATAmtCaptionLbl)
                        {
                        }
                        column(AddCurrBaseCaption; AddCurrBaseCaptionLbl)
                        {
                        }
                        column(AddCurrVATAmtCaption; AddCurrVATAmtCaptionLbl)
                        {
                        }
                        column(InvoicesCaption; InvoicesCaptionLbl)
                        {
                        }
                        column(CreditMemosCaption; CreditMemosCaptionLbl)
                        {
                        }
                        column(VATPostingDescriptionCaption; VATPostingDescriptionCaptionLbl)
                        {
                        }
                        column(EntryNo_VATEntry; "Entry No.")
                        {
                        }
                        column(VATBusPostGroup_VATEntry; "VAT Bus. Posting Group")
                        {
                        }
                        column(VATProdPostGroup_VATEntry; "VAT Prod. Posting Group")
                        {
                        }
                        column(DocType_VATEntry; "Document Type")
                        {
                        }

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
                            "G/L Entry".CopyFilter("Posting Date", "Posting Date");

                            VATSumBuffer.DeleteAll();
                        end;
                    }
                    dataitem(VATSummary; "Integer")
                    {
                        DataItemLinkReference = "Gen. Journal Template";
                        DataItemTableView = sorting(Number);
                        column(VATSumBuffVATAmtCM; VATSumBuffer."VAT Amount CM")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffBaseCM; VATSumBuffer."Base CM")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffVATAmtInvoices; -VATSumBuffer."VAT Amount Invoices")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffBaseInvoices; -VATSumBuffer."Base Invoices")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffVATProdPostGroup; VATSumBuffer."VAT Prod. Posting Group")
                        {
                        }
                        column(VATSumBuffVATBusPostGroup; VATSumBuffer."VAT Bus. Posting Group")
                        {
                        }
                        column(VATPostingDescription; VATPostingDescription)
                        {
                        }
                        column(VATSumBuffAddCurrBaseCM; VATSumBuffer."Add.-Curr. Base CM")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffAddCurrVATAmtCM; VATSumBuffer."Add.-Curr. VAT Amount CM")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffAddCurrVATAmtInvoices; -VATSumBuffer."Add.-Curr. VAT Amount Invoices")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBuffAddCurrBaseInvoices; -VATSumBuffer."Add.-Curr. Base Invoices")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(UseAmtsInAddCurrVATDetail; UseAmtsInAddCurr)
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
                        column(RowNo_VATStmntLine; "Row No.")
                        {
                        }
                        column(Desc_VATStmntLine; Description)
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
                        column(NetAmtLCYTotalAmt; NetAmountLCY - TotalAmount)
                        {
                            AutoFormatType = 1;
                        }
                        column(TotalAmountAddCurr; TotalAmountAddCurr)
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(CashDiscCaption; CashDiscCaptionLbl)
                        {
                        }
                        column(AmtVATStmntCaption; AmtVATStmntCaptionLbl)
                        {
                        }
                        column(AmtGLAccCaption; AmtGLAccCaptionLbl)
                        {
                        }
                        column(DescCaption_VATStmntLine; FieldCaption(Description))
                        {
                        }
                        column(RowNoCaption_VATStmntLine; FieldCaption("Row No."))
                        {
                        }
                        column(SalesLedgVATStmntsCaption; SalesLedgVATStmntsCaptionLbl)
                        {
                        }
                        column(StmntTempName_VATStmntLine; "Statement Template Name")
                        {
                        }
                        column(StmntName_VATStmntLine; "Statement Name")
                        {
                        }
                        column(LineNo_VATStmntLine; "Line No.")
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
                            "G/L Entry".CopyFilter("Posting Date", "Date Filter");

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
    end;

    var
        Text11300: Label 'Date Filter : ';
        Text11301: Label 'Journal Template Name: ';
        Text11302: Label 'Add.-Curr. VAT Amount';
        VATSumBuffer: Record "VAT Summary Buffer" temporary;
        VATDetail: Record "VAT Entry";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        VATStatementName: Record "VAT Statement Name";
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
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        NoOfPeriods: Integer;
        PeriodLength: DateFormula;
        Startpage: Integer;
        MultipleVATEntries: Integer;
        OldTransactionNo: Integer;
        GLPostingDescription: Text;
        ExcludeDeferrals: Boolean;
        PageNoCaptionLbl: Label 'Page';
        SalesLedgCaptionLbl: Label 'Sales Ledger';
        PostDateCaptionLbl: Label 'Posting Date';
        DocNoCaptionLbl: Label 'Document No.';
        CurrCodeCaptionLbl: Label 'Currency Code';
        AmtCurrencyCaptionLbl: Label 'Amount Currency';
        PrnDateCaptionLbl: Label 'Posting Date';
        VATBaseCaptionLbl: Label 'VAT\Base';
        TransferCaptionLbl: Label 'Transfer';
        TobeTransferredCaptionLbl: Label 'To be Transferred';
        TotalCaptionLbl: Label 'Total';
        SalesLedgSummaryCaptionLbl: Label 'Sales Ledger Summary';
        SalesLedgVATEntrySummaryCaptionLbl: Label 'Sales Ledger - VAT Entry Summary';
        VATBusPostGroupCaptionLbl: Label 'VAT Bus. Posting Group';
        VATProdPostGroupCaptionLbl: Label 'VAT Prod. Posting Group';
        BaseCaptionLbl: Label 'Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        AddCurrBaseCaptionLbl: Label 'Add.-Curr. Base';
        AddCurrVATAmtCaptionLbl: Label 'Add.-Curr. VAT Amount';
        InvoicesCaptionLbl: Label 'Invoices';
        CreditMemosCaptionLbl: Label 'Credit Memos';
        VATPostingDescriptionCaptionLbl: Label 'VAT Posting Setup Description';
        CashDiscCaptionLbl: Label 'Cash Discount';
        AmtVATStmntCaptionLbl: Label 'Amount VAT Statement';
        AmtGLAccCaptionLbl: Label 'Amount G/L Account';
        SalesLedgVATStmntsCaptionLbl: Label 'Sales Ledger - VAT Statements';
}
