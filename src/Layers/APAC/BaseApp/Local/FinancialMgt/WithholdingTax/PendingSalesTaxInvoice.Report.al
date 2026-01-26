// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Sales.History;

report 28070 "Pending Sales Tax Invoice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/PendingSalesTaxInvoice.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Pending Sales Tax Invoice';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = sorting("Tax Document Type", "Bill-to Customer No.", "Currency Code", "Payment Discount %", "Printed Tax Document", "Posted Tax Document") where("Posted Tax Document" = filter(false));
            RequestFilterFields = "Tax Date Filter", "Tax Document Type", "Bill-to Customer No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(FooterPrinted; FooterPrinted)
            {
            }
            column(Sales_Invoice_Header__Printed_Tax_Document_; "Printed Tax Document")
            {
            }
            column(Sales_Invoice_Header__Bill_to_Customer_No__; "Bill-to Customer No.")
            {
            }
            column(LastFieldNo; LastFieldNo)
            {
            }
            column(Sales_Invoice_Header__No__; "No.")
            {
            }
            column(Sales_Invoice_Header_Amount; Amount)
            {
            }
            column(Sales_Invoice_Header__Amount_Including_VAT_; "Amount Including VAT")
            {
            }
            column(Sales_Invoice_Header__Bill_to_Customer_No___Control1500024; "Bill-to Customer No.")
            {
            }
            column(Sales_Invoice_Header__Bill_to_Name_; "Bill-to Name")
            {
            }
            column(Sales_Invoice_Header__Payment_Discount___; "Payment Discount %")
            {
            }
            column(Sales_Invoice_Header__Currency_Code_; "Currency Code")
            {
            }
            column(Sales_Invoice_Header__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(Sales_Invoice_Header__Printed_Tax_Document__Control1500029; "Printed Tax Document")
            {
            }
            column(Sales_Invoice_Header__Posted_Tax_Document_; "Posted Tax Document")
            {
            }
            column(Sales_Invoice_Header__Tax_Document_Marked_; "Tax Document Marked")
            {
            }
            column(TotalFor___FIELDCAPTION__Bill_to_Customer_No___; TotalFor + FieldCaption("Bill-to Customer No."))
            {
            }
            column(Sales_Invoice_Header_Amount_Control1500033; Amount)
            {
            }
            column(Sales_Invoice_Header__Amount_Including_VAT__Control1500034; "Amount Including VAT")
            {
            }
            column(TotalFor___FIELDCAPTION__Printed_Tax_Document__; TotalFor + FieldCaption("Printed Tax Document"))
            {
            }
            column(Sales_Invoice_Header_Amount_Control1500036; Amount)
            {
            }
            column(Sales_Invoice_Header__Amount_Including_VAT__Control1500037; "Amount Including VAT")
            {
            }
            column(Sales_Invoice_Header_Tax_Document_Type; "Tax Document Type")
            {
            }
            column(Pending_Sales_Tax_InvoiceCaption; Pending_Sales_Tax_InvoiceCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Sales_Invoice_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Sales_Invoice_Header_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Sales_Invoice_Header__Amount_Including_VAT_Caption; FieldCaption("Amount Including VAT"))
            {
            }
            column(Sales_Invoice_Header__Bill_to_Customer_No___Control1500024Caption; FieldCaption("Bill-to Customer No."))
            {
            }
            column(Sales_Invoice_Header__Bill_to_Name_Caption; FieldCaption("Bill-to Name"))
            {
            }
            column(Sales_Invoice_Header__Payment_Discount___Caption; FieldCaption("Payment Discount %"))
            {
            }
            column(Sales_Invoice_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Sales_Invoice_Header__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
            {
            }
            column(Sales_Invoice_Header__Printed_Tax_Document__Control1500029Caption; FieldCaption("Printed Tax Document"))
            {
            }
            column(Sales_Invoice_Header__Posted_Tax_Document_Caption; FieldCaption("Posted Tax Document"))
            {
            }
            column(Sales_Invoice_Header__Tax_Document_Marked_Caption; FieldCaption("Tax Document Marked"))
            {
            }
            column(Sales_Invoice_Header__Printed_Tax_Document_Caption; FieldCaption("Printed Tax Document"))
            {
            }
            column(Sales_Invoice_Header__Bill_to_Customer_No__Caption; FieldCaption("Bill-to Customer No."))
            {
            }

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Bill-to Customer No.");
            end;
        }
    }

    requestpage
    {

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

    var
        LastFieldNo: Integer;
        FooterPrinted: Boolean;
        TotalFor: Label 'Total for ';
        Pending_Sales_Tax_InvoiceCaptionLbl: Label 'Pending Sales Tax Invoice';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

