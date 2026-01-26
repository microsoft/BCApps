#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting;

table 5005358 "Phys. Inventory Comment Line"
{
    Caption = 'Phys. Inventory Comment Line';
    ObsoleteReason = 'Merged to W1';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Order,Recording,Posted Order,Posted Recording';
            OptionMembers = "Order",Recording,"Posted Order","Posted Recording";
        }
        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(3; "Recording No."; Integer)
        {
            Caption = 'Recording No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(11; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(12; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Order No.", "Recording No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif