// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Telemetry;

/// <summary>
/// Implements the reminder action interface for automated posting of reminder documents.
/// </summary>
codeunit 6758 "Issue Reminder Action" implements "Reminder Action"
{
    var
        IssueReminderSetup: Record "Issue Reminders Setup";
        ReminderAction: Record "Reminder Action";
        DefaultSetupLbl: Label 'Default setup';

    /// <summary>
    /// Initializes the reminder action with setup data from the specified system identifier.
    /// </summary>
    /// <param name="ReminderActionSystemId">Specifies the system ID of the reminder action to initialize.</param>
    procedure Initialize(ReminderActionSystemId: Guid)
    begin
        if ReminderAction.GetBySystemId(ReminderActionSystemId) then;

        if IssueReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code") then
            exit;

        Clear(IssueReminderSetup);
    end;

    /// <summary>
    /// Retrieves the setup record table ID and system ID for the issue reminders action.
    /// </summary>
    /// <param name="TableID">Returns the table ID of the setup record.</param>
    /// <param name="RecordSystemId">Returns the system ID of the setup record.</param>
    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid)
    begin
        TableID := Database::"Issue Reminders Setup";
        RecordSystemId := IssueReminderSetup.SystemId;
    end;

    /// <summary>
    /// Executes the reminder issuing action and reports whether errors occurred.
    /// </summary>
    /// <param name="ErrorOccured">Returns true if errors occurred during execution; otherwise, false.</param>
    procedure Invoke(var ErrorOccured: Boolean)
    var
        IssueReminderAction: Codeunit "Issue Reminder Action Job";
    begin
        IssueReminderAction.IssueReminders(ReminderAction, ErrorOccured);
    end;

    /// <summary>
    /// Creates a new issue reminders setup record with default values.
    /// </summary>
    /// <param name="ActionCode">Specifies the code for the new action.</param>
    /// <param name="ActionGroupCode">Specifies the action group code the action belongs to.</param>
    /// <returns>True if the setup was created successfully.</returns>
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

    /// <summary>
    /// Deletes the issue reminders setup record.
    /// </summary>
    procedure Delete()
    begin
        if IssueReminderSetup.Delete(true) then;
        Clear(IssueReminderSetup);
    end;

    /// <summary>
    /// Opens the setup page for configuring the issue reminders action.
    /// </summary>
    procedure Setup();
    begin
        IssueReminderSetup.SetRecFilter();
        Page.RunModal(Page::"Issue Reminders Setup", IssueReminderSetup);
    end;

    /// <summary>
    /// Retrieves the description text summarizing the action setup.
    /// </summary>
    /// <returns>The description text from the setup record.</returns>
    procedure GetSummary(): Text
    begin
        exit(IssueReminderSetup.Description);
    end;

    /// <summary>
    /// Retrieves the unique code identifier for this action.
    /// </summary>
    /// <returns>The action code from the setup record.</returns>
    procedure GetID(): Code[50]
    begin
        exit(IssueReminderSetup.Code);
    end;

    /// <summary>
    /// Retrieves the system ID of the reminder action record.
    /// </summary>
    /// <returns>The system ID of the reminder action.</returns>
    procedure GetReminderActionSystemId(): Guid
    begin
        exit(ReminderAction.SystemId);
    end;

    /// <summary>
    /// Validates the setup configuration for the issue reminders action.
    /// </summary>
    procedure ValidateSetup()
    begin
    end;
}