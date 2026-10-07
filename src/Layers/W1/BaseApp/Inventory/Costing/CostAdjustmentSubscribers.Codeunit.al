// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using System.Telemetry;
using System.Utilities;

codeunit 5821 "Cost Adjustment Subscribers"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Cost Adjustment Log" = rimd,
                  tabledata "Cost Adjustment Detailed Log" = rimd,
                  tabledata "Item Register" = r,
                  tabledata "Cost Adjustment Trace Log" = rimd;

    var
        InventorySetup: Record "Inventory Setup";
        TempItem: Record Item temporary;
        TempCostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log" temporary;
        TempCostAdjustmentLog: Record "Cost Adjustment Log" temporary;
        TempCostAdjustmentTraceLog: Record "Cost Adjustment Trace Log" temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ItemCostSourceRecipient: Enum "Item Cost Source/Recipient";
        CostAdjustmentRunGuid: Guid;
        CostAdjmtTelemetryCustomDim: Dictionary of [Text, Text];
        StartingDateTime: DateTime;
        LastError: Text[2048];
        LastErrorCallStack: Text[2048];
        FailedItemNo: Code[20];
        EntryNo: Integer;
        Trace: Boolean;
        CostAdjustmentRunnerFeatureTok: Label 'Cost adjustment batch runner', Locked = true;
        ItemCostAdjustedTok: Label 'Item cost was adjusted with the batch runner.', Locked = true;
        ItemCostNotAdjustedTok: Label 'Item cost was not adjusted with the batch runner.', Locked = true;
        RunWithTracingTok: Label 'Cost adjustment was run with enabled tracing.', Locked = true;
        GuidTok: Label 'GUID', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnBeforeRunCostAdjustment, '', false, false)]
    local procedure InitializeBucketRunCostAdjustment(CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        InventorySetup.Get();
        CostAdjustmentRunGuid := CreateGuid();
        Clear(CostAdjmtTelemetryCustomDim);
        CostAdjmtTelemetryCustomDim.Add(GuidTok, Format(CostAdjustmentRunGuid));
        StartingDateTime := CurrentDateTime();
        TempItem.Reset();
        TempItem.DeleteAll();
        TempCostAdjustmentDetailedLog.Reset();
        TempCostAdjustmentDetailedLog.DeleteAll();

        Trace := CostAdjItemBucket.Trace;
        if Trace then
            ClearTraceLog();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnBeforeRunCostAdjustment, '', false, false)]
    local procedure InitializeRegularCostAdjustment()
    begin
        InventorySetup.Get();
        CostAdjustmentRunGuid := CreateGuid();
        StartingDateTime := CurrentDateTime();
        TempItem.Reset();
        TempItem.DeleteAll();
        TempCostAdjustmentDetailedLog.Reset();
        TempCostAdjustmentDetailedLog.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnAfterRunCostAdjustment, '', false, false)]
    local procedure LogLastBucketRun(CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    var
        ItemRegister: Record "Item Register";
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        if Trace then begin
            FlushTraceLog();
            Trace := false;
        end;

        case InventorySetup."Cost Adjustment Logging" of
            InventorySetup."Cost Adjustment Logging"::All:
                begin
                    ItemRegister.SetCurrentKey("Cost Adjustment Run Guid");
                    ItemRegister.SetRange("Cost Adjustment Run Guid", CostAdjustmentRunGuid);
                    ItemRegister.SetLoadFields("No.");
                    if ItemRegister.FindSet() then
                        repeat
                            Clear(CostAdjustmentLog);
                            CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                            CostAdjustmentLog."Item Filter" := CostAdjItemBucket."Item Filter";
                            CostAdjustmentLog.Status := CostAdjItemBucket.Status;
                            CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                            CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                            CostAdjustmentLog."Item Register No." := ItemRegister."No.";
                            CostAdjustmentLog.Insert();
                        until ItemRegister.Next() = 0
                    else begin
                        // in case the cost adjustment run is not logged in item register (e.g. no item is adjusted)
                        Clear(CostAdjustmentLog);
                        CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                        CostAdjustmentLog."Item Filter" := CostAdjItemBucket."Item Filter";
                        CostAdjustmentLog.Status := CostAdjItemBucket.Status;
                        CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                        CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                        CostAdjustmentLog."Last Error" := CostAdjItemBucket."Last Error";
                        CostAdjustmentLog."Last Error Call Stack" := CostAdjItemBucket."Last Error Call Stack";
                        CostAdjustmentLog."Failed Item No." := CostAdjItemBucket."Failed Item No.";
                        CostAdjustmentLog.Insert();
                    end;

                    TempCostAdjustmentDetailedLog.Reset();
                    if CostAdjustmentLog."Failed Item No." <> '' then
                        TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindSet() then
                        repeat
                            CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                            CostAdjustmentDetailedLog.Insert();
                            OnCostAdjustmentDetailLogCreated(CostAdjustmentDetailedLog);
                        until TempCostAdjustmentDetailedLog.Next() = 0;
                end;
            InventorySetup."Cost Adjustment Logging"::"Errors Only":
                begin
                    if CostAdjItemBucket.Status <> CostAdjItemBucket.Status::Failed then
                        exit;

                    Clear(CostAdjustmentLog);
                    CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                    CostAdjustmentLog."Item Filter" := CostAdjItemBucket."Item Filter";
                    CostAdjustmentLog.Status := CostAdjItemBucket.Status;
                    CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                    CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                    CostAdjustmentLog."Last Error" := CostAdjItemBucket."Last Error";
                    CostAdjustmentLog."Last Error Call Stack" := CostAdjItemBucket."Last Error Call Stack";
                    CostAdjustmentLog."Failed Item No." := CostAdjItemBucket."Failed Item No.";
                    CostAdjustmentLog.Insert();

                    TempCostAdjustmentDetailedLog.Reset();
                    TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindFirst() then begin
                        CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                        CostAdjustmentDetailedLog.Insert();
                        OnCostAdjustmentDetailLogCreated(CostAdjustmentDetailedLog);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnAfterRunCostAdjustment, '', false, false)]
    local procedure LogLastOrdinaryRun(var Item: Record Item)
    var
        ItemRegister: Record "Item Register";
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        case InventorySetup."Cost Adjustment Logging" of
            InventorySetup."Cost Adjustment Logging"::All:
                begin
                    ItemRegister.SetCurrentKey("Cost Adjustment Run Guid");
                    ItemRegister.SetRange("Cost Adjustment Run Guid", CostAdjustmentRunGuid);
                    ItemRegister.SetLoadFields("No.");
                    if ItemRegister.FindSet() then
                        repeat
                            Clear(CostAdjustmentLog);
                            CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                            CostAdjustmentLog."Item Filter" := CopyStr(Item.GetFilters(), 1, MaxStrLen(CostAdjustmentLog."Item Filter"));
                            CostAdjustmentLog.Status := TempCostAdjustmentLog.Status;
                            CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                            CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                            CostAdjustmentLog."Item Register No." := ItemRegister."No.";
                            CostAdjustmentLog.Insert();
                        until ItemRegister.Next() = 0
                    else begin
                        // in case the cost adjustment run is not logged in item register (e.g. no item is adjusted)
                        Clear(CostAdjustmentLog);
                        CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                        CostAdjustmentLog."Item Filter" := CopyStr(Item.GetFilters(), 1, MaxStrLen(CostAdjustmentLog."Item Filter"));
                        CostAdjustmentLog.Status := TempCostAdjustmentLog.Status;
                        CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                        CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                        CostAdjustmentLog."Last Error" := LastError;
                        CostAdjustmentLog."Last Error Call Stack" := LastErrorCallStack;
                        CostAdjustmentLog."Failed Item No." := FailedItemNo;
                        CostAdjustmentLog.Insert();
                    end;

                    TempCostAdjustmentDetailedLog.Reset();
                    if CostAdjustmentLog."Failed Item No." <> '' then
                        TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindSet() then
                        repeat
                            CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                            CostAdjustmentDetailedLog.Insert();
                            OnCostAdjustmentDetailLogCreated(CostAdjustmentDetailedLog);
                        until TempCostAdjustmentDetailedLog.Next() = 0;
                end;
            InventorySetup."Cost Adjustment Logging"::"Errors Only":
                begin
                    if TempCostAdjustmentLog.Status <> TempCostAdjustmentLog.Status::Failed then
                        exit;

                    Clear(CostAdjustmentLog);
                    CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                    CostAdjustmentLog."Item Filter" := CopyStr(Item.GetFilters(), 1, MaxStrLen(CostAdjustmentLog."Item Filter"));
                    CostAdjustmentLog.Status := TempCostAdjustmentLog.Status;
                    CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                    CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                    CostAdjustmentLog."Last Error" := LastError;
                    CostAdjustmentLog."Last Error Call Stack" := LastErrorCallStack;
                    CostAdjustmentLog."Failed Item No." := FailedItemNo;
                    CostAdjustmentLog.Insert();

                    TempCostAdjustmentDetailedLog.Reset();
                    TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindFirst() then begin
                        CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                        CostAdjustmentDetailedLog.Insert();
                        OnCostAdjustmentDetailLogCreated(CostAdjustmentDetailedLog);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnRegisterSuccess, '', false, false)]
    local procedure RegisterSuccessBucketRun(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        FeatureTelemetry.LogUsage('0000MEN', CostAdjustmentRunnerFeatureTok, ItemCostAdjustedTok, CostAdjmtTelemetryCustomDim);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnRegisterFailure, '', false, false)]
    local procedure RegisterFailureBucketRun(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        if TempItem.FindLast() then
            CostAdjItemBucket."Failed Item No." := TempItem."No.";

        FeatureTelemetry.LogUsage('0000MEO', CostAdjustmentRunnerFeatureTok, ItemCostNotAdjustedTok, CostAdjmtTelemetryCustomDim);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnRegisterSuccess, '', false, false)]
    local procedure RegisterSuccessRegularRun()
    begin
        TempCostAdjustmentLog.Status := TempCostAdjustmentLog.Status::Success;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnRegisterFailure, '', false, false)]
    local procedure RegisterFailureRegularRun()
    begin
        if TempItem.FindLast() then
            FailedItemNo := TempItem."No.";
        TempCostAdjustmentLog.Status := TempCostAdjustmentLog.Status::Failed;
        LastError := CopyStr(GetLastErrorText(), 1, MaxStrLen(LastError));
        LastErrorCallStack := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(LastErrorCallStack));

        TempCostAdjustmentDetailedLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
        TempCostAdjustmentDetailedLog."Item No." := FailedItemNo;
        if TempCostAdjustmentDetailedLog.Find() then begin
            TempCostAdjustmentDetailedLog."Ending Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog.Duration += (TempCostAdjustmentDetailedLog."Ending Date-Time" - TempCostAdjustmentDetailedLog."Interim Date-Time");
            TempCostAdjustmentDetailedLog.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnInsertItemRegOnBeforeItemRegInsert', '', false, false)]
    local procedure AddGuidToItemRegister(var ItemRegister: Record "Item Register")
    begin
        ItemRegister."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", 'OnBeforeAdjustItem', '', false, false)]
    local procedure PushItemBeforeAdjustment(var TheItem: Record Item)
    begin
        TempItem := TheItem;
        if TempItem.Insert() then;

        TempCostAdjustmentDetailedLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
        TempCostAdjustmentDetailedLog."Item No." := TheItem."No.";
        if TempCostAdjustmentDetailedLog.Find() then begin
            TempCostAdjustmentDetailedLog."Interim Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog.Modify();
        end else begin
            TempCostAdjustmentDetailedLog."Starting Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog."Ending Date-Time" := 0DT;
            TempCostAdjustmentDetailedLog.Duration := 0;
            TempCostAdjustmentDetailedLog."Interim Date-Time" := TempCostAdjustmentDetailedLog."Starting Date-Time";
            TempCostAdjustmentDetailedLog.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", 'OnAfterAdjustItem', '', false, false)]
    local procedure PopItemAfterAdjustment(var TheItem: Record Item)
    begin
        if TempItem.Get(TheItem."No.") then
            TempItem.Delete();

        TempCostAdjustmentDetailedLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
        TempCostAdjustmentDetailedLog."Item No." := TheItem."No.";
        if TempCostAdjustmentDetailedLog.Find() then begin
            TempCostAdjustmentDetailedLog."Ending Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog.Duration += (TempCostAdjustmentDetailedLog."Ending Date-Time" - TempCostAdjustmentDetailedLog."Interim Date-Time");
            TempCostAdjustmentDetailedLog.Modify();
        end;
    end;

    /// <summary>
    /// Logs the event of posting a new item journal line.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforePostItemJnlLine, '', false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        CustomDimensions.Add('NewAdjustedCost', Format(NewAdjustedCost));
        CustomDimensions.Add('NewAdjustedCostACY', Format(NewAdjustedCostACY));
        LogAppend(
          'OnBeforePostItemJnlLine', ItemCostSourceRecipient::Recipient, Database::"Value Entry", OrigValueEntry."Item Ledger Entry No.",
          OrigValueEntry."Item No.", OrigValueEntry."Location Code", OrigValueEntry."Variant Code", OrigValueEntry."Valuation Date", OrigValueEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of forwarding the cost to outbound item ledger entries.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustItemAppliedCostForItemLedgerEntry, '', false, false)]
    local procedure OnAdjustItemAppliedCostForItemLedgerEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnAdjustItemAppliedCostForItemLedgerEntry', ItemCostSourceRecipient::Source, Database::"Item Ledger Entry", ItemLedgEntry."Entry No.",
          ItemLedgEntry."Item No.", ItemLedgEntry."Location Code", ItemLedgEntry."Variant Code", 0D, ItemLedgEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of eliminating the rounding residual on fully applied inbound item ledger entry.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnEliminateRndgResidualOnBeforeCheckHasNewCost, '', false, false)]
    local procedure OnEliminateRndgResidualOnBeforeCheckHasNewCost(InbndItemLedgerEntry: Record "Item Ledger Entry"; RndgCost: Decimal; RndgCostACY: Decimal)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        CustomDimensions.Add('RoundingCost', Format(RndgCost));
        CustomDimensions.Add('RoundingCostACY', Format(RndgCostACY));
        LogAppend(
          'OnEliminateRndgResidualOnBeforeCheckHasNewCost', ItemCostSourceRecipient::Source, Database::"Item Ledger Entry", InbndItemLedgerEntry."Entry No.",
          InbndItemLedgerEntry."Item No.", InbndItemLedgerEntry."Location Code", InbndItemLedgerEntry."Variant Code", 0D, InbndItemLedgerEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of applying the cost to outbound item ledger entry.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustAppliedOutbndEntry, '', false, false)]
    local procedure OnAdjustAppliedOutbndEntry(var OutbndItemLedgEntry: Record "Item Ledger Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnAdjustAppliedOutbndEntry', ItemCostSourceRecipient::Recipient, Database::"Item Ledger Entry", OutbndItemLedgEntry."Entry No.",
          OutbndItemLedgEntry."Item No.", OutbndItemLedgEntry."Location Code", OutbndItemLedgEntry."Variant Code", 0D, OutbndItemLedgEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of putting the cost difference to the adjustment buffer.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforeUpdateAdjmtBuf, '', false, false)]
    local procedure OnBeforeUpdateAdjmtBuf(OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        if (NewAdjustedCost = 0) and (NewAdjustedCostACY = 0) then
            exit;

        CustomDimensions.Add('NewAdjustedCost', Format(NewAdjustedCost));
        CustomDimensions.Add('NewAdjustedCostACY', Format(NewAdjustedCostACY));

        LogAppend(
          'OnBeforeUpdateAdjmtBuf', ItemCostSourceRecipient::Recipient, Database::"Value Entry", OrigValueEntry."Item Ledger Entry No.",
          OrigValueEntry."Item No.", OrigValueEntry."Location Code", OrigValueEntry."Variant Code", OrigValueEntry."Valuation Date", OrigValueEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of adjusting the inbound transfer entry (receive part).
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustAppliedInbndTransEntry, '', false, false)]
    local procedure OnAdjustAppliedInbndTransEntry(var TransItemLedgEntry: Record "Item Ledger Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnAdjustAppliedInbndTransEntry', ItemCostSourceRecipient::Recipient, Database::"Item Ledger Entry", TransItemLedgEntry."Entry No.",
          TransItemLedgEntry."Item No.", TransItemLedgEntry."Location Code", TransItemLedgEntry."Variant Code", 0D, TransItemLedgEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of adjusting inbound item ledger entry applied from an outbound entry (cost application).
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustAppliedInbndEntry, '', false, false)]
    local procedure OnAdjustAppliedInbndEntry(var InbndItemLedgEntry: Record "Item Ledger Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnAdjustAppliedInbndEntry', ItemCostSourceRecipient::Recipient, Database::"Item Ledger Entry", InbndItemLedgEntry."Entry No.",
          InbndItemLedgEntry."Item No.", InbndItemLedgEntry."Location Code", InbndItemLedgEntry."Variant Code", 0D, InbndItemLedgEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of beginning processing the average cost entry point.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforeAvgCostAdjmtEntryPoint, '', false, false)]
    local procedure OnBeforeAvgCostAdjmtEntryPoint(AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnBeforeAvgCostAdjmtEntryPoint', ItemCostSourceRecipient::" ", Database::"Avg. Cost Adjmt. Entry Point", 0,
          AvgCostAdjmtEntryPoint."Item No.", AvgCostAdjmtEntryPoint."Location Code", AvgCostAdjmtEntryPoint."Variant Code", AvgCostAdjmtEntryPoint."Valuation Date", 0D, CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of adjusting the outbound entry with average cost.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustOutbndAvgEntry, '', false, false)]
    local procedure OnAdjustOutbndAvgEntry(var OutbndValueEntry: Record "Value Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnAdjustOutbndAvgEntry', ItemCostSourceRecipient::Recipient, Database::"Value Entry", OutbndValueEntry."Item Ledger Entry No.",
          OutbndValueEntry."Item No.", OutbndValueEntry."Location Code", OutbndValueEntry."Variant Code", OutbndValueEntry."Valuation Date", OutbndValueEntry."Posting Date", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of beginning iterating over the outbound average entries.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforeIteratingOverOutbndAvgEntries, '', false, false)]
    local procedure OnBeforeIteratingOverOutbndAvgEntries(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; RemainingOutbnd: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        CustomDimensions.Add('RemainingOutboundValueEntries', Format(RemainingOutbnd));
        LogAppend(
          'OnBeforeIteratingOverOutbndAvgEntries', ItemCostSourceRecipient::Recipient, Database::"Avg. Cost Adjmt. Entry Point", 0,
          AvgCostAdjmtEntryPoint."Item No.", AvgCostAdjmtEntryPoint."Location Code", AvgCostAdjmtEntryPoint."Variant Code", AvgCostAdjmtEntryPoint."Valuation Date", 0D, CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of adjusting the assembly order.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnMakeAssemblyAdjmt, '', false, false)]
    local procedure OnMakeAssemblyAdjmt(var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnMakeAssemblyAdjmt', ItemCostSourceRecipient::Recipient, Database::"Inventory Adjmt. Entry (Order)",
          SourceInvtAdjmtEntryOrder."Order Type", SourceInvtAdjmtEntryOrder."Order No.", SourceInvtAdjmtEntryOrder."Order Line No.", SourceInvtAdjmtEntryOrder."Item No.", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of adjusting the production order.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnMakeWIPAdjmt, '', false, false)]
    local procedure OnMakeWIPAdjmt(var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnMakeWIPAdjmt', ItemCostSourceRecipient::Recipient, Database::"Inventory Adjmt. Entry (Order)",
          SourceInvtAdjmtEntryOrder."Order Type", SourceInvtAdjmtEntryOrder."Order No.", SourceInvtAdjmtEntryOrder."Order Line No.", SourceInvtAdjmtEntryOrder."Item No.", CustomDimensions);
    end;

    /// <summary>
    /// Logs the event of assessing if the revaluation value entry should be excluded from the average cost calculation.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforeIsExcludeFromAvgCostForRevalPoint, '', false, false)]
    local procedure OnBeforeIsExcludeFromAvgCostForRevalPoint(var RevaluationPoint: Record "Integer"; var RevaluationCheckValueEntry: Record "Value Entry"; var OutbndValueEntry: Record "Value Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        CustomDimensions.Add('RevaluationPointCount', Format(RevaluationPoint.Count()));
        CustomDimensions.Add('RevaluationCheckValueEntryEntryNo', Format(RevaluationCheckValueEntry."Entry No."));
        CustomDimensions.Add('OutbndValueEntryEntryNo', Format(OutbndValueEntry."Entry No."));
        LogAppend(
          'OnBeforeIsExcludeFromAvgCostForRevalPoint', ItemCostSourceRecipient::" ", Database::Integer, 0,
          RevaluationCheckValueEntry."Item No.", RevaluationCheckValueEntry."Location Code", RevaluationCheckValueEntry."Variant Code", 0D, 0D, CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustOutbndAvgEntryOnBeforeForwardAvgCostToInbndEntries, '', false, false)]
    local procedure OnAdjustOutbndAvgEntryOnBeforeForwardAvgCostToInbndEntries(var OutbndItemLedgEntry: Record "Item Ledger Entry")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Trace then
            exit;

        LogAppend(
          'OnAdjustOutbndAvgEntryOnBeforeForwardAvgCostToInbndEntries', ItemCostSourceRecipient::Recipient, Database::"Item Ledger Entry", OutbndItemLedgEntry."Entry No.",
          OutbndItemLedgEntry."Item No.", OutbndItemLedgEntry."Location Code", OutbndItemLedgEntry."Variant Code", 0D, OutbndItemLedgEntry."Posting Date", CustomDimensions);
    end;

    local procedure ClearTraceLog()
    begin
        TempCostAdjustmentTraceLog.Reset();
        TempCostAdjustmentTraceLog.DeleteAll();
    end;

    local procedure LogAppend(EventName: Text[250]; SourceRecipient: Enum "Item Cost Source/Recipient";
                              TracedTableId: Integer; TracedEntryNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10];
                              ValuationDate: Date; PostingDate: Date; CustomDimensions: Dictionary of [Text, Text])
    begin
        EntryNo += 1;
        TempCostAdjustmentTraceLog.Init();
        TempCostAdjustmentTraceLog."Entry No." := EntryNo;
        TempCostAdjustmentTraceLog."Event Name" := EventName;
        TempCostAdjustmentTraceLog."Item Cost Source/Recipient" := SourceRecipient;
        TempCostAdjustmentTraceLog."Traced Table ID" := TracedTableId;
        TempCostAdjustmentTraceLog."Traced Entry No." := TracedEntryNo;
        TempCostAdjustmentTraceLog."Item No." := ItemNo;
        TempCostAdjustmentTraceLog."Location Code" := LocationCode;
        TempCostAdjustmentTraceLog."Variant Code" := VariantCode;
        TempCostAdjustmentTraceLog."Valuation Date" := ValuationDate;
        TempCostAdjustmentTraceLog."Posting Date" := PostingDate;
        TempCostAdjustmentTraceLog."Custom Dimensions" := CopyStr(DictionaryToJsonAsText(CustomDimensions), 1, MaxStrLen(TempCostAdjustmentTraceLog."Custom Dimensions"));
        TempCostAdjustmentTraceLog.Insert(true);
    end;

    local procedure LogAppend(EventName: Text[250]; SourceRecipient: Enum "Item Cost Source/Recipient";
                              TracedTableId: Integer; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; ItemNo: Code[20]; CustomDimensions: Dictionary of [Text, Text])
    begin
        EntryNo += 1;
        TempCostAdjustmentTraceLog.Init();
        TempCostAdjustmentTraceLog."Entry No." := EntryNo;
        TempCostAdjustmentTraceLog."Event Name" := EventName;
        TempCostAdjustmentTraceLog."Item Cost Source/Recipient" := SourceRecipient;
        TempCostAdjustmentTraceLog."Traced Table ID" := TracedTableId;
        TempCostAdjustmentTraceLog."Order Type" := OrderType;
        TempCostAdjustmentTraceLog."Order No." := OrderNo;
        TempCostAdjustmentTraceLog."Order Line No." := OrderLineNo;
        TempCostAdjustmentTraceLog."Item No." := ItemNo;
        TempCostAdjustmentTraceLog."Custom Dimensions" := CopyStr(DictionaryToJsonAsText(CustomDimensions), 1, MaxStrLen(TempCostAdjustmentTraceLog."Custom Dimensions"));
        TempCostAdjustmentTraceLog.Insert(true);
    end;

    internal procedure FlushTraceLog()
    var
        CostAdjustmentTraceLog: Record "Cost Adjustment Trace Log";
    begin
        CostAdjustmentTraceLog.Reset();
        CostAdjustmentTraceLog.DeleteAll();

        TempCostAdjustmentTraceLog.Reset();
        if TempCostAdjustmentTraceLog.FindSet() then
            repeat
                CostAdjustmentTraceLog := TempCostAdjustmentTraceLog;
                CostAdjustmentTraceLog.Insert();
            until TempCostAdjustmentTraceLog.Next() = 0;

        FeatureTelemetry.LogUsage('0000OOM', CostAdjustmentRunnerFeatureTok, RunWithTracingTok, CostAdjmtTelemetryCustomDim);
    end;

    local procedure DictionaryToJsonAsText(Dict: Dictionary of [Text, Text]) JsonAsText: Text
    var
        JObject: JsonObject;
        DictKey: Text;
    begin
        foreach DictKey in Dict.Keys() do
            JObject.Add(DictKey, Dict.Get(DictKey));
        JObject.WriteTo(JsonAsText);
    end;

    [InternalEvent(false, false)]
    local procedure OnCostAdjustmentDetailLogCreated(var CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log")
    begin
    end;
}
