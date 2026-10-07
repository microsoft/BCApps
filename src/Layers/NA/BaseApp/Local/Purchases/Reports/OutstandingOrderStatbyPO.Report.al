// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;

report 10094 "Outstanding Order Stat. by PO"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/OutstandingOrderStatbyPO.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Outstanding Order Stat. by PO';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Order Date";
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
            column(Text001; Text001Lbl)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(PeriodText______; PeriodText + '.')
            {
            }
            column(Purchase_Header__TABLECAPTION__________FilterString; "Purchase Header".TableCaption + ': ' + FilterString)
            {
            }
            column(Purchase_Header__No__; "No.")
            {
            }
            column(Purchase_Header__Order_Date_; "Order Date")
            {
            }
            column(Purchase_Header__Expected_Receipt_Date_; "Expected Receipt Date")
            {
            }
            column(Purchase_Header__Buy_from_Vendor_No__; "Buy-from Vendor No.")
            {
            }
            column(CurrencyCodeToPrint; CurrencyCodeToPrint)
            {
            }
            column(OutstandingExclTax__; "OutstandingExclTax$")
            {
            }
            column(Purchase_Header_Document_Type; "Document Type")
            {
            }
            column(Outstanding_Orders_StatusCaption; Outstanding_Orders_StatusCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(For_delivery_in_the_periodCaption; For_delivery_in_the_periodCaptionLbl)
            {
            }
            column(Purchase_Header__No__Caption; Purchase_Header__No__CaptionLbl)
            {
            }
            column(OutstandExclInvDisc_Control43Caption; OutstandExclInvDisc_Control43CaptionLbl)
            {
            }
            column(Purchase_Line_TypeCaption; Purchase_Line_TypeCaptionLbl)
            {
            }
            column(Purchase_Line__No__Caption; Purchase_Line__No__CaptionLbl)
            {
            }
            column(Purchase_Line_DescriptionCaption; "Purchase Line".FieldCaption(Description))
            {
            }
            column(Purchase_Line_QuantityCaption; Purchase_Line_QuantityCaptionLbl)
            {
            }
            column(Purchase_Line__Outstanding_Quantity_Caption; Purchase_Line__Outstanding_Quantity_CaptionLbl)
            {
            }
            column(BackOrderQuantityCaption; BackOrderQuantityCaptionLbl)
            {
            }
            column(Purchase_Line__Unit_Cost_Caption; "Purchase Line".FieldCaption("Unit Cost"))
            {
            }
            column(Order_Date_Caption; Order_Date_CaptionLbl)
            {
            }
            column(Expected_Date_Caption; Expected_Date_CaptionLbl)
            {
            }
            column(Vendor_Caption; Vendor_CaptionLbl)
            {
            }
            column(Control33Caption; CaptionClassTranslate('101,0,Report Total (%1)'))
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Expected Receipt Date";
                column(OutstandExclInvDisc; OutstandExclInvDisc)
                {
                }
                column(Purchase_Line_Type; Type)
                {
                }
                column(Purchase_Line__No__; "No.")
                {
                }
                column(Purchase_Line_Description; Description)
                {
                }
                column(Purchase_Line_Quantity; Quantity)
                {
                }
                column(Purchase_Line__Outstanding_Quantity_; "Outstanding Quantity")
                {
                }
                column(BackOrderQuantity; BackOrderQuantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Purchase_Line__Unit_Cost_; "Unit Cost")
                {
                }
                column(OutstandExclInvDisc_Control43; OutstandExclInvDisc)
                {
                }
                column(OutstandExclInvDisc_Control44; OutstandExclInvDisc)
                {
                }
                column(OutstandingExclTax___OutstandExclInvDisc; OutstandingExclTax - OutstandExclInvDisc)
                {
                }
                column(Purchase_Order______Purchase_Header___No_______Total_; 'Purchase Order ' + "Purchase Header"."No." + ' Total')
                {
                }
                column(OutstandingExclTax; OutstandingExclTax)
                {
                }
                column(CurrencyCodeToPrint_Control1; CurrencyCodeToPrint)
                {
                }
                column(Purchase_Line_Document_Type; "Document Type")
                {
                }
                column(Purchase_Line_Document_No_; "Document No.")
                {
                }
                column(Purchase_Line_Line_No_; "Line No.")
                {
                }
                column(Balance_ForwardCaption; Balance_ForwardCaptionLbl)
                {
                }
                column(Balance_to_Carry_ForwardCaption; Balance_to_Carry_ForwardCaptionLbl)
                {
                }
                column(Invoice_DiscountCaption; Invoice_DiscountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Expected Receipt Date" <= WorkDate() then
                        BackOrderQuantity := "Outstanding Quantity"
                    else
                        BackOrderQuantity := 0;

                    OutstandingExclTax := Round("Outstanding Quantity" * "Line Amount" / Quantity);
                    if "Outstanding Amount" = 0 then
                        "OutstandingExclTax$" := 0
                    else
                        "OutstandingExclTax$" := Round(OutstandingExclTax * "Outstanding Amount (LCY)" / "Outstanding Amount");
                    OutstandExclInvDisc := Round("Outstanding Quantity" * "Unit Cost");
                end;

                trigger OnPreDataItem()
                begin
                    Clear(OutstandExclInvDisc);
                    Clear(OutstandingExclTax);
                    Clear("OutstandingExclTax$");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Currency Code" <> '' then
                    CurrencyCodeToPrint := Text000 + ' ' + "Currency Code"
                else
                    CurrencyCodeToPrint := '';
            end;

            trigger OnPreDataItem()
            begin
                Clear("OutstandingExclTax$");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
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
        FilterString := "Purchase Header".GetFilters();
        PeriodText := "Purchase Line".GetFilter("Expected Receipt Date");
        CompanyInformation.Get();
    end;

    var
        FilterString: Text;
        PeriodText: Text;
        CurrencyCodeToPrint: Text[20];
        OutstandExclInvDisc: Decimal;
        OutstandingExclTax: Decimal;
        "OutstandingExclTax$": Decimal;
        BackOrderQuantity: Decimal;
        CompanyInformation: Record "Company Information";
        Text000: Label 'Currency:';
        Text001Lbl: Label '(by Purchase Order Number)';
        Outstanding_Orders_StatusCaptionLbl: Label 'Outstanding Orders Status';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        For_delivery_in_the_periodCaptionLbl: Label 'For delivery in the period';
        Purchase_Header__No__CaptionLbl: Label 'P.O. Number';
        OutstandExclInvDisc_Control43CaptionLbl: Label 'Remaining Amount';
        Purchase_Line_TypeCaptionLbl: Label 'Item Type';
        Purchase_Line__No__CaptionLbl: Label 'Item';
        Purchase_Line_QuantityCaptionLbl: Label 'Ordered';
        Purchase_Line__Outstanding_Quantity_CaptionLbl: Label 'Quantity Remaining';
        BackOrderQuantityCaptionLbl: Label 'Back Ordered';
        Order_Date_CaptionLbl: Label 'Order Date:';
        Expected_Date_CaptionLbl: Label 'Expected Date:';
        Vendor_CaptionLbl: Label 'Vendor:';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Balance_to_Carry_ForwardCaptionLbl: Label 'Balance to Carry Forward';
        Invoice_DiscountCaptionLbl: Label 'Invoice Discount';
}

