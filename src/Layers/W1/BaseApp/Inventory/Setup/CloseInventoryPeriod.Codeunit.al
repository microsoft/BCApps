// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;

codeunit 5820 "Close Inventory Period"
{
    Permissions = TableData "Inventory Period" = rimd,
                  TableData "Inventory Period Entry" = rimd;
    TableNo = "Inventory Period";

    trigger OnRun()
    begin
        if not HideDialog then
            if not ReOpen then begin
                if not Confirm(
                     Text002,
                     false,
                     Rec."Ending Date")
                then
                    exit
            end else
                if not Confirm(Text006, false, Rec.TableCaption(), Rec."Ending Date") then
                    exit;

        Rec.TestField(Closed, ReOpen);

        OnRunOnBeforeCheck(Rec, ReOpen);

        if not ReOpen then begin
            Rec.TestField("Ending Date");
            CheckCostIsAdjusted(Rec."Ending Date");
            CheckOpenOutboundEntryExist(Rec."Ending Date");
        end else
            if not HideDialog and AccPeriodIsClosed(Rec."Ending Date") then
                if not Confirm(Text008, false, Rec.TableCaption(), Rec."Ending Date") then
                    exit;

        UpdateInvtPeriod(Rec);
        CreateInvtPeriodEntry(Rec);

        if not HideDialog then
            if not ReOpen then
                Message(Text005, Rec.TableCaption(), Rec."Ending Date")
            else
                Message(Text007, Rec."Ending Date");
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'The Inventory Period cannot be closed because there is at least one item with unadjusted entries in the current period.\\Run the Close Inventory Period - Test report to identify item ledger entries for the affected items.';
        Text001: Label 'The Inventory Period cannot be closed because there is negative inventory for one or more items.\\Run the Close Inventory Period - Test report to identify item ledger entries for the affected items.';
#pragma warning disable AA0470
        Text002: Label 'This function closes the inventory up to %1. Once it is closed, you cannot post in the period until it is re-opened.\\Make sure that all your inventory is posted to G/L.\\Do you want to close the inventory period?';
        Text005: Label 'The %1 has been closed on %2.';
        Text006: Label 'Do you want to reopen the %1 that ends %2?';
        Text007: Label 'All inventory periods from %1 have been reopened.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ReOpen: Boolean;
        HideDialog: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label 'The accounting period is already closed. Are you sure you want to reopen the %1 that ends %2?';
        Text010: Label 'The Inventory Period cannot be closed because there is at least one %1 Order in the current period that has not been adjusted.\\Run the Close Inventory Period - Test report to identify the affected orders.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckCostIsAdjusted(EndingDate: Date)
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ValueEntry: Record "Value Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        if not AvgCostEntryPointHandler.IsEntriesAdjusted('', EndingDate) then
            Error(Text000);

        InvtAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted");
        InvtAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InvtAdjmtEntryOrder.SetRange("Is Finished", true);
        if InvtAdjmtEntryOrder.FindSet() then
            repeat
                ValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
                ValueEntry.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type");
                ValueEntry.SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
                ValueEntry.SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
                ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
                  ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Item Ledger Entry Type"::"Assembly Output");
                ValueEntry.SetRange("Valuation Date", 0D, EndingDate);
                if not ValueEntry.IsEmpty() then
                    Error(Text010, InvtAdjmtEntryOrder."Order Type");
            until InvtAdjmtEntryOrder.Next() = 0;
    end;

    local procedure CheckOpenOutboundEntryExist(EndingDate: Date)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange(Positive, false);
        ItemLedgEntry.SetRange("Posting Date", 0D, EndingDate);
        if not ItemLedgEntry.IsEmpty() then
            Error(Text001);
    end;

    local procedure AccPeriodIsClosed(StartDate: Date): Boolean
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetCurrentKey(Closed);
        AccPeriod.SetRange(Closed, true);
        AccPeriod.SetFilter("Starting Date", '>=%1', StartDate);
        exit(not AccPeriod.IsEmpty);
    end;

    local procedure UpdateInvtPeriod(var TheInvtPeriod: Record "Inventory Period")
    var
        InvtPeriod2: Record "Inventory Period";
        InvtPeriod3: Record "Inventory Period";
    begin
        InvtPeriod2.SetRange(Closed, ReOpen);
        if ReOpen then
            InvtPeriod2.SetFilter("Ending Date", '>%1', TheInvtPeriod."Ending Date")
        else
            InvtPeriod2.SetFilter("Ending Date", '<%1', TheInvtPeriod."Ending Date");
        if InvtPeriod2.FindSet(true) then
            repeat
                InvtPeriod3 := InvtPeriod2;
                InvtPeriod3.Closed := not ReOpen;
                InvtPeriod3.Modify();
                CreateInvtPeriodEntry(InvtPeriod3);
            until InvtPeriod2.Next() = 0;

        TheInvtPeriod.Closed := not ReOpen;
        TheInvtPeriod.Modify();
    end;

    local procedure CreateInvtPeriodEntry(InvtPeriod: Record "Inventory Period")
    var
        InvtPeriodEntry: Record "Inventory Period Entry";
        ItemRegister: Record "Item Register";
        EntryNo: Integer;
    begin
        InvtPeriodEntry.SetRange("Ending Date", InvtPeriod."Ending Date");
        if InvtPeriodEntry.FindLast() then
            EntryNo := InvtPeriodEntry."Entry No." + 1
        else
            EntryNo := 1;

        InvtPeriodEntry.Init();
        InvtPeriodEntry."Entry No." := EntryNo;
        InvtPeriodEntry."Ending Date" := InvtPeriod."Ending Date";
        InvtPeriodEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(InvtPeriodEntry."User ID"));
        InvtPeriodEntry."Creation Date" := WorkDate();
        InvtPeriodEntry."Creation Time" := Time;
        if InvtPeriod.Closed then begin
            InvtPeriodEntry."Entry Type" := InvtPeriodEntry."Entry Type"::Close;
            if ItemRegister.FindLast() then
                InvtPeriodEntry."Closing Item Register No." := ItemRegister."No.";
        end else
            InvtPeriodEntry."Entry Type" := InvtPeriodEntry."Entry Type"::"Re-open";

        InvtPeriodEntry.Insert();
    end;

    procedure SetReOpen(NewReOpen: Boolean)
    begin
        ReOpen := NewReOpen;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheck(InventoryPeriod: Record "Inventory Period"; Reopen: Boolean)
    begin
    end;
}

