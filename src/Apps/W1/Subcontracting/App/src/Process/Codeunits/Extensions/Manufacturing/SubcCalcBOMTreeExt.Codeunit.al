// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;

codeunit 99001521 "Subc. Calc BOM Tree Ext."
{
#if not CLEAN27
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate BOM Tree", OnBeforeCalcRoutingLineCosts, '', false, false)]
#pragma warning restore AL0432
#else
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Calculate BOM Tree", OnBeforeCalcRoutingLineCosts, '', false, false)]
#endif
    local procedure OnBeforeCalcRoutingLineCosts(var RoutingLine: Record "Routing Line"; var LotSize: Decimal; var ScrapPct: Decimal; ParentItem: Record Item)
    var
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
    begin
        SingleInstanceDictionary.SetRecordID('OnBeforeCalcRoutingLineCosts', ParentItem.RecordId());
    end;
}