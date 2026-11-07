// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 10133 "Back Order Fill by Item"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/BackOrderFillbyItem.rdlc';
    Caption = 'Back Order Fill by Item';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group", "Statistics Group", "Location Filter";
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
            column(ItemFilter; ItemFilter)
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Sales_Line__TABLECAPTION__________SalesLineFilter; "Sales Line".TableCaption + ': ' + SalesLineFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item_Inventory; Inventory)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Item_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Back_Order_Fill_by_ItemCaption; Back_Order_Fill_by_ItemCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Sales_Line__Document_No__Caption; "Sales Line".FieldCaption("Document No."))
            {
            }
            column(Cust_NameCaption; Cust_NameCaptionLbl)
            {
            }
            column(Cust__Phone_No__Caption; Cust__Phone_No__CaptionLbl)
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
            column(OtherBackOrdersCaption; OtherBackOrdersCaptionLbl)
            {
            }
            column(Sales_Line__Sell_to_Customer_No__Caption; "Sales Line".FieldCaption("Sell-to Customer No."))
            {
            }
            column(Item__No__Caption; Item__No__CaptionLbl)
            {
            }
            column(Item_InventoryCaption; FieldCaption(Inventory))
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where(Type = const(Item), "Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(Sales_Line__Document_No__; "Document No.")
                {
                }
                column(Cust_Name; Cust.Name)
                {
                }
                column(Cust__Phone_No__; Cust."Phone No.")
                {
                }
                column(Sales_Line__Shipment_Date_; "Shipment Date")
                {
                }
                column(Sales_Line_Quantity; Quantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Sales_Line__Outstanding_Quantity_; "Outstanding Quantity")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OtherBackOrders; OtherBackOrders)
                {
                }
                column(Sales_Line__Sell_to_Customer_No__; "Sell-to Customer No.")
                {
                }
                column(Text000_________FIELDCAPTION__Outstanding_Quantity__; Text000 + ' ' + FieldCaption("Outstanding Quantity"))
                {
                }
                column(Sales_Line__Outstanding_Quantity__Control26; "Outstanding Quantity")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Item__No___Control29; Item."No.")
                {
                }
                column(Sales_Line_Document_Type; "Document Type")
                {
                }
                column(Sales_Line_Line_No_; "Line No.")
                {
                }
                column(Sales_Line_No_; "No.")
                {
                }
                column(Sales_Line_Location_Code; "Location Code")
                {
                }
                column(Sales_Line_Variant_Code; "Variant Code")
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
                    Cust.Get("Sell-to Customer No.");

                    SalesOrderLine.Copy("Sales Line");
                    SalesOrderLine.SetRange("Sell-to Customer No.", Cust."No.");
                    SalesOrderLine.SetFilter("No.", '<>' + Item."No.");
                    OtherBackOrders := SalesOrderLine.FindFirst();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Inventory);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, WorkDate() - 1);
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
    end;

    var
        Cust: Record Customer;
        SalesOrderLine: Record "Sales Line";
        CompanyInformation: Record "Company Information";
        OtherBackOrders: Boolean;
        ItemFilter: Text;
        SalesLineFilter: Text;
        Text000: Label 'Item Total';
        Back_Order_Fill_by_ItemCaptionLbl: Label 'Back Order Fill by Item';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Cust_NameCaptionLbl: Label 'Customer Name';
        Cust__Phone_No__CaptionLbl: Label 'Phone No.';
        OtherBackOrdersCaptionLbl: Label 'Other Back Orders';
        Item__No__CaptionLbl: Label 'Item No.';
}

