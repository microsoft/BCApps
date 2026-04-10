// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Stores execution history records for reminder automation group runs including status and timing.
/// </summary>
table 6753 "Reminder Action Group Log"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique auto-incrementing identifier for this automation run.
        /// </summary>
        field(1; "Run Id"; Integer)
        {
            ToolTip = 'Specifies the unique identifier of the reminder action group log entry. Each job will get an unique identifier.';
            AutoIncrement = true;
        }
        /// <summary>
        /// Specifies the reminder action group that was executed.
        /// </summary>
        field(3; "Reminder Action Group ID"; Code[50])
        {
            ToolTip = 'Specifies the reminder action group that was run.';
        }
        /// <summary>
        /// Specifies the current status of the automation run: running, completed, or failed.
        /// </summary>
        field(10; Status; Enum "Reminder Log Status")
        {
            ToolTip = 'Specifies the status of the reminder action group log entry.';
        }
        /// <summary>
        /// Specifies the identifier of the last step that was processed in this run.
        /// </summary>
        field(11; "Last Step ID"; Integer)
        {
        }
#if not CLEAN27
#pragma warning disable AA0232
        /// <summary>
        /// Contains the total number of errors encountered during this automation run.
        /// </summary>
        field(15; "Number of Errors"; Integer)
#pragma warning restore AA0232
        {
            ObsoleteReason = 'Field is removed do not use';
            ObsoleteState = Pending;
#pragma warning disable AS0074
            ObsoleteTag = '27.0';
#pragma warning restore AS0074
            FieldClass = FlowField;
            CalcFormula = sum("Reminder Action Log"."Total Errors" where("Reminder Action Group ID" = field("Reminder Action Group ID"), "Run Id" = field("Run Id")));
            Editable = false;
        }
#endif
        /// <summary>
        /// Specifies the date and time when the automation run started.
        /// </summary>
        field(16; "Started On"; DateTime)
        {
            ToolTip = 'Specifies when the job was started.';
        }
        /// <summary>
        /// Specifies the date and time when the automation run completed.
        /// </summary>
        field(17; "Completed On"; DateTime)
        {
            ToolTip = 'Specifies when the job was completed.';
        }
    }

    keys
    {
        key(Key1; "Run Id")
        {
            Clustered = true;
        }
    }

    internal procedure UpdateInProgressRecords()
    var
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderActionLog: Record "Reminder Action Log";
    begin
        if not ReminderActionGroup.Get("Reminder Action Group ID") then
            exit;

        if ReminderActionGroup.InProgress() then
            exit;

        ReminderActionGroupLog.SetRange(Status, Status::Running);
        if ReminderActionGroupLog.IsEmpty() then
            exit;

        ReminderActionGroupLog.ModifyAll(Status, Status::Failed);

        ReminderActionLog.SetRange("Reminder Action Group ID", ReminderActionGroup.Code);
        ReminderActionLog.SetRange(Status, Status::Running);
        if ReminderActionGroup.IsEmpty() then
            exit;

        ReminderActionLog.ModifyAll(Status, Status::Failed);
    end;

    internal procedure GetNumberOfActiveErrors(): Integer
    var
        ReminderAutomationError: Record "Reminder Automation Error";
    begin
        GetActiveErrors(ReminderAutomationError);
        exit(ReminderAutomationError.Count);
    end;

    internal procedure GetActiveErrors(var ReminderAutomationError: Record "Reminder Automation Error"): Integer
    begin
        ReminderAutomationError.SetRange("Reminder Action Group Code", Rec."Reminder Action Group ID");
        ReminderAutomationError.SetRange("Run Id", Rec."Run Id");
        ReminderAutomationError.SetRange(Dismissed, false);
    end;
}