// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Reports;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.ledger;
using System.Utilities;

report 915 "Assemble to Order - Sales"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Assembly/Reports/AssembletoOrderSales.rdlc';
    AdditionalSearchTerms = 'kit to order,kit sale';
    ApplicationArea = Assembly;
    Caption = 'Assemble to Order - Sales';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Inventory Posting Group", "Date Filter";
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Item No.", "Entry Type") where("Entry Type" = const(Sale));

                trigger OnAfterGetRecord()
                begin
                    TempATOSalesBuffer.UpdateBufferWithItemLedgEntry("Item Ledger Entry", not "Assemble to Order");
                end;

                trigger OnPreDataItem()
                begin
                    ItemFilters.CopyFilter("Date Filter", "Posting Date");
                end;
            }

            trigger OnPreDataItem()
            begin
                ItemFilters.Copy(Item);
                Reset();
            end;
        }
        dataitem(ATOConsumptionLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            trigger OnAfterGetRecord()
            begin
                if not FindNextRecord(TempATOSalesBuffer, Number) then
                    CurrReport.Break();

                if TempVisitedAsmHeader.Get(TempVisitedAsmHeader."Document Type"::Order, TempATOSalesBuffer."Order No.") then
                    CurrReport.Skip();
                TempVisitedAsmHeader."Document Type" := TempVisitedAsmHeader."Document Type"::Order;
                TempVisitedAsmHeader."No." := TempATOSalesBuffer."Order No.";
                TempVisitedAsmHeader.Insert();

                if TempATOSalesBuffer."Order No." <> '' then begin
                    TempATOSalesBuffer.Delete();
                    FetchAsmComponents(TempCompATOSalesBuffer, TempATOSalesBuffer."Order No.");
                    ConvertAsmComponentsToSale(TempATOSalesBuffer, TempCompATOSalesBuffer, TempATOSalesBuffer."Profit %");
                end;
            end;

            trigger OnPreDataItem()
            begin
                TempATOSalesBuffer.Reset();

                TempATOSalesBuffer.SetRange(Type, TempATOSalesBuffer.Type::Sale);
            end;
        }
        dataitem(Item2; Item)
        {
            DataItemTableView = sorting("No.");
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTABLECAPTION_ItemFilter; TableCaption + ': ' + ItemFilters.GetFilters)
            {
            }
            column(Item_No; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(ShowChartAs; ShowChartAs)
            {
            }
            column(ChartTitle; StrSubstNo(Text000, SelectStr(ShowChartAs + 1, ShowChartAsTxt)))
            {
            }
            column(ItemHasAsmDetails; ItemHasAsmDetails)
            {
            }
            column(ShowAsmDetails; ShowAsmDetails)
            {
            }
            dataitem(ATOSalesBuffer; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(ParentItemNo; TempATOSalesBuffer."Parent Item No.")
                {
                }
                column(Quantity; TempATOSalesBuffer.Quantity)
                {
                }
                column(SalesCost; TempATOSalesBuffer."Sales Cost")
                {
                }
                column(SalesAmt; TempATOSalesBuffer."Sales Amount")
                {
                }
                column(ProfitPct; TempATOSalesBuffer."Profit %")
                {
                }
                column(Type; TempATOSalesBuffer.Type)
                {
                    OptionCaption = ',Sales,Directly,Assembly,In Assembly';
                    OptionMembers = ,Sale,"Total Sale",Assembly,"Total Assembly";
                }

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                begin
                    if not FindNextRecord(TempATOSalesBuffer, Number) then
                        CurrReport.Break();
                    if TempATOSalesBuffer."Parent Item No." <> '' then begin
                        Item.Get(TempATOSalesBuffer."Parent Item No.");
                        TempATOSalesBuffer."Parent Description" := Item.Description;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempATOSalesBuffer.Reset();
                TempATOSalesBuffer.SetRange("Item No.", "No.");
                TempATOSalesBuffer.SetRange(Quantity, 0);
                TempATOSalesBuffer.DeleteAll();
                TempATOSalesBuffer.SetRange(Quantity);
                if TempATOSalesBuffer.IsEmpty() then
                    CurrReport.Skip();

                TempATOSalesBuffer.SetRange(Type, TempATOSalesBuffer.Type::Assembly);

                ItemHasAsmDetails := not TempATOSalesBuffer.IsEmpty();
                if not ShowAsmDetails then
                    TempATOSalesBuffer.DeleteAll();

                if not (ItemHasAsmDetails or IsInBOMComp("No.")) then
                    CurrReport.Skip();

                TempATOSalesBuffer.SetRange(Type);
            end;

            trigger OnPreDataItem()
            begin
                Copy(ItemFilters);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Assemble to Order - Sales';
        AboutText = 'Analyze the quantity, cost, sales, and profit figures of assembly components. For example, decide whether to price a kit differently or stop or start using an item in assemblies.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowAsmDetails; ShowAsmDetails)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Show Assembly Details';
                        ToolTip = 'Specifies if you want to expand the In Assembly row to show the same figures for each parent item where the assembly component was sold.';
                    }
                    field(ShowChartAs; ShowChartAs)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Show Chart as';
                        OptionCaption = 'Quantity,Sales,Profit %';
                        ToolTip = 'Specifies which figures to show graphically in the report. The following options exist - Quantity, Sales, or Profit %.';
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
        Report_Caption = 'Assemble to Order - Sales';
        PageNo_Caption = 'Page';
        SoldQuantity_Caption = 'Total Sold';
        CostOfSale_Caption = 'Cost of Sale';
        SalesAmount_Caption = 'Sales Amount';
        ProfitPct_Caption = 'Profit %';
        ParentItemNo_Caption = 'Parent Item No.';
        Quantity_Caption = 'Quantity';
        ItemNo_Caption = 'Item No.';
        Description_Caption = 'Description';
    }

    trigger OnPreReport()
    begin
        TempATOSalesBuffer.Reset();
        TempATOSalesBuffer.DeleteAll();
    end;

    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        TempVisitedAsmHeader: Record "Assembly Header" temporary;
        TempCompATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        ItemFilters: Record Item;
        ShowChartAs: Option Quantity,Sales,"Profit %";
        ShowAsmDetails: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Show as %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemHasAsmDetails: Boolean;
        ShowChartAsTxt: Label 'Quantity,Sales,Profit %';

    procedure InitializeRequest(NewShowChartAs: Option; NewShowAsmDetails: Boolean)
    begin
        ShowChartAs := NewShowChartAs;
        ShowAsmDetails := NewShowAsmDetails;
    end;

    local procedure FetchAsmComponents(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; AsmOrderNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
        ItemLedgEntry.SetRange("Order No.", AsmOrderNo);
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::"Assembly Consumption" then
                    TempATOSalesBuffer.UpdateBufferWithItemLedgEntry(ItemLedgEntry, false);
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure ConvertAsmComponentsToSale(var ToATOSalesBuffer: Record "ATO Sales Buffer"; var FromCompATOSalesBuffer: Record "ATO Sales Buffer"; ProfitPct: Decimal)
    var
        CopyOfATOSalesBuffer: Record "ATO Sales Buffer";
    begin
        CopyOfATOSalesBuffer.Copy(ToATOSalesBuffer);
        ToATOSalesBuffer.Reset();

        FromCompATOSalesBuffer.Reset();
        if FromCompATOSalesBuffer.Find('-') then
            repeat
                ToATOSalesBuffer.UpdateBufferWithComp(FromCompATOSalesBuffer, ProfitPct, false);
                ToATOSalesBuffer.UpdateBufferWithComp(FromCompATOSalesBuffer, ProfitPct, true);
            until FromCompATOSalesBuffer.Next() = 0;
        FromCompATOSalesBuffer.DeleteAll();

        ToATOSalesBuffer.Copy(CopyOfATOSalesBuffer);
    end;

    local procedure IsInBOMComp(ItemNo: Code[20]): Boolean
    var
        BOMComponent: Record "BOM Component";
        ParentItem: Record Item;
    begin
        BOMComponent.SetCurrentKey(Type, "No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.SetRange("No.", ItemNo);
        if BOMComponent.FindSet() then
            repeat
                ParentItem.Get(BOMComponent."Parent Item No.");
                if ParentItem."Assembly Policy" = ParentItem."Assembly Policy"::"Assemble-to-Order" then
                    exit(true);
            until BOMComponent.Next() = 0;
    end;

    local procedure FindNextRecord(var ATOSalesBuffer: Record "ATO Sales Buffer"; Position: Integer): Boolean
    begin
        if Position = 1 then
            exit(ATOSalesBuffer.FindSet());
        exit(ATOSalesBuffer.Next() <> 0);
    end;
}

