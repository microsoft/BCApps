// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Utilities;

/// <summary>
/// Report that summarizes sales deferral activity by customer and period.
/// Provides detailed analysis of deferred revenue amounts and recognition patterns for sales transactions.
/// </summary>
report 1701 "Deferral Summary - Sales"
{
    ApplicationArea = Suite;
    Caption = 'Deferral Summary - Sales';
#if not CLEAN27
    DefaultRenderingLayout = Word;
#else
    DefaultRenderingLayout = Excel;
#endif
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
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
            column(GLAccTableCaption; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            // RDLC only
            column(EmptyString; '')
            {
            }
            // RDLC only
            column(DeferralSummarySalesCaption; DeferralSummarySalesCaptionLbl)
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
            column(DocumentCaption; DocumentCaptionLbl + Format(DocumentFilter))
            {
            }
            column(DocumentFilter; DocumentFilter)
            {
            }
            // RDLC only
            column(CustomerCaption; CustomerCaptionLbl + Format(CustomerFilter))
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
                DataItemLink = CustVendorNo = field("No.");
                DataItemLinkReference = Customer;
                DataItemTableView = sorting("Deferral Doc. Type", CustVendorNo, "Posting Date", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.") order(ascending) where("Deferral Doc. Type" = const(Sales), CustVendorNo = filter(<> ''));
                RequestFilterFields = "Document No.";
                column(CustomerFilter; CustomerFilter)
                {
                }
                column(CustNo; CustVendorNo)
                {
                }
                column(No_GLAcc; "Account No.")
                {
                }
                column(Document_No; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Document_Type; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(DocumentTypeString; DocumentTypeString)
                {
                }
                column(Line_No; "Line No.")
                {
                }
                column(AccountName; AccountName)
                {
                }
                column(CustName; CustName)
                {
                }
                column(TotalAmtDeferred; "Amount to Defer (LCY)")
                {
                }
                column(NumOfPeriods; "No. of Periods")
                {
                    IncludeCaption = true;
                }
                column(DocumentType; "Document Type")
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
                column(PostingDate; Format(PostingDate))
                {
                }
                column(DeferralAccount; DeferralAccount)
                {
                }
                column(Amount; "Amount to Defer (LCY)")
                {
                }
                column(LineDescription; LineDescription)
                {
                }
                column(LineType; LineType)
                {
                }

                trigger OnAfterGetRecord()
                var
                    PostedDeferralLine: Record "Posted Deferral Line";
                    SalesHeader: Record "Sales Header";
                    SalesLine: Record "Sales Line";
                    SalesInvoiceHeader: Record "Sales Invoice Header";
                    SalesInvoiceLine: Record "Sales Invoice Line";
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    SalesCrMemoLine: Record "Sales Cr.Memo Line";
                    ReverseAmounts: Boolean;
                    LinesFound: Boolean;
                begin
                    PreviousCustomer := WorkingCustomer;
                    ReverseAmounts := false;

                    if Customer.Get(CustVendorNo) then begin
                        CustName := Customer.Name;
                        WorkingCustomer := CustVendorNo;
                    end;

                    if (PreviousCustomer <> WorkingCustomer) then begin
                        if PrintOnlyOnePerPage then begin
                            PostedDeferralHeaderPage.Reset();
                            PostedDeferralHeaderPage.SetRange(CustVendorNo, CustVendorNo);
                            if PostedDeferralHeaderPage.FindFirst() then
                                PageGroupNo := PageGroupNo + 1;
                        end;

                        SumAmtRecognized := 0;
                        SumRemainingAmtDeferred := 0;
                        SumTotalAmtDeferred := 0;
                    end;

                    LineDescription := '';
                    case "Document Type" of
                        7: // Posted Invoice
                            if SalesInvoiceLine.Get("Document No.", "Line No.") then begin
                                LineDescription := SalesInvoiceLine.Description;
                                LineType := SalesInvoiceLine.Type.AsInteger();
                                if SalesInvoiceHeader.Get("Document No.") then
                                    PostingDate := SalesInvoiceHeader."Posting Date";
                            end;
                        8: // Posted Credit Memo
                            if SalesCrMemoLine.Get("Document No.", "Line No.") then begin
                                LineDescription := SalesCrMemoLine.Description;
                                LineType := SalesCrMemoLine.Type.AsInteger();
                                if SalesCrMemoHeader.Get("Document No.") then
                                    PostingDate := SalesCrMemoHeader."Posting Date";
                                ReverseAmounts := true;
                            end;
                        9: // Posted Return Receipt
                            if SalesLine.Get("Document Type", "Document No.", "Line No.") then begin
                                LineDescription := SalesLine.Description;
                                LineType := SalesLine.Type.AsInteger();
                                if SalesHeader.Get("Document Type", "Document No.") then
                                    PostingDate := SalesHeader."Posting Date";
                                ReverseAmounts := true;
                            end;
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

                    DocumentTypeString := ReturnSalesDocTypeString("Document Type");
                    if ReverseAmounts then begin
                        AmtRecognized := -AmtRecognized;
                        RemainingAmtDeferred := -RemainingAmtDeferred;
                        "Amount to Defer (LCY)" := -"Amount to Defer (LCY)";
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
        AboutTitle = 'About Deferral Summary - Sales';
        AboutText = 'Track recognition of deferred sales revenue. Use this report when analyzing how sales-related revenue is deferred across accounting periods and to reconcile revenue deferral balances.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPageperCustomer; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer''s information is printed on a new page if you have chosen two or more customers to be included in the report.';
                    }
                    field(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Balance as of:';
                        ToolTip = 'Specifies the date up to which you want to see deferred revenues.';
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
            Caption = 'Deferral Summary Sales Excel';
            Type = Excel;
            LayoutFile = './Finance/Deferral/DeferralSummarySales.xlsx';
        }
        layout(Word)
        {
            Caption = 'Deferral Summary Sales Word';
            Type = Word;
            LayoutFile = './Finance/Deferral/DeferralSummarySales.docx';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Deferral Summary Sales RDLC';
            Type = RDLC;
            LayoutFile = './Finance/Deferral/DeferralSummarySales.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DeferralSummarySalesLabel = 'Deferral Summary Sales';
        DeferralSummarySalesPrint = 'Deferral Summary Sales (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DefSummarySalesAnalysis = 'Def. Summary Sales (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
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
        LineNoCaption = 'Line No.';
        CustNoCaption = 'Customer No.';
        CustNameCaption = 'Customer Name';
        LineDescCaption = 'Line Description';
        LineTypeCaption = 'Line Type';
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustomerFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
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
        GLFilter: Text;
        CustomerFilter: Text;
        DocumentFilter: Text;
        PrintOnlyOnePerPage: Boolean;
        PageGroupNo: Integer;
        BalanceAsOfDateFilter: Date;
        PostingDate: Date;
        AmtRecognized: Decimal;
        RemainingAmtDeferred: Decimal;
        AccountName: Text[100];
        CustName: Text[100];
        WorkingCustomer: Code[20];
        PreviousCustomer: Code[20];
        DeferralAccount: Code[20];
        DocumentTypeString: Text;
        HideZeroRemainingAmounts: Boolean;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        LineCount: Integer;
        QuoteLbl: Label 'Quote';
        OrderLbl: Label 'Order';
        InvoiceLbl: Label 'Invoice';
        CreditMemoLbl: Label 'Credit Memo';
        BlanketOrderLbl: Label 'Blanket Order';
        ReturnOrderLbl: Label 'Return Order';
        ShipmentLbl: Label 'Shipment';
        PostedInvoiceLbl: Label 'Posted Invoice';
        PostedCreditMemoLbl: Label 'Posted Credit Memo';
        PostedReturnReceiptLbl: Label 'Posted Return Receipt';
        LineDescription: Text[100];
        LineType: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        SumAmtRecognized: Decimal;
        SumRemainingAmtDeferred: Decimal;
        SumTotalAmtDeferred: Decimal;
        // RDLC Only layout field captions. To be removed in a future release along with the RDLC layout.
        PageCaptionLbl: Label 'Page';
        BalanceCaptionLbl: Label 'This also includes general ledger accounts that only have a balance.';
        PeriodCaptionLbl: Label 'This report also includes closing entries within the period.';
        GLBalCaptionLbl: Label 'Balance';
        DeferralSummarySalesCaptionLbl: Label 'Deferral Summary - Sales';
        RemAmtDefCaptionLbl: Label 'Remaining Amt. Deferred';
        TotAmtDefCaptionLbl: Label 'Total Amt. Deferred';
        BalanceAsOfDateCaptionLbl: Label 'Balance as of: ';
        AccountNoLbl: Label 'Account No.';
        AmtRecognizedLbl: Label 'Amt. Recognized';
        DocumentCaptionLbl: Label 'Document:';
        CustomerCaptionLbl: Label 'Customer:';

    /// <summary>
    /// Initializes report parameters for the sales deferral summary report.
    /// </summary>
    /// <param name="NewPrintOnlyOnePerPage">Whether to print each customer on a separate page</param>
    /// <param name="NewBalanceAsOfDateFilter">Balance as of date filter for calculations</param>
    /// <param name="NewDocumentNoFilter">Document number filter to apply</param>
    /// <param name="NewCustomerNoFilter">Customer number filter to apply</param>
    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewBalanceAsOfDateFilter: Date; NewDocumentNoFilter: Text; NewCustomerNoFilter: Text)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        BalanceAsOfDateFilter := NewBalanceAsOfDateFilter;
        CustomerFilter := NewCustomerNoFilter;
        DocumentFilter := NewDocumentNoFilter;
    end;

    local procedure ReturnSalesDocTypeString(SalesDocType: Integer): Text
    begin
        case SalesDocType of
            0:
                exit(QuoteLbl);
            1:
                exit(OrderLbl);
            2:
                exit(InvoiceLbl);
            3:
                exit(CreditMemoLbl);
            4:
                exit(BlanketOrderLbl);
            5:
                exit(ReturnOrderLbl);
            6:
                exit(ShipmentLbl);
            7:
                exit(PostedInvoiceLbl);
            8:
                exit(PostedCreditMemoLbl);
            9:
                exit(PostedReturnReceiptLbl);
            else
                exit('');
        end;
    end;
}