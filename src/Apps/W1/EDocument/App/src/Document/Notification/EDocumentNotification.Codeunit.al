// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Environment.Configuration;

codeunit 6123 "E-Document Notification"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Adds a notification that informs a user of Purchase Document Draft that a vendor is matched by name but not by address.
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    /// </summary>
    procedure AddVendorMatchedByNameNotAddressNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
        MyNotifications: Record "My Notifications";
        VendorMatchedByNameNotAddressMsg: Label 'Vendor matched by name but not by address.';
    begin
        if not GuiAllowed() then
            exit;
        if not MyNotifications.IsEnabled(GetVendorMatchedByNameNotAddressNotificationId()) then
            exit;
        if EDocumentNotification.Get(EDocumentEntryNo, GetVendorMatchedByNameNotAddressNotificationId(), UserId()) then
            exit;
        EDocumentNotification.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.Validate(ID, GetVendorMatchedByNameNotAddressNotificationId());
        EDocumentNotification.Validate("User Id", UserId());
        EDocumentNotification.Validate(Type, "E-Document Notification Type"::"Vendor Matched By Name Not Address");
        EDocumentNotification.Validate(Message, VendorMatchedByNameNotAddressMsg);
        EDocumentNotification.Insert(true);
    end;

    procedure AddVATRateMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
        MyNotifications: Record "My Notifications";
        VATRateMismatchMsg: Label 'VAT Product Posting Groups could not be automatically determined for one or more lines. Please review before creating the invoice.';
    begin
        if not GuiAllowed() then
            exit;
        if not MyNotifications.IsEnabled(GetVATRateMismatchNotificationId()) then
            exit;
        if EDocumentNotification.Get(EDocumentEntryNo, GetVATRateMismatchNotificationId(), UserId()) then
            exit;
        EDocumentNotification.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.Validate(ID, GetVATRateMismatchNotificationId());
        EDocumentNotification.Validate("User Id", UserId());
        EDocumentNotification.Validate(Type, "E-Document Notification Type"::"VAT Rate Mismatch");
        EDocumentNotification.Validate(Message, VATRateMismatchMsg);
        EDocumentNotification.Insert(true);
    end;

    /// <summary>
    /// Send notifications for Purchase Document Draft page
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    /// </summary>
    procedure SendPurchaseDocumentDraftNotifications(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not GuiAllowed() then
            exit;

        EDocumentNotification.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.SetFilter(Type, '%1|%2',
            "E-Document Notification Type"::"Vendor Matched By Name Not Address",
            "E-Document Notification Type"::"VAT Rate Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        if not EDocumentNotification.FindSet() then
            exit;

        repeat
            SendNotification(EDocumentNotification);
        until EDocumentNotification.Next() = 0;
    end;

    /// <summary>
    /// Dismisses the notification of the certain Purchase Document Draft that informs a user about a vendor that is matched by name but not by address.
    /// </summary>
    /// <param name="Notification"></param>
    procedure DismissVendorMatchedByNameNotAddressNotification(Notification: Notification)
    var
        EDocumentNotification: Record "E-Document Notification";
        EDocumentEntryNo: Integer;
        Id: Guid;
    begin
        Evaluate(EDocumentEntryNo, Notification.GetData(EDocumentNotification.FieldName("E-Document Entry No.")));
        Evaluate(Id, Notification.GetData(EDocumentNotification.FieldName(ID)));
        if not EDocumentNotification.Get(EDocumentEntryNo, Id, UserId()) then
            exit;
        EDocumentNotification.Delete(true);
    end;

    /// <summary>
    /// Disables the notification that informs a user of Purchase Document Draft that a vendor is matched by name but not by address.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DisableVendorMatchedByNameNotAddressNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
        EDocumentNotification: Record "E-Document Notification";
        VendorMatchedByNameNotAddressNotificationNameTok: Label 'Notify user of Purchase Document Draft that vendor is matched by name but not by address.';
        VendorMatchedByNameNotAddressNotificationDescTok: Label 'Show a notification informing a user of Purchase Document Draft that a vendor is matched by name but not by address.';
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetVendorMatchedByNameNotAddressNotificationId()) then
                MyNotifications.InsertDefault(GetVendorMatchedByNameNotAddressNotificationId(), VendorMatchedByNameNotAddressNotificationNameTok, VendorMatchedByNameNotAddressNotificationDescTok, false);
        EDocumentNotification.SetRange(Type, "E-Document Notification Type"::"Vendor Matched By Name Not Address");
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.DeleteAll(true);
    end;

    procedure DismissVATRateMismatchNotification(Notification: Notification)
    var
        EDocumentNotification: Record "E-Document Notification";
        EDocumentEntryNo: Integer;
        Id: Guid;
    begin
        Evaluate(EDocumentEntryNo, Notification.GetData(EDocumentNotification.FieldName("E-Document Entry No.")));
        Evaluate(Id, Notification.GetData(EDocumentNotification.FieldName(ID)));
        if not EDocumentNotification.Get(EDocumentEntryNo, Id, UserId()) then
            exit;
        EDocumentNotification.Delete(true);
    end;

    procedure DisableVATRateMismatchNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
        EDocumentNotification: Record "E-Document Notification";
        VATRateMismatchNotificationNameTok: Label 'Notify user of Purchase Document Draft that VAT posting groups could not be auto-resolved.';
        VATRateMismatchNotificationDescTok: Label 'Show a notification when VAT Product Posting Groups could not be automatically determined from the extracted VAT rate.';
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetVATRateMismatchNotificationId()) then
                MyNotifications.InsertDefault(GetVATRateMismatchNotificationId(), VATRateMismatchNotificationNameTok, VATRateMismatchNotificationDescTok, false);
        EDocumentNotification.SetRange(Type, "E-Document Notification Type"::"VAT Rate Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.DeleteAll(true);
    end;

    local procedure SendNotification(EDocumentNotification: Record "E-Document Notification")
    var
        MyNotifications: Record "My Notifications";
        VendorMatchedByNameNotAddressNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(EDocumentNotification.ID) then
            exit;

        VendorMatchedByNameNotAddressNotification.Id := EDocumentNotification.ID;
        VendorMatchedByNameNotAddressNotification.Message := EDocumentNotification.Message;
        VendorMatchedByNameNotAddressNotification.Scope := NotificationScope::LocalScope;
        AddActionsToNotification(VendorMatchedByNameNotAddressNotification, EDocumentNotification);
        VendorMatchedByNameNotAddressNotification.Send();
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
            "E-Document Notification Type"::"VAT Rate Mismatch":
                begin
                    Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissVATRateMismatchNotification');
                    Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableVATRateMismatchNotification');
                end;
        end;
    end;

    local procedure GetVendorMatchedByNameNotAddressNotificationId(): Guid
    begin
        exit('bc0d8537-8e8d-4d94-a07a-a5a54c729d2a');
    end;

    local procedure GetVATRateMismatchNotificationId(): Guid
    begin
        exit('d4a7e1c3-5f92-4b8a-ae67-1c3d5f924b8a');
    end;
}