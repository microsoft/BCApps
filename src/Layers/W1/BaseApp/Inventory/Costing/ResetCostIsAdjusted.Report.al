// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Telemetry;
using System.Utilities;

report 5803 "Reset Cost Is Adjusted"
{
    Caption = 'Reset Cost is Adjusted';
    ApplicationArea = Basic, Suite;
    ProcessingOnly = true;
    Permissions = tabledata Item = rm,
                  tabledata "Item Ledger Entry" = rm,
                  tabledata "Avg. Cost Adjmt. Entry Point" = rm,
                  tabledata "Inventory Adjmt. Entry (Order)" = rm,
                  tabledata "Item Application Entry" = rm;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Item."No.");
                "Cost is Adjusted" := false;
                Modify();

                FeatureTelemetry.LogUsage('0000MEL', CostIsAdjustedResetTok, ItemCostIsAdjustedResetTok);

                if Item."Costing Method" = Item."Costing Method"::Average then begin
                    AvgCostAdjmtEntryPoint.SetCurrentKey("Item No.", "Cost Is Adjusted", "Valuation Date");
                    AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
                    AvgCostAdjmtEntryPoint.SetFilter("Valuation Date", '%1..', FromDate);
                    AvgCostAdjmtEntryPoint.ModifyAll("Cost Is Adjusted", false);

                    ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
                    ItemLedgerEntry.SetRange("Item No.", Item."No.");
                    ItemLedgerEntry.SetFilter("Posting Date", '%1..', FromDate);
                    ItemLedgerEntry.SetFilter("Applies-to Entry", '<>0');
                    ItemLedgerEntry.SetLoadFields("Applies-to Entry", Positive, "Applied Entry to Adjust");
                    if ItemLedgerEntry.FindSet() then
                        repeat
                            if ItemLedgerEntry.Positive then
                                ItemLedgerEntry.SetAppliedEntryToAdjust(true)
                            else
                                if AppliedItemLedgerEntry.Get(ItemLedgerEntry."Applies-to Entry") then
                                    AppliedItemLedgerEntry.SetAppliedEntryToAdjust(true);
                        until ItemLedgerEntry.Next() = 0;
                end else begin
                    // Costing method other than Average
                    ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
                    ItemLedgerEntry.SetRange("Item No.", Item."No.");
                    ItemLedgerEntry.SetFilter("Posting Date", '%1..', FromDate);
                    ItemLedgerEntry.SetRange(Positive, true);
                    ItemLedgerEntry.SetLoadFields("Applied Entry to Adjust");
                    if ItemLedgerEntry.FindSet() then
                        repeat
                            ItemLedgerEntry.SetAppliedEntryToAdjust(true);
                            if ItemApplicationEntry.AppliedOutbndEntryExists(ItemLedgerEntry."Entry No.", false, false) then
                                repeat
                                    if ItemApplicationEntry."Outbound Entry is Updated" then begin
                                        ItemApplicationEntry."Outbound Entry is Updated" := false;
                                        ItemApplicationEntry.Modify();
                                    end;
                                until ItemApplicationEntry.Next() = 0;
                        until ItemLedgerEntry.Next() = 0;
                end;
            end;
        }

        dataitem(AdditionalCosting; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                if not (ResetAssemblyOrderCosting or ResetProdOrderCosting) then
                    CurrReport.Break();
            end;

            trigger OnAfterGetRecord()
            begin
                InventoryAdjmtEntryOrder.Reset();
                if ResetProdOrderCosting then begin
                    InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
                    InventoryAdjmtEntryOrder.SetFilter("Order No.", ProdOrderNo);
                    InventoryAdjmtEntryOrder.ModifyAll("Cost is Adjusted", false);
                end;
                if ResetAssemblyOrderCosting then begin
                    InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Assembly);
                    InventoryAdjmtEntryOrder.SetFilter("Order No.", PostedAssemblyOrderNo);
                    InventoryAdjmtEntryOrder.ModifyAll("Cost is Adjusted", false);
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Item)
                {
                    Caption = 'Item';

                    field("Reset Item Costing"; ResetItemCosting)
                    {
                        Caption = 'Adjust Items';
                        ToolTip = 'Specifies if you want to mark items for the next cost adjustment run.';
                    }
                    field("From Date"; FromDate)
                    {
                        Caption = 'From Date';
                        ToolTip = 'Specifies the starting date for the cost adjustment. You can leave this field blank to run the batch job for all dates.';
                    }
                }
                group(AssemblyOrder)
                {
                    Caption = 'Assembly Order';

                    field("Reset Assembly Order Costing"; ResetAssemblyOrderCosting)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Adjust Assembly Orders';
                        ToolTip = 'Specifies if you want to mark assembly orders for the next cost adjustment run.';
                    }
                    field("Assembly Order No."; PostedAssemblyOrderNo)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'No.';
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain posted assembly orders. You can leave this field blank to run the batch job for all posted assembly orders.';
                        TableRelation = "Posted Assembly Header"."No.";
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        if not ResetItemCosting then
            CurrReport.Quit();

        if FromDate = 0D then
            if not Confirm(NoFilterWarningStartDateQst) then
                CurrReport.Quit();

        if Item.GetFilter("No.") = '' then
            if not Confirm(NoFilterWarningItemQst) then
                CurrReport.Quit();

        if ResetProdOrderCosting and (ProdOrderNo = '') then
            if not Confirm(NoProdOrderFilterQst) then
                CurrReport.Quit();

        if ResetAssemblyOrderCosting and (PostedAssemblyOrderNo = '') then
            if not Confirm(NoAssemblyHeaderFilterQst) then
                CurrReport.Quit();

        Window.Open(ItemProgressTxt);

        Item.LockTable();
        ItemApplicationEntry.LockTable();
        ItemLedgerEntry.LockTable();
        AvgCostAdjmtEntryPoint.LockTable();
        InventoryAdjmtEntryOrder.LockTable();
    end;

    trigger OnPostReport()
    begin
        Window.Close();
        Message(CompletedMsg);
    end;

    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ItemLedgerEntry: Record "Item Ledger Entry";
        AppliedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Window: Dialog;
        PostedAssemblyOrderNo: Code[50];
        FromDate: Date;
        ResetItemCosting: Boolean;
        ResetAssemblyOrderCosting: Boolean;
        ItemProgressTxt: Label 'Processing item #1###########', Comment = '%1: Item No.';
        NoFilterWarningStartDateQst: Label 'You have not specified a start date, which means that the following cost adjustment may take some time. Are you sure you want to continue?';
        NoFilterWarningItemQst: Label 'You have not specified an Item No., which means that the following cost adjustment may take some time. Are you sure you want to continue?';
        CompletedMsg: Label 'Reset is completed. Please run Adjust Cost - Item Entries batch job.';
        NoProdOrderFilterQst: Label 'You have not specified a Production Order filter, which means that the following cost adjustment may take some time. Are you sure you want to continue?';
        NoAssemblyHeaderFilterQst: Label 'You have not specified an Assembly Order filter, which means that the following cost adjustment may take some time. Are you sure you want to continue?';
        CostIsAdjustedResetTok: Label 'Cost adjusted reset', Locked = true;
        ItemCostIsAdjustedResetTok: Label 'Item cost was set up to be adjusted.', Locked = true;

    protected var
        ProdOrderNo: Code[50];
        ResetProdOrderCosting: Boolean;
}
