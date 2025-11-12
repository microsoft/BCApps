// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

table 6753 "Reminder Action Group Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run Id"; Integer)
        {
            AutoIncrement = true;
        }
        field(3; "Reminder Action Group ID"; Code[50])
        {
        }
        field(10; Status; Enum "Reminder Log Status")
        {
        }
        field(11; "Last Step ID"; Integer)
        {
        }
#if not CLEAN26
#pragma warning disable AA0232
        field(15; "Number of Errors"; Integer)
#pragma warning restore AA0232
        {
            ObsoleteReason = 'Field is removed do not use';
            ObsoleteState = Pending;
#pragma warning disable AS0074
            ObsoleteTag = '26.0';
#pragma warning restore AS0074
            FieldClass = FlowField;
            CalcFormula = sum("Reminder Action Log"."Total Errors" where("Reminder Action Group ID" = field("Reminder Action Group ID"), "Run Id" = field("Run Id")));
            Editable = false;
        }
#endif
        field(16; "Started On"; DateTime)
        {
        }
        field(17; "Completed On"; DateTime)
        {
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