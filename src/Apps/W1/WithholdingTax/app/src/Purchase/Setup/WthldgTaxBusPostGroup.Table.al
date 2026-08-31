// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.WithholdingTax.Employee;

table 6784 "Wthldg. Tax Bus. Post. Group"
{
    Caption = 'Withholding Tax Bus. Post. Group';
    LookupPageID = "Wthldg. Tax Bus. Post. Group";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(100; "Party Applicability"; Enum "Withholding Party Type")
        {
            Caption = 'Party Applicability';
        }
        field(101; "Jurisdiction Code"; Code[20])
        {
            Caption = 'Jurisdiction Code';
        }
        field(102; "Default Certificate Type"; Code[20])
        {
            Caption = 'Default Certificate Type';
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
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}