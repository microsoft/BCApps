// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.StandardCost;

codeunit 99001514 "Subc. Calc.StandardCost Ext."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", OnAfterCalcRtngLineCost, '', false, false)]
    local procedure OnAfterCalcRtngLineCost(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLSub: Decimal)
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        SubcPriceManagement.CalcStandardCostOnAfterCalcRtngLineCost(RoutingLine, MfgItemQtyBase, SLSub);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", OnCalcMfgItemOnBeforeCalcRtngCost, '', false, false)]
    local procedure OnCalcMfgItemOnBeforeCalcRtngCost(var Item: Record Item; Level: Integer; var LotSize: Decimal; var MfgItemQtyBase: Decimal)
    var
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
    begin
        SingleInstanceDictionary.SetRecordID('OnCalcMfgItemOnBeforeCalcRtngCost', Item.RecordId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", OnAfterSetProperties, '', false, false)]
    local procedure OnAfterSetProperties(var NewCalculationDate: Date; var NewCalcMultiLevel: Boolean; var NewUseAssemblyList: Boolean; var NewLogErrors: Boolean; var NewStdCostWkshName: Text[50]; var NewShowDialog: Boolean)
    var
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
    begin
        SingleInstanceDictionary.SetDate('OnAfterSetProperties', NewCalculationDate);
    end;
}