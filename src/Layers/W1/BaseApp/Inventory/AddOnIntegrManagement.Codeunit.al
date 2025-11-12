#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 5403 AddOnIntegrManagement
{
    Permissions = TableData Microsoft.Manufacturing.Setup."Manufacturing Setup" = rimd;
    ObsoleteReason = 'Procedures from thois codeunit moved to other codeunits';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    [Obsolete('Moved to codeunit CheckProdOrderStatus', '27.0')]
    procedure CheckReceiptOrderStatus(var SalesLine: Record "Sales Line")
    var
        CheckProdOrderStatus: Codeunit Microsoft.Manufacturing.Document."Check Prod. Order Status";
    begin
        CheckProdOrderStatus.CheckReceiptOrderStatus(SalesLine);
    end;

    [Obsolete('Moved to table extension MfgPurchaseLine', '27.0')]
    procedure ValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        PurchLine.ValidateProdOrderOnPurchLine();
    end;

    [Obsolete('Replaced by subscriber in codeunit MfgRequisitionLine', '27.0')]
    procedure ResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
        ReqLine.ResetReqLineFields();
    end;

    [Obsolete('Moved to table extension MfgRequisitionLine', '27.0')]
    procedure ValidateProdOrderOnReqLine(var ReqLine: Record "Requisition Line")
    begin
        ReqLine.ValidateProdOrderOnReqLine(ReqLine);
    end;

    [Obsolete('Not used', '27.0')]
    procedure InitMfgSetup()
    var
        MfgSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
    begin
        if not MfgSetup.FindFirst() then begin
            MfgSetup.Init();
            MfgSetup.Insert();
        end;
    end;

    [Obsolete('Moved to codeunit ', '27.0')]
    procedure TransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; ReqLine: Record "Requisition Line")
    begin
        PurchOrderLine.TransferFromReqLineToPurchLine(PurchOrderLine, ReqLine);
    end;

    internal procedure RunOnBeforeCheckReceiptOrderStatus(SalesLine: Record "Sales Line"; var Checked: Boolean)
    begin
        OnBeforeCheckReceiptOrderStatus(SalesLine, Checked);
    end;

    [Obsolete('Moved to codeunit CheckProdOrderStatus', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiptOrderStatus(SalesLine: Record "Sales Line"; var Checked: Boolean)
    begin
    end;

    internal procedure RunOnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line")
    begin
        OnAfterTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine);
    end;

    [Obsolete('Moved to codeunit MfgRequisitionLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line")
    begin
    end;

    internal procedure RunOnBeforeTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
        OnBeforeTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgRequisitionLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnBeforeValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforeValidateProdOrderOnPurchLine(PurchLine, IsHandled);
    end;

    [Obsolete('Moved to table extension MfgPurchaseLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(var WordCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; var OrderDate: Date)
    begin
        OnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(WordCenter, OrderDate);
    end;

    [Obsolete('Moved to cpodeunit MfgRequisitionLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(var WordCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; var OrderDate: Date)
    begin
    end;

    internal procedure RunOnAfterResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
        OnAfterResetReqLineFields(ReqLine);
    end;

    [Obsolete('Moved to codeunit MfgRequisitionLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
    end;
}
#endif

