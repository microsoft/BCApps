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
            ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
            Editable = false;
        }
        field(2; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Depreciation Book";
        }
        field(3; "Part of Book Value"; Boolean)
        {
            Caption = 'Part of Book Value';
            ToolTip = 'Specifies that entries posted with the FA Posting Type field will be part of the book value.';

            trigger OnValidate()
            begin
                if not "Part of Book Value" then
                    TestField("Reverse before Disposal", false);
            end;
        }
        field(4; "Part of Depreciable Basis"; Boolean)
        {
            Caption = 'Part of Depreciable Basis';
            ToolTip = 'Specifies that entries posted with the FA Posting Type field will be part of the depreciable basis.';
        }
        field(5; "Include in Depr. Calculation"; Boolean)
        {
            Caption = 'Include in Depr. Calculation';
            ToolTip = 'Specifies that entries posted with the FA Posting Type field must be included in periodic depreciation calculations.';
        }
        field(6; "Include in Gain/Loss Calc."; Boolean)
        {
            Caption = 'Include in Gain/Loss Calc.';
            ToolTip = 'Specifies that entries posted with the FA Posting Type field must be included in the calculation of gain or loss for a sold asset.';
        }
        field(7; "Reverse before Disposal"; Boolean)
        {
            Caption = 'Reverse before Disposal';
            ToolTip = 'Specifies that entries posted with the FA Posting Type field must be reversed (that is, set to zero) before disposal.';

            trigger OnValidate()
            begin
                if "Reverse before Disposal" then
                    TestField("Part of Book Value", true);
            end;
        }
        field(8; Sign; Option)
        {
            Caption = 'Sign';
            ToolTip = 'Specifies whether the type in the FA Posting Type field should be a debit or a credit.';
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = " ",Debit,Credit;
        }
        field(9; "Depreciation Type"; Boolean)
        {
            Caption = 'Depreciation Type';
            ToolTip = 'Specifies that entries posted with the FA Posting Type field will be regarded as part of the total depreciation for the fixed asset.';

            trigger OnValidate()
            begin
                if "Depreciation Type" then
                    "Acquisition Type" := false;
            end;
        }
        field(10; "Acquisition Type"; Boolean)
        {
            Caption = 'Acquisition Type';
            ToolTip = 'Specifies that entries posted with the FA Posting Type must be part of the total acquisition for the fixed asset in the Fixed Asset - Book Value 01 report.';

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

