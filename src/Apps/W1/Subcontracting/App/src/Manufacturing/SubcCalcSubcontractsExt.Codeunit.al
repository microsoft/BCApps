// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99001529 "Subc. Calc Subcontracts Ext."
{
    [EventSubscriber(ObjectType::Report, Report::"Subc. Calculate Subcontracts", OnAfterTransferProdOrderRoutingLine, '', false, false)]
    local procedure OnAfterTransferProdOrderRoutingLine(var RequisitionLine: Record "Requisition Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
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
        if RequisitionLine."Description 2" = '' then begin
            WorkCenter.SetLoadFields("Name 2");
            if WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
                RequisitionLine."Description 2" := WorkCenter."Name 2";
        end;

        RequisitionLine.Validate("Subc. Standard Task Code", ProdOrderRoutingLine."Standard Task Code");
    end;
}