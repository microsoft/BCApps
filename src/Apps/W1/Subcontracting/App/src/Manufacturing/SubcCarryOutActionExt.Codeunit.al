// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;

codeunit 99001523 "Subc. Carry Out Action Ext."
{
#if not CLEAN27
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", OnAfterTransferPlanningComp, '', false, false)]
#pragma warning restore AL0432
#else
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Carry Out Action", OnAfterTransferPlanningComp, '', false, false)]
#endif
    local procedure OnAfterTransferPlanningComp(var PlanningComponent: Record "Planning Component"; var ProdOrderComponent: Record "Prod. Order Component")
#if not CLEAN29
    var
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
        ProdOrderComponent."Component Supply Method" := PlanningComponent."Component Supply Method";
        ProdOrderComponent."Subc. Original Location Code" := PlanningComponent."Orig. Location Code";
        ProdOrderComponent."Subc. Orig. Bin Code" := PlanningComponent."Orig. Bin Code";
    end;
}