// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Item;

codeunit 99000812 PlanningWkshManagement
{

    trigger OnRun()
    begin
    end;

    var
        LastReqLine: Record "Requisition Line";

    procedure SetName(CurrentWkshBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
        ReqLine.FilterGroup(2);
        ReqLine.SetRange("Journal Batch Name", CurrentWkshBatchName);
        ReqLine.FilterGroup(0);
        if ReqLine.Find('-') then;
    end;

    procedure GetDescriptionAndRcptName(var ReqLine: Record "Requisition Line"; var ItemDescription: Text[100]; var RoutingDescription: Text[100])
    var
        Item: Record Item;
    begin
        if ReqLine."No." = '' then
            ItemDescription := ''
        else
            if ReqLine."No." <> LastReqLine."No." then
                if Item.Get(ReqLine."No.") then
                    ItemDescription := Item.Description
                else
                    ItemDescription := '';

        OnGetRoutingDescription(ReqLine, RoutingDescription);

        LastReqLine := ReqLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRoutingDescription(var ReqLine: Record "Requisition Line"; var RoutingDescription: Text[100])
    begin
    end;
}

