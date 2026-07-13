// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

table 6793 "Withholding Tax Group Line"
{
    Caption = 'Withholding Tax Group Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20])
        {
            Caption = 'Group Code';
            TableRelation = "Withholding Tax Group";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Wthldg. Tax Prod. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Prod. Post. Group';
            TableRelation = "Wthldg. Tax Prod. Post. Group";
        }
        field(4; "Component Order"; Integer)
        {
            Caption = 'Component Order';
            MinValue = 1;
        }
        field(5; "Compound Base Includes"; Text[250])
        {
            Caption = 'Compound Base Includes';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Group Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Group Code", "Component Order")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Group Code");
    end;
}
