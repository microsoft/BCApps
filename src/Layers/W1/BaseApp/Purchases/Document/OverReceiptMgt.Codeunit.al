// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using System.Utilities;
using Microsoft.Warehouse.Request;
using System.Environment.Configuration;

codeunit 8510 "Over-Receipt Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        OverReceiptQuantityErrTitleTxt: Label 'Qty. to Receive isn''t valid.';
        OverReceiptQuantityErrDescriptionTxt: Label 'The selected Over-Receipt Code - %1, allows you to receive up to %2 units.', Comment = '%1 = Over Receipt Code, %2 = numbers of allowed quantity to receive.';
        OverReceiptNotificationTxt: Label 'An over-receipt quantity is recorded on purchase order %1.', Comment = '%1 - document number';
        QtyToSetCustomDimKeyTxt: Label 'Qty. to Set', Locked = true;
        OverReceiptSetQtyActionCaptionTxt: Label 'Set value to %1', Comment = '%1 = Quantity to set';
#pragma warning disable AA0470
        OverReceiptSetQtyActionTooltipTxt: Label 'Corrects %1 value to %2.';
#pragma warning restore AA0470

    procedure IsOverReceiptAllowed() OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := true;
        OnIsOverReceiptAllowed(OverReceiptAllowed);
    end;

    procedure IsQuantityUpdatedFromWarehouseOverReceipt(PurchaseLine: Record "Purchase Line"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
    begin
        if not IsOverReceiptAllowed() then
            exit(false);
        WhseManagement.SetSourceFilterForWhseRcptLine(
            WarehouseReceiptLine, Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", true);
        if not WarehouseReceiptLine.FindFirst() then
            exit(false);
        exit(PurchaseLine.Quantity = WarehouseReceiptLine.Quantity);
    end;

    procedure IsQuantityUpdatedFromInvtPutAwayOverReceipt(PurchaseLine: Record "Purchase Line"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseManagement: Codeunit "Whse. Management";
    begin
        if not IsOverReceiptAllowed() then
            exit(false);
        WhseManagement.SetSourceFilterForWhseActivityLine(
            WarehouseActivityLine, Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", true);
        WarehouseActivityLine.CalcSums(Quantity);
        exit(PurchaseLine.Quantity = WarehouseActivityLine.Quantity);
    end;

    procedure UpdatePurchaseLineOverReceiptQuantityFromWarehouseReceiptLine(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        UpdatePurchaseLineOverReceiptQuantityFromWarehouseReceiptLine(WarehouseReceiptLine, 0);
    end;

    internal procedure UpdatePurchaseLineOverReceiptQuantityFromWarehouseReceiptLine(WarehouseReceiptLine: Record "Warehouse Receipt Line"; CalledFromFieldNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not IsOverReceiptAllowed() then
            exit;
        if PurchaseLine.Get(WarehouseReceiptLine."Source Subtype", WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then begin
            if CalledFromFieldNo <> 0 then begin
                PurchaseLine.ClearFieldCausedPriceCalculation();
                PurchaseLine.PlanPriceCalcByField(CalledFromFieldNo);
            end;
            PurchaseLine.Validate("Over-Receipt Code", WarehouseReceiptLine."Over-Receipt Code");
            PurchaseLine.Validate("Over-Receipt Quantity", WarehouseReceiptLine."Over-Receipt Quantity");
            PurchaseLine.Modify();
        end;
    end;

    procedure UpdatePurchaseLineOverReceiptQuantityFromWarehouseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        UpdatePurchaseLineOverReceiptQuantityFromWarehouseActivityLine(WarehouseActivityLine, 0)
    end;

    internal procedure UpdatePurchaseLineOverReceiptQuantityFromWarehouseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; CalledFromFieldNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not IsOverReceiptAllowed() then
            exit;

        PurchaseLine.SetLoadFields(PurchaseLine."Over-Receipt Code", PurchaseLine."Over-Receipt Quantity");
        if PurchaseLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then begin
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
            WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
            WarehouseActivityLine.SetSourceFilter(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
              WarehouseActivityLine."Source Line No.", 0, false);
            WarehouseActivityLine.CalcSums("Over-Receipt Quantity");

            if (PurchaseLine."Over-Receipt Code" <> WarehouseActivityLine."Over-Receipt Code") or (PurchaseLine."Over-Receipt Quantity" <> WarehouseActivityLine."Over-Receipt Quantity") then begin
                if CalledFromFieldNo <> 0 then begin
                    PurchaseLine.ClearFieldCausedPriceCalculation();
                    PurchaseLine.PlanPriceCalcByField(CalledFromFieldNo);
                end;
                PurchaseLine.Validate("Over-Receipt Code", WarehouseActivityLine."Over-Receipt Code");
                PurchaseLine.Validate("Over-Receipt Quantity", WarehouseActivityLine."Over-Receipt Quantity");
                PurchaseLine.Modify();
            end;
        end;
    end;

    procedure VerifyOverReceiptQuantity(PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    var
        OverReceiptCode: Record "Over-Receipt Code";
        UoMMgt: Codeunit "Unit of Measure Management";
        ErrorMessageManagement: Codeunit "Error Message Management";
        OverReceiptQtyBase: Decimal;
        LineBaseQty: Decimal;
        MaxOverReceiptBaseQtyAllowed: Decimal;
        MaxQtyAllowed: Decimal;
        IsHandled: Boolean;
        ShouldCallError: Boolean;
        ActionableErrorInfo: ErrorInfo;
    begin
        IsHandled := false;
        OnBeforeVerifyOverReceiptQuantity(PurchaseLine, xPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if not IsOverReceiptAllowed() then
            exit;
        OverReceiptCode.Get(PurchaseLine."Over-Receipt Code");
        OverReceiptQtyBase := UOMMgt.CalcBaseQty(PurchaseLine."Over-Receipt Quantity", PurchaseLine."Qty. per Unit of Measure");
        LineBaseQty := UoMMgt.CalcBaseQty(xPurchaseLine.Quantity - xPurchaseLine."Over-Receipt Quantity", xPurchaseLine."Qty. per Unit of Measure");
        MaxOverReceiptBaseQtyAllowed := UOMMgt.RoundQty(LineBaseQty / 100 * OverReceiptCode."Over-Receipt Tolerance %");
        MaxQtyAllowed := (xPurchaseLine.Quantity - xPurchaseLine."Over-Receipt Quantity") * (1 + OverReceiptCode."Over-Receipt Tolerance %" / 100);
        MaxQtyAllowed := UoMMgt.RoundQty(MaxQtyAllowed, xPurchaseLine."Qty. Rounding Precision", '<');

        ShouldCallError := OverReceiptQtyBase > MaxOverReceiptBaseQtyAllowed;
        OnVerifyOverReceiptQuantityOnAfterCalcShouldCallError(PurchaseLine, OverReceiptQtyBase, MaxOverReceiptBaseQtyAllowed, ShouldCallError);
        if ShouldCallError then
            if MaxQtyAllowed = xPurchaseLine."Qty. to Receive" then
                Error(OverReceiptQuantityErrTitleTxt)
            else begin
                ActionableErrorInfo := ErrorMessageManagement.BuildActionableErrorInfo(OverReceiptQuantityErrTitleTxt,
                    StrSubstNo(OverReceiptQuantityErrDescriptionTxt, OverReceiptCode.Code, MaxQtyAllowed),
                    PurchaseLine.SystemId,
                    StrSubstNo(OverReceiptSetQtyActionCaptionTxt, MaxQtyAllowed),
                    Codeunit::"Over-Receipt Mgt.",
                    'SetMaxAllowedOverReceiptQtyOnPurchaseLine',
                    StrSubstNo(OverReceiptSetQtyActionTooltipTxt, PurchaseLine.FieldCaption("Qty. to Receive"), MaxQtyAllowed));
                ActionableErrorInfo.CustomDimensions.Add(QtyToSetCustomDimKeyTxt, Format(MaxQtyAllowed));
                Error(ActionableErrorInfo);
            end;
    end;

    procedure GetDefaultOverReceiptCode(PurchaseLine: Record "Purchase Line") DefaultOverReceiptCode: Code[20]
    var
        Item: Record Item;
        Vendor: Record Vendor;
        OverReceiptCode: Record "Over-Receipt Code";
        IsHandled: Boolean;
    begin
        DefaultOverReceiptCode := '';
        OnGetDefaultOverReceiptCode(PurchaseLine, DefaultOverReceiptCode, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        Item.Get(PurchaseLine."No.");
        if Item."Over-Receipt Code" <> '' then begin
            DefaultOverReceiptCode := Item."Over-Receipt Code";
            exit;
        end;

        Vendor.Get(PurchaseLine.GetPurchHeader()."Buy-from Vendor No.");
        if Vendor."Over-Receipt Code" <> '' then begin
            DefaultOverReceiptCode := Vendor."Over-Receipt Code";
            exit;
        end;

        OverReceiptCode.SetRange(Default, true);
        if OverReceiptCode.FindFirst() then
            DefaultOverReceiptCode := OverReceiptCode.Code;
    end;

    procedure RecallOverReceiptNotification(PurchaseHeaderRecordId: RecordId)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(PurchaseHeaderRecordId, false);
    end;

    local procedure ShowOverReceiptNotification(PurchaseHeaderRecordId: RecordId; NotificationMessage: Text)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OverReceiptNotification: Notification;
    begin
        OverReceiptNotification.Id := GetOverReceiptNotificationId();
        OverReceiptNotification.Scope(NotificationScope::LocalScope);
        OverReceiptNotification.Message(NotificationMessage);
        NotificationLifecycleMgt.SendNotification(OverReceiptNotification, PurchaseHeaderRecordId);
    end;

    procedure ShowOverReceiptNotificationFromLine(DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if not IsOverReceiptAllowed() then
            exit;
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
        ShowOverReceiptNotification(PurchaseHeader.RecordId(), StrSubstNo(OverReceiptNotificationTxt, PurchaseHeader."No."));
    end;

    procedure ShowOverReceiptNotificationFromOrder(DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        if not IsOverReceiptAllowed() then
            exit;

        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo) then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Over-Receipt Quantity", '<>0');
        if not PurchaseLine.IsEmpty() then
            ShowOverReceiptNotification(PurchaseHeader.RecordId(), StrSubstNo(OverReceiptNotificationTxt, PurchaseHeader."No."));
    end;

    internal procedure SetMaxAllowedOverReceiptQtyOnPurchaseLine(ErrorInfo: ErrorInfo)
    var
        PurchaseLine: Record "Purchase Line";
        QtyToReceive: Decimal;
    begin
        Evaluate(QtyToReceive, ErrorInfo.CustomDimensions.Get(QtyToSetCustomDimKeyTxt));
        PurchaseLine.GetBySystemId(ErrorInfo.SystemId);

        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure GetOverReceiptNotificationId(): Guid
    begin
        exit('ea49207f-4275-45d1-804e-508dea5ae8dc');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyOverReceiptQuantity(PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOverReceiptAllowed(var OverReceiptAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultOverReceiptCode(PurchaseLine: Record "Purchase Line"; var DefaultOverReceipCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyOverReceiptQuantityOnAfterCalcShouldCallError(PurchaseLine: Record "Purchase Line"; OverReceiptQtyBase: Decimal; MaxOverReceiptQtyAllowed: Decimal; var ShouldCallError: Boolean)
    begin
    end;
}
