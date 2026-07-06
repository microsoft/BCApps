// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Email;
using System.Telemetry;

/// <summary>
/// Implements the reminder action interface for automated sending of issued reminders via email.
/// </summary>
codeunit 6755 "Send Reminder Action" implements "Reminder Action"
{
    var
        SendReminderSetup: Record "Send Reminders Setup";
        ReminderAction: Record "Reminder Action";
        DefaultSetupLbl: Label 'Default setup';
        NoEmailAccountSetupErrorLbl: Label 'No email account are set up, it will not be possible to send reminders by email.\\Do you want to continue?';

    /// <summary>
    /// Initializes the reminder action with setup data from the specified system identifier.
    /// </summary>
    /// <param name="ReminderActionSystemId">Specifies the system ID of the reminder action to initialize.</param>
    procedure Initialize(ReminderActionSystemId: Guid)
    begin
        if ReminderAction.GetBySystemId(ReminderActionSystemId) then;

        if SendReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code") then
            exit;

        Clear(SendReminderSetup);
    end;

    /// <summary>
    /// Retrieves the setup record table ID and system ID for the send reminders action.
    /// </summary>
    /// <param name="TableID">Returns the table ID of the setup record.</param>
    /// <param name="RecordSystemId">Returns the system ID of the setup record.</param>
    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid)
    begin
        TableID := Database::"Send Reminders Setup";
        RecordSystemId := SendReminderSetup.SystemId;
    end;

    /// <summary>
    /// Executes the reminder sending action and reports whether errors occurred.
    /// </summary>
    /// <param name="ErrorOccured">Returns true if errors occurred during execution; otherwise, false.</param>
    procedure Invoke(var ErrorOccured: Boolean)
    var
        SendReminderAction: Codeunit "Send Reminder Action Job";
    begin
        SendReminderAction.SendReminders(ReminderAction, ErrorOccured);
    end;

    /// <summary>
    /// Creates a new send reminders setup record with default values.
    /// </summary>
    /// <param name="ActionCode">Specifies the code for the new action.</param>
    /// <param name="ActionGroupCode">Specifies the action group code the action belongs to.</param>
    /// <returns>True if the setup was created successfully.</returns>
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

    /// <summary>
    /// Deletes the send reminders setup record.
    /// </summary>
    procedure Delete()
    begin
        if SendReminderSetup.Delete(true) then;
        Clear(SendReminderSetup);
    end;

    /// <summary>
    /// Opens the setup page for configuring the send reminders action.
    /// </summary>
    procedure Setup();
    begin
        SendReminderSetup.SetRecFilter();
        Page.RunModal(Page::"Send Reminders Setup", SendReminderSetup);
    end;

    /// <summary>
    /// Retrieves the description text summarizing the action setup.
    /// </summary>
    /// <returns>The description text from the setup record.</returns>
    procedure GetSummary(): Text
    begin
        exit(SendReminderSetup.Description);
    end;

    /// <summary>
    /// Retrieves the unique code identifier for this action.
    /// </summary>
    /// <returns>The action code from the setup record.</returns>
    procedure GetID(): Code[50]
    begin
        exit(SendReminderSetup.Code);
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
    /// Validates the setup configuration and warns if no email account is configured when email sending is enabled.
    /// </summary>
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