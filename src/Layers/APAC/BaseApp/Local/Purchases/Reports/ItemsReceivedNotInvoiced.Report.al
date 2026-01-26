// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Document;

report 17111 "Items Received & Not Invoiced"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/ItemsReceivedNotInvoiced.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Items Received & Not Invoiced';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "Buy-from Vendor No.", "No.") where("Document Type" = const(Order));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Buy-from Vendor No.", "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Purchase_Header__No__; "No.")
            {
            }
            column(Purchase_Header__Pay_to_Vendor_No__; "Pay-to Vendor No.")
            {
            }
            column(Purchase_Header__Pay_to_Name_; "Pay-to Name")
            {
            }
            column(Purchase_Header_Document_Type; "Document Type")
            {
            }
            column(Items_Received_and_not_yet_InvoicedCaption; Items_Received_and_not_yet_InvoicedCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Purchase_Header__Pay_to_Vendor_No__Caption; FieldCaption("Pay-to Vendor No."))
            {
            }
            column(Purchase_Header__Pay_to_Name_Caption; FieldCaption("Pay-to Name"))
            {
            }
            column(Purchase_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Purchase_Line__No__Caption; "Purchase Line".FieldCaption("No."))
            {
            }
            column(Purchase_Line_DescriptionCaption; "Purchase Line".FieldCaption(Description))
            {
            }
            column(Purchase_Line__Quantity_Received_Caption; "Purchase Line".FieldCaption("Quantity Received"))
            {
            }
            column(Purchase_Line__Quantity_Invoiced_Caption; "Purchase Line".FieldCaption("Quantity Invoiced"))
            {
            }
            column(Purchase_Line_QuantityCaption; "Purchase Line".FieldCaption(Quantity))
            {
            }
            column(Purchase_Line__Qty__Rcd__Not_Invoiced_Caption; "Purchase Line".FieldCaption("Qty. Rcd. Not Invoiced"))
            {
            }
            column(Purchase_Line__Amt__Rcd__Not_Invoiced_Caption; "Purchase Line".FieldCaption("Amt. Rcd. Not Invoiced"))
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Qty. Rcd. Not Invoiced" = filter(> 0));
                column(Purchase_Line__No__; "No.")
                {
                }
                column(Purchase_Line_Description; Description)
                {
                }
                column(Purchase_Line__Quantity_Received_; "Quantity Received")
                {
                }
                column(Purchase_Line__Quantity_Invoiced_; "Quantity Invoiced")
                {
                }
                column(Purchase_Line_Quantity; Quantity)
                {
                }
                column(Purchase_Line__Qty__Rcd__Not_Invoiced_; "Qty. Rcd. Not Invoiced")
                {
                }
                column(Purchase_Line__Amt__Rcd__Not_Invoiced_; AmtRcdNotInvoiced)
                {
                }
                column(Purchase_Line__Amt__Rcd__Not_Invoiced__Control33; AmtRcdNotInvoiced)
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
                column(TotalCaption; TotalCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    AmtRcdNotInvoiced := Round(Amount * "Qty. Rcd. Not Invoiced" / Quantity, Currency."Amount Rounding Precision");
                end;

                trigger OnPreDataItem()
                begin
                    if "Purchase Header"."Currency Code" = '' then
                        Currency.InitRoundingPrecision()
                    else begin
                        Currency.Get("Purchase Header"."Currency Code");
                        Currency.TestField("Amount Rounding Precision");
                    end;
                end;
            }
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
        Currency: Record Currency;
        AmtRcdNotInvoiced: Decimal;
        Items_Received_and_not_yet_InvoicedCaptionLbl: Label 'Items Received and not yet Invoiced';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
}

