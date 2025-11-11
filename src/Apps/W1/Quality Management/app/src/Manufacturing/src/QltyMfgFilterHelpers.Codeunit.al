// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Helper functions for filtering manufacturing-related data in Quality Management.
/// </summary>
codeunit 20470 "Qlty. Mfg. Filter Helpers"
{
    /// <summary>
    /// Starts the assist edit dialog for choosing a machine.
    /// </summary>
    /// <param name="MachineNoFilter"></param>
    /// <returns></returns>
    procedure AssistEditMachine(var MachineNoFilter: Code[20]): Boolean
    var
        MachineCenter: Record "Machine Center";
        MachineCenterList: Page "Machine Center List";
    begin
        MachineCenterList.LookupMode(true);
        if MachineNoFilter <> '' then begin
            MachineCenter.SetFilter("No.", MachineNoFilter);
            if MachineCenter.FindSet() then
                MachineCenterList.SetRecord(MachineCenter);
        end;
        MachineCenter.SetRange("No.");

        if MachineCenterList.RunModal() in [Action::LookupOK, Action::OK] then begin
            MachineCenterList.GetRecord(MachineCenter);
            MachineNoFilter := MachineCenter."No.";
            exit(true);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing a routing.
    /// </summary>
    /// <param name="RoutingNoFilter"></param>
    /// <returns></returns>
    procedure AssistEditRouting(var RoutingNoFilter: Code[20]): Boolean
    var
        RoutingHeader: Record "Routing Header";
        RoutingList: Page "Routing List";
    begin
        RoutingList.LookupMode(true);
        if RoutingNoFilter <> '' then begin
            RoutingHeader.SetFilter("No.", RoutingNoFilter);
            if RoutingHeader.FindSet() then
                RoutingList.SetRecord(RoutingHeader);
        end;
        RoutingHeader.SetRange("No.");

        if RoutingList.RunModal() in [Action::LookupOK, Action::OK] then begin
            RoutingList.GetRecord(RoutingHeader);
            RoutingNoFilter := RoutingHeader."No.";
            exit(true);
        end;
    end;

    procedure AssistEditRoutingOperation(InRoutingNoFilter: Code[20]; var OperationNoFilter: Code[20]): Boolean
    var
        RoutingLine: Record "Routing Line";
        QltyRoutingLineLookup: Page "Qlty. Routing Line Lookup";

    begin
        QltyRoutingLineLookup.LookupMode(true);

        if InRoutingNoFilter <> '' then
            RoutingLine.SetFilter("Routing No.", InRoutingNoFilter);

        if OperationNoFilter <> '' then begin
            RoutingLine.SetFilter("Operation No.", OperationNoFilter);
            if RoutingLine.FindSet() then
                QltyRoutingLineLookup.SetRecord(RoutingLine);
            RoutingLine.SetRange("Operation No.");
        end;

        QltyRoutingLineLookup.SetTableView(RoutingLine);

        if QltyRoutingLineLookup.RunModal() in [Action::LookupOK, Action::OK] then begin
            QltyRoutingLineLookup.GetRecord(RoutingLine);
            OperationNoFilter := RoutingLine."Operation No.";
            exit(true);
        end;
    end;

    procedure AssistEditWorkCenter(var WorkCenterNoFilter: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: Page "Work Center List";
    begin
        WorkCenterList.LookupMode(true);
        if WorkCenterNoFilter <> '' then begin
            WorkCenter.SetFilter("No.", WorkCenterNoFilter);
            if WorkCenter.FindSet() then
                WorkCenterList.SetRecord(WorkCenter);
        end;
        WorkCenter.SetRange("No.");

        if WorkCenterList.RunModal() in [Action::LookupOK, Action::OK] then begin
            WorkCenterList.GetRecord(WorkCenter);
            WorkCenterNoFilter := WorkCenter."No.";
            exit(true);
        end;
    end;

    #region Event Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Filter Helpers", 'OnAssistEditMachine', '', false, false)]
    local procedure HandleOnAssistEditMachine(var MachineNoFilter: Code[20]; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        IsHandled := AssistEditMachine(MachineNoFilter);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Filter Helpers", 'OnAssistEditRouting', '', false, false)]
    local procedure HandleOnAssistEditRouting(var RoutingNoFilter: Code[20]; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        IsHandled := AssistEditRouting(RoutingNoFilter);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Filter Helpers", 'OnAssistEditRoutingOperation', '', false, false)]
    local procedure HandleOnAssistEditRoutingOperation(InRoutingNoFilter: Code[20]; var OperationNoFilter: Code[20]; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        IsHandled := AssistEditRoutingOperation(InRoutingNoFilter, OperationNoFilter);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Filter Helpers", 'OnAssistEditWorkCenter', '', false, false)]
    local procedure HandleOnAssistEditWorkCenter(var WorkCenterNoFilter: Code[20]; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        IsHandled := AssistEditWorkCenter(WorkCenterNoFilter);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnInferGenerationRuleIntentForSourceTable', '', false, false)]
    local procedure HandleOnInferGenerationRuleIntentForSourceTable(SourceTableNo: Integer; var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"; var QltyCertainty: Enum "Qlty. Certainty")
    begin
        case SourceTableNo of
            Database::"Prod. Order Routing Line", Database::"Prod. Order Line", Database::"Production Order":
                begin
                    QltyGenRuleIntent := "Qlty. Gen. Rule Intent".FromInteger(20470); // Production
                    QltyCertainty := QltyCertainty::Yes;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnGetIsProductionIntent', '', false, false)]
    local procedure HandleOnGetIsProductionIntent(SourceTableNo: Integer; ConditionFilter: Text[400]; var IsProduction: Boolean)
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        if IsProduction then
            exit;

        case SourceTableNo of
            Database::"Prod. Order Routing Line",
            Database::"Prod. Order Line",
            Database::"Production Order":
                IsProduction := true;
            Database::"Item Ledger Entry":
                if QltyFilterHelpers.GetIsFilterSetToValue(SourceTableNo, ConditionFilter, TempItemLedgerEntry.FieldNo("Entry Type"), TempItemLedgerEntry."Entry Type"::Output) then
                    IsProduction := true
                else
                    if QltyFilterHelpers.GetIsFilterSetToValue(SourceTableNo, ConditionFilter, TempItemLedgerEntry.FieldNo("Order Type"), TempItemLedgerEntry."Order Type"::Production) then
                        IsProduction := true;
            Database::"Item Journal Line":
                if QltyFilterHelpers.GetIsFilterSetToValue(SourceTableNo, ConditionFilter, TempItemJournalLine.FieldNo("Entry Type"), TempItemJournalLine."Entry Type"::Output) then
                    IsProduction := true
                else
                    if QltyFilterHelpers.GetIsFilterSetToValue(SourceTableNo, ConditionFilter, TempItemJournalLine.FieldNo("Order Type"), TempItemJournalLine."Order Type"::Production) then
                        IsProduction := true;
        end;
    end;

    #endregion Event Subscribers
}
