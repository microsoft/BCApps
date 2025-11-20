// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Email;
using System.Telemetry;

codeunit 6755 "Send Reminder Action" implements "Reminder Action"
{
    var
        SendReminderSetup: Record "Send Reminders Setup";
        ReminderAction: Record "Reminder Action";
        DefaultSetupLbl: Label 'Default setup';
        NoEmailAccountSetupErrorLbl: Label 'No email account are set up, it will not be possible to send reminders by email.\\Do you want to continue?';

    procedure Initialize(ReminderActionSystemId: Guid)
    begin
        if ReminderAction.GetBySystemId(ReminderActionSystemId) then;

        if SendReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code") then
            exit;

        Clear(SendReminderSetup);
    end;

    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid)
    begin
        TableID := Database::"Send Reminders Setup";
        RecordSystemId := SendReminderSetup.SystemId;
    end;

    procedure Invoke(var ErrorOccured: Boolean)
    var
        SendReminderAction: Codeunit "Send Reminder Action Job";
    begin
        SendReminderAction.SendReminders(ReminderAction, ErrorOccured);
    end;

    procedure CreateNew(ActionCode: Code[50]; ActionGroupCode: Code[50]): Boolean
    var
        DummyReminderActionGroup: Record "Reminder Action Group";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        Clear(SendReminderSetup);
        SendReminderSetup.Code := ActionCode;
        SendReminderSetup."Action Group Code" := ActionGroupCode;
        SendReminderSetup.Description := DefaultSetupLbl;
        SendReminderSetup.Insert();
        SendReminderSetup.Find();
        SendReminderSetup.SetRecFilter();
        FeatureTelemetry.LogUptake('0000MKA', DummyReminderActionGroup.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000MKB', DummyReminderActionGroup.GetFeatureTelemetryName(), 'Reminder Automation - Setup done for Sending Reminders');
        exit(true);
    end;

    procedure Delete()
    begin
        if SendReminderSetup.Delete(true) then;
        Clear(SendReminderSetup);
    end;

    procedure Setup();
    begin
        SendReminderSetup.SetRecFilter();
        Page.RunModal(Page::"Send Reminders Setup", SendReminderSetup);
    end;

    procedure GetSummary(): Text
    begin
        exit(SendReminderSetup.Description);
    end;

    procedure GetID(): Code[50]
    begin
        exit(SendReminderSetup.Code);
    end;

    procedure GetReminderActionSystemId(): Guid
    begin
        exit(ReminderAction.SystemId);
    end;

    procedure ValidateSetup()
    var
        EmailAccountRecord: Record "Email Account";
        EmailAccount: Codeunit "Email Account";
    begin
        if not GuiAllowed then
            exit;

        EmailAccount.GetAllAccounts(false, EmailAccountRecord);
        if SendReminderSetup."Send by Email" or SendReminderSetup."Use Document Sending Profile" then
            if EmailAccountRecord.IsEmpty() then
                if not Confirm(NoEmailAccountSetupErrorLbl) then
                    Error('');
    end;
}