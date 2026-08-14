// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Environment.Configuration;

codeunit 6123 "E-Document Notification"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EDocDraftNotifState: Codeunit "E-Doc. Draft Notif. State";

    /// <summary>
    /// Persists a notification that informs a user of Purchase Document Draft that a vendor is matched by name but not by address.
    /// Does not display anything.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure AddVendorMatchedByNameNotAddressNotification(EDocumentEntryNo: Integer)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not GuiAllowed() then
            exit;
        if not MyNotifications.IsEnabled(EDocDraftNotifState.VendorMatchedByNameNotAddressNotificationId()) then
            exit;
        EDocDraftNotifState.AddVendorMatchedByNameNotAddress(EDocumentEntryNo);
    end;

    /// <summary>
    /// Persists a notification that informs a user of Purchase Document Draft that the header Sub Total no longer matches the sum of the lines.
    /// Does not display anything.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure AddSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    begin
        if not IsSubTotalMismatchNotificationEnabled() then
            exit;
        EDocDraftNotifState.AddSubTotalMismatch(EDocumentEntryNo);
    end;

    /// <summary>
    /// Removes the persisted Sub Total Mismatch notification for the current user and e-document, e.g. when the totals re-converge.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure RemoveSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    begin
        EDocDraftNotifState.RemoveSubTotalMismatch(EDocumentEntryNo);
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch and updates the persisted notification. Does not display anything.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader">The draft header as currently loaded by the caller</param>
    procedure RefreshSubTotalMismatch(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
        if not IsSubTotalMismatchNotificationEnabled() then
            exit;
        EDocDraftNotifState.RefreshSubTotalMismatch(EDocumentPurchaseHeader);
    end;

    /// <summary>
    /// Refreshes the Sub Total mismatch state and then shows every pending Purchase Document Draft notification once.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure RefreshAndShowPendingDraftNotifications(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        if EDocumentPurchaseHeader.Get(EDocumentEntryNo) then
            RefreshSubTotalMismatch(EDocumentPurchaseHeader);
        SendPurchaseDocumentDraftNotifications(EDocumentEntryNo);
    end;

    /// <summary>
    /// Shows every pending Purchase Document Draft notification for the current user.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure SendPurchaseDocumentDraftNotifications(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not GuiAllowed() then
            exit;
        if not EDocDraftNotifState.FindPendingDraftNotifications(EDocumentEntryNo, EDocumentNotification) then
            exit;

        repeat
            SendNotification(EDocumentNotification);
        until EDocumentNotification.Next() = 0;
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch after a header amount edit, re-arming a dismissal, and shows the notification if it applies.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader">The draft header as currently edited by the user</param>
    procedure RefreshAndShowSubTotalMismatchAfterHeaderEdit(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
        if not IsSubTotalMismatchNotificationEnabled() then
            exit;
        if not EDocDraftNotifState.RefreshSubTotalMismatchAfterHeaderEdit(EDocumentPurchaseHeader) then
            exit;
        ShowSubTotalMismatchNotification(EDocumentPurchaseHeader."E-Document Entry No.");
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch after a line amount edit, re-arming a dismissal, and shows the notification if it applies.
    /// </summary>
    /// <param name="EDocumentPurchaseLine">The line as currently edited by the user</param>
    procedure RefreshAndShowSubTotalMismatchAfterLineEdit(EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
        if not IsSubTotalMismatchNotificationEnabled() then
            exit;
        if not EDocDraftNotifState.RefreshSubTotalMismatchAfterLineEdit(EDocumentPurchaseLine) then
            exit;
        ShowSubTotalMismatchNotification(EDocumentPurchaseLine."E-Document Entry No.");
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch while a line is being deleted, re-arming a dismissal, and shows the notification if it applies.
    /// </summary>
    /// <param name="EDocumentPurchaseLine">The line being deleted</param>
    procedure RefreshAndShowSubTotalMismatchAfterLineDeletion(EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
        if not IsSubTotalMismatchNotificationEnabled() then
            exit;
        if not EDocDraftNotifState.RefreshSubTotalMismatchAfterLineDeletion(EDocumentPurchaseLine) then
            exit;
        ShowSubTotalMismatchNotification(EDocumentPurchaseLine."E-Document Entry No.");
    end;

    /// <summary>
    /// Shows the Sub Total Mismatch notification for the e-document, if it is persisted and not dismissed.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure ShowSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not GuiAllowed() then
            exit;
        if not EDocDraftNotifState.GetNotification(EDocumentEntryNo, EDocDraftNotifState.SubTotalMismatchNotificationId(), EDocumentNotification) then
            exit;
        if EDocumentNotification.Dismissed then
            exit;
        SendNotification(EDocumentNotification);
    end;

    /// <summary>
    /// Returns whether the current user has the Sub Total Mismatch notification enabled.
    /// </summary>
    procedure IsSubTotalMismatchNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(GuiAllowed() and MyNotifications.IsEnabled(EDocDraftNotifState.SubTotalMismatchNotificationId()));
    end;

    /// <summary>
    /// Returns whether the current user has dismissed the Sub Total Mismatch notification for the e-document.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure IsSubTotalMismatchDismissed(EDocumentEntryNo: Integer): Boolean
    begin
        exit(EDocDraftNotifState.IsSubTotalMismatchDismissed(EDocumentEntryNo));
    end;

    /// <summary>
    /// Dismisses the notification of the certain Purchase Document Draft that informs a user about a vendor that is matched by name but not by address.
    /// The persisted notification row is kept and marked as dismissed so it is not re-shown to this user.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DismissVendorMatchedByNameNotAddressNotification(Notification: Notification)
    var
        EDocumentEntryNo: Integer;
        Id: Guid;
    begin
        if not TryGetNotificationKeys(Notification, EDocumentEntryNo, Id) then
            exit;
        EDocDraftNotifState.MarkDismissed(EDocumentEntryNo, Id);
    end;

    /// <summary>
    /// Disables the notification that informs a user of Purchase Document Draft that a vendor is matched by name but not by address.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DisableVendorMatchedByNameNotAddressNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
        VendorMatchedByNameNotAddressNotificationNameTok: Label 'Notify user of Purchase Document Draft that vendor is matched by name but not by address.';
        VendorMatchedByNameNotAddressNotificationDescTok: Label 'Show a notification informing a user of Purchase Document Draft that a vendor is matched by name but not by address.';
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(EDocDraftNotifState.VendorMatchedByNameNotAddressNotificationId()) then
                MyNotifications.InsertDefault(EDocDraftNotifState.VendorMatchedByNameNotAddressNotificationId(), VendorMatchedByNameNotAddressNotificationNameTok, VendorMatchedByNameNotAddressNotificationDescTok, false);
        EDocDraftNotifState.DeleteAllOfType("E-Document Notification Type"::"Vendor Matched By Name Not Address");
    end;

    /// <summary>
    /// Dismisses the Sub Total Mismatch notification for the current Purchase Document Draft.
    /// The persisted notification row is kept and marked as dismissed so the mismatch is not
    /// re-shown to this user until an amount edit re-arms it.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DismissSubTotalMismatchNotification(Notification: Notification)
    var
        EDocumentEntryNo: Integer;
        Id: Guid;
    begin
        if not TryGetNotificationKeys(Notification, EDocumentEntryNo, Id) then
            exit;
        EDocDraftNotifState.MarkDismissed(EDocumentEntryNo, Id);
    end;

    /// <summary>
    /// Disables the Sub Total Mismatch notification for the current user.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DisableSubTotalMismatchNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
        SubTotalMismatchNotificationNameTok: Label 'Notify user of Purchase Document Draft that the document total does not match the sum of the lines.';
        SubTotalMismatchNotificationDescTok: Label 'Show a notification informing a user of Purchase Document Draft that the header total no longer matches the sum of the lines.';
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(EDocDraftNotifState.SubTotalMismatchNotificationId()) then
                MyNotifications.InsertDefault(EDocDraftNotifState.SubTotalMismatchNotificationId(), SubTotalMismatchNotificationNameTok, SubTotalMismatchNotificationDescTok, false);
        EDocDraftNotifState.DeleteAllOfType("E-Document Notification Type"::"Sub Total Mismatch");
    end;

    local procedure TryGetNotificationKeys(Notification: Notification; var EDocumentEntryNo: Integer; var Id: Guid): Boolean
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not Evaluate(EDocumentEntryNo, Notification.GetData(EDocumentNotification.FieldName("E-Document Entry No."))) then
            exit(false);
        exit(Evaluate(Id, Notification.GetData(EDocumentNotification.FieldName(ID))));
    end;

    local procedure SendNotification(EDocumentNotification: Record "E-Document Notification")
    var
        MyNotifications: Record "My Notifications";
        DraftNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(EDocumentNotification.ID) then
            exit;

        DraftNotification.Id := EDocumentNotification.ID;
        DraftNotification.Message := EDocumentNotification.Message;
        DraftNotification.Scope := NotificationScope::LocalScope;
        AddActionsToNotification(DraftNotification, EDocumentNotification);
        DraftNotification.Send();
    end;

    local procedure AddActionsToNotification(var Notification: Notification; EDocumentNotification: Record "E-Document Notification")
    var
        DismissMsg: Label 'Dismiss';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
    begin
        Notification.SetData(EDocumentNotification.FieldName("E-Document Entry No."), Format(EDocumentNotification."E-Document Entry No."));
        Notification.SetData(EDocumentNotification.FieldName(ID), EDocumentNotification.ID);
        case EDocumentNotification.Type of
            "E-Document Notification Type"::"Vendor Matched By Name Not Address":
                begin
                    Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissVendorMatchedByNameNotAddressNotification');
                    Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableVendorMatchedByNameNotAddressNotification');
                end;
            "E-Document Notification Type"::"Sub Total Mismatch":
                begin
                    Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissSubTotalMismatchNotification');
                    Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableSubTotalMismatchNotification');
                end;
        end;
    end;
}
