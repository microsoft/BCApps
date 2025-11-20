// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

table 366 "Analysis View Budget Entry"
{
    Caption = 'Analysis View Budget Entry';
    DrillDownPageID = "Analysis View Budget Entries";
    LookupPageID = "Analysis View Budget Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Analysis View";
        }
        field(2; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "G/L Budget Name";
        }
        field(3; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(5; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        field(6; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        field(7; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        field(8; "Dimension 4 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Value Code';
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Analysis View Code", "Budget Name", "G/L Account No.", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Business Unit Code", "Posting Date", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Analysis View Code", "Business Unit Code", "Budget Name", "G/L Account No.", "Posting Date", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    var
        AnalysisViewEntry: Record "Analysis View Entry";
    begin
        AnalysisViewEntry.Init();
        AnalysisViewEntry."Analysis View Code" := "Analysis View Code";
        exit(AnalysisViewEntry.GetCaptionClass(AnalysisViewDimType));
    end;

    procedure CopyDimFilters(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Value Code");
        AccSchedLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Value Code");
        AccSchedLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Value Code");
        AccSchedLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Value Code");
    end;

    procedure SetDimFilters(DimFilter1: Text; DimFilter2: Text; DimFilter3: Text; DimFilter4: Text)
    begin
        SetFilter("Dimension 1 Value Code", DimFilter1);
        SetFilter("Dimension 2 Value Code", DimFilter2);
        SetFilter("Dimension 3 Value Code", DimFilter3);
        SetFilter("Dimension 4 Value Code", DimFilter4);
    end;
}
