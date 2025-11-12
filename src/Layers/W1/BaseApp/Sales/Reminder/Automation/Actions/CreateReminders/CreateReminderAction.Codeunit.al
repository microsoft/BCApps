// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Telemetry;

codeunit 6760 "Create Reminder Action" implements "Reminder Action"
{
    var
        CreateReminderSetup: Record "Create Reminders Setup";
        ReminderAction: Record "Reminder Action";
        DefaultSetupLbl: Label 'Default setup';

    procedure Initialize(ReminderActionSystemId: Guid)
    begin
        if ReminderAction.GetBySystemId(ReminderActionSystemId) then;

        if CreateReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code") then
            exit;

        Clear(CreateReminderSetup);
    end;

    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid)
    begin
        TableID := Database::"Create Reminders Setup";
        RecordSystemId := CreateReminderSetup.SystemId;
    end;

    procedure Invoke(var ErrorOccured: Boolean)
    var
        CreateRemindersAction: Codeunit "Create Reminders Action Job";
    begin
        CreateRemindersAction.CreateReminders(ReminderAction, ErrorOccured);
    end;

    procedure CreateNew(ActionCode: Code[50]; ActionGroupCode: Code[50]): Boolean
    var
        DummyReminderActionGroup: Record "Reminder Action Group";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        Clear(CreateReminderSetup);
        CreateReminderSetup.Code := ActionCode;
        CreateReminderSetup."Action Group Code" := ActionGroupCode;
        CreateReminderSetup.Description := DefaultSetupLbl;
        CreateReminderSetup.Insert(true);
        CreateReminderSetup.Find();
        CreateReminderSetup.SetRecFilter();
        FeatureTelemetry.LogUptake('0000MK6', DummyReminderActionGroup.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000MK7', DummyReminderActionGroup.GetFeatureTelemetryName(), 'Reminder Automation - Setup done for Creating Reminders');
        exit(true);
    end;

    procedure Delete()
    begin
        if CreateReminderSetup.Delete(true) then;
        Clear(CreateReminderSetup);
    end;

    procedure Setup();
    begin
        CreateReminderSetup.SetRecFilter();
        Page.RunModal(Page::"Create Reminders Setup", CreateReminderSetup);
    end;

    procedure GetSummary(): Text
    begin
        exit(CreateReminderSetup.Description);
    end;

    procedure GetID(): Code[50]
    begin
        exit(CreateReminderSetup.Code);
    end;

    procedure GetReminderActionSystemId(): Guid
    begin
        exit(ReminderAction.SystemId);
    end;

    procedure ValidateSetup()
    begin
    end;
}