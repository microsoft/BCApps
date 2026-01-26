// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

table 5005276 "Delivery Reminder Term"
{
    Caption = 'Delivery Reminder Term';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Delivery Reminder Terms List";
    LookupPageID = "Delivery Reminder Terms List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Max. No. of Delivery Reminders"; Integer)
        {
            Caption = 'Max. No. of Delivery Reminders';
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Max. No. of Delivery Reminders")
        {
        }
    }

    trigger OnDelete()
    begin
        DeliveryReminderLevel.SetRange("Reminder Terms Code", Code);
        DeliveryReminderLevel.DeleteAll(true);
    end;

    var
        DeliveryReminderLevel: Record "Delivery Reminder Level";
}

