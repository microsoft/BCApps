// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99000802 "Mfg. Standard Cost Worksheet" extends "Standard Cost Worksheet"
{
    fields
    {
        modify("No.")
        {
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
    }

    procedure GetWorkCenterCosts(var WorkCenter: Record "Work Center")
    begin
        OnBeforeGetWorkCtrCosts(Rec, WorkCenter);

        "Standard Cost" := WorkCenter."Unit Cost";
        "New Standard Cost" := WorkCenter."Unit Cost";
        "Overhead Rate" := WorkCenter."Overhead Rate";
        "New Overhead Rate" := WorkCenter."Overhead Rate";
        "Indirect Cost %" := WorkCenter."Indirect Cost %";
        "New Indirect Cost %" := WorkCenter."Indirect Cost %";
    end;

    procedure GetMachineCenterCosts(var MachineCenter: Record "Machine Center")
    begin
        OnBeforeGetMachCtrCosts(Rec, MachineCenter);

        "Standard Cost" := MachineCenter."Unit Cost";
        "New Standard Cost" := MachineCenter."Unit Cost";
        "Overhead Rate" := MachineCenter."Overhead Rate";
        "New Overhead Rate" := MachineCenter."Overhead Rate";
        "Indirect Cost %" := MachineCenter."Indirect Cost %";
        "New Indirect Cost %" := MachineCenter."Indirect Cost %";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWorkCtrCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMachCtrCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var MachineCenter: Record "Machine Center")
    begin
    end;
}