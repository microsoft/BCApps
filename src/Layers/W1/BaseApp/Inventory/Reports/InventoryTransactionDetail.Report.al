// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 704 "Inventory - Transaction Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryTransactionDetail.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Transaction Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Description, "Assembly BOM", "Inventory Posting Group", "Shelf No.", "Statistics Group", "Date Filter";
            column(PeriodItemDateFilter; StrSubstNo(PeriodInfoTxt, ItemDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableCaptionItemFilter; StrSubstNo(TableFiltersTxt, TableCaption(), ItemFilter))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(InventoryTransDetailCaption; InventoryTransDetailCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemLedgEntryPostDateCaption; ItemLedgEntryPostDateCaptionLbl)
            {
            }
            column(ItemLedgEntryEntryTypCaption; ItemLedgEntryEntryTypCaptionLbl)
            {
            }
            column(IncreasesQtyCaption; IncreasesQtyCaptionLbl)
            {
            }
            column(DecreasesQtyCaption; DecreasesQtyCaptionLbl)
            {
            }
            column(ItemOnHandCaption; ItemOnHandCaptionLbl)
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Description_Item; Item.Description)
                {
                }
                column(StartOnHand; StartOnHand)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(RecordNo; RecordNo)
                {
                }
                dataitem("Item Ledger Entry"; "Item Ledger Entry")
                {
                    DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Posting Date" = field("Date Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Item;
                    DataItemTableView = sorting("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");
                    column(StartOnHandQuantity; StartOnHand + Quantity)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(PostingDate_ItemLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(EntryType_ItemLedgEntry; "Entry Type")
                    {
                    }
                    column(DocumentNo_PItemLedgEntry; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description_ItemLedgEntry; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(IncreasesQty; IncreasesQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(DecreasesQty; DecreasesQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(ItemOnHand; ItemOnHand)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(EntryNo_ItemLedgerEntry; "Entry No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Quantity_ItemLedgerEntry; Quantity)
                    {
                    }
                    column(ItemDescriptionControl32; Item.Description)
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ItemOnHand := ItemOnHand + Quantity;
                        Clear(IncreasesQty);
                        Clear(DecreasesQty);
                        if Quantity > 0 then
                            IncreasesQty := Quantity
                        else
                            DecreasesQty := Abs(Quantity);
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(Quantity);
                        Clear(IncreasesQty);
                        Clear(DecreasesQty);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                StartOnHand := 0;
                if ItemDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        OnItemOnAfterGetRecordOnBeforeCalcNetChange(Item);
                        CalcFields("Net Change");
                        StartOnHand := "Net Change";
                        SetFilter("Date Filter", ItemDateFilter);
                    end;
                ItemOnHand := StartOnHand;

                if PrintOnlyOnePerPageReq then
                    RecordNo := RecordNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                RecordNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Transaction Detail';
        AboutText = 'View a history of inventory transaction details with a running total of inventory during a period defined in the Date Filter.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Item';
                        ToolTip = 'Specifies if you want each item transaction detail to be printed on a separate page.';
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
        ItemFilter := Item.GetFilters();
        ItemDateFilter := Item.GetFilter("Date Filter");
    end;

    var
        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;
        ItemFilter: Text;
        ItemDateFilter: Text;
        ItemOnHand: Decimal;
        StartOnHand: Decimal;
        IncreasesQty: Decimal;
        DecreasesQty: Decimal;
        PrintOnlyOnePerPageReq: Boolean;
        RecordNo: Integer;
        InventoryTransDetailCaptionLbl: Label 'Inventory - Transaction Detail';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemLedgEntryPostDateCaptionLbl: Label 'Posting Date';
        ItemLedgEntryEntryTypCaptionLbl: Label 'Entry Type';
        IncreasesQtyCaptionLbl: Label 'Increases';
        DecreasesQtyCaptionLbl: Label 'Decreases';
        ItemOnHandCaptionLbl: Label 'Inventory';
        ContinuedCaptionLbl: Label 'Continued';

    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean)
    begin
        PrintOnlyOnePerPageReq := NewPrintOnlyOnePerPage;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemOnAfterGetRecordOnBeforeCalcNetChange(var Item: Record Item)
    begin
    end;
}

