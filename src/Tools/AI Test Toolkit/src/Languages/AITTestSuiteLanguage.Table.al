// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Globalization;

table 149035 "AIT Test Suite Language"
{
    Caption = 'AI Eval Suite Language';
    DataClassification = SystemMetadata;
    ReplicateData = false;
    Access = Public;

    fields
    {
        field(1; "Test Suite Code"; Code[10])
        {
            Caption = 'Eval Suite Code';
            TableRelation = "AIT Test Suite".Code;
            ValidateTableRelation = true;
        }
        field(2; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            ToolTip = 'Specifies the Windows Language ID for the eval suite language.';
            TableRelation = "Windows Language"."Language ID";
            ValidateTableRelation = true;
        }
        field(10; "Language Tag"; Text[80])
        {
            Caption = 'Language Tag';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Windows Language"."Language Tag" where("Language ID" = field("Language ID")));
            ToolTip = 'Specifies the language tag for the language.';
        }
        field(11; "Language Name"; Text[80])
        {
            Caption = 'Language Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language ID")));
            ToolTip = 'Specifies the name of the language.';
        }
        field(20; "Run Frequency"; Enum "AIT Run Frequency")
        {
            Caption = 'Run Frequency';
            ToolTip = 'Specifies how frequently the eval suite should be run for this language.';
        }
        field(21; Validation; Boolean)
        {
            Caption = 'Validation';
            ToolTip = 'Specifies whether this language version is used for validation purposes.';
        }
    }

    keys
    {
        key(Key1; "Test Suite Code", "Language ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Language Tag", "Language Name")
        {
        }
    }
}
