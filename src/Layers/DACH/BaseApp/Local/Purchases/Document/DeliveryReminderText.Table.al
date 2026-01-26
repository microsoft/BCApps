// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

table 5005278 "Delivery Reminder Text"
{
    Caption = 'Delivery Reminder Text';
    DrillDownPageID = "Delivery Reminder Text";
    LookupPageID = "Delivery Reminder Text";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            NotBlank = true;
            TableRelation = "Delivery Reminder Term";
        }
        field(2; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            MinValue = 1;
            NotBlank = true;
            TableRelation = "Delivery Reminder Level"."No." where("Reminder Terms Code" = field("Reminder Terms Code"));
        }
        field(3; Position; Option)
        {
            Caption = 'Position';
            OptionCaption = 'Beginning,Ending';
            OptionMembers = Beginning,Ending;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
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
        DeliveryReminderLevel.Get("Reminder Terms Code", "Reminder Level");
    end;

    var
        DeliveryReminderLevel: Record "Delivery Reminder Level";
}

