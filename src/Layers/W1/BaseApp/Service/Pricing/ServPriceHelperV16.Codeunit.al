// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;

codeunit 6457 "Serv. Price Helper V16"
{
    var
        PriceHelperV16: Codeunit "Price Helper - V16";

    [EventSubscriber(ObjectType::Table, Database::"Service Cost", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteServiceCost(var Rec: Record "Service Cost"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            PriceHelperV16.DeletePriceLines(AssetType::"Service Cost", Rec.Code, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cost", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameServiceCost(var Rec: Record "Service Cost"; var xRec: Record "Service Cost"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            PriceHelperV16.RenameAssetInPrices(AssetType::"Service Cost", xRec.Code, Rec.Code);
    end;
}