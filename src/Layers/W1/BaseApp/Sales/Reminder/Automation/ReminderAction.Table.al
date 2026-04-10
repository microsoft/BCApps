// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Stores individual automation actions that belong to a reminder action group with their type and execution order.
/// </summary>
table 6750 "Reminder Action"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of automation action, such as create, issue, or send reminders.
        /// </summary>
        field(1; "Type"; Enum "Reminder Action")
        {
            ToolTip = 'Specifies the type of the action.';
        }
        /// <summary>
        /// Specifies the reminder action group to which this action belongs.
        /// </summary>
        field(2; "Reminder Action Group Code"; Code[50])
        {
            TableRelation = "Reminder Action Group".Code;
        }
        /// <summary>
        /// Specifies the unique code identifying this action within the group.
        /// </summary>
        field(3; Code; Code[50])
        {
            ToolTip = 'Specifies the code of the action.';
        }
        /// <summary>
        /// Specifies the execution sequence number for this action within the group.
        /// </summary>
        field(8; Order; Integer)
        {
            ToolTip = 'Specifies the order in which the actions will be performed.';
        }
        /// <summary>
        /// Indicates whether automation processing should stop if this action encounters an error.
        /// </summary>
        field(9; "Stop on Error"; Boolean)
        {
            ToolTip = 'Specifies if the job should stop if an error occurs during this action. If not selected, the job will attempt to process all records and actions.';
        }
    }

    keys
    {
        key(Key1; "Reminder Action Group Code", Code)
        {
            Clustered = true;
        }
        key(Key2; "Reminder Action Group Code", Order)
        {
        }
    }

    trigger OnInsert()
    begin
        if Rec.Order = 0 then
            Rec.Order := GetNextOrderNumber();
    end;

    internal procedure GetNextOrderNumber(): Integer
    var
        LastReminderAction: Record "Reminder Action";
        NextOrderNumber: Integer;
    begin
        if Rec.Order <> 0 then
            exit(0);

        LastReminderAction.SetCurrentKey("Reminder Action Group Code", Order);
        LastReminderAction.SetRange("Reminder Action Group Code", Rec."Reminder Action Group Code");
        if LastReminderAction.FindLast() then
            NextOrderNumber := LastReminderAction.Order + 1
        else
            NextOrderNumber := 1;

        exit(NextOrderNumber);
    end;

    internal procedure MoveDown()
    var
        NextReminderAction: Record "Reminder Action";
        NextOrderNumber: Integer;
    begin
        NextReminderAction.Copy(Rec);
        NextReminderAction.SetFilter(Order, '>%1', Rec.Order);
        NextReminderAction.SetCurrentKey(Order);
        if not NextReminderAction.FindFirst() then
            exit;

        NextOrderNumber := NextReminderAction.Order;
        NextReminderAction.Order := Rec.Order;
        NextReminderAction.Modify();
        Rec.Order := NextOrderNumber;
        Rec.Modify();
    end;


    internal procedure MoveUp()
    var
        PreviousReminderAction: Record "Reminder Action";
        PreviousOrderNumber: Integer;
    begin
        PreviousReminderAction.Copy(Rec);
        PreviousReminderAction.SetFilter(Order, '<%1', Rec.Order);
        PreviousReminderAction.SetCurrentKey(Order);
        if not PreviousReminderAction.FindLast() then
            exit;

        PreviousOrderNumber := PreviousReminderAction.Order;
        PreviousReminderAction.Order := Rec.Order;
        PreviousReminderAction.Modify();
        Rec.Order := PreviousOrderNumber;
        Rec.Modify();
    end;

    /// <summary>
    /// Gets the interface implementation for this reminder action type.
    /// </summary>
    /// <returns>The initialized reminder action interface for the action type.</returns>
    procedure GetReminderActionInterface(): Interface "Reminder Action"
    var
        ReminderActionInterface: Interface "Reminder Action";
    begin
        ReminderActionInterface := Rec.Type;
        ReminderActionInterface.Initialize(Rec.SystemId);
        exit(ReminderActionInterface);
    end;

    trigger OnDelete()
    var
        ReminderActionInterface: Interface "Reminder Action";
    begin
        ReminderActionInterface := GetReminderActionInterface();
        ReminderActionInterface.Delete();
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr);
    end;

    var
        RenameNotAllowedErr: Label 'Remaning records is not allowed, delete the record and set it up again';
}