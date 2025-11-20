// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 714 "Inventory - Vendor Purchases"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryVendorPurchases.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Vendor Purchases';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReportHeader; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(0));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
        }
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "No. 2", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(No_Item; "No.")
            {
            }
            column(Desc_Item; Description)
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Source Type", "Source No.", "Item No.") where("Source Type" = const(Vendor), "Expected Cost" = const(false));
                RequestFilterFields = "Posting Date", "Source No.", "Source Posting Group";

                trigger OnAfterGetRecord()
                begin
                    FillTempValueEntry("Value Entry");

                    CurrReport.Skip();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(> 0));
                column(SourceNo_ValueEntry; TempValueEntry."Source No.")
                {
                }
                column(VendName; Vendor.Name)
                {
                }
                column(InvQty_ValueEntry; TempValueEntry."Invoiced Quantity")
                {
                    IncludeCaption = true;
                }
                column(CostAmtAct_ValueEntry; TempValueEntry."Cost Amount (Actual)")
                {
                    IncludeCaption = true;
                }
                column(DiscAmt_ValueEntry; TempValueEntry."Discount Amount")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    TempValueEntry.SetRange("Source No.");

                    if Number = 1 then
                        TempValueEntry.FindSet()
                    else
                        if TempValueEntry.Next() = 0 then
                            CurrReport.Break();

                    if not Vendor.Get(TempValueEntry."Source No.") then
                        Clear(Vendor);
                end;

                trigger OnPreDataItem()
                begin
                    if TempValueEntry.IsEmpty() then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempValueEntry.DeleteAll();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Vendor Purchases';
        AboutText = 'Analyse your vendor purchases per item to manage inventory procurement and improve supply chain processes. Assess the relationship between discounts, cost amount with volume of item purchases for each vendor/item combination in the given period.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        PageCaption = 'Page';
        ReportTitle = 'Inventory - Vendor Purchases';
        VendorNoCaption = 'Vendor No.';
        NameCaption = 'Name';
        TotalCaption = 'Total';
    }

    trigger OnPreReport()
    begin
        ItemFilter := GetTableFilters(Item.TableCaption(), Item.GetFilters);
        ItemLedgEntryFilter := GetTableFilters("Value Entry".TableCaption(), "Value Entry".GetFilters);
        PeriodText := StrSubstNo(PeriodInfoTxt, "Value Entry".GetFilter("Posting Date"));
    end;

    var
        Vendor: Record Vendor;
        TempValueEntry: Record "Value Entry" temporary;
        PeriodText: Text;
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;

        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;

    local procedure FillTempValueEntry(ValueEntry: Record "Value Entry")
    begin
        TempValueEntry.SetRange("Source No.", ValueEntry."Source No.");
        if not TempValueEntry.FindSet() then begin
            TempValueEntry.Init();
            TempValueEntry := "Value Entry";
            TempValueEntry.Insert();
        end else begin
            TempValueEntry."Cost Amount (Actual)" := TempValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Actual)";
            TempValueEntry."Invoiced Quantity" := TempValueEntry."Invoiced Quantity" + ValueEntry."Invoiced Quantity";
            TempValueEntry."Discount Amount" := TempValueEntry."Discount Amount" + ValueEntry."Discount Amount";
            TempValueEntry.Modify();
        end;
    end;

    local procedure GetTableFilters(TableName: Text; Filters: Text): Text
    begin
        if Filters <> '' then
            exit(StrSubstNo(TableFiltersTxt, TableName, Filters));
        exit('');
    end;
}

