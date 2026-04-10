// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Foundation.Reporting;
using System.EMail;

codeunit 545 "Send Reminder"
{
    Permissions = tabledata "Issued Reminder Header" = rmid,
                  tabledata "Email Outbox" = rmid;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnAfterEmailSent', '', false, false)]
    local procedure HandleEmailSent(var TempEmailItem: Record "Email Item" temporary; PostedDocNo: Code[20]; ReportUsage: Integer; EmailSentSuccesfully: Boolean)
    var
        DummyReportSelections: Record "Report Selections";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if not EmailSentSuccesfully then
            exit;

        if ReportUsage <> DummyReportSelections.Usage::Reminder.AsInteger() then
            exit;

        if not IssuedReminderHeader.Get(PostedDocNo) then
            exit;

        UpdateSentEmailFields(IssuedReminderHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Issued Reminder Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ClearEmailFields(var Rec: Record "Issued Reminder Header"; var xRec: Record "Issued Reminder Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if not xRec.Find() then
            exit;

        if Rec."Reminder Level" <> xRec."Reminder Level" then
            Rec.ClearSentEmailFieldsOnLevelUpdate(Rec);
    end;

    /// <summary>
    /// Prompts the user to select how the reminder was sent and updates the sent email fields accordingly.
    /// </summary>
    /// <param name="IssuedReminderHeader">Specifies the issued reminder header to update.</param>
    procedure UpdateReminderSentFromUI(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        SelectedOption: Integer;
    begin
        SelectedOption := StrMenu(ReminderSentByEmailTxt, 1, MarkAsSentQst);
        if SelectedOption = 0 then
            exit;

        if SelectedOption = 1 then
            UpdateSentEmailFields(IssuedReminderHeader)
        else
            UpdateSentForCurrentLevelWithoutEmail(IssuedReminderHeader);
    end;

    /// <summary>
    /// Updates the email tracking fields on the issued reminder header after successful email delivery.
    /// </summary>
    /// <param name="IssuedReminderHeader">Specifies the issued reminder header to update.</param>
    procedure UpdateSentEmailFields(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader."Sent For Current Level" := true;
        IssuedReminderHeader."Last Email Sent Date Time" := CurrentDateTime();
        IssuedReminderHeader."Total Email Sent Count" += 1;
        if IssuedReminderHeader."Email Sent Level" <> IssuedReminderHeader."Reminder Level" then begin
            IssuedReminderHeader."Last Level Email Sent Count" := 1;
            IssuedReminderHeader."Email Sent Level" := IssuedReminderHeader."Reminder Level";
        end else
            IssuedReminderHeader."Last Level Email Sent Count" += 1;

        IssuedReminderHeader.Modify();
    end;

    /// <summary>
    /// Marks the reminder as sent for the current level without recording email delivery details.
    /// </summary>
    /// <param name="IssuedReminderHeader">Specifies the issued reminder header to update.</param>
    procedure UpdateSentForCurrentLevelWithoutEmail(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        if IssuedReminderHeader."Reminder Level" <> IssuedReminderHeader."Email Sent Level" then
            IssuedReminderHeader.ClearSentEmailFieldsOnLevelUpdate(IssuedReminderHeader);

        IssuedReminderHeader."Sent For Current Level" := true;
        IssuedReminderHeader.Modify();
    end;

    /// <summary>
    /// Stores the failed email outbox message ID on the issued reminder header for later retry.
    /// </summary>
    /// <param name="MessageID">Specifies the email outbox entry number of the failed message.</param>
    /// <param name="IssuedReminderNo">Specifies the issued reminder number to update.</param>
    procedure SetFailedOutboxMessageID(MessageID: BigInteger; IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if not IssuedReminderHeader.Get(IssuedReminderNo) then
            exit;

        IssuedReminderHeader."Failed Email Outbox Entry No." := MessageID;
        IssuedReminderHeader.Modify();
    end;

    /// <summary>
    /// Deletes the failed email outbox message linked to the issued reminder if it exists.
    /// </summary>
    /// <param name="IssuedReminderNo">Specifies the issued reminder number whose failed outbox message should be deleted.</param>
    procedure DeleteFailedOutboxMessageIfExists(IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        EmailOutbox: Record "Email Outbox";
    begin
        if not IssuedReminderHeader.Get(IssuedReminderNo) then
            exit;

        if EmailOutbox.Get(IssuedReminderHeader."Failed Email Outbox Entry No.") then
            EmailOutbox.Delete();

        Clear(IssuedReminderHeader."Failed Email Outbox Entry No.");
        IssuedReminderHeader.Modify();
    end;

    var
        ReminderSentByEmailTxt: Label 'Yes,No';
        MarkAsSentQst: Label 'Was reminder sent by email?';
}
