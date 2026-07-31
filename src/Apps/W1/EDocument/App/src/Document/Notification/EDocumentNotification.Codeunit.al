// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Environment.Configuration;
using System.Telemetry;

codeunit 6123 "E-Document Notification"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SubTotalMismatchNoToleranceTxt: Label 'E-Document purchase draft header Sub Total differs from the sum of the lines.', Locked = true;
        SubTotalMismatchNotificationShownTxt: Label 'E-Document purchase draft Sub Total mismatch notification shown.', Locked = true;

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

    /// <summary>
    /// Adds a notification that informs a user of Purchase Document Draft that the header Sub Total no longer matches the sum of the lines.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure AddSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
        MyNotifications: Record "My Notifications";
        SubTotalMismatchMsg: Label 'The document total does not match the sum of the lines. Review the amounts before finalizing the draft.';
    begin
        if not GuiAllowed() then
            exit;
        if not MyNotifications.IsEnabled(GetSubTotalMismatchNotificationId()) then
            exit;
        if EDocumentNotification.Get(EDocumentEntryNo, GetSubTotalMismatchNotificationId(), UserId()) then
            exit;
        EDocumentNotification.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.Validate(ID, GetSubTotalMismatchNotificationId());
        EDocumentNotification.Validate("User Id", UserId());
        EDocumentNotification.Validate(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotification.Validate(Message, SubTotalMismatchMsg);
        EDocumentNotification.Insert(true);
    end;

    /// <summary>
    /// Removes the persisted Sub Total Mismatch notification for the current user and e-document, e.g. when the totals re-converge.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure RemoveSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if EDocumentNotification.Get(EDocumentEntryNo, GetSubTotalMismatchNotificationId(), UserId()) then
            EDocumentNotification.Delete(true);
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
            "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.SetRange(Dismissed, false);
        if not EDocumentNotification.FindSet() then
            exit;

        repeat
            SendNotification(EDocumentNotification);
        until EDocumentNotification.Next() = 0;
    end;

    /// <summary>
    /// Dismisses the notification of the certain Purchase Document Draft that informs a user about a vendor that is matched by name but not by address.
    /// The persisted notification row is kept and marked as dismissed so it is not re-shown to this user.
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
        EDocumentNotification.Dismissed := true;
        EDocumentNotification.Modify(true);
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

    /// <summary>
    /// Dismisses the Sub Total Mismatch notification for the current Purchase Document Draft.
    /// The persisted notification row is kept and marked as dismissed so the mismatch is not
    /// re-shown to this user until an amount edit re-arms it.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DismissSubTotalMismatchNotification(Notification: Notification)
    var
        EDocumentNotification: Record "E-Document Notification";
        EDocumentEntryNo: Integer;
        Id: Guid;
    begin
        Evaluate(EDocumentEntryNo, Notification.GetData(EDocumentNotification.FieldName("E-Document Entry No.")));
        Evaluate(Id, Notification.GetData(EDocumentNotification.FieldName(ID)));
        if not EDocumentNotification.Get(EDocumentEntryNo, Id, UserId()) then
            exit;
        EDocumentNotification.Dismissed := true;
        EDocumentNotification.Modify(true);
    end;

    /// <summary>
    /// Returns whether the current user has the Sub Total Mismatch notification enabled.
    /// </summary>
    procedure IsSubTotalMismatchNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(GuiAllowed() and MyNotifications.IsEnabled(GetSubTotalMismatchNotificationId()));
    end;

    /// <summary>
    /// Returns whether the current user has dismissed the Sub Total Mismatch notification for the e-document.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure IsSubTotalMismatchDismissed(EDocumentEntryNo: Integer): Boolean
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if EDocumentNotification.Get(EDocumentEntryNo, GetSubTotalMismatchNotificationId(), UserId()) then
            exit(EDocumentNotification.Dismissed);
        exit(false);
    end;

    /// <summary>
    /// Re-arms the Sub Total Mismatch notification for the current user by removing a previously
    /// dismissed row, so the mismatch can be evaluated and shown again after an amount edit.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure ReArmSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not EDocumentNotification.Get(EDocumentEntryNo, GetSubTotalMismatchNotificationId(), UserId()) then
            exit;
        if EDocumentNotification.Dismissed then
            EDocumentNotification.Delete(true);
    end;

    /// <summary>
    /// Disables the Sub Total Mismatch notification for the current user.
    /// </summary>
    /// <param name="Notification">Current notification</param>
    procedure DisableSubTotalMismatchNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
        EDocumentNotification: Record "E-Document Notification";
        SubTotalMismatchNotificationNameTok: Label 'Notify user of Purchase Document Draft that the document total does not match the sum of the lines.';
        SubTotalMismatchNotificationDescTok: Label 'Show a notification informing a user of Purchase Document Draft that the header total no longer matches the sum of the lines.';
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetSubTotalMismatchNotificationId()) then
                MyNotifications.InsertDefault(GetSubTotalMismatchNotificationId(), SubTotalMismatchNotificationNameTok, SubTotalMismatchNotificationDescTok, false);
        EDocumentNotification.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.DeleteAll(true);
    end;

    /// <summary>
    /// Sends the Sub Total Mismatch notification for the e-document, if it is persisted and not dismissed.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure SendSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not GuiAllowed() then
            exit;
        if not EDocumentNotification.Get(EDocumentEntryNo, GetSubTotalMismatchNotificationId(), UserId()) then
            exit;
        if EDocumentNotification.Dismissed then
            exit;
        SendNotification(EDocumentNotification);
    end;

    /// <summary>
    /// Evaluates whether the header Sub Total still matches the sum of the persisted lines and updates the
    /// persisted Sub Total Mismatch notification accordingly. Used on the display path, where the notification
    /// is sent separately by <see cref="SendPurchaseDocumentDraftNotifications"/>.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure EvaluateSubTotalMismatch(EDocumentEntryNo: Integer)
    var
        PendingEDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        UpdateSubTotalMismatchNotification(EDocumentEntryNo, PendingEDocumentPurchaseLine, false, false, false, false);
    end;

    /// <summary>
    /// Re-evaluates the Sub Total Mismatch notification after the user changed an amount on the header,
    /// re-arming a previously dismissed notification.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure EvaluateSubTotalMismatchOnHeaderEdit(EDocumentEntryNo: Integer)
    var
        PendingEDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        UpdateSubTotalMismatchNotification(EDocumentEntryNo, PendingEDocumentPurchaseLine, false, false, true, true);
    end;

    /// <summary>
    /// Re-evaluates the Sub Total Mismatch notification after the user changed an amount on a draft line.
    /// The supplied line is used instead of its persisted version, because page field validation runs before
    /// the record is written to the database.
    /// </summary>
    /// <param name="EDocumentPurchaseLine">The line as currently edited by the user</param>
    /// <param name="LineDeleted">Whether the line is being deleted</param>
    procedure EvaluateSubTotalMismatchOnLineEdit(EDocumentPurchaseLine: Record "E-Document Purchase Line"; LineDeleted: Boolean)
    begin
        UpdateSubTotalMismatchNotification(EDocumentPurchaseLine."E-Document Entry No.", EDocumentPurchaseLine, true, LineDeleted, true, true);
    end;

    local procedure UpdateSubTotalMismatchNotification(EDocumentEntryNo: Integer; PendingEDocumentPurchaseLine: Record "E-Document Purchase Line"; HasPendingLine: Boolean; PendingLineDeleted: Boolean; ReArm: Boolean; SendOnMismatch: Boolean)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
        RoundingPrecision: Decimal;
        LinesSubTotal: Decimal;
        Difference: Decimal;
        Tolerance: Decimal;
        LineCount: Integer;
    begin
        if not IsSubTotalMismatchNotificationEnabled() then
            exit;
        if not EDocumentPurchaseHeader.Get(EDocumentEntryNo) then
            exit;
        if ReArm then
            ReArmSubTotalMismatchNotification(EDocumentEntryNo);

        RoundingPrecision := Abs(EDocumentImportHelper.GetCurrencyRoundingPrecision(EDocumentPurchaseHeader."Currency Code"));
        LinesSubTotal := CalculateLinesSubTotal(EDocumentEntryNo, PendingEDocumentPurchaseLine, HasPendingLine, PendingLineDeleted, RoundingPrecision, LineCount);

        Difference := Abs(EDocumentPurchaseHeader."Sub Total" - LinesSubTotal);
        Tolerance := LineCount * RoundingPrecision;

        CustomDimensions.Add('EntryNo', Format(EDocumentEntryNo));
        CustomDimensions.Add('HeaderSubTotal', Format(EDocumentPurchaseHeader."Sub Total", 0, 9));
        CustomDimensions.Add('LinesSubTotal', Format(LinesSubTotal, 0, 9));
        CustomDimensions.Add('Tolerance', Format(Tolerance, 0, 9));
        CustomDimensions.Add('Difference', Format(Difference, 0, 9));

        if Difference <> 0 then
            Telemetry.LogMessage('0000UVL', SubTotalMismatchNoToleranceTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);

        if Difference <= Tolerance then begin
            RemoveSubTotalMismatchNotification(EDocumentEntryNo);
            exit;
        end;

        Telemetry.LogMessage('0000UVM', SubTotalMismatchNotificationShownTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        if IsSubTotalMismatchDismissed(EDocumentEntryNo) then
            exit;
        AddSubTotalMismatchNotification(EDocumentEntryNo);
        if SendOnMismatch then
            SendSubTotalMismatchNotification(EDocumentEntryNo);
    end;

    local procedure CalculateLinesSubTotal(EDocumentEntryNo: Integer; PendingEDocumentPurchaseLine: Record "E-Document Purchase Line"; HasPendingLine: Boolean; PendingLineDeleted: Boolean; RoundingPrecision: Decimal; var LineCount: Integer) LinesSubTotal: Decimal
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PendingLineFound: Boolean;
    begin
        EDocumentPurchaseLine.SetLoadFields("E-Document Entry No.", "Line No.", Quantity, "Unit Price", "Total Discount");
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        if EDocumentPurchaseLine.FindSet() then
            repeat
                if HasPendingLine and (EDocumentPurchaseLine."Line No." = PendingEDocumentPurchaseLine."Line No.") then begin
                    PendingLineFound := true;
                    if not PendingLineDeleted then begin
                        LinesSubTotal += LineSubTotal(PendingEDocumentPurchaseLine, RoundingPrecision);
                        LineCount += 1;
                    end;
                end else begin
                    LinesSubTotal += LineSubTotal(EDocumentPurchaseLine, RoundingPrecision);
                    LineCount += 1;
                end;
            until EDocumentPurchaseLine.Next() = 0;

        if HasPendingLine and (not PendingLineFound) and (not PendingLineDeleted) then begin
            LinesSubTotal += LineSubTotal(PendingEDocumentPurchaseLine, RoundingPrecision);
            LineCount += 1;
        end;
    end;

    local procedure LineSubTotal(EDocumentPurchaseLine: Record "E-Document Purchase Line"; RoundingPrecision: Decimal): Decimal
    begin
        exit(Round(EDocumentPurchaseLine.Quantity * EDocumentPurchaseLine."Unit Price", RoundingPrecision) - EDocumentPurchaseLine."Total Discount");
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
            "E-Document Notification Type"::"Sub Total Mismatch":
                begin
                    Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissSubTotalMismatchNotification');
                    Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableSubTotalMismatchNotification');
                end;
        end;
    end;

    local procedure GetVendorMatchedByNameNotAddressNotificationId(): Guid
    begin
        exit('bc0d8537-8e8d-4d94-a07a-a5a54c729d2a');
    end;

    local procedure GetSubTotalMismatchNotificationId(): Guid
    begin
        exit('a1e6c0d2-3b4f-4c8a-9d1e-2f7b6a5c4d3e');
    end;
}