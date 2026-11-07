// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;

report 10160 "Serial Number Sold History"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/SerialNumberSoldHistory.rdlc';
    Caption = 'Serial Number Sold History';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where("Item Tracking Code" = filter(<> ''));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Vendor No.", "Location Filter", "Variant Filter";
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
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilterNotBlank; ItemFilter <> '')
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item_Date_Filter; "Date Filter")
            {
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
            column(Serial_Number_Sold_HistoryCaption; Serial_Number_Sold_HistoryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Source_No__Caption; "Item Ledger Entry".FieldCaption("Source No."))
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Serial_No__Caption; "Item Ledger Entry".FieldCaption("Serial No."))
            {
            }
            column(Item_Ledger_Entry__Posting_Date_Caption; "Item Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Item_Ledger_Entry__Invoiced_Quantity_Caption; "Item Ledger Entry".FieldCaption("Invoiced Quantity"))
            {
            }
            column(Item_Ledger_Entry__Sales_Amount__Actual__Caption; "Item Ledger Entry".FieldCaption("Sales Amount (Actual)"))
            {
            }
            column(Item_Ledger_Entry__Cost_Amount__Actual__Caption; "Item Ledger Entry".FieldCaption("Cost Amount (Actual)"))
            {
            }
            column(Item_Ledger_Entry__Lot_No__Caption; "Item Ledger Entry".FieldCaption("Lot No."))
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Posting Date" = field("Date Filter"), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Entry Type", "Item No.", "Variant Code", "Source Type", "Source No.", "Posting Date") where("Entry Type" = const(Sale));
                column(Item_Ledger_Entry__Source_No__; "Source No.")
                {
                }
                column(Customer_Name; Customer.Name)
                {
                }
                column(Item_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Item_Ledger_Entry__Invoiced_Quantity_; "Invoiced Quantity")
                {
                }
                column(Item_Ledger_Entry__Sales_Amount__Actual__; "Sales Amount (Actual)")
                {
                }
                column(Item_Ledger_Entry__Cost_Amount__Actual__; "Cost Amount (Actual)")
                {
                }
                column(Item_Ledger_Entry__Lot_No__; "Lot No.")
                {
                }
                column(Item_Ledger_Entry__Serial_No__; "Serial No.")
                {
                }
                column(Item_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Item_Ledger_Entry_Item_No_; "Item No.")
                {
                }
                column(Item_Ledger_Entry_Location_Code; "Location Code")
                {
                }
                column(Item_Ledger_Entry_Variant_Code; "Variant Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Customer.Get("Source No.") then
                        Customer.Init();
                    CalcFields("Cost Amount (Actual)", "Sales Amount (Actual)");
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
        ItemFilter := Item.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        ItemFilter: Text;
        Serial_Number_Sold_HistoryCaptionLbl: Label 'Serial Number Sold History';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customer_NameCaptionLbl: Label 'Customer Name';
}

