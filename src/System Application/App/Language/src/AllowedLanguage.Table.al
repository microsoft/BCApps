// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Globalization;

/// <summary>
/// Table that contains a list of specific application languages available for the users. If the table is empty, then all installed application languages will be available.
/// </summary>
table 3563 "Allowed Language"
{
    Caption = 'Allowed Language';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    InherentEntitlements = RX;
    InherentPermissions = RX;

    fields
    {
        field(1; "Language Id"; Integer)
        {
            Caption = 'Language Id';
            NotBlank = true;
            BlankZero = true;
            TableRelation = "Windows Language";
            ToolTip = 'Specifies the language id(s) that should be available for this environment.';
        }
        field(2; Language; Text[80])
        {
            Caption = 'Language';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language Id")));
            ToolTip = 'Specifies the language that should be available for this environment.';
        }
    }

    keys
    {
        key(PK; "Language Id")
        {
            Clustered = true;
        }
    }
}