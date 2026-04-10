// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Foundation.NoSeries;

table 5603 "FA Setup"
{
    Caption = 'FA Setup';
    Permissions = TableData "Ins. Coverage Ledger Entry" = r;
    DataClassification = CustomerContent;
    DrillDownPageID = "Fixed Asset Setup";
    LookupPageID = "Fixed Asset Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(3; "Allow Posting to Main Assets"; Boolean)
        {
            Caption = 'Allow Posting to Main Assets';
            ToolTip = 'Specifies whether you have split your fixed assets into main assets and components, and you want to be able to post directly to main assets.';
        }
        field(4; "Default Depr. Book"; Code[10])
        {
            Caption = 'Default Depr. Book';
            ToolTip = 'Specifies the default depreciation book on journal lines and purchase lines and when you run batch jobs and reports.';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                if "Insurance Depr. Book" = '' then
                    Validate("Insurance Depr. Book", "Default Depr. Book");
            end;
        }
        field(5; "Allow FA Posting From"; Date)
        {
            Caption = 'Allow FA Posting From';
            ToolTip = 'Specifies the earliest date when posting to the fixed assets is allowed.';
        }
        field(6; "Allow FA Posting To"; Date)
        {
            Caption = 'Allow FA Posting To';
            ToolTip = 'Specifies the latest date when posting to the fixed assets is allowed.';
        }
        field(7; "Insurance Depr. Book"; Code[10])
        {
            Caption = 'Insurance Depr. Book';
            ToolTip = 'Specifies a depreciation book code. If you use the insurance facilities, you must enter a code to post insurance coverage ledger entries.';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            var
                InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
                MakeInsCoverageLedgEntry: Codeunit "Make Ins. Coverage Ledg. Entry";
            begin
                if InsCoverageLedgEntry.IsEmpty() then
                    exit;

                if "Insurance Depr. Book" <> xRec."Insurance Depr. Book" then
                    MakeInsCoverageLedgEntry.UpdateInsCoverageLedgerEntryFromFASetup("Insurance Depr. Book");
            end;
        }
        field(8; "Automatic Insurance Posting"; Boolean)
        {
            Caption = 'Automatic Insurance Posting';
            ToolTip = 'Specifies you want to post insurance coverage ledger entries when you post acquisition cost entries with the Insurance No. field filled in.';
            InitValue = true;
        }
        field(9; "Fixed Asset Nos."; Code[20])
        {
            Caption = 'Fixed Asset Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to fixed assets.';
            TableRelation = "No. Series";
        }
        field(10; "Insurance Nos."; Code[20])
        {
            AccessByPermission = TableData Insurance = R;
            Caption = 'Insurance Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to insurance policies.';
            TableRelation = "No. Series";
        }
        field(11; "Bonus Depreciation %"; Decimal)
        {
            Caption = 'Bonus Depreciation Percentage';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of bonus depreciation allowed for fixed assets.';
        }
        field(12; "Bonus Depr. Effective Date"; Date)
        {
            Caption = 'Bonus Depreciation Effective Date';
            ToolTip = 'Specifies the date when bonus depreciation becomes effective for fixed assets.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    internal procedure BonusDepreciationCorrectlySetup(): Boolean
    begin
        exit((Rec."Bonus Depreciation %" > 0) and (Rec."Bonus Depr. Effective Date" <> 0D));
    end;
}

