// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Pricing;

using Microsoft.Projects.Resources.Resource;

codeunit 221 "Resource-Find Price"
{
    TableNo = "Resource Price";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(ResPrice, Rec, IsHandled);
        if IsHandled then
            exit;

        ResPrice.Copy(Rec);
        OnRunOnAfterCopyResourcePrice(Rec, Res);
        if FindResPrice() then
            ResPrice := ResPrice2
        else begin
            ResPrice.Init();
            ResPrice.Code := Res."No.";
            ResPrice."Currency Code" := '';
            ResPrice."Unit Price" := Res."Unit Price";
        end;
        Rec := ResPrice;
    end;

    var
        ResPrice: Record "Resource Price";
        ResPrice2: Record "Resource Price";
        Res: Record Resource;

    local procedure FindResPrice(): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindResPrice(ResPrice, IsHandled, Result, ResPrice2);
        if IsHandled then
            exit(Result);

        if ResPrice2.Get(ResPrice.Type::Resource, ResPrice.Code, ResPrice."Work Type Code", ResPrice."Currency Code") then
            exit(true);

        if ResPrice2.Get(ResPrice.Type::Resource, ResPrice.Code, ResPrice."Work Type Code", '') then
            exit(true);

        Res.Get(ResPrice.Code);
        if ResPrice2.Get(ResPrice.Type::"Group(Resource)", Res."Resource Group No.", ResPrice."Work Type Code", ResPrice."Currency Code") then
            exit(true);

        if ResPrice2.Get(ResPrice.Type::"Group(Resource)", Res."Resource Group No.", ResPrice."Work Type Code", '') then
            exit(true);

        if ResPrice2.Get(ResPrice.Type::All, '', ResPrice."Work Type Code", ResPrice."Currency Code") then
            exit(true);

        if ResPrice2.Get(ResPrice.Type::All, '', ResPrice."Work Type Code", '') then
            exit(true);

        OnAfterFindResPrice(ResPrice, Res);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResPrice(var ResourcePrice: Record "Resource Price"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ResourcePrice: Record "Resource Price"; var ResourcePriceRec: Record "Resource Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindResPrice(var ResourcePrice: Record "Resource Price"; var IsHandled: Boolean; var Result: Boolean; var ResourcePrice2: Record "Resource Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCopyResourcePrice(ResourcePrice: Record "Resource Price"; var Res: Record Resource)
    begin
    end;
}
