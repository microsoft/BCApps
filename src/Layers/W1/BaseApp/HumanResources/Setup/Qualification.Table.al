// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Setup;

using Microsoft.HumanResources.Employee;

table 5202 Qualification
{
    Caption = 'Qualification';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = Qualifications;
    LookupPageID = Qualifications;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Qualified Employees"; Boolean)
        {
            CalcFormula = exist("Employee Qualification" where("Qualification Code" = field(Code),
                                                                "Employee Status" = const(Active)));
            Caption = 'Qualified Employees';
            Editable = false;
            FieldClass = FlowField;
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
    }
}

