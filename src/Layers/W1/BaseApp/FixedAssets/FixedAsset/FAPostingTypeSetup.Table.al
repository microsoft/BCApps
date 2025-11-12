// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.FixedAssets.Depreciation;

table 5604 "FA Posting Type Setup"
{
    Caption = 'FA Posting Type Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "FA Posting Type Setup";
    LookupPageID = "FA Posting Type Setup";

    fields
    {
        field(1; "FA Posting Type"; Enum "FA Posting Type Setup Type")
        {
            Caption = 'FA Posting Type';
            Editable = false;
        }
        field(2; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Depreciation Book";
        }
        field(3; "Part of Book Value"; Boolean)
        {
            Caption = 'Part of Book Value';

            trigger OnValidate()
            begin
                if not "Part of Book Value" then
                    TestField("Reverse before Disposal", false);
            end;
        }
        field(4; "Part of Depreciable Basis"; Boolean)
        {
            Caption = 'Part of Depreciable Basis';
        }
        field(5; "Include in Depr. Calculation"; Boolean)
        {
            Caption = 'Include in Depr. Calculation';
        }
        field(6; "Include in Gain/Loss Calc."; Boolean)
        {
            Caption = 'Include in Gain/Loss Calc.';
        }
        field(7; "Reverse before Disposal"; Boolean)
        {
            Caption = 'Reverse before Disposal';

            trigger OnValidate()
            begin
                if "Reverse before Disposal" then
                    TestField("Part of Book Value", true);
            end;
        }
        field(8; Sign; Option)
        {
            Caption = 'Sign';
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = " ",Debit,Credit;
        }
        field(9; "Depreciation Type"; Boolean)
        {
            Caption = 'Depreciation Type';

            trigger OnValidate()
            begin
                if "Depreciation Type" then
                    "Acquisition Type" := false;
            end;
        }
        field(10; "Acquisition Type"; Boolean)
        {
            Caption = 'Acquisition Type';

            trigger OnValidate()
            begin
                if "Acquisition Type" then
                    "Depreciation Type" := false;
            end;
        }
    }

    keys
    {
        key(Key1; "Depreciation Book Code", "FA Posting Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

