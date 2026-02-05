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
    begin
        ProdOrderComponent."Subcontracting Type" := PlanningComponent."Subcontracting Type";
        ProdOrderComponent."Orig. Location Code" := PlanningComponent."Orig. Location Code";
        ProdOrderComponent."Orig. Bin Code" := PlanningComponent."Orig. Bin Code";
    end;
}