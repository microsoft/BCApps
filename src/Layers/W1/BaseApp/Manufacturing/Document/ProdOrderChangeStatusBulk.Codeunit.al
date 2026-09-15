// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

codeunit 99000750 ProdOrderChangeStatusBulk
{
    TableNo = "Production Order";

    trigger OnRun()
    var
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(NewFinishOrderWithoutOutput);
        ProdOrderStatusMgt.ChangeProdOrderStatus(Rec, NewProductionOrderStatus, NewPostingDate, NewUpdateUnitCost);
    end;

    internal procedure SetParameters(Status: Enum "Production Order Status"; PostingDate: Date; UpdateUnitCost: Boolean; FinishOrderWithoutOutput: Boolean)
    begin
        NewProductionOrderStatus := Status;
        NewPostingDate := PostingDate;
        NewUpdateUnitCost := UpdateUnitCost;
        NewFinishOrderWithoutOutput := FinishOrderWithoutOutput;
    end;

    var
        NewProductionOrderStatus: Enum "Production Order Status";
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        NewFinishOrderWithoutOutput: Boolean;
}
