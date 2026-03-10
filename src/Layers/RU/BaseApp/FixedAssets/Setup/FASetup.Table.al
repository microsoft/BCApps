// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
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
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if "Insurance Depr. Book" = '' then
                    Validate("Insurance Depr. Book", "Default Depr. Book");

                GLSetup.Get();
                if GLSetup."Enable Russian Tax Accounting" then
                    if ("Default Depr. Book" <> xRec."Default Depr. Book") and
                       ("Default Depr. Book" <> '')
                    then
                        if TaxRegisterSetup.Get() then
                            if TaxRegisterSetup."Calculate TD for each FA" then begin
                                DeprBook.Get("Default Depr. Book");
                                DeprBook.TestField(DeprBook."Control FA Acquis. Cost", true);
                            end;
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
        field(12402; "Writeoff Nos."; Code[20])
        {
            Caption = 'Writeoff Nos.';
            TableRelation = "No. Series";
        }
        field(12403; "Posted Writeoff Nos."; Code[20])
        {
            Caption = 'Posted Writeoff Nos.';
            TableRelation = "No. Series";
        }
        field(12408; "Release Nos."; Code[20])
        {
            Caption = 'Release Nos.';
            TableRelation = "No. Series";
        }
        field(12409; "Posted Release Nos."; Code[20])
        {
            Caption = 'Posted Release Nos.';
            TableRelation = "No. Series";
        }
        field(12410; "Disposal Nos."; Code[20])
        {
            Caption = 'Disposal Nos.';
            TableRelation = "No. Series";
        }
        field(12411; "Posted Disposal Nos."; Code[20])
        {
            Caption = 'Posted Disposal Nos.';
            TableRelation = "No. Series";
        }
        field(12412; "Release Depr. Book"; Code[10])
        {
            Caption = 'Release Depr. Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                if "Insurance Depr. Book" = '' then
                    Validate("Insurance Depr. Book", "Default Depr. Book");
            end;
        }
        field(12413; "Disposal Depr. Book"; Code[10])
        {
            Caption = 'Disposal Depr. Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                if "Insurance Depr. Book" = '' then
                    Validate("Insurance Depr. Book", "Default Depr. Book");
            end;
        }
        field(12415; "FA Location Mandatory"; Boolean)
        {
            Caption = 'FA Location Mandatory';
        }
        field(12416; "Employee No. Mandatory"; Boolean)
        {
            Caption = 'Employee No. Mandatory';
        }
        field(12417; "Future Depr. Book"; Code[10])
        {
            Caption = 'Future Depr. Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                if "Insurance Depr. Book" = '' then
                    Validate("Insurance Depr. Book", "Default Depr. Book");
            end;
        }
        field(12418; "Quantitative Depr. Book"; Code[10])
        {
            Caption = 'Quantitative Depr. Book';
            TableRelation = "Depreciation Book";
        }
        field(12420; "On Disposal Maintenance Code"; Code[10])
        {
            Caption = 'On Disposal Maintenance Code';
            TableRelation = Maintenance;
        }
        field(12450; "FA-1b Template Code"; Code[10])
        {
            Caption = 'FA-1b Template Code';
            TableRelation = "Excel Template";
        }
        field(12451; "FA-4b Template Code"; Code[10])
        {
            Caption = 'FA-4b Template Code';
            TableRelation = "Excel Template";
        }
        field(12452; "FA-6a Template Code"; Code[10])
        {
            Caption = 'FA-6a Template Code';
            TableRelation = "Excel Template";
        }
        field(12453; "FA-6b Template Code"; Code[10])
        {
            Caption = 'FA-6b Template Code';
            TableRelation = "Excel Template";
        }
        field(12454; "INV-1a Template Code"; Code[10])
        {
            Caption = 'INV-1a Template Code';
            TableRelation = "Excel Template";
        }
        field(12455; "INV-11 Template Code"; Code[10])
        {
            Caption = 'INV-11 Template Code';
            TableRelation = "Excel Template";
        }
        field(12456; "INV-18 Template Code"; Code[10])
        {
            Caption = 'INV-18 Template Code';
            TableRelation = "Excel Template";
        }
        field(12457; "M-2a Template Code"; Code[10])
        {
            Caption = 'M-2a Template Code';
            TableRelation = "Excel Template";
        }
        field(12458; "FA-2 Template Code"; Code[10])
        {
            Caption = 'FA-2 Template Code';
            TableRelation = "Excel Template";
        }
        field(12459; "FA-14 Template Code"; Code[10])
        {
            Caption = 'FA-14 Template Code';
            TableRelation = "Excel Template";
        }
        field(12460; "FA-3 Template Code"; Code[10])
        {
            Caption = 'FA-3 Template Code';
            TableRelation = "Excel Template";
        }
        field(12461; "INV-1 Template Code"; Code[10])
        {
            Caption = 'INV-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(12462; "FA-4 Template Code"; Code[10])
        {
            Caption = 'FA-4 Template Code';
            TableRelation = "Excel Template";
        }
        field(12463; "FA-4a Template Code"; Code[10])
        {
            Caption = 'FA-4a Template Code';
            TableRelation = "Excel Template";
        }
        field(12464; "FA-6 Template Code"; Code[10])
        {
            Caption = 'FA-6 Template Code';
            TableRelation = "Excel Template";
        }
        field(12465; "FA-15 Template Code"; Code[10])
        {
            Caption = 'FA-15 Template Code';
            TableRelation = "Excel Template";
        }
        field(14924; KBK; Code[20])
        {
            Caption = 'KBK';
            TableRelation = KBK;
        }
        field(14925; "KBK (UGSS)"; Code[20])
        {
            Caption = 'KBK (UGSS)';
            TableRelation = KBK;
        }
        field(14926; "AT Declaration Template Code"; Code[10])
        {
            Caption = 'AT Declaration Template Code';
            TableRelation = "Excel Template";
        }
        field(14927; "AT Advance Template Code"; Code[10])
        {
            Caption = 'AT Advance Template Code';
            TableRelation = "Excel Template";
        }
        field(14928; "FA-1 Template Code"; Code[10])
        {
            Caption = 'FA-1 Template Code';
            TableRelation = "Excel Template";
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

    var
        DeprBook: Record "Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
}

