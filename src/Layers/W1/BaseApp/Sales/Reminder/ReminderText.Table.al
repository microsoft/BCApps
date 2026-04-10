// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Stores beginning and ending text lines that appear on reminder documents for each level.
/// </summary>
table 294 "Reminder Text"
{
    Caption = 'Reminder Text';
    DrillDownPageID = "Reminder Text";
    LookupPageID = "Reminder Text";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the reminder terms to which this text line belongs.
        /// </summary>
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            ToolTip = 'Specifies the reminder terms code this text applies to.';
            NotBlank = true;
            TableRelation = "Reminder Terms";
        }
        /// <summary>
        /// Specifies the reminder level at which this text line appears.
        /// </summary>
        field(2; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            ToolTip = 'Specifies the reminder level this text applies to.';
            MinValue = 1;
            NotBlank = true;
            TableRelation = "Reminder Level"."No." where("Reminder Terms Code" = field("Reminder Terms Code"));
        }
        /// <summary>
        /// Specifies whether this text appears at the beginning or ending of the reminder document.
        /// </summary>
        field(3; Position; Enum "Reminder Text Position")
        {
            Caption = 'Position';
            ToolTip = 'Specifies whether the text will appear at the beginning or the end of the reminder.';
        }
        /// <summary>
        /// Specifies the sequential line number for ordering text lines within a position.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Contains the text content that appears on the printed reminder document.
        /// </summary>
        field(5; Text; Text[100])
        {
            Caption = 'Text';
            ToolTip = 'Specifies the text that you want to insert in the reminder.';
        }
        /// <summary>
        /// Contains the text content that appears in reminder email communications.
        /// </summary>
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

