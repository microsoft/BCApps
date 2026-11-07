// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 10132 "Back Order Fill by Customer"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/BackOrderFillbyCustomer.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Back Order Fill by Customer';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Name;
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
            column(CustomerFilter; CustomerFilter)
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(Customer_TABLECAPTION__________CustomerFilter; Customer.TableCaption + ': ' + CustomerFilter)
            {
            }
            column(Sales_Line__TABLECAPTION__________SalesLineFilter; "Sales Line".TableCaption + ': ' + SalesLineFilter)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(Customer_Contact; Contact)
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Back_Order_Fill_by_CustomerCaption; Back_Order_Fill_by_CustomerCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Sales_Line__Document_No__Caption; "Sales Line".FieldCaption("Document No."))
            {
            }
            column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
            {
            }
            column(Sales_Line__Shipment_Date_Caption; "Sales Line".FieldCaption("Shipment Date"))
            {
            }
            column(Sales_Line_QuantityCaption; "Sales Line".FieldCaption(Quantity))
            {
            }
            column(Sales_Line__Outstanding_Quantity_Caption; "Sales Line".FieldCaption("Outstanding Quantity"))
            {
            }
            column(Sales_Line__No__Caption; Sales_Line__No__CaptionLbl)
            {
            }
            column(Customer__No__Caption; Customer__No__CaptionLbl)
            {
            }
            column(Customer__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Customer_ContactCaption; FieldCaption(Contact))
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Sell-to Customer No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where(Type = const(Item), "Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date", "Location Code";
                RequestFilterHeading = 'Sales Order Line';
                column(Sales_Line__Document_No__; "Document No.")
                {
                }
                column(Item_Description; Item.Description)
                {
                }
                column(Sales_Line__Shipment_Date_; "Shipment Date")
                {
                }
                column(Sales_Line_Quantity; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Sales_Line__Outstanding_Quantity_; "Outstanding Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Sales_Line__No__; "No.")
                {
                }
                column(Text000_________FIELDCAPTION__Outstanding_Quantity__; Text000 + ' ' + FieldCaption("Outstanding Quantity"))
                {
                }
                column(Sales_Line__Outstanding_Quantity__Control26; "Outstanding Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Customer__No___Control29; Customer."No.")
                {
                }
                column(Sales_Line_Document_Type; "Document Type")
                {
                }
                column(Sales_Line_Line_No_; "Line No.")
                {
                }
                column(Sales_Line_Sell_to_Customer_No_; "Sell-to Customer No.")
                {
                }
                column(Sales_Line_Shortcut_Dimension_1_Code; "Shortcut Dimension 1 Code")
                {
                }
                column(Sales_Line_Shortcut_Dimension_2_Code; "Shortcut Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Shipment Date" >= WorkDate() then
                        CurrReport.Skip();
                    Item.Get("No.");
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        CustomerFilter := Customer.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
    end;

    var
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        CustomerFilter: Text;
        SalesLineFilter: Text;
        Text000: Label 'Customer Total';
        Back_Order_Fill_by_CustomerCaptionLbl: Label 'Back Order Fill by Customer';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_DescriptionCaptionLbl: Label 'Item Description';
        Sales_Line__No__CaptionLbl: Label 'Item No.';
        Customer__No__CaptionLbl: Label 'Customer No.';
}

