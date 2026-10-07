// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;

report 10100 "Purchaser Stat. by Invoice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/PurchaserStatbyInvoice.rdlc';
    ApplicationArea = Suite;
    Caption = 'Purchaser Stat. by Invoice';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code", "Date Filter";
            RequestFilterHeading = 'Purchaser';
            column(Purchaser_Statistics_by_Invoice_; 'Purchaser Statistics by Invoice')
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(For_the_period_____PeriodText; 'For the period ' + PeriodText)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(Document_Number_is______Vendor_Ledger_Entry__FIELDCAPTION__External_Document_No___; 'Document Number is ' + "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(UseExternalDocNo; UseExternalDocNo)
            {
            }
            column(TABLECAPTION__________FilterString; TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Salesperson_Purchaser_Code; Code)
            {
            }
            column(Salesperson_Purchaser_Name; Name)
            {
            }
            column(Vendor_Ledger_Entry___Inv__Discount__LCY__; -"Vendor Ledger Entry"."Inv. Discount (LCY)")
            {
            }
            column(Vendor_Ledger_Entry___Purchase__LCY__; -"Vendor Ledger Entry"."Purchase (LCY)")
            {
            }
            column(Vendor_Ledger_Entry___Amount__LCY__; -"Vendor Ledger Entry"."Amount (LCY)")
            {
            }
            column(Vendor_Ledger_Entry___Pmt__Disc__Rcd__LCY__; -"Vendor Ledger Entry"."Pmt. Disc. Rcd.(LCY)")
            {
            }
            column(Payment_Credits_; -"Payment&Credits")
            {
            }
            column(Vendor_Ledger_Entry___Remaining_Amt___LCY__; -"Vendor Ledger Entry"."Remaining Amt. (LCY)")
            {
            }
            column(Salesperson_Purchaser_Date_Filter; "Date Filter")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(PurchaserCaption; PurchaserCaptionLbl)
            {
            }
            column(InvoiceCaption; InvoiceCaptionLbl)
            {
            }
            column(Total_InvoiceCaption; Total_InvoiceCaptionLbl)
            {
            }
            column(Pay_DiscountCaption; Pay_DiscountCaptionLbl)
            {
            }
            column(Payments__Caption; Payments__CaptionLbl)
            {
            }
            column(RemainingCaption; RemainingCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; "Vendor Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Inv__Discount__LCY__Caption; Inv__Discount__LCY__CaptionLbl)
            {
            }
            column(Purchase__LCY__Caption; Purchase__LCY__CaptionLbl)
            {
            }
            column(Amount__LCY__Caption; Amount__LCY__CaptionLbl)
            {
            }
            column(Pmt__Disc__Rcd__LCY__Caption; Pmt__Disc__Rcd__LCY__CaptionLbl)
            {
            }
            column(Payment_Credits__Control50Caption; Payment_Credits__Control50CaptionLbl)
            {
            }
            column(Remaining_Amt___LCY__Caption; Remaining_Amt___LCY__CaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; Vendor_Ledger_Entry__Vendor_No__CaptionLbl)
            {
            }
            column(Salesperson_Purchaser__Code_Control60Caption; Salesperson_Purchaser__Code_Control60CaptionLbl)
            {
            }
            column(Salesperson_Purchaser__NameCaption; Salesperson_Purchaser__NameCaptionLbl)
            {
            }
            column(Inv__Discount__LCY___Control62Caption; Inv__Discount__LCY___Control62CaptionLbl)
            {
            }
            column(Purchase__LCY___Control63Caption; Purchase__LCY___Control63CaptionLbl)
            {
            }
            column(Amount__LCY___Control64Caption; Amount__LCY___Control64CaptionLbl)
            {
            }
            column(Payment_Credits__Control66Caption; Payment_Credits__Control66CaptionLbl)
            {
            }
            column(Remaining_Amt___LCY___Control67Caption; Remaining_Amt___LCY___Control67CaptionLbl)
            {
            }
            column(Pmt__Disc__Rcd__LCY___Control65Caption; Pmt__Disc__Rcd__LCY___Control65CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Purchaser Code" = field(Code), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Vendor No.", "Posting Date") where("Document Type" = const(Invoice));
                column(Vendor_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(DocNo; DocNo)
                {
                }
                column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
                {
                }
                column(Inv__Discount__LCY__; -"Inv. Discount (LCY)")
                {
                }
                column(Purchase__LCY__; -"Purchase (LCY)")
                {
                }
                column(Amount__LCY__; -"Amount (LCY)")
                {
                }
                column(Pmt__Disc__Rcd__LCY__; -"Pmt. Disc. Rcd.(LCY)")
                {
                }
                column(Payment_Credits__Control50; -"Payment&Credits")
                {
                }
                column(Remaining_Amt___LCY__; -"Remaining Amt. (LCY)")
                {
                }
                column(Salesperson_Purchaser__Code; "Salesperson/Purchaser".Code)
                {
                }
                column(Inv__Discount__LCY___Control53; -"Inv. Discount (LCY)")
                {
                }
                column(Purchase__LCY___Control54; -"Purchase (LCY)")
                {
                }
                column(Amount__LCY___Control55; -"Amount (LCY)")
                {
                }
                column(Pmt__Disc__Rcd__LCY___Control56; -"Pmt. Disc. Rcd.(LCY)")
                {
                }
                column(Payment_Credits__Control57; -"Payment&Credits")
                {
                }
                column(Remaining_Amt___LCY___Control58; -"Remaining Amt. (LCY)")
                {
                }
                column(Salesperson_Purchaser__Code_Control60; "Salesperson/Purchaser".Code)
                {
                }
                column(Salesperson_Purchaser__Name; "Salesperson/Purchaser".Name)
                {
                }
                column(Inv__Discount__LCY___Control62; -"Inv. Discount (LCY)")
                {
                }
                column(Purchase__LCY___Control63; -"Purchase (LCY)")
                {
                }
                column(Amount__LCY___Control64; -"Amount (LCY)")
                {
                }
                column(Pmt__Disc__Rcd__LCY___Control65; -"Pmt. Disc. Rcd.(LCY)")
                {
                }
                column(Payment_Credits__Control66; -"Payment&Credits")
                {
                }
                column(Remaining_Amt___LCY___Control67; -"Remaining Amt. (LCY)")
                {
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Vendor_Ledger_Entry_Purchaser_Code; "Purchaser Code")
                {
                }
                column(Purchaser_TotalCaption; Purchaser_TotalCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                    "Payment&Credits" := "Amount (LCY)" - "Remaining Amt. (LCY)" - "Pmt. Disc. Rcd.(LCY)";
                    if UseExternalDocNo then
                        DocNo := "External Document No."
                    else
                        DocNo := "Document No.";
                end;

                trigger OnPreDataItem()
                begin
                    Clear("Payment&Credits");
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear("Payment&Credits");
                if PrintDetail then
                    SubTitle := Text000
                else
                    SubTitle := Text001;
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
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';
                    }
                    field(UseExternalDocNo; UseExternalDocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Use External Doc. No.';
                        ToolTip = 'Specifies if you want to print the vendor''s document numbers, such as the invoice number, on all transactions. Clear this check box to print only internal document numbers.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PeriodText := "Salesperson/Purchaser".GetFilter("Date Filter");
        "Salesperson/Purchaser".SetRange("Date Filter");  // so it won't show twice on header
        FilterString := "Salesperson/Purchaser".GetFilters();
        CompanyInformation.Get();
    end;

    var
        FilterString: Text;
        SubTitle: Text[88];
        PeriodText: Text;
        PrintDetail: Boolean;
        "Payment&Credits": Decimal;
        CompanyInformation: Record "Company Information";
        UseExternalDocNo: Boolean;
        DocNo: Code[50];
        Text000: Label '(Detail)';
        Text001: Label '(Summary)';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        PurchaserCaptionLbl: Label 'Purchaser';
        InvoiceCaptionLbl: Label 'Invoice';
        Total_InvoiceCaptionLbl: Label 'Total Invoice';
        Pay_DiscountCaptionLbl: Label 'Pay Discount';
        Payments__CaptionLbl: Label 'Payments &';
        RemainingCaptionLbl: Label 'Remaining';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Type';
        Inv__Discount__LCY__CaptionLbl: Label 'Discount';
        Purchase__LCY__CaptionLbl: Label 'Purchases';
        Amount__LCY__CaptionLbl: Label 'Amount';
        Pmt__Disc__Rcd__LCY__CaptionLbl: Label 'Taken';
        Payment_Credits__Control50CaptionLbl: Label 'Other Credits';
        Remaining_Amt___LCY__CaptionLbl: Label 'Balance';
        DocNoCaptionLbl: Label 'Document No.';
        Vendor_Ledger_Entry__Vendor_No__CaptionLbl: Label 'Vendor';
        Salesperson_Purchaser__Code_Control60CaptionLbl: Label 'Code';
        Salesperson_Purchaser__NameCaptionLbl: Label 'Name';
        Inv__Discount__LCY___Control62CaptionLbl: Label 'Discount';
        Purchase__LCY___Control63CaptionLbl: Label 'Purchases';
        Amount__LCY___Control64CaptionLbl: Label 'Amount';
        Payment_Credits__Control66CaptionLbl: Label 'Other Credits';
        Remaining_Amt___LCY___Control67CaptionLbl: Label 'Balance';
        Pmt__Disc__Rcd__LCY___Control65CaptionLbl: Label 'Taken';
        Report_TotalCaptionLbl: Label 'Report Total';
        Purchaser_TotalCaptionLbl: Label 'Purchaser Total';
}

