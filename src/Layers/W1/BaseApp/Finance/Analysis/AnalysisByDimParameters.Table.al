// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

table 361 "Analysis by Dim. Parameters"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            TableRelation = "Analysis View";
            DataClassification = SystemMetadata;
        }
        field(3; "Line Dim Option"; Enum "Analysis Dimension Option")
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Column Dim Option"; Enum "Analysis Dimension Option")
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Date Filter"; Text[250])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(6; "Account Filter"; Text[250])
        {
            Caption = 'Account Filter';
            DataClassification = SystemMetadata;
        }
        field(7; "Bus. Unit Filter"; Text[250])
        {
            Caption = 'Business Unit Filter';
            DataClassification = SystemMetadata;
        }
        field(8; "Cash Flow Forecast Filter"; Text[250])
        {
            Caption = 'Cash Flow Forecast Filter';
            DataClassification = SystemMetadata;
        }
        field(9; "Budget Filter"; Text[250])
        {
            Caption = 'Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(10; "Dimension 1 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Dimension 2 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(12; "Dimension 3 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(13; "Dimension 4 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(20; "Show Actual/Budgets"; Enum "Analysis Show Amount Type")
        {
            Caption = 'Show';
            DataClassification = SystemMetadata;
        }
        field(21; "Show Amount Field"; Enum "Analysis Show Amount Field")
        {
            DataClassification = SystemMetadata;
        }
        field(22; "Closing Entries"; Option)
        {
            Caption = 'Closing Entries';
            OptionCaption = 'Include,Exclude';
            OptionMembers = Include,Exclude;
            DataClassification = SystemMetadata;
        }
        field(23; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
            DataClassification = SystemMetadata;
        }
        field(24; "Show In Add. Currency"; Boolean)
        {
            Caption = 'Show Amounts in Add. Reporting Currency';
            DataClassification = SystemMetadata;
        }
        field(25; "Show Column Name"; Boolean)
        {
            Caption = 'Show Column Name';
            DataClassification = SystemMetadata;
        }
        field(26; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
            DataClassification = SystemMetadata;
        }
        field(30; "Period Type"; Enum "Analysis Period Type")
        {
            Caption = 'View by';
            DataClassification = SystemMetadata;
        }
        field(31; "Column Set"; Text[250])
        {
            Caption = 'Column Set';
            DataClassification = SystemMetadata;
        }
        field(33; "Amount Type"; Enum "Analysis Amount Type")
        {
            Caption = 'View as';
            DataClassification = SystemMetadata;
        }
        field(34; "Analysis Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Analysis Account Source';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key("Key 1"; "Analysis View Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure GetRangeMinDateFilter(): Date
    var
        TempGLAccount: Record "G/L Account" temporary;
    begin
        if "Date Filter" <> '' then begin
            TempGLAccount.SetFilter("Date Filter", "Date Filter");
            exit(TempGLAccount.GetRangeMin("Date Filter"));
        end;
    end;
}
