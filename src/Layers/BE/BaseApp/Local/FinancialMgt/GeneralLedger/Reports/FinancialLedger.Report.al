// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11304 "Financial Ledger"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/FinancialLedger.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Ledger';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Gen. Journal Template"; "Gen. Journal Template")
        {
            DataItemTableView = sorting(Name) where(Type = const(Financial));
            RequestFilterFields = Name;
            column(Name_GenJnlTemplate; Name)
            {
            }
            column(UserId; UserId)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PageCaption; PageCaptionLbl)
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
                    column(GenJnlTemplateName; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(Startpage; Startpage)
                    {
                    }
                    column(FinancialLedgerCaption; FinancialLedgerCaptionLbl)
                    {
                    }
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLinkReference = PeriodLoop;
                    DataItemTableView = sorting("Journal Templ. Name", "Posting Date", "Document No.");
                    column(ReportFilter_GLEntry; ReportFilter)
                    {
                    }
                    column(GenJnlTemplateName_GLEntry; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                    }
                    column(BeginBalance; BeginBalance)
                    {
                        AutoFormatType = 1;
                    }
                    column(JTNdescription; JTNdescription)
                    {
                    }
                    column(GenJnlTemplateNameFmt; Text11301 + Format("Journal Templ. Name"))
                    {
                    }
                    column(HeaderPrinted; HeaderPrinted)
                    {
                    }
                    column(CrAmt_GLEntry; "Credit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(DebitAmt_GLEntry; "Debit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(VATDetail_Base; VATDetail.Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATDetail_Amount; VATDetail.Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(AddCurrAmt_GLEntry; "Additional-Currency Amount")
                    {
                        AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(GLAccNo_GLEntry; "G/L Account No.")
                    {
                    }
                    column(PostingDateFormatted_GLEntry; Format("Posting Date"))
                    {
                    }
                    column(DocNo_GLEntry; "Document No.")
                    {
                    }
                    column(Desc_GLEntry; Description)
                    {
                    }
                    column(VATBusPostingGrp_GLEntry; "VAT Bus. Posting Group")
                    {
                    }
                    column(VATProdPostingGrp_GLEntry; "VAT Prod. Posting Group")
                    {
                    }
                    column(TotalBalance; TotalBalance)
                    {
                        AutoFormatType = 1;
                    }
                    column(CurrencyCode; CurrencyCode)
                    {
                    }
                    column(CurrencyAmount; CurrencyAmount)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(FinancialLedgerCaption_GLEntry; FinancialLedgerCaptionLbl)
                    {
                    }
                    column(PostingDateCaption; PostingDateCaptionLbl)
                    {
                    }
                    column(DocNoCaption_GLEntry; FieldCaption("Document No."))
                    {
                    }
                    column(GLAccNoCaption_GLEntry; FieldCaption("G/L Account No."))
                    {
                    }
                    column(DescCaption_GLEntry; FieldCaption(Description))
                    {
                    }
                    column(DebitAmtCaption_GLEntry; FieldCaption("Debit Amount"))
                    {
                    }
                    column(CrAmtCaption_GLEntry; FieldCaption("Credit Amount"))
                    {
                    }
                    column(CurrCodeCaption; CurrCodeCaptionLbl)
                    {
                    }
                    column(AmtCurrCaption; AmtCurrCaptionLbl)
                    {
                    }
                    column(BalanceCaption; BalanceCaptionLbl)
                    {
                    }
                    column(AdditionalCurrAmtCaption; AdditionalCurrAmtCaptionLbl)
                    {
                    }
                    column(DocNoCaption; DocNoCaptionLbl)
                    {
                    }
                    column(GLEntryPostingDateCaption; GLEntryPostingDateCaptionLbl)
                    {
                    }
                    column(VATProdPostingGrpCaption_GLEntry; FieldCaption("VAT Prod. Posting Group"))
                    {
                    }
                    column(VATBaseCaption; VATBaseCaptionLbl)
                    {
                    }
                    column(VATAmtCaption; VATAmtCaptionLbl)
                    {
                    }
                    column(VATBusPostingGrpCaption_GLEntry; FieldCaption("VAT Bus. Posting Group"))
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

                    trigger OnAfterGetRecord()
                    begin
                        if OldName <> "Journal Templ. Name" then begin
                            TotalBalance := 0;
                            OldName := "Journal Templ. Name";
                            GenJnlTemplate.Get("Journal Templ. Name");
                            if GenJnlTemplate."Bal. Account Type" = GenJnlTemplate."Bal. Account Type"::"G/L Account" then
                                BalAccNo := GenJnlTemplate."Bal. Account No."
                            else
                                if GenJnlTemplate."Bal. Account Type" = GenJnlTemplate."Bal. Account Type"::"Bank Account" then begin
                                    BankAccount.Get(GenJnlTemplate."Bal. Account No.");
                                    BankAccPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
                                    BalAccNo := BankAccPostingGroup."G/L Account No.";
                                end;

                            if not GLAccount.Get(BalAccNo) then
                                GLAccount.Init();
                            JTNdescription := GLAccount.Name;

                            GLAccount.SetRange("Date Filter", 0D, ClosingDate(PeriodStartDate - 1));
                            GLAccount.CalcFields("Balance at Date");
                            BeginBalance := GLAccount."Balance at Date";
                            TotalBalance := BeginBalance;
                        end;

                        if not GLAccount.Get("G/L Account No.") then
                            GLAccount.Init();
                        GLPostingDescription := Description;

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

                        if BalAccNo <> "G/L Account No." then
                            if Amount > 0 then
                                TotalBalance := TotalBalance - "Debit Amount"
                            else
                                TotalBalance := TotalBalance + "Credit Amount";

                        if (BalAccNo = "G/L Account No.") and (BalAccNo <> "Bal. Account No.") then
                            CurrReport.Skip();

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
                    column(GenJnlTemplateName_Loop2; Text11301 + "Gen. Journal Template".Name)
                    {
                    }
                    column(UseAmtsInAddCurr_Loop2; UseAmtsInAddCurr)
                    {
                    }
                    column(FinLedgSummaryCaption; FinLedgSummaryCaptionLbl)
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
                        column(CrAmt_GLEntry2; "Credit Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(AddCurrDebitAmt_GLEntry2; "Add.-Currency Debit Amount")
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AddCurrCrAmt_GLEntry2; "Add.-Currency Credit Amount")
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
                        column(CrAmtCaption_GLEntry2; FieldCaption("Credit Amount"))
                        {
                        }
                        column(AddCurrCrAmtCaption_GLEntry2; FieldCaption("Add.-Currency Credit Amount"))
                        {
                        }
                        column(AddCurrDebitAmtCaption_GLEntry2; FieldCaption("Add.-Currency Debit Amount"))
                        {
                        }
                        column(TotalCaption_GLEntry2; TotalCaptionLbl)
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
                        column(UseAmtsInAddCurr_VATEntry; UseAmtsInAddCurr)
                        {
                        }
                        column(FinLedgerVATEntrySummaryCaption; FinLedgerVATEntrySummaryCaptionLbl)
                        {
                        }
                        column(VATBusPostingGroupCaption; VATBusPostingGroupCaptionLbl)
                        {
                        }
                        column(VATProdPostingGroupCaption; VATProdPostingGroupCaptionLbl)
                        {
                        }
                        column(BaseCaption; BaseCaptionLbl)
                        {
                        }
                        column(VATAmountCaption; VATAmountCaptionLbl)
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
                        column(VATBusPostingGrp_VATEntry; "VAT Bus. Posting Group")
                        {
                        }
                        column(VATProdPostingGrp_VATEntry; "VAT Prod. Posting Group")
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
                        column(VATSumBufferVATAmtCM; VATSumBuffer."VAT Amount CM")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferBaseCM; VATSumBuffer."Base CM")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferVATAmtInv; -VATSumBuffer."VAT Amount Invoices")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferBaseInv; -VATSumBuffer."Base Invoices")
                        {
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferVATProdPostingGrp; VATSumBuffer."VAT Prod. Posting Group")
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
                        column(VATSumBufferAddCurrVATAmtCM; VATSumBuffer."Add.-Curr. VAT Amount CM")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferAddCurrVATAmtInv; -VATSumBuffer."Add.-Curr. VAT Amount Invoices")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATSumBufferAddCurrBaseInv; -VATSumBuffer."Add.-Curr. Base Invoices")
                        {
                            AutoFormatExpression = VATSumBuffer.GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(UseAmtsInAddCurr_VATSummary; UseAmtsInAddCurr)
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
                        column(RowNo_VATStmtLine; "Row No.")
                        {
                        }
                        column(Desc_VATStmtLine; Description)
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
                        column(DiffrecenceAmount; NetAmountLCY - TotalAmount)
                        {
                            AutoFormatType = 1;
                        }
                        column(TotalAmountAddCurr; TotalAmountAddCurr)
                        {
                            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(CashDiscountCaption; CashDiscountCaptionLbl)
                        {
                        }
                        column(AmtVATStmtCaption; AmtVATStmtCaptionLbl)
                        {
                        }
                        column(AmtGLAccCaption; AmtGLAccCaptionLbl)
                        {
                        }
                        column(DescCaption_VATSTmtLine; FieldCaption(Description))
                        {
                        }
                        column(RowNoCaption_VATSTmtLine; FieldCaption("Row No."))
                        {
                        }
                        column(FinLedgerVATStmtsCaption; FinLedgerVATStmtsCaptionLbl)
                        {
                        }
                        column(StmtTempName_VATStmtLine; "Statement Template Name")
                        {
                        }
                        column(StmtName_VATStmtLine; "Statement Name")
                        {
                        }
                        column(LineNo_VATStmtLine; "Line No.")
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

                            VATStatName.Get(GLSetup."VAT Statement Template Name", GLSetup."VAT Statement Name");
                            VATStmt.InitializeRequest(
                              VATStatName, "VAT Statement Line", Selection::"Open and Closed",
                              PeriodSelection::"Within Period", false, false);
                            if UseAmtsInAddCurr then begin
                                VATStmtAddCurr.InitializeRequest(
                                  VATStatName, "VAT Statement Line", Selection::"Open and Closed",
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
                HeaderPrinted := false;
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
    end;

    var
        Text11300: Label 'Date Filter : ';
        Text11301: Label 'Journal Template Name: ';
        Text11302: Label 'Add.-Curr. VAT Amount';
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        VATStatName: Record "VAT Statement Name";
        VATSumBuffer: Record "VAT Summary Buffer" temporary;
        VATDetail: Record "VAT Entry";
        BankAccount: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlTemplate: Record "Gen. Journal Template";
        VATStmt: Report "VAT Statement";
        VATStmtAddCurr: Report "VAT Statement";
        OldName: Code[10];
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
        HeaderPrinted: Boolean;
        MultipleVATEntries: Integer;
        OldTransactionNo: Integer;
        BeginBalance: Decimal;
        TotalBalance: Decimal;
        BalAccNo: Code[20];
        JTNdescription: Text[100];
        GLPostingDescription: Text;
        PageCaptionLbl: Label 'Page';
        FinancialLedgerCaptionLbl: Label 'Financial Ledger';
        PostingDateCaptionLbl: Label 'Posting Date';
        CurrCodeCaptionLbl: Label 'Currency Code';
        AmtCurrCaptionLbl: Label 'Amount Currency';
        BalanceCaptionLbl: Label 'Balance';
        AdditionalCurrAmtCaptionLbl: Label 'Additional-Currency Amount';
        DocNoCaptionLbl: Label 'Document No.';
        GLEntryPostingDateCaptionLbl: Label 'Posting Date';
        VATBaseCaptionLbl: Label 'VAT\Base';
        VATAmtCaptionLbl: Label 'VAT\Amount';
        TransferCaptionLbl: Label 'Transfer';
        TobeTransferredCaptionLbl: Label 'To be Transferred';
        TotalCaptionLbl: Label 'Total';
        FinLedgSummaryCaptionLbl: Label 'Financial Ledger Summary';
        FinLedgerVATEntrySummaryCaptionLbl: Label 'Financial Ledger - VAT Entry Summary';
        VATBusPostingGroupCaptionLbl: Label 'VAT Bus. Posting Group';
        VATProdPostingGroupCaptionLbl: Label 'VAT Prod. Posting Group';
        BaseCaptionLbl: Label 'Base';
        VATAmountCaptionLbl: Label 'VAT Amount';
        AddCurrBaseCaptionLbl: Label 'Add.-Curr. Base';
        AddCurrVATAmtCaptionLbl: Label 'Add.-Curr. VAT Amount';
        InvoicesCaptionLbl: Label 'Invoices';
        CreditMemosCaptionLbl: Label 'Credit Memos';
        VATPostingDescriptionCaptionLbl: Label 'VAT Posting Setup Description';
        CashDiscountCaptionLbl: Label 'Cash Discount';
        AmtVATStmtCaptionLbl: Label 'Amount VAT Statement';
        AmtGLAccCaptionLbl: Label 'Amount G/L Account';
        FinLedgerVATStmtsCaptionLbl: Label 'Financial Ledger - VAT Statements';
}
