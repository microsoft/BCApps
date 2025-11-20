// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

codeunit 6752 "Reminder Automation Log Errors"
{
    var
        GlobalReminderAction: Record "Reminder Action";
        GlobalRunId: Integer;

    procedure LogLastError(ReminderErrorType: Enum "Reminder Automation Error Type")
    var
        LastErrorCode: Text;
    begin
        LastErrorCode := GetLastErrorCode();
        if LastErrorCode = '' then
            exit;

        LogError(GetLastErrorText(), GetLastErrorCallStack(), ReminderErrorType);
    end;

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