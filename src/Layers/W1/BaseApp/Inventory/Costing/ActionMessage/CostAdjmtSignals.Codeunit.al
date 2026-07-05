// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using System.Telemetry;
using System.Threading;

codeunit 5842 "Cost Adjmt. Signals"
{
    Access = Internal;
    InherentPermissions = X;
    Permissions = TableData "Cost Adjmt. Action Message" = RIMD;

    var
        InventorySetup: Record "Inventory Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CostAdjustmentActionMsgTok: Label 'Cost adjustment action message', Locked = true;
        NoIssuesFoundTok: Label 'No issues found';
        AverageCostCalcTypeTok: Label 'For the best performance, we recommend setting the Average Cost Calc. Type to Item & Location & Variant';
        AverageCostPeriodTok: Label 'For the best performance, we do not recommend using Average Cost Period longer than a month.';
        AverageCostSettingsSuboptimalTok: Label 'Suboptimal average cost settings';
        CostAdjmtNotRunningTok: Label 'Cost adjustment is not running.';
        InventoryPeriodsUnusedTok: Label 'Inventory periods are not in use.';
        ManyNonAdjustedEntryPointsWithNumberTok: Label '%1 periods require cost adjustment.', Comment = '%1 = count';
        ManyNonAdjustedEntryPointsTok: Label 'Many non-adjusted periods exist.';
        ManyNonAdjustedOrdersWithNumberTok: Label '%1 production and assembly orders require cost adjustment.', Comment = '%1 = count';
        ManyNonAdjustedOrdersTok: Label 'Many non-adjusted orders exist.';
        ZeroInventoryResidualAmountMsg: Label 'Residual amount for zero inventory exists.';
        ItemsExcludedFromCostAdjustmentTok: Label 'Some items remain unadjusted and are excluded from the cost adjustment.';
        ItemsExcludedFromCostAdjustmentWithNumberTok: Label '%1 items remain unadjusted and are excluded from the cost adjustment.', Comment = '%1 = item count';
        OneItemExcludedFromCostAdjustmentWithTok: Label 'One item remains unadjusted and is excluded from the cost adjustment.';
        AutomaticCostAdjustmentTok: Label 'Automatic cost adjustment';
        AdjustCostJobTok: Label 'Adjust Cost job scheduled';
        AdjustCostSourceCodeTok: Label 'Adjust Cost set up in the Source Code Setup';
        AdjustCostInItemRegisterTok: Label 'Adjust Cost logged in the Item Register';
        AdjustCostItemRegisterNewerTok: Label 'Adjust Cost was logged in the Item Register more than %1 days ago.', Comment = '%1 = number of days';
        AdjustCostRunningLongForItemTok: Label 'Cost adjustment for the item took longer than expected.';
        AdjustCostItemDimensionTok: Label 'Item No.';
        AdjustCostDurationDimensionTok: Label 'Duration';
        AdjustCostRunIdDimensionTok: Label 'Run ID';
        ResidualAmountsTelemetryMsg: Label 'Data inconsistency in inventory valuation was detected.';

    internal procedure RunAllTests()
    var
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        CostAdjmtActionMessage.DeleteAll();

        CheckCostingEnabled();
        CheckInventorySetup();
        CheckInventoryPeriod();
        CheckAvgCostAdjmtEntryPoint();
        CheckInvtAdjmtEntryOrder();
        CheckIfItemsAreExcludedFromCostAdjustment();
        CheckResidualAmountFor0Inventory();
    end;

    internal procedure ShowActionMessages(ActionMessagesNotification: Notification)
    var
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        CostAdjmtActionMessage.SetFilter("Next Check Date/Time", '>=%1', CurrentDateTime());
        CostAdjmtActionMessage.SetRange(Active, true);
        Page.Run(0, CostAdjmtActionMessage);
    end;

    local procedure CheckCostingEnabled()
    var
        CustomDimensions: Dictionary of [Text, Text];
        Importance: Integer;
        NextCheckInDays: Integer;
        IsSignalActive: Boolean;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Cost Adjustment Not Running", Database::"Inventory Setup") then
            exit;

        Importance := 2;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        IsSignalActive := false;
        if not CheckAdjustCostEnabledInInventorySetup(CustomDimensions) then
            if not CheckAdjustCostJobScheduled(CustomDimensions) then
                if not CheckAdjustCostItemRegisterExists(CustomDimensions) then
                    IsSignalActive := true;

        if IsSignalActive then begin
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Cost Adjustment Not Running", CostAdjmtNotRunningTok,
              NextCheckInDays, Importance, Database::"Inventory Setup", CopyStr(DictionaryToJsonText(CustomDimensions), 1, 2048), true);
            LogUsageInTelemetry(CostAdjmtNotRunningTok);
        end else
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Cost Adjustment Not Running", NoIssuesFoundTok,
              NextCheckInDays, 5, Database::"Inventory Setup", '', false);
    end;

    local procedure CheckAdjustCostEnabledInInventorySetup(var Dimensions: Dictionary of [Text, Text]): Boolean
    var
        Enabled: Boolean;
    begin
        InventorySetup.GetRecordOnce();
        Enabled := InventorySetup.AutomaticCostAdjmtRequired();

        Dimensions.Add(AutomaticCostAdjustmentTok, Format(Enabled));
        exit(Enabled);
    end;

    local procedure CheckAdjustCostJobScheduled(var Dimensions: Dictionary of [Text, Text]): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        Scheduled: Boolean;
    begin
        JobQueueEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        Scheduled := not JobQueueEntry.IsEmpty();
        Dimensions.Add(AdjustCostJobTok, Format(Scheduled));
        exit(Scheduled);
    end;

    local procedure CheckAdjustCostItemRegisterExists(var Dimensions: Dictionary of [Text, Text]): Boolean
    var
        SourceCodeSetup: Record "Source Code Setup";
        ItemRegister: Record "Item Register";
        Exists: Boolean;
        MaxDays: Integer;
    begin
        MaxDays := GetMaxDaysCostAdjustmentNotRunning();

        SourceCodeSetup.ReadIsolation := IsolationLevel::ReadUncommitted;
        ItemRegister.ReadIsolation := IsolationLevel::ReadUncommitted;
        Exists := true;
        SourceCodeSetup.SetLoadFields("Adjust Cost");
        Exists := SourceCodeSetup.Get() and (SourceCodeSetup."Adjust Cost" <> '');
        Dimensions.Add(AdjustCostSourceCodeTok, Format(Exists));
        if Exists then begin
            ItemRegister.SetCurrentKey("Source Code");
            ItemRegister.SetRange("Source Code", SourceCodeSetup."Adjust Cost");
            Exists := ItemRegister.FindLast();
            Dimensions.Add(AdjustCostInItemRegisterTok, Format(Exists));
            if Exists then
                Dimensions.Add(StrSubstNo(AdjustCostItemRegisterNewerTok, MaxDays), Format(ItemRegister."Creation Date" >= Today() - MaxDays));
        end;
        exit(Exists);
    end;

    local procedure CheckIfItemsAreExcludedFromCostAdjustment()
    var
        Item: Record "Item";
        ActionMessageText: Text[250];
        UnadjustedAndExcludedItemsCount: Integer;
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Item Excluded from Cost Adjustment", Database::Item) then
            exit;

        Importance := 4;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        Item.ReadIsolation := IsolationLevel::ReadUncommitted;

        Item.SetLoadFields("Cost is Adjusted", "Excluded from Cost Adjustment", "No.");
        Item.SetRange("Cost is Adjusted", false);
        Item.SetRange("Excluded from Cost Adjustment", true);
        UnadjustedAndExcludedItemsCount := Item.Count();
        if UnadjustedAndExcludedItemsCount > 0 then begin
            if UnadjustedAndExcludedItemsCount = 1 then
                ActionMessageText := OneItemExcludedFromCostAdjustmentWithTok
            else
                ActionMessageText := StrSubstNo(ItemsExcludedFromCostAdjustmentWithNumberTok, UnadjustedAndExcludedItemsCount);
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Item Excluded from Cost Adjustment", ActionMessageText,
              NextCheckInDays, Importance, Database::Item, '', true);
            LogUsageInTelemetry(ItemsExcludedFromCostAdjustmentTok);
        end else
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Item Excluded from Cost Adjustment", NoIssuesFoundTok,
              NextCheckInDays, 5, Database::Item, '', false);
    end;

    local procedure CheckAvgCostAdjmtEntryPoint()
    var
        NotAdjustedEntryPoints: Query "Avg. Cost Entry Points Not Adj";
        CustomDimensions: Dictionary of [Text, Text];
        MaxEntryPointsNotAdjusted: Integer;
        EntryPointsNotAdjusted: Integer;
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Entry Points", Database::"Avg. Cost Adjmt. Entry Point") then
            exit;

        Importance := 3;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();
        MaxEntryPointsNotAdjusted := GetMaxAvgCostAdjmtEntryPointsNotAdjusted();
        EntryPointsNotAdjusted := 0;

        NotAdjustedEntryPoints.Open();
        while NotAdjustedEntryPoints.Read() and (EntryPointsNotAdjusted < MaxEntryPointsNotAdjusted) do
            EntryPointsNotAdjusted += 1;

        if EntryPointsNotAdjusted >= MaxEntryPointsNotAdjusted then begin
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Entry Points", StrSubstNo(ManyNonAdjustedEntryPointsWithNumberTok, EntryPointsNotAdjusted),
              NextCheckInDays, Importance, Database::"Avg. Cost Adjmt. Entry Point", CopyStr(DictionaryToJsonText(CustomDimensions), 1, 2048), true);
            LogUsageInTelemetry(ManyNonAdjustedEntryPointsTok);
        end else
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Entry Points", NoIssuesFoundTok,
              NextCheckInDays, 5, Database::"Avg. Cost Adjmt. Entry Point", '', false);
    end;

    local procedure CheckInvtAdjmtEntryOrder()
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Orders", Database::"Inventory Adjmt. Entry (Order)") then
            exit;

        Importance := 3;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        InventoryAdjmtEntryOrder.ReadIsolation := IsolationLevel::ReadUncommitted;
        InventoryAdjmtEntryOrder.SetRange("Cost Is Adjusted", false);

        if InventoryAdjmtEntryOrder.Count() > GetMaxInvtAdjmtEntryOrdersNotAdjusted() then begin
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Orders", StrSubstNo(ManyNonAdjustedOrdersWithNumberTok, InventoryAdjmtEntryOrder.Count()),
              NextCheckInDays, Importance, Database::"Inventory Adjmt. Entry (Order)", '', true);
            LogUsageInTelemetry(ManyNonAdjustedOrdersTok);
        end else
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Orders", NoIssuesFoundTok,
              NextCheckInDays, 5, Database::"Inventory Adjmt. Entry (Order)", '', false);
    end;

    local procedure CheckResidualAmountFor0Inventory()
    var
        ResidualAmountItems: Query "Residual Amount - Items";
        CustomDimensions: Dictionary of [Text, Text];
        NoOfSignalsLogged: Integer;
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Data Discrepancy", 0) then
            exit;

        Importance := 2;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        NoOfSignalsLogged := 0;
        ResidualAmountItems.SetFilter(Cost_Amount_Actual, '<>0');
        ResidualAmountItems.TopNumberOfRows(GetMaxNumberOfSignalsLogged());
        ResidualAmountItems.Open();
        while ResidualAmountItems.Read() and (NoOfSignalsLogged < GetMaxNumberOfSignalsLogged()) do begin
            NoOfSignalsLogged += 1;
            CustomDimensions.Add(ResidualAmountItems.ColumnCaption(Item_No), ResidualAmountItems.Item_No);
            CustomDimensions.Add(ResidualAmountItems.ColumnCaption(Cost_Amount_Actual), Format(ResidualAmountItems.Cost_Amount_Actual));
            CustomDimensions.Add(ResidualAmountItems.ColumnCaption(Cost_Amount_Expected), Format(ResidualAmountItems.Cost_Amount_Expected));
        end;
        ResidualAmountItems.Close();

        if NoOfSignalsLogged < GetMaxNumberOfSignalsLogged() then begin
            ResidualAmountItems.SetFilter(Cost_Amount_Expected, '<>0');
            ResidualAmountItems.TopNumberOfRows(GetMaxNumberOfSignalsLogged());
            ResidualAmountItems.Open();
            while ResidualAmountItems.Read() and (NoOfSignalsLogged < GetMaxNumberOfSignalsLogged()) do begin
                NoOfSignalsLogged += 1;
                CustomDimensions.Add(ResidualAmountItems.ColumnCaption(Item_No), ResidualAmountItems.Item_No);
                CustomDimensions.Add(ResidualAmountItems.ColumnCaption(Cost_Amount_Actual), Format(ResidualAmountItems.Cost_Amount_Actual));
                CustomDimensions.Add(ResidualAmountItems.ColumnCaption(Cost_Amount_Expected), Format(ResidualAmountItems.Cost_Amount_Expected));
            end;
        end;

        if NoOfSignalsLogged > 0 then begin
            RaiseCostAdjmtSignal(
                "Cost Adjmt. Action Msg. Type"::"Data Discrepancy", ZeroInventoryResidualAmountMsg, NextCheckInDays,
                Importance, 0, CopyStr(DictionaryToJsonText(CustomDimensions), 1, 2048), true);
            LogUsageInTelemetry(ResidualAmountsTelemetryMsg);
        end;
    end;

    local procedure CheckInventorySetup()
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        IssueFound: Boolean;
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Suboptimal Avg. Cost Settings", Database::"Inventory Setup") then
            exit;

        Importance := 4;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        if AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(WorkDate()) then begin
            IssueFound := true;
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Suboptimal Avg. Cost Settings", AverageCostCalcTypeTok,
              NextCheckInDays, Importance, Database::"Inventory Setup", '', true);
            LogUsageInTelemetry(AverageCostSettingsSuboptimalTok);
        end;

        InventorySetup.GetRecordOnce();
        if InventorySetup."Average Cost Period" in [InventorySetup."Average Cost Period"::Quarter, InventorySetup."Average Cost Period"::Year] then begin
            IssueFound := true;
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Suboptimal Avg. Cost Settings", AverageCostPeriodTok,
              NextCheckInDays, Importance, Database::"Inventory Setup", '', true);
            LogUsageInTelemetry(AverageCostSettingsSuboptimalTok);
        end;

        if not IssueFound then
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Suboptimal Avg. Cost Settings", NoIssuesFoundTok,
              NextCheckInDays, 5, Database::"Inventory Setup", '', false);

    end;

    local procedure CheckInventoryPeriod()
    var
        InventoryPeriod: Record "Inventory Period";
        IssueFound: Boolean;
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Inventory Periods Unused", Database::"Inventory Setup") then
            exit;

        Importance := 4;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        // current period must be open, previous period must be closed
        InventoryPeriod.SetFilter("Ending Date", '>=%1', WorkDate());
        InventoryPeriod.SetRange(Closed, false);
        if InventoryPeriod.IsEmpty() then
            IssueFound := true
        else begin
            InventoryPeriod.SetFilter("Ending Date", '<%1', WorkDate());
            InventoryPeriod.SetRange(Closed, true);
            if InventoryPeriod.IsEmpty() then
                IssueFound := true;
        end;

        if IssueFound then begin
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Inventory Periods Unused", InventoryPeriodsUnusedTok,
              NextCheckInDays, Importance, Database::"Inventory Setup", '', true);
            LogUsageInTelemetry(InventoryPeriodsUnusedTok);
        end else
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Inventory Periods Unused", NoIssuesFoundTok,
              NextCheckInDays, 5, Database::"Inventory Setup", '', false);
    end;

    local procedure RaiseCostAdjmtSignal(Type: Enum "Cost Adjmt. Action Msg. Type"; Message: Text[250]; NextCheckInDays: Integer; Importance: Integer; TableId: Integer; CustomDimensions: Text[2048]; IsActive: Boolean)
    var
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        CostAdjmtActionMessage.Init();
        CostAdjmtActionMessage.Type := Type;
        CostAdjmtActionMessage.Message := Message;
        CostAdjmtActionMessage."Next Check Date/Time" := CreateDateTime(CurrentDateTime().Date() + NextCheckInDays, CurrentDateTime().Time());
        CostAdjmtActionMessage.Importance := Importance;
        CostAdjmtActionMessage."Table Id" := TableId;
        CostAdjmtActionMessage."Custom Dimensions" := CustomDimensions;
        CostAdjmtActionMessage.Active := IsActive;
        CostAdjmtActionMessage.Insert();
    end;

    local procedure SignalAlreadyRaised(Type: Enum "Cost Adjmt. Action Msg. Type"; TableId: Integer): Boolean
    var
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        CostAdjmtActionMessage.ReadIsolation := IsolationLevel::ReadUncommitted;
        CostAdjmtActionMessage.SetRange(Type, Type);
        CostAdjmtActionMessage.SetRange("Table Id", TableId);
        CostAdjmtActionMessage.SetFilter("Next Check Date/Time", '>=%1', CurrentDateTime());
        exit(not CostAdjmtActionMessage.IsEmpty());
    end;

    local procedure DictionaryToJsonText(Dict: Dictionary of [Text, Text]) JsonAsText: Text
    var
        JObject: JsonObject;
        DictKey: Text;
    begin
        foreach DictKey in Dict.Keys() do
            JObject.Add(DictKey, Dict.Get(DictKey));
        JObject.WriteTo(JsonAsText);
    end;

    local procedure IsLoggingEnabled(): Boolean
    begin
        InventorySetup.GetRecordOnce();
        exit(not InventorySetup."Disable Cost Adjmt. Signals");
    end;

    local procedure GetMaxAvgCostAdjmtEntryPointsNotAdjusted(): Integer
    begin
        InventorySetup.GetRecordOnce();

        case InventorySetup."Average Cost Period" of
            InventorySetup."Average Cost Period"::Day:
                exit(GetMaxDaysCostAdjustmentNotRunning());
            InventorySetup."Average Cost Period"::Week:
                exit(GetMaxWeeksCostAdjustmentNotRunning());
            InventorySetup."Average Cost Period"::Month:
                exit(GetMaxMonthsCostAdjustmentNotRunning());
            InventorySetup."Average Cost Period"::Quarter, InventorySetup."Average Cost Period"::Year:
                exit(2);
        end;
    end;

    local procedure LogUsageInTelemetry(EventName: Text)
    begin
        FeatureTelemetry.LogUsage('0000OP3', CostAdjustmentActionMsgTok, EventName);
    end;

    local procedure GetMaxInvtAdjmtEntryOrdersNotAdjusted(): Integer
    begin
        exit(500);
    end;

    local procedure GetMaxCostAdjustmentDurationForItem(): Integer
    begin
        exit(1000 * 60 * 5); // 5 minutes
    end;

    local procedure GetMaxDaysCostAdjustmentNotRunning(): Integer
    begin
        exit(30);
    end;

    local procedure GetMaxWeeksCostAdjustmentNotRunning(): Integer
    begin
        exit(8);
    end;

    local procedure GetMaxMonthsCostAdjustmentNotRunning(): Integer
    begin
        exit(3);
    end;

    local procedure GetMinDaysBetweenCostAdjmtSignals(): Integer
    begin
        exit(7);
    end;

    local procedure GetMaxNumberOfSignalsLogged(): Integer
    begin
        exit(20);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterPostItem, '', true, true)]
    local procedure CheckAndLogAdjustCostEnabledOnAfterPostItem(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
        if not IsLoggingEnabled() then
            exit;

        if not CalledFromAdjustment then
            CheckCostingEnabled();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Subscribers", OnCostAdjustmentDetailLogCreated, '', true, true)]
    local procedure RaiseSignalOnCostAdjustmentDurationExceeded(var CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log")
    var
        CustomDimensions: Dictionary of [Text, Text];
        Importance: Integer;
        NextCheckInDays: Integer;
    begin
        if not IsLoggingEnabled() then
            exit;

        if SignalAlreadyRaised("Cost Adjmt. Action Msg. Type"::"Cost Adjustment Running Long", Database::"Cost Adjustment Detailed Log") then
            exit;

        Importance := 4;
        NextCheckInDays := GetMinDaysBetweenCostAdjmtSignals();

        if CostAdjustmentDetailedLog.Duration > GetMaxCostAdjustmentDurationForItem() then begin
            CustomDimensions.Add(AdjustCostItemDimensionTok, CostAdjustmentDetailedLog."Item No.");
            CustomDimensions.Add(AdjustCostDurationDimensionTok, Format(CostAdjustmentDetailedLog.Duration));
            CustomDimensions.Add(AdjustCostRunIdDimensionTok, CostAdjustmentDetailedLog."Cost Adjustment Run Guid");
            RaiseCostAdjmtSignal(
              "Cost Adjmt. Action Msg. Type"::"Cost Adjustment Running Long", AdjustCostRunningLongForItemTok,
              NextCheckInDays, Importance, Database::"Cost Adjustment Detailed Log", CopyStr(DictionaryToJsonText(CustomDimensions), 1, 2048), true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment Handler", OnAfterMakeInventoryAdjustment, '', true, true)]
    local procedure RaiseSignalOnAfterMakeInventoryAdjustment(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.")
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
    begin
        if not IsLoggingEnabled() then
            exit;

        CostAdjustmentParamsMgt.GetParameters(CostAdjustmentParameter);

        if not CostAdjustmentParameter."Online Adjustment" then begin
            CheckInventorySetup();
            CheckInventoryPeriod();
            CheckAvgCostAdjmtEntryPoint();
            CheckInvtAdjmtEntryOrder();
        end;

        CheckIfItemsAreExcludedFromCostAdjustment();
    end;
}