// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Telemetry;

codeunit 6758 "Issue Reminder Action" implements "Reminder Action"
{
    var
        IssueReminderSetup: Record "Issue Reminders Setup";
        ReminderAction: Record "Reminder Action";
        DefaultSetupLbl: Label 'Default setup';

    procedure Initialize(ReminderActionSystemId: Guid)
    begin
        if ReminderAction.GetBySystemId(ReminderActionSystemId) then;

        if IssueReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code") then
            exit;

        Clear(IssueReminderSetup);
    end;

    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid)
    begin
        TableID := Database::"Issue Reminders Setup";
        RecordSystemId := IssueReminderSetup.SystemId;
    end;

    procedure Invoke(var ErrorOccured: Boolean)
    var
        IssueReminderAction: Codeunit "Issue Reminder Action Job";
    begin
        IssueReminderAction.IssueReminders(ReminderAction, ErrorOccured);
    end;

    procedure CreateNew(ActionCode: Code[50]; ActionGroupCode: Code[50]): Boolean
    var
        DummyReminderActionGroup: Record "Reminder Action Group";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        Clear(IssueReminderSetup);
        IssueReminderSetup.Code := ActionCode;
        IssueReminderSetup."Action Group Code" := ActionGroupCode;
        IssueReminderSetup.Description := DefaultSetupLbl;
        IssueReminderSetup.Insert();
        IssueReminderSetup.Find();
        IssueReminderSetup.SetRecFilter();
        FeatureTelemetry.LogUptake('0000MK2', DummyReminderActionGroup.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000MK3', DummyReminderActionGroup.GetFeatureTelemetryName(), 'Reminder Automation - Setup done for Issue Reminders');
        exit(true);
    end;

    procedure Delete()
    begin
        if IssueReminderSetup.Delete(true) then;
        Clear(IssueReminderSetup);
    end;

    procedure Setup();
    begin
        IssueReminderSetup.SetRecFilter();
        Page.RunModal(Page::"Issue Reminders Setup", IssueReminderSetup);
    end;

    procedure GetSummary(): Text
    begin
        exit(IssueReminderSetup.Description);
    end;

    procedure GetID(): Code[50]
    begin
        exit(IssueReminderSetup.Code);
    end;

    procedure GetReminderActionSystemId(): Guid
    begin
        exit(ReminderAction.SystemId);
    end;

    procedure ValidateSetup()
    begin
    end;
}