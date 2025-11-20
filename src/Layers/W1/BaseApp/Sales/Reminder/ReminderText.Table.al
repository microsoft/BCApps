// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

table 294 "Reminder Text"
{
    Caption = 'Reminder Text';
    DrillDownPageID = "Reminder Text";
    LookupPageID = "Reminder Text";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            NotBlank = true;
            TableRelation = "Reminder Terms";
        }
        field(2; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            MinValue = 1;
            NotBlank = true;
            TableRelation = "Reminder Level"."No." where("Reminder Terms Code" = field("Reminder Terms Code"));
        }
        field(3; Position; Enum "Reminder Text Position")
        {
            Caption = 'Position';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Text; Text[100])
        {
            Caption = 'Text';
        }
        field(55; "Email Text"; Blob)
        {
            Caption = 'Email Text';
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "Reminder Level", Position, "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ReminderLevel.Get("Reminder Terms Code", "Reminder Level");
    end;

    var
        ReminderLevel: Record "Reminder Level";
}

