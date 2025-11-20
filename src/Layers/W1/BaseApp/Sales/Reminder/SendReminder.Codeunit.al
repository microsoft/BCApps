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

    procedure UpdateSentForCurrentLevelWithoutEmail(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        if IssuedReminderHeader."Reminder Level" <> IssuedReminderHeader."Email Sent Level" then
            IssuedReminderHeader.ClearSentEmailFieldsOnLevelUpdate(IssuedReminderHeader);

        IssuedReminderHeader."Sent For Current Level" := true;
        IssuedReminderHeader.Modify();
    end;

    procedure SetFailedOutboxMessageID(MessageID: BigInteger; IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if not IssuedReminderHeader.Get(IssuedReminderNo) then
            exit;

        IssuedReminderHeader."Failed Email Outbox Entry No." := MessageID;
        IssuedReminderHeader.Modify();
    end;

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
