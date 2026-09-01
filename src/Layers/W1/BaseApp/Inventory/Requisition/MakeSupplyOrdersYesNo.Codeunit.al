// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Foundation.Navigate;

codeunit 5521 "Make Supply Orders (Yes/No)"
{
    TableNo = "Requisition Line";

    trigger OnRun()
    begin
        ReqLine.Copy(Rec);
        Code();
        Rec := ReqLine;
    end;

    var
        ReqLine: Record "Requisition Line";
        MfgUserTempl: Record "Manufacturing User Template";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        BlockForm: Boolean;
        CarriedOut: Boolean;

    local procedure "Code"()
    var
        ReqLine2: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        CarriedOut := false;
        IsHandled := false;
        OnBeforeCode(ReqLine, MfgUserTempl, CarriedOut, BlockForm, IsHandled);
        if IsHandled then
            exit;

        if not BlockForm then
            if not (PAGE.RunModal(PAGE::"Make Supply Orders", MfgUserTempl) = ACTION::LookupOK) then
                exit;

        ReqLine2.Copy(ReqLine);
        ReqLine2.FilterGroup(2);
        ReqLine.CopyFilters(ReqLine2);

        RunCarryOutActionMsgPlan();
    end;

    local procedure RunCarryOutActionMsgPlan()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCarryOutActionMsgPlan(IsHandled, CarriedOut, ReqLine, MfgUserTempl);
        if IsHandled then
            exit;

        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.SetDemandOrder(ReqLine, MfgUserTempl);
        CarryOutActionMsgPlan.RunModal();
        Clear(CarryOutActionMsgPlan);
        CarriedOut := true;

        OnAfterRunCarryOutActionMsgPlan(CarriedOut, ReqLine, MfgUserTempl);
    end;

    procedure SetManufUserTemplate(ManufUserTemplate: Record "Manufacturing User Template")
    begin
        MfgUserTempl := ManufUserTemplate;
    end;

    procedure SetBlockForm()
    begin
        BlockForm := true;
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntry: Record "Document Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCreatedDocumentBuffer(IsHandled, TempDocumentEntry);
        if not IsHandled then
            CarryOutActionMsgPlan.SetCreatedDocumentBuffer(TempDocumentEntry);
    end;

    procedure ActionMsgCarriedOut(): Boolean
    begin
        exit(CarriedOut);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCarryOutActionMsgPlan(CarriedOut: Boolean; ReqLine: Record "Requisition Line"; MfgUserTempl: Record "Manufacturing User Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ReqLine: Record "Requisition Line"; var MfgUserTempl: Record "Manufacturing User Template"; var CarriedOut: Boolean; var BlockForm: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCarryOutActionMsgPlan(var IsHandled: Boolean; var CarriedOut: Boolean; var ReqLine: Record "Requisition Line"; var MfgUserTempl: Record "Manufacturing User Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCreatedDocumentBuffer(var IsHandled: Boolean; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;
}

