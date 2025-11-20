// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

table 6750 "Reminder Action"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Type"; Enum "Reminder Action")
        {
        }
        field(2; "Reminder Action Group Code"; Code[50])
        {
            TableRelation = "Reminder Action Group".Code;
        }
        field(3; Code; Code[50])
        {
        }
        field(8; Order; Integer)
        {
        }
        field(9; "Stop on Error"; Boolean)
        {
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