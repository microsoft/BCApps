// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Provides functionality to log and manage errors that occur during reminder automation execution.
/// </summary>
codeunit 6752 "Reminder Automation Log Errors"
{
    var
        GlobalReminderAction: Record "Reminder Action";
        GlobalRunId: Integer;

    /// <summary>
    /// Logs the last system error that occurred during reminder automation processing.
    /// </summary>
    /// <param name="ReminderErrorType">Specifies the type of reminder automation error.</param>
    procedure LogLastError(ReminderErrorType: Enum "Reminder Automation Error Type")
    var
        LastErrorCode: Text;
    begin
        LastErrorCode := GetLastErrorCode();
        if LastErrorCode = '' then
            exit;

        LogError(GetLastErrorText(), GetLastErrorCallStack(), ReminderErrorType);
    end;

    /// <summary>
    /// Creates an error log entry with the specified error message and call stack information.
    /// </summary>
    /// <param name="ErrorMessage">Specifies the error message text to log.</param>
    /// <param name="ErrorCallstack">Specifies the call stack information for debugging.</param>
    /// <param name="ReminderErrorType">Specifies the type of reminder automation error.</param>
    procedure LogError(ErrorMessage: Text; ErrorCallstack: Text; ReminderErrorType: Enum "Reminder Automation Error Type")
    var
        ReminderAutomationError: Record "Reminder Automation Error";
    begin
        ReminderAutomationError.ReminderActionId := GlobalReminderAction.Code;
        ReminderAutomationError."Reminder Action Group Code" := GlobalReminderAction."Reminder Action Group Code";
        ReminderAutomationError."Run Id" := GlobalRunId;
        ReminderAutomationError.Insert(true);
        ReminderAutomationError.SetErrorMessage(ErrorMessage);
        ReminderAutomationError.SetErrorCallStack(ErrorCallstack);
    end;

    /// <summary>
    /// Initializes the error logging context with the specified reminder action for the current run.
    /// </summary>
    /// <param name="ReminderAction">Specifies the reminder action to associate with logged errors.</param>
    procedure Initialize(ReminderAction: Record "Reminder Action")
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        ReminderActionProgress.GetLastEntryForGroup(ReminderAction."Reminder Action Group Code", ReminderActionGroupLog);
        GlobalReminderAction.Copy(ReminderAction);
        GlobalRunId := ReminderActionGroupLog."Run Id";
    end;
}