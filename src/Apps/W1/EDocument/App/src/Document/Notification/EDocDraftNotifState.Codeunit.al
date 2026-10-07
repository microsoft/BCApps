// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Telemetry;

/// <summary>
/// Owns the persisted state of Purchase Document Draft notifications: the rows in the
/// "E-Document Notification" table, the Sub Total mismatch evaluation, and its telemetry.
/// This codeunit never displays anything. Everything user-facing lives in
/// codeunit "E-Document Notification", which is the only caller of this one.
/// </summary>
codeunit 6436 "E-Doc. Draft Notif. State"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        VendorMatchedByNameNotAddressMsg: Label 'Vendor matched by name but not by address.';
        SubTotalMismatchMsg: Label 'The document total does not match the sum of the lines. Review the amounts before finalizing the draft.';
        SubTotalMismatchNoToleranceTxt: Label 'E-Document purchase draft header Sub Total differs from the sum of the lines.';
        SubTotalMismatchNotificationCreatedTxt: Label 'E-Document purchase draft Sub Total mismatch notification state created.';

    /// <summary>
    /// Re-evaluates the Sub Total mismatch from the persisted lines and updates the persisted
    /// notification. A previously dismissed notification stays dismissed.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader">The draft header as currently loaded by the caller</param>
    /// <returns>True if the state was evaluated; false if the header carries no e-document.</returns>
    procedure RefreshSubTotalMismatch(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    var
        RoundingPrecision: Decimal;
        LinesSubTotal: Decimal;
        LineCount: Integer;
    begin
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit(false);
        RoundingPrecision := GetRoundingPrecision(EDocumentPurchaseHeader);
        LinesSubTotal := CalculateLinesSubTotal(EDocumentPurchaseHeader."E-Document Entry No.", RoundingPrecision, LineCount);
        ApplyMismatchState(EDocumentPurchaseHeader, LinesSubTotal, LineCount, RoundingPrecision);
        exit(true);
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch after the user changed an amount on the header,
    /// re-arming a previously dismissed notification.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader">The draft header as currently edited by the user</param>
    /// <returns>True if the state was evaluated; false if the header carries no e-document.</returns>
    procedure RefreshSubTotalMismatchAfterHeaderEdit(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    begin
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit(false);
        ReArmSubTotalMismatch(EDocumentPurchaseHeader."E-Document Entry No.");
        exit(RefreshSubTotalMismatch(EDocumentPurchaseHeader));
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch after the user changed an amount on a draft line,
    /// re-arming a previously dismissed notification. The supplied line is used instead of its
    /// persisted version, because page field validation runs before the record is written.
    /// </summary>
    /// <param name="EDocumentPurchaseLine">The line as currently edited by the user</param>
    /// <returns>True if the state was evaluated; false if the owning header could not be read.</returns>
    procedure RefreshSubTotalMismatchAfterLineEdit(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        RoundingPrecision: Decimal;
        LinesSubTotal: Decimal;
        LineCount: Integer;
    begin
        if not GetHeaderForLine(EDocumentPurchaseLine, EDocumentPurchaseHeader) then
            exit(false);
        ReArmSubTotalMismatch(EDocumentPurchaseHeader."E-Document Entry No.");
        RoundingPrecision := GetRoundingPrecision(EDocumentPurchaseHeader);
        LinesSubTotal := CalculateLinesSubTotalWithPendingLine(EDocumentPurchaseHeader."E-Document Entry No.", EDocumentPurchaseLine, RoundingPrecision, LineCount);
        ApplyMismatchState(EDocumentPurchaseHeader, LinesSubTotal, LineCount, RoundingPrecision);
        exit(true);
    end;

    /// <summary>
    /// Re-evaluates the Sub Total mismatch while a draft line is being deleted, re-arming a
    /// previously dismissed notification. The line is still persisted when this runs, so it is
    /// excluded explicitly.
    /// </summary>
    /// <param name="EDocumentPurchaseLine">The line being deleted</param>
    /// <returns>True if the state was evaluated; false if the owning header could not be read.</returns>
    procedure RefreshSubTotalMismatchAfterLineDeletion(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        RoundingPrecision: Decimal;
        LinesSubTotal: Decimal;
        LineCount: Integer;
    begin
        if not GetHeaderForLine(EDocumentPurchaseLine, EDocumentPurchaseHeader) then
            exit(false);
        ReArmSubTotalMismatch(EDocumentPurchaseHeader."E-Document Entry No.");
        RoundingPrecision := GetRoundingPrecision(EDocumentPurchaseHeader);
        LinesSubTotal := CalculateLinesSubTotalExcludingLine(EDocumentPurchaseHeader."E-Document Entry No.", EDocumentPurchaseLine, RoundingPrecision, LineCount);
        ApplyMismatchState(EDocumentPurchaseHeader, LinesSubTotal, LineCount, RoundingPrecision);
        exit(true);
    end;

    /// <summary>
    /// Persists the Vendor Matched By Name Not Address notification for the current user.
    /// Gating on My Notifications is the caller's responsibility.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure AddVendorMatchedByNameNotAddress(EDocumentEntryNo: Integer)
    begin
        AddNotification(EDocumentEntryNo, VendorMatchedByNameNotAddressNotificationId(), "E-Document Notification Type"::"Vendor Matched By Name Not Address", VendorMatchedByNameNotAddressMsg);
    end;

    /// <summary>
    /// Persists the Sub Total Mismatch notification for the current user.
    /// Gating on My Notifications is the caller's responsibility.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure AddSubTotalMismatch(EDocumentEntryNo: Integer)
    begin
        AddNotification(EDocumentEntryNo, SubTotalMismatchNotificationId(), "E-Document Notification Type"::"Sub Total Mismatch", SubTotalMismatchMsg);
    end;

    local procedure AddNotification(EDocumentEntryNo: Integer; NotificationId: Guid; NotificationType: Enum "E-Document Notification Type"; NotificationMessage: Text)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if EDocumentNotification.Get(EDocumentEntryNo, NotificationId, UserId()) then
            exit;
        EDocumentNotification.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.Validate(ID, NotificationId);
        EDocumentNotification.Validate("User Id", CopyStr(UserId(), 1, MaxStrLen(EDocumentNotification."User Id")));
        EDocumentNotification.Validate(Type, NotificationType);
        EDocumentNotification.Validate(Message, CopyStr(NotificationMessage, 1, MaxStrLen(EDocumentNotification.Message)));
        EDocumentNotification.Insert(true);
    end;

    /// <summary>
    /// Removes the persisted Sub Total Mismatch notification for the current user, e.g. when the totals re-converge.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure RemoveSubTotalMismatch(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if EDocumentNotification.Get(EDocumentEntryNo, SubTotalMismatchNotificationId(), UserId()) then
            EDocumentNotification.Delete(true);
    end;

    /// <summary>
    /// Removes a previously dismissed Sub Total Mismatch row so the mismatch can be shown again after an amount edit.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure ReArmSubTotalMismatch(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not EDocumentNotification.Get(EDocumentEntryNo, SubTotalMismatchNotificationId(), UserId()) then
            exit;
        if EDocumentNotification.Dismissed then
            EDocumentNotification.Delete(true);
    end;

    /// <summary>
    /// Marks a persisted notification as dismissed, keeping the row so it is not re-shown to this user.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    /// <param name="NotificationId">Id of the notification</param>
    procedure MarkDismissed(EDocumentEntryNo: Integer; NotificationId: Guid)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not EDocumentNotification.Get(EDocumentEntryNo, NotificationId, UserId()) then
            exit;
        EDocumentNotification.Dismissed := true;
        EDocumentNotification.Modify(true);
    end;

    /// <summary>
    /// Deletes every persisted notification of a type for the current user.
    /// </summary>
    /// <param name="NotificationType">The notification type to clear</param>
    procedure DeleteAllOfType(NotificationType: Enum "E-Document Notification Type")
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        EDocumentNotification.SetRange(Type, NotificationType);
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.DeleteAll(true);
    end;

    /// <summary>
    /// Reads one persisted notification for the current user.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    /// <param name="NotificationId">Id of the notification</param>
    /// <param name="EDocumentNotification">The row, when found</param>
    procedure GetNotification(EDocumentEntryNo: Integer; NotificationId: Guid; var EDocumentNotification: Record "E-Document Notification"): Boolean
    begin
        exit(EDocumentNotification.Get(EDocumentEntryNo, NotificationId, UserId()));
    end;

    /// <summary>
    /// Finds the Purchase Document Draft notifications that are pending display for the current user.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    /// <param name="EDocumentNotification">Filtered and positioned on the first pending row</param>
    procedure FindPendingDraftNotifications(EDocumentEntryNo: Integer; var EDocumentNotification: Record "E-Document Notification"): Boolean
    begin
        EDocumentNotification.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.SetFilter(Type, '%1|%2',
            "E-Document Notification Type"::"Vendor Matched By Name Not Address",
            "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.SetRange(Dismissed, false);
        exit(EDocumentNotification.FindSet());
    end;

    /// <summary>
    /// Returns whether a Sub Total Mismatch row exists for the current user and e-document.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure SubTotalMismatchExists(EDocumentEntryNo: Integer): Boolean
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        exit(EDocumentNotification.Get(EDocumentEntryNo, SubTotalMismatchNotificationId(), UserId()));
    end;

    /// <summary>
    /// Returns whether the current user has dismissed the Sub Total Mismatch notification for the e-document.
    /// </summary>
    /// <param name="EDocumentEntryNo">Id of e-document</param>
    procedure IsSubTotalMismatchDismissed(EDocumentEntryNo: Integer): Boolean
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if EDocumentNotification.Get(EDocumentEntryNo, SubTotalMismatchNotificationId(), UserId()) then
            exit(EDocumentNotification.Dismissed);
        exit(false);
    end;

    procedure VendorMatchedByNameNotAddressNotificationId(): Guid
    begin
        exit('bc0d8537-8e8d-4d94-a07a-a5a54c729d2a');
    end;

    procedure SubTotalMismatchNotificationId(): Guid
    begin
        exit('a1e6c0d2-3b4f-4c8a-9d1e-2f7b6a5c4d3e');
    end;

    local procedure ApplyMismatchState(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; LinesSubTotal: Decimal; LineCount: Integer; RoundingPrecision: Decimal)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
        Difference: Decimal;
        Tolerance: Decimal;
        EDocumentEntryNo: Integer;
        NotificationExisted: Boolean;
    begin
        EDocumentEntryNo := EDocumentPurchaseHeader."E-Document Entry No.";
        Difference := Abs(EDocumentPurchaseHeader."Sub Total" - LinesSubTotal);
        Tolerance := LineCount * RoundingPrecision;

        CustomDimensions.Add('EntryNo', Format(EDocumentEntryNo));
        CustomDimensions.Add('LineCount', Format(LineCount));
        CustomDimensions.Add('WithinTolerance', Format(Difference <= Tolerance, 0, 9));
        CustomDimensions.Add('DifferenceMagnitude', DifferenceMagnitudeBucket(Difference, EDocumentPurchaseHeader."Sub Total"));

        if Difference <= Tolerance then begin
            RemoveSubTotalMismatch(EDocumentEntryNo);
            exit;
        end;

        // Only log on the transition into the mismatch state, not on every subsequent amount edit.
        NotificationExisted := SubTotalMismatchExists(EDocumentEntryNo);
        if not NotificationExisted then
            Telemetry.LogMessage('0000UVL', SubTotalMismatchNoToleranceTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);

        if IsSubTotalMismatchDismissed(EDocumentEntryNo) then
            exit;
        AddSubTotalMismatch(EDocumentEntryNo);
        if not NotificationExisted then
            Telemetry.LogMessage('0000UVM', SubTotalMismatchNotificationCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure GetHeaderForLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    begin
        if EDocumentPurchaseLine."E-Document Entry No." = 0 then
            exit(false);
        exit(EDocumentPurchaseHeader.Get(EDocumentPurchaseLine."E-Document Entry No."));
    end;

    local procedure GetRoundingPrecision(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Decimal
    var
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
    begin
        exit(Abs(EDocumentImportHelper.GetCurrencyRoundingPrecision(EDocumentPurchaseHeader."Currency Code")));
    end;

    local procedure CalculateLinesSubTotal(EDocumentEntryNo: Integer; RoundingPrecision: Decimal; var LineCount: Integer) LinesSubTotal: Decimal
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        LineCount := 0;
        if not FindLines(EDocumentEntryNo, EDocumentPurchaseLine) then
            exit;
        repeat
            LinesSubTotal += LineSubTotal(EDocumentPurchaseLine, RoundingPrecision);
            LineCount += 1;
        until EDocumentPurchaseLine.Next() = 0;
    end;

    local procedure CalculateLinesSubTotalWithPendingLine(EDocumentEntryNo: Integer; PendingEDocumentPurchaseLine: Record "E-Document Purchase Line"; RoundingPrecision: Decimal; var LineCount: Integer) LinesSubTotal: Decimal
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PendingLineFound: Boolean;
    begin
        LineCount := 0;
        if FindLines(EDocumentEntryNo, EDocumentPurchaseLine) then
            repeat
                if EDocumentPurchaseLine."Line No." = PendingEDocumentPurchaseLine."Line No." then begin
                    PendingLineFound := true;
                    LinesSubTotal += LineSubTotal(PendingEDocumentPurchaseLine, RoundingPrecision);
                end else
                    LinesSubTotal += LineSubTotal(EDocumentPurchaseLine, RoundingPrecision);
                LineCount += 1;
            until EDocumentPurchaseLine.Next() = 0;

        if not PendingLineFound then begin
            LinesSubTotal += LineSubTotal(PendingEDocumentPurchaseLine, RoundingPrecision);
            LineCount += 1;
        end;
    end;

    local procedure CalculateLinesSubTotalExcludingLine(EDocumentEntryNo: Integer; ExcludedEDocumentPurchaseLine: Record "E-Document Purchase Line"; RoundingPrecision: Decimal; var LineCount: Integer) LinesSubTotal: Decimal
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        LineCount := 0;
        if not FindLines(EDocumentEntryNo, EDocumentPurchaseLine) then
            exit;
        repeat
            if EDocumentPurchaseLine."Line No." <> ExcludedEDocumentPurchaseLine."Line No." then begin
                LinesSubTotal += LineSubTotal(EDocumentPurchaseLine, RoundingPrecision);
                LineCount += 1;
            end;
        until EDocumentPurchaseLine.Next() = 0;
    end;

    local procedure FindLines(EDocumentEntryNo: Integer; var EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    begin
        EDocumentPurchaseLine.SetLoadFields("E-Document Entry No.", "Line No.", Quantity, "Unit Price", "Total Discount");
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        exit(EDocumentPurchaseLine.FindSet());
    end;

    local procedure LineSubTotal(EDocumentPurchaseLine: Record "E-Document Purchase Line"; RoundingPrecision: Decimal): Decimal
    begin
        exit(Round(EDocumentPurchaseLine.Quantity * EDocumentPurchaseLine."Unit Price", RoundingPrecision) - EDocumentPurchaseLine."Total Discount");
    end;

    local procedure DifferenceMagnitudeBucket(Difference: Decimal; HeaderSubTotal: Decimal): Text
    var
        RelativeDifference: Decimal;
    begin
        if Difference = 0 then
            exit('None');
        if HeaderSubTotal = 0 then
            exit('Unknown');
        RelativeDifference := Abs(Difference / HeaderSubTotal);
        if RelativeDifference < 0.01 then
            exit('Below1Pct');
        if RelativeDifference < 0.1 then
            exit('Below10Pct');
        exit('AtLeast10Pct');
    end;
}
