// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

table 5716 "Substitution Condition"
{
    Caption = 'Substitution Condition';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Item Substitution"."No." where("No." = field("No."));
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Substitution"."Variant Code" where("No." = field("No."),
                                                                      "Variant Code" = field("Variant Code"));
        }
        field(3; "Substitute No."; Code[20])
        {
            Caption = 'Substitute No.';
            TableRelation = "Item Substitution"."Substitute No." where("No." = field("No."),
                                                                        "Variant Code" = field("Variant Code"),
                                                                        "Substitute No." = field("Substitute No."));
        }
        field(4; "Substitute Variant Code"; Code[10])
        {
            Caption = 'Substitute Variant Code';
            TableRelation = "Item Substitution"."Substitute Variant Code" where("No." = field("No."),
                                                                                 "Variant Code" = field("Variant Code"),
                                                                                 "Substitute No." = field("Substitute No."),
                                                                                 "Substitute Variant Code" = field("Substitute Variant Code"));
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Condition; Text[80])
        {
            Caption = 'Condition';
        }
        field(100; Type; Enum "Item Substitution Type")
        {
            Caption = 'Type';
        }
        field(101; "Substitute Type"; Enum "Item Substitute Type")
        {
            Caption = 'Substitute Type';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Variant Code", "Substitute Type", "Substitute No.", "Substitute Variant Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

