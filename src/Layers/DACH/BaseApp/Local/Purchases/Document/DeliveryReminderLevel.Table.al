// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

table 5005277 "Delivery Reminder Level"
{
    Caption = 'Delivery Reminder Level';
    DrillDownPageID = "Delivery Reminder Levels";
    LookupPageID = "Delivery Reminder Levels";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            NotBlank = true;
            TableRelation = "Delivery Reminder Term";
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            MinValue = 1;
            NotBlank = true;
        }
        field(3; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeliveryReminderText.SetRange("Reminder Terms Code", "Reminder Terms Code");
        DeliveryReminderText.SetRange("Reminder Level", "No.");
        DeliveryReminderText.DeleteAll();
    end;

    var
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        DeliveryReminderText: Record "Delivery Reminder Text";

    [Scope('OnPrem')]
    procedure NewRecord()
    begin
        DeliveryReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        if DeliveryReminderLevel.FindLast() then;
        "No." := DeliveryReminderLevel."No." + 1;
    end;
}

