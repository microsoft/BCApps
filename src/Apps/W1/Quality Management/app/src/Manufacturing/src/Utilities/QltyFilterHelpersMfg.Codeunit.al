// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
codeunit 20400 "Qlty. Filter Helpers Mfg."
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

    procedure AssistEditWorkCenter(var RoutingNoFilter: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: Page "Work Center List";
    begin
        WorkCenterList.LookupMode(true);
        if RoutingNoFilter <> '' then begin
            WorkCenter.SetFilter("No.", RoutingNoFilter);
            if WorkCenter.FindSet() then
                WorkCenterList.SetRecord(WorkCenter);
        end;
        WorkCenter.SetRange("No.");

        if WorkCenterList.RunModal() in [Action::LookupOK, Action::OK] then begin
            WorkCenterList.GetRecord(WorkCenter);
            RoutingNoFilter := WorkCenter."No.";
            exit(true);
        end;
    end;
}