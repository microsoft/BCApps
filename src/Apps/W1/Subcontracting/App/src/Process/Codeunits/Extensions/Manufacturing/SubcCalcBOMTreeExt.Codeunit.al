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
        SubcSessionState: Codeunit "Subc. Session State";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcSessionState.SetRecordID('OnBeforeCalcRoutingLineCosts', ParentItem.RecordId());
    end;
}