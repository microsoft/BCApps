// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

table 319 "Tax Area Line"
{
    Caption = 'Tax Area Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax Area"; Code[20])
        {
            Caption = 'Tax Area';
            TableRelation = "Tax Area";
        }
        field(2; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
        }
        field(3; "Jurisdiction Description"; Text[100])
        {
            CalcFormula = lookup ("Tax Jurisdiction".Description where(Code = field("Tax Jurisdiction Code")));
            Caption = 'Jurisdiction Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Calculation Order"; Integer)
        {
            Caption = 'Calculation Order';
        }
    }

    keys
    {
        key(Key1; "Tax Area", "Tax Jurisdiction Code")
        {
            Clustered = true;
        }
        key(Key2; "Tax Jurisdiction Code")
        {
        }
        key(Key3; "Tax Area", "Calculation Order")
        {
        }
    }

    fieldgroups
    {
    }
}

