// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Pricing;

using Microsoft.Projects.Resources.Resource;

codeunit 220 "Resource-Find Cost"
{
    TableNo = "Resource Cost";

    trigger OnRun()
    begin
        ResCost.Copy(Rec);
        ResCost2 := ResCost;

        FindResUnitCost(ResCost);

        case ResCost."Cost Type" of
            ResCost."Cost Type"::Fixed:
                ;
            ResCost."Cost Type"::"% Extra":
                begin
                    ResCost2."Work Type Code" := '';
                    FindResUnitCost(ResCost2);
                    ResCost."Direct Unit Cost" := ResCost2."Direct Unit Cost" * (1 + ResCost."Direct Unit Cost" / 100);
                    ResCost."Unit Cost" := ResCost2."Unit Cost" * (1 + ResCost."Unit Cost" / 100);
                end;
            ResCost."Cost Type"::"LCY Extra":
                begin
                    ResCost2."Work Type Code" := '';
                    FindResUnitCost(ResCost2);
                    ResCost."Direct Unit Cost" := ResCost2."Direct Unit Cost" + ResCost."Direct Unit Cost";
                    ResCost."Unit Cost" := ResCost2."Unit Cost" + ResCost."Unit Cost";
                end;
        end;
        Rec := ResCost;
    end;

    var
        ResCost: Record "Resource Cost";
        ResCost2: Record "Resource Cost";
        Res: Record Resource;

    local procedure FindResUnitCost(var NearestResCost: Record "Resource Cost")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindResUnitCost(NearestResCost, IsHandled);
        if IsHandled then
            exit;

        if NearestResCost.Get(NearestResCost.Type::Resource, NearestResCost.Code, NearestResCost."Work Type Code") then
            exit;
        Res.Get(NearestResCost.Code);
        if NearestResCost.Get(NearestResCost.Type::"Group(Resource)", Res."Resource Group No.", NearestResCost."Work Type Code") then
            exit;
        if NearestResCost.Get(NearestResCost.Type::All, '', NearestResCost."Work Type Code") then
            exit;
        NearestResCost.Init();
        NearestResCost.Code := Res."No.";
        NearestResCost."Direct Unit Cost" := Res."Direct Unit Cost";
        NearestResCost."Unit Cost" := Res."Unit Cost";

        OnAfterFindResUnitCost(NearestResCost, Res);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResUnitCost(var ResourceCost: Record "Resource Cost"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindResUnitCost(var ResourceCost: Record "Resource Cost"; var IsHandled: Boolean)
    begin
    end;
}
