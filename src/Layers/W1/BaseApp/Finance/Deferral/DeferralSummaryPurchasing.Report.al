// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

/// <summary>
/// Report that summarizes purchasing deferral activity by vendor and period.
/// Provides detailed analysis of deferred expense amounts and recognition patterns for purchase transactions.
/// </summary>
report 1702 "Deferral Summary - Purchasing"
{
    ApplicationArea = Suite;
    Caption = 'Deferral Summary - Purchasing';
#if not CLEAN27
    DefaultRenderingLayout = Word;
#else
    DefaultRenderingLayout = Excel;
#endif
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
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
            column(DeferralSummaryPurchCaption; DeferralSummaryPurchCaptionLbl)
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
            column(VendorCaption; VendorCaptionLbl + Format(VendorFilter))
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
                DataItemLinkReference = Vendor;
                DataItemTableView = sorting("Deferral Doc. Type", CustVendorNo, "Posting Date", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.") order(ascending) where("Deferral Doc. Type" = const(Purchase), CustVendorNo = filter(<> ''));
                RequestFilterFields = "Document No.";
                column(VendorFilter; VendorFilter)
                {
                }
                column(VendNo; CustVendorNo)
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
                column(VendorName; VendorName)
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
                    PurchaseHeader: Record "Purchase Header";
                    PurchaseLine: Record "Purchase Line";
                    PurchInvHeader: Record "Purch. Inv. Header";
                    PurchInvLine: Record "Purch. Inv. Line";
                    PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                    PurchCrMemoLine: Record "Purch. Cr. Memo Line";
                    ReverseAmounts: Boolean;
                    LinesFound: Boolean;
                begin
                    PreviousVendor := WorkingVendor;
                    ReverseAmounts := false;

                    if Vendor.Get(CustVendorNo) then begin
                        VendorName := Vendor.Name;
                        WorkingVendor := CustVendorNo;
                    end;

                    if (PreviousVendor <> WorkingVendor) then begin
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
                            if PurchInvLine.Get("Document No.", "Line No.") then begin
                                LineDescription := PurchInvLine.Description;
                                LineType := PurchInvLine.Type.AsInteger();
                                if PurchInvHeader.Get("Document No.") then
                                    PostingDate := PurchInvHeader."Posting Date";
                            end;
                        8: // Posted Credit Memo
                            if PurchCrMemoLine.Get("Document No.", "Line No.") then begin
                                LineDescription := PurchCrMemoLine.Description;
                                LineType := PurchCrMemoLine.Type.AsInteger();
                                if PurchCrMemoHdr.Get("Document No.") then
                                    PostingDate := PurchCrMemoHdr."Posting Date";
                                ReverseAmounts := true;
                            end;
                        9: // Posted Return Receipt
                            if PurchaseLine.Get("Document Type", "Document No.", "Line No.") then begin
                                LineDescription := PurchaseLine.Description;
                                LineType := PurchaseLine.Type.AsInteger();
                                if PurchaseHeader.Get("Document Type", "Document No.") then
                                    PostingDate := PurchaseHeader."Posting Date";
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

                    DocumentTypeString := ReturnPurchDocTypeString("Document Type");
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
        AboutTitle = 'About Deferral Summary - Purchasing';
        AboutText = 'Check deferred purchasing costs by schedule. Use this report during review of expense deferrals on purchasing transactions for accrual accuracy and to reconcile expense deferral balances.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPageperVendor; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if each vendor''s information is printed on a new page if you have chosen two or more vendors to be included in the report.';
                    }
                    field(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Balance as of:';
                        ToolTip = 'Specifies the date up to which you want to see deferred expenses.';
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
            Caption = 'Deferral Summary Purchasing Excel';
            Type = Excel;
            LayoutFile = './Finance/Deferral/DeferralSummaryPurchasing.xlsx';
        }
        layout(Word)
        {
            Caption = 'Deferral Summary Purchasing Word';
            Type = Word;
            LayoutFile = './Finance/Deferral/DeferralSummaryPurchasing.docx';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Deferral Summary Purchasing RDLC';
            Type = RDLC;
            LayoutFile = './Finance/Deferral/DeferralSummaryPurchasing.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DeferralSummaryPurchLabel = 'Deferral Summary Purchasing';
        DeferralSummaryPurchPrint = 'Deferral Summary Purch. (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DefSummaryPurchAnalysis = 'Def. Summary Purch. (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
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
        VendNoCaption = 'Vendor No.';
        VendNameCaption = 'Vendor Name';
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
        VendorFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
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
        VendorFilter: Text;
        DocumentFilter: Text;
        PrintOnlyOnePerPage: Boolean;
        PageGroupNo: Integer;
        BalanceAsOfDateFilter: Date;
        PostingDate: Date;
        AmtRecognized: Decimal;
        RemainingAmtDeferred: Decimal;
        AccountName: Text[100];
        VendorName: Text[100];
        WorkingVendor: Code[20];
        PreviousVendor: Code[20];
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
        DeferralSummaryPurchCaptionLbl: Label 'Deferral Summary - Purchasing';
        RemAmtDefCaptionLbl: Label 'Remaining Amt. Deferred';
        TotAmtDefCaptionLbl: Label 'Total Amt. Deferred';
        BalanceAsOfDateCaptionLbl: Label 'Balance as of: ';
        AccountNoLbl: Label 'Account No.';
        AmtRecognizedLbl: Label 'Amt. Recognized';
        DocumentCaptionLbl: Label 'Document:';
        VendorCaptionLbl: Label 'Vendor:';

    /// <summary>
    /// Initializes report parameters for the purchasing deferral summary report.
    /// </summary>
    /// <param name="NewPrintOnlyOnePerPage">Whether to print each vendor on a separate page</param>
    /// <param name="NewBalanceAsOfDateFilter">Balance as of date filter for calculations</param>
    /// <param name="NewDocumentNoFilter">Document number filter to apply</param>
    /// <param name="NewVendorNoFilter">Vendor number filter to apply</param>
    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewBalanceAsOfDateFilter: Date; NewDocumentNoFilter: Text; NewVendorNoFilter: Text)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        BalanceAsOfDateFilter := NewBalanceAsOfDateFilter;
        VendorFilter := NewVendorNoFilter;
        DocumentFilter := NewDocumentNoFilter;
    end;

    local procedure ReturnPurchDocTypeString(PurchDocType: Integer): Text
    begin
        case PurchDocType of
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

