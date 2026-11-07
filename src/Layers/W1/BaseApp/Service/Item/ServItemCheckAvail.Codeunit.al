// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Service.Document;
using System.Environment.Configuration;

codeunit 6453 "Serv. Item Check Avail."
{
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ContextInfo: Dictionary of [Text, Text];

    procedure ServiceInvLineCheck(ServInvLine: Record "Service Line") Rollback: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceInvLineCheck(ServInvLine, Rollback, IsHandled);
        if IsHandled then
            exit(Rollback);

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          ServInvLine.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), true);
        if ServiceInvLineShowWarning(ServInvLine) then
            Rollback := ItemCheckAvail.ShowAndHandleAvailabilityPage(ServInvLine.RecordId);
    end;

    procedure ServiceInvLineShowWarning(ServLine: Record "Service Line") IsWarning: Boolean
    var
        OldServLine: Record "Service Line";
        OldItemNetChange: Decimal;
        OldItemNetResChange: Decimal;
        IsHandled: Boolean;
    begin
        if not ItemCheckAvail.ShowWarningForThisItem(ServLine."No.") then
            exit(false);

        OldItemNetChange := 0;

        OldServLine := ServLine;

        if OldServLine.Find() then // Find previous quantity
            if (OldServLine."Document Type" = OldServLine."Document Type"::Order) and
               (OldServLine."No." = ServLine."No.") and
               (OldServLine."Variant Code" = ServLine."Variant Code") and
               (OldServLine."Location Code" = ServLine."Location Code") and
               (OldServLine."Bin Code" = ServLine."Bin Code")
            then begin
                IsHandled := false;
                OnServiceInvLineShowWarningOnAfterFindingPrevServiceLineQtyWithinPeriod(ServLine, OldServLine, IsHandled);
                if not IsHandled then begin
                    OldItemNetChange := -OldServLine."Outstanding Qty. (Base)";
                    OldServLine.CalcFields("Reserved Qty. (Base)");
                    OldItemNetResChange := -OldServLine."Reserved Qty. (Base)";
                end;
            end;

        ItemCheckAvail.SetUseOrderPromise(true);
        IsHandled := false;
        OnServiceInvLineShowWarningOnBeforeShowWarning(ServLine, ContextInfo, OldServLine, OldItemNetChange, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        exit(
          ItemCheckAvail.ShowWarning(
            ServLine."No.",
            ServLine."Variant Code",
            ServLine."Location Code",
            ServLine."Unit of Measure Code",
            ServLine."Qty. per Unit of Measure",
            -ServLine."Outstanding Quantity",
            OldItemNetChange,
            ServLine."Needed by Date",
            OldServLine."Needed by Date"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceInvLineShowWarningOnAfterFindingPrevServiceLineQtyWithinPeriod(ServiceLine: Record "Service Line"; OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceInvLineShowWarningOnBeforeShowWarning(ServLine: Record "Service Line"; var ContextInfo: Dictionary of [Text, Text]; OldServLine: Record "Service Line"; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvLineCheck(ServInvLine: Record Microsoft.Service.Document."Service Line"; var Rollback: Boolean; var IsHandled: Boolean)
    begin
    end;

    procedure RaiseUpdateInterruptedError()
    begin
        ItemCheckAvail.RaiseUpdateInterruptedError();
    end;
}
