// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

report 14311 "Stock Card"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/InventoryMgt/Reports/StockCard.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Stock Card';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Ledger Entry"; "Item Ledger Entry")
        {
            RequestFilterFields = "Item No.", "Location Code", "Posting Date";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemNo_ItemLedgerEntry; "Item No.")
            {
            }
            column(CostingMethod; CostingMethod)
            {
            }
            column(GroupTotals; GroupTotals)
            {
            }
            column(OpeningStockAmount; OpeningStockAmount)
            {
            }
            column(OpeningStock; OpeningStock)
            {
            }
            column(FORMAT_StartingDate_; Format(StartingDate))
            {
            }
            column(DateFilter; DateFilter)
            {
            }
            column(OpeningCost; OpeningCost)
            {
            }
            column(OpeningStock2; OpeningStock2)
            {
            }
            column(OpeningCost2; OpeningCost2)
            {
            }
            column(OpeningStockAmount2; OpeningStockAmount2)
            {
            }
            column(ShowOutput; ShowOutput)
            {
            }
            column(Location_Name; Location.Name)
            {
            }
            column(StartingDateFormatted; Format(StartingDate))
            {
            }
            column(PostingDateFormatted; Format("Posting Date"))
            {
            }
            column(DocumentNo_ItemLedgerEntry; "Document No.")
            {
            }
            column(ExternalDocumentNo_ItemLedgerEntry; "External Document No.")
            {
            }
            column(ReceivedQty; ReceivedQty)
            {
            }
            column(ReceivedCost; ReceivedCost)
            {
            }
            column(IssuedQty; IssuedQty)
            {
            }
            column(IssuedCost; IssuedCost)
            {
            }
            column(Amount; Amount)
            {
            }
            column(BalanceQty; BalanceQty)
            {
            }
            column(BalanceCost; BalanceCost)
            {
                DecimalPlaces = 0 : 2;
            }
            column(TotalBalanceAmount; TotalBalanceAmount)
            {
            }
            column(LocationBalance; LocationBalance)
            {
            }
            column(TotalFor___FIELDCAPTION__Location_Code____________Location_Name; TotalFor + FieldCaption("Location Code") + '    ' + Location.Name)
            {
            }
            column(TotalFor___FIELDCAPTION__Item_No______________Item_Description; TotalFor + FieldCaption("Item No.") + '     ' + Item.Description)
            {
            }
            column(ItemTotalQty; ItemTotalQty)
            {
            }
            column(ItemTotalBalance; ItemTotalBalance)
            {
            }
            column(Item_Ledger_Entry_Entry_No_; "Entry No.")
            {
            }
            column(Item_Ledger_Entry_Location_Code; "Location Code")
            {
            }
            column(Item_Ledger_Entry__Item_No__Caption; FieldCaption("Item No."))
            {
            }
            dataitem("Item Application Entry"; "Item Application Entry")
            {
                DataItemLink = "Item Ledger Entry No." = field("Entry No.");
                DataItemTableView = sorting("Entry No.");
                column(FORMAT__Item_Ledger_Entry___Posting_Date__; Format("Item Ledger Entry"."Posting Date"))
                {
                }
                column(Item_Ledger_Entry___Document_No__; "Item Ledger Entry"."Document No.")
                {
                }
                column(ItemLedgEntry2__Document_No__; ItemLedgEntry2."Document No.")
                {
                }
                column(IssuedQty_Control1500082; IssuedQty)
                {
                }
                column(IssuedCost_Control1500083; IssuedCost)
                {
                }
                column(Amount_Control1500084; Amount)
                {
                }
                column(BalanceQty_Control1500085; BalanceQty)
                {
                }
                column(BalanceCost_Control1500086; BalanceCost)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(TotalBalanceAmount_Control1500087; TotalBalanceAmount)
                {
                }
                column(ShowOutput2; ShowOutput2)
                {
                }
                column(Item_Application_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Item_Application_Entry_Item_Ledger_Entry_No_; "Item Ledger Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Item Ledger Entry".Quantity > 0 then
                        CurrReport.Skip();
                    if (Item."Costing Method" = Item."Costing Method"::Average) or (Item."Costing Method" = Item."Costing Method"::Standard) then
                        CurrReport.Skip();

                    ShowOutput2 := true;
                    IssuedQty := 0;
                    IssuedCost := 0;
                    Amount := 0;
                    if "Item Ledger Entry".Quantity < 0 then begin
                        ItemLedgEntry2.Get("Item Application Entry"."Inbound Item Entry No.");
                        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
                        if ValueEntry.FindFirst() then begin
                            IssuedQty := Abs("Item Application Entry".Quantity);
                            IssuedCost := ValueEntry."Cost per Unit";
                            Amount := IssuedQty * IssuedCost;
                            BalanceQty := OpeningStock - IssuedQty;
                            TotalBalanceAmount := OpeningStockAmount - Amount;
                            if not ShowOutput then begin
                                LocationBalance := LocationBalance - PreviousTotalBalanceAmount + TotalBalanceAmount;
                                ItemTotalQty := ItemTotalQty - PreviousBalanceQty + BalanceQty;
                                ItemTotalBalance := ItemTotalBalance - PreviousTotalBalanceAmount + TotalBalanceAmount;
                                PreviousTotalBalanceAmount := TotalBalanceAmount;
                                PreviousBalanceQty := BalanceQty;
                            end;
                            OpeningStock := BalanceQty;
                            OpeningStockAmount := TotalBalanceAmount;
                        end;
                    end else
                        ShowOutput2 := false;

                    PreviousApplication := "Item Application Entry";
                    PreviousTotalBalanceAmount2 := TotalBalanceAmount;
                    PreviousBalanceQty2 := BalanceQty;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Item.Get("Item Ledger Entry"."Item No.");
                if Item."Costing Method" = Item."Costing Method"::FIFO then
                    CostingMethod := Text001
                else
                    if Item."Costing Method" = Item."Costing Method"::LIFO then
                        CostingMethod := Text002
                    else
                        if Item."Costing Method" = Item."Costing Method"::Specific then
                            CostingMethod := Text003
                        else
                            if Item."Costing Method" = Item."Costing Method"::Average then
                                CostingMethod := Text004
                            else
                                if Item."Costing Method" = Item."Costing Method"::Standard then
                                    CostingMethod := Text005;

                ShowOutput := true;
                if Previous.IsEmpty() or ("Item No." <> Previous."Item No.") then begin
                    OpeningStock := 0;
                    OpeningStockAmount := 0;
                    ItemTotalQty := 0;
                    ItemTotalBalance := 0;
                    ItemLedgEntry1.Reset();
                    ItemLedgEntry1.SetCurrentKey("Item No.", "Location Code");
                    ItemLedgEntry1.SetRange("Item No.", "Item Ledger Entry"."Item No.");
                    ItemLedgEntry1.SetRange("Location Code", "Item Ledger Entry"."Location Code");
                    ItemLedgEntry1.SetRange("Posting Date", 0D, StartingDate - 1);
                    if ItemLedgEntry1.Find('-') then
                        repeat
                            ItemLedgEntry1.CalcFields("Cost Amount (Actual)");
                            OpeningStock := OpeningStock + ItemLedgEntry1.Quantity;
                            OpeningStockAmount := OpeningStockAmount + ItemLedgEntry1."Cost Amount (Actual)";
                        until ItemLedgEntry1.Next() = 0;
                    BalanceCost := 0;
                end;

                if Previous.IsEmpty() or ("Item No." <> Previous."Item No.") or
                   (("Location Code" <> Previous."Location Code") and
                    ("Item No." = Previous."Item No."))
                then
                    if GroupTotals = GroupTotals::Location then begin
                        OpeningStock := 0;
                        OpeningStockAmount := 0;
                        OpeningCost := 0;
                        ItemLedgEntry1.Reset();
                        ItemLedgEntry1.SetCurrentKey("Item No.", "Location Code", "Posting Date");
                        ItemLedgEntry1.SetRange("Item No.", "Item Ledger Entry"."Item No.");
                        ItemLedgEntry1.SetRange("Location Code", "Item Ledger Entry"."Location Code");
                        ItemLedgEntry1.SetRange("Posting Date", 0D, StartingDate - 1);
                        if ItemLedgEntry1.Find('-') then
                            repeat
                                ItemLedgEntry1.CalcFields("Cost Amount (Actual)");
                                OpeningStock := OpeningStock + ItemLedgEntry1.Quantity;
                                OpeningStockAmount := OpeningStockAmount + ItemLedgEntry1."Cost Amount (Actual)";
                                if (Item."Costing Method" = Item."Costing Method"::Average) or
                                   (Item."Costing Method" = Item."Costing Method"::Standard)
                                then
                                    if OpeningStock <> 0 then
                                        OpeningCost := OpeningStockAmount / OpeningStock;
                            until ItemLedgEntry1.Next() = 0;
                        BalanceCost := 0;
                        OpeningStock2 := OpeningStock;
                        OpeningStockAmount2 := OpeningStockAmount;
                        OpeningCost2 := OpeningCost;
                    end;

                if Location.Get("Location Code") then;
                if Previous.IsEmpty() or ("Location Code" <> Previous."Location Code") then begin
                    OpeningStock := 0;
                    OpeningStockAmount := 0;
                    LocationBalance := 0;
                    ItemLedgEntry1.Reset();
                    ItemLedgEntry1.SetCurrentKey("Item No.", "Location Code");
                    ItemLedgEntry1.SetRange("Item No.", "Item Ledger Entry"."Item No.");
                    ItemLedgEntry1.SetRange("Location Code", "Item Ledger Entry"."Location Code");
                    ItemLedgEntry1.SetRange("Posting Date", 0D, StartingDate - 1);
                    if ItemLedgEntry1.Find('-') then
                        repeat
                            ItemLedgEntry1.CalcFields("Cost Amount (Actual)");
                            OpeningStock := OpeningStock + ItemLedgEntry1.Quantity;
                            OpeningStockAmount := OpeningStockAmount + ItemLedgEntry1."Cost Amount (Actual)";
                        until ItemLedgEntry1.Next() = 0;
                    BalanceCost := 0;
                end;

                if Previous.IsEmpty() or ("Location Code" <> Previous."Location Code") or
                   (("Location Code" = Previous."Location Code") and
                    ("Item No." <> Previous."Item No."))
                then
                    if GroupTotals = GroupTotals::"Item " then begin
                        OpeningStock := 0;
                        OpeningStockAmount := 0;
                        OpeningCost := 0;
                        ItemLedgEntry1.Reset();
                        ItemLedgEntry1.SetCurrentKey("Item No.", "Location Code", "Posting Date");
                        ItemLedgEntry1.SetRange("Item No.", "Item Ledger Entry"."Item No.");
                        ItemLedgEntry1.SetRange("Location Code", "Item Ledger Entry"."Location Code");
                        ItemLedgEntry1.SetRange("Posting Date", 0D, StartingDate - 1);
                        if ItemLedgEntry1.Find('-') then
                            repeat
                                ItemLedgEntry1.CalcFields("Cost Amount (Actual)");
                                OpeningStock := OpeningStock + ItemLedgEntry1.Quantity;
                                OpeningStockAmount := OpeningStockAmount + ItemLedgEntry1."Cost Amount (Actual)";
                                if (Item."Costing Method" = Item."Costing Method"::Average) or
                                   (Item."Costing Method" = Item."Costing Method"::Standard)
                                then
                                    if OpeningStock <> 0 then
                                        OpeningCost := OpeningStockAmount / OpeningStock;
                            until ItemLedgEntry1.Next() = 0;
                        BalanceCost := 0;
                        OpeningStock2 := OpeningStock;
                        OpeningStockAmount2 := OpeningStockAmount;
                        OpeningCost2 := OpeningCost;
                    end;

                if (Item."Costing Method" = Item."Costing Method"::FIFO) or
                   (Item."Costing Method" = Item."Costing Method"::LIFO) or
                   (Item."Costing Method" = Item."Costing Method"::Specific)
                then begin
                    if "Item Ledger Entry".Quantity > 0 then begin
                        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
                        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
                        if not ValueEntry.FindFirst() then
                            ValueEntry.Init();
                        ReceivedQty := ValueEntry."Invoiced Quantity";
                        ReceivedCost := ValueEntry."Cost per Unit";
                        Amount := ReceivedQty * ReceivedCost;
                        BalanceQty := OpeningStock + ReceivedQty;
                        TotalBalanceAmount := OpeningStockAmount + Amount;
                        OpeningStock := BalanceQty;
                        OpeningStockAmount := TotalBalanceAmount;
                        if (Item."Costing Method" = Item."Costing Method"::Average) or
                           (Item."Costing Method" = Item."Costing Method"::Standard)
                        then
                            if BalanceQty <> 0 then
                                BalanceCost := TotalBalanceAmount / BalanceQty;
                        IssuedQty := 0;
                        IssuedCost := 0;
                    end else begin
                        ReceivedQty := 0;
                        ReceivedCost := 0;
                        Amount := 0;
                        ShowOutput := false;
                        BalanceCost := 0;
                    end;
                end else
                    if "Item Ledger Entry".Quantity > 0 then begin
                        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
                        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
                        if not ValueEntry.FindFirst() then
                            ValueEntry.Init();
                        ReceivedQty := ValueEntry."Invoiced Quantity";
                        ReceivedCost := ValueEntry."Cost per Unit";
                        Amount := ReceivedQty * ReceivedCost;
                        BalanceQty := OpeningStock + ReceivedQty;
                        TotalBalanceAmount := OpeningStockAmount + Amount;
                        OpeningStock := BalanceQty;
                        OpeningStockAmount := TotalBalanceAmount;
                        if BalanceQty <> 0 then
                            BalanceCost := TotalBalanceAmount / BalanceQty;
                        IssuedQty := 0;
                        IssuedCost := 0;
                    end else begin
                        IssuedQty := Abs("Item Ledger Entry".Quantity);
                        "Item Ledger Entry".CalcFields("Cost Amount (Actual)");
                        if IssuedQty > 0 then
                            IssuedCost := Abs("Item Ledger Entry"."Cost Amount (Actual)") / IssuedQty;
                        Amount := IssuedQty * IssuedCost;
                        BalanceQty := OpeningStock - IssuedQty;
                        TotalBalanceAmount := OpeningStockAmount - Amount;
                        if BalanceQty <> 0 then
                            BalanceCost := TotalBalanceAmount / BalanceQty;
                        OpeningStock := BalanceQty;
                        OpeningStockAmount := TotalBalanceAmount;
                        ReceivedQty := 0;
                        ReceivedCost := 0;
                    end;

                ItemTotalQty := ItemTotalQty + BalanceQty;
                ItemTotalBalance := ItemTotalBalance + TotalBalanceAmount;
                if ("Item Ledger Entry"."Location Code" = Previous."Location Code") and
                   ("Item Ledger Entry"."Item No." = Previous."Item No.")
                then begin
                    ItemTotalQty := ItemTotalQty - PreviousBalanceQty;
                    ItemTotalBalance := ItemTotalBalance - PreviousTotalBalanceAmount;
                end;

                LocationBalance := LocationBalance + TotalBalanceAmount;
                if ("Item Ledger Entry"."Item No." = Previous."Item No.") and
                   ("Item Ledger Entry"."Location Code" = Previous."Location Code")
                then
                    LocationBalance := LocationBalance - PreviousTotalBalanceAmount;

                Previous := "Item Ledger Entry";
                PreviousTotalBalanceAmount := TotalBalanceAmount;
                PreviousBalanceQty := BalanceQty;
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Posting Date");
                case GroupTotals of
                    GroupTotals::Location:
                        SetCurrentKey("Location Code", "Item No.", "Posting Date");
                    GroupTotals::"Item ":
                        SetCurrentKey("Item No.", "Location Code", "Posting Date");
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group Totals';
                        OptionCaption = 'Location,Item';
                        ToolTip = 'Specifies that you want to group totals.';
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
        StockCardCaption = 'Stock Card';
        PageNoCaption = 'Page';
        PostingDateCaption = 'Posting Date';
        DocumentNoCaption = 'Document No.';
        ReferenceNoCapton = 'Reference Number';
        ReceivedQtyCaption = 'Received Qty.';
        ReceivedCostCaption = 'Received Cost';
        IssuedQtyCaption = 'Issued Qty.';
        IssuedCostCaptioin = 'Issued Cost';
        AmountCaption = 'Amount';
        BalanceQuantityCaption = 'Balance Qty.';
        BalanceCostCaption = 'Balance Cost';
        TotalBalanceAmtCaption = 'Total Balance Amount';
        CostingMethodCaptioin = 'Costing Method';
        OpeningBalCaption = 'Opening Balance';
        TransDuringPeriodCaption = 'Transactions during the period';
        LocationCaption = 'Location';
    }

    trigger OnInitReport()
    begin
        Previous.Reset();
    end;

    trigger OnPreReport()
    begin
        DateFilter := "Item Ledger Entry".GetFilter("Posting Date");
        if DateFilter = '' then
            Error(Text006);
        StartingDate := "Item Ledger Entry".GetRangeMin("Posting Date");
        EndingDate := "Item Ledger Entry".GetRangeMax("Posting Date");
    end;

    var
        LastFieldNo: Integer;
        TotalFor: Label 'Total for ';
        ValueEntry: Record "Value Entry";
        ItemLedgEntry1: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        Location: Record Location;
        Item: Record Item;
        GroupTotals: Option Location,"Item ";
        StartingDate: Date;
        EndingDate: Date;
        DateFilter: Text[80];
        ReceivedQty: Decimal;
        ReceivedCost: Decimal;
        IssuedQty: Decimal;
        IssuedCost: Decimal;
        Amount: Decimal;
        BalanceQty: Decimal;
        BalanceCost: Decimal;
        TotalBalanceAmount: Decimal;
        ItemTotalQty: Decimal;
        ItemTotalBalance: Decimal;
        OpeningStock: Decimal;
        OpeningCost: Decimal;
        OpeningStockAmount: Decimal;
        LocationBalance: Decimal;
        Text001: Label 'FIFO';
        Text002: Label 'LIFO';
        Text003: Label 'SPECIFIC';
        Text004: Label 'AVERAGE';
        Text005: Label 'STANDARD';
        Text006: Label 'Please enter the Date filter.';
        CostingMethod: Code[10];
        Previous: Record "Item Ledger Entry";
        PreviousTotalBalanceAmount: Decimal;
        PreviousBalanceQty: Decimal;
        OpeningStock2: Decimal;
        OpeningCost2: Decimal;
        OpeningStockAmount2: Decimal;
        ShowOutput: Boolean;
        ShowOutput2: Boolean;
        PreviousApplication: Record "Item Application Entry";
        PreviousBalanceQty2: Decimal;
        PreviousTotalBalanceAmount2: Decimal;
}

