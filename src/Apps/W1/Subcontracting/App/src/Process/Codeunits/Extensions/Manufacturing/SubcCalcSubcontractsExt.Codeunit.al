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
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Report, Report::"Calculate Subcontracts", OnAfterTransferProdOrderRoutingLine, '', false, false)]
#pragma warning restore AL0432
    local procedure OnAfterTransferProdOrderRoutingLine(var RequisitionLine: Record "Requisition Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
        RequisitionLine."Description 2" := '';
        WorkCenter.SetLoadFields("Name 2");
        if WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
            RequisitionLine."Description 2" := WorkCenter."Name 2";
    end;
}