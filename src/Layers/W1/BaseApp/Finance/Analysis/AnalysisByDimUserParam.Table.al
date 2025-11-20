// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Foundation.Enums;

table 727 "Analysis by Dim. User Param."
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
        field(30; "Period Type"; Option)
        {
            Caption = 'View by';
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period";
            DataClassification = SystemMetadata;
        }
        field(31; "Column Set"; Text[250])
        {
            Caption = 'Column Set';
            DataClassification = SystemMetadata;
        }
        field(33; "Amount Type"; Option)
        {
            Caption = 'View as';
            OptionCaption = 'Net Change,Balance at Date';
            OptionMembers = "Net Change","Balance at Date";
            DataClassification = SystemMetadata;
        }
        field(1000; "User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
        }
        field(1001; "Page ID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User ID", "Page ID")
        {
            Clustered = true;
        }
    }

    procedure Load(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; PageId: Integer)
    begin
        case PageId of
            Page::"Analysis by Dimensions":
                LoadForAnalysisByDimensions(AnalysisByDimParameters);
            Page::"G/L Balance by Dimension":
                LoadForGLBalanceByDimension(AnalysisByDimParameters);
        end;
    end;

    local procedure LoadForGLBalanceByDimension(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
        AnalysisByDimParameters.Init();
        if Get(UserId(), Page::"G/L Balance by Dimension") then
            AnalysisByDimParameters.TransferFields(Rec);
        AnalysisByDimParameters.Insert();
    end;

    local procedure LoadForAnalysisByDimensions(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        SavedAnalysisViewCode: Code[10];
        AccountsFilter: Text[250];
    begin
        AccountsFilter := AnalysisByDimParameters."Account Filter";
        if AnalysisByDimParameters."Analysis View Code" <> '' then begin
            SavedAnalysisViewCode := AnalysisByDimParameters."Analysis View Code";
            if Get(UserId(), Page::"Analysis by Dimensions") then begin
                AnalysisByDimParameters.TransferFields(Rec);
                if AccountsFilter <> '' then
                    AnalysisByDimParameters."Account Filter" := AccountsFilter;
                AnalysisByDimParameters."Analysis View Code" := SavedAnalysisViewCode;
            end;
            AnalysisByDimParameters.Modify();
        end else begin
            AnalysisByDimParameters.Init();
            if Get(UserId(), Page::"Analysis by Dimensions") then begin
                AnalysisByDimParameters.TransferFields(Rec);
                if AccountsFilter <> '' then
                    AnalysisByDimParameters."Account Filter" := AccountsFilter;
            end;
            AnalysisByDimParameters.Insert();
        end;
    end;

    procedure Save(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; PageId: Integer)
    var
        CurrUserId: Code[50];
    begin
        CurrUserId := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        if Get(CurrUserId, PageId) then begin
            TransferFields(AnalysisByDimParameters);
            Modify();
        end else begin
            Init();
            TransferFields(AnalysisByDimParameters);
            "User ID" := CurrUserId;
            "Page ID" := PageId;
            Insert();
        end;
    end;
}
