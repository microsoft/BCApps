// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using System.Visualization;

table 771 "Analysis Report Chart Line"
{
    Caption = 'Analysis Report Chart Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Analysis Report Chart Setup"."User ID" where(Name = field(Name),
                                                                           "Analysis Area" = field("Analysis Area"));
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
            Editable = false;
            TableRelation = "Analysis Report Chart Setup".Name where("User ID" = field("User ID"),
                                                                      "Analysis Area" = field("Analysis Area"));
        }
        field(3; "Analysis Line Line No."; Integer)
        {
            Caption = 'Analysis Line Line No.';
            Editable = false;
            TableRelation = "Analysis Line"."Line No." where("Analysis Area" = field("Analysis Area"),
                                                              "Analysis Line Template Name" = field("Analysis Line Template Name"));
        }
        field(4; "Analysis Column Line No."; Integer)
        {
            Caption = 'Analysis Column Line No.';
            Editable = false;
            TableRelation = "Analysis Column"."Line No." where("Analysis Area" = field("Analysis Area"),
                                                                "Analysis Column Template" = field("Analysis Column Template Name"));
        }
        field(6; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
            Editable = false;
            TableRelation = "Analysis Report Chart Setup"."Analysis Area" where("User ID" = field("User ID"),
                                                                                 Name = field(Name));
        }
        field(7; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            Editable = false;
            TableRelation = "Analysis Report Chart Setup"."Analysis Line Template Name" where("User ID" = field("User ID"),
                                                                                               "Analysis Area" = field("Analysis Area"),
                                                                                               Name = field(Name));
        }
        field(8; "Analysis Column Template Name"; Code[10])
        {
            Caption = 'Analysis Column Template Name';
            Editable = false;
            TableRelation = "Analysis Report Chart Setup"."Analysis Column Template Name" where("User ID" = field("User ID"),
                                                                                                 "Analysis Area" = field("Analysis Area"),
                                                                                                 Name = field(Name));
        }
        field(10; "Original Measure Name"; Text[111])
        {
            Caption = 'Original Measure Name';
            Editable = false;
        }
        field(15; "Measure Name"; Text[111])
        {
            Caption = 'Measure Name';

            trigger OnValidate()
            begin
                TestField("Measure Name");
            end;
        }
        field(20; "Measure Value"; Text[30])
        {
            Caption = 'Measure Value';
            Editable = false;
        }
        field(40; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            OptionCaption = ' ,Line,StepLine,Column,StackedColumn';
            OptionMembers = " ",Line,StepLine,Column,StackedColumn;

            trigger OnValidate()
            var
                AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
                AnalysisReportChartLine: Record "Analysis Report Chart Line";
                BusinessChartBuffer: Record "Business Chart Buffer";
                ActualNumMeasures: Integer;
            begin
                if ("Chart Type" <> "Chart Type"::" ") and IsMeasure() then begin
                    AnalysisReportChartSetup.Get("User ID", "Analysis Area", Name);
                    AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine);
                    AnalysisReportChartLine.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
                    ActualNumMeasures := 0;
                    if AnalysisReportChartLine.FindSet() then
                        repeat
                            if (AnalysisReportChartLine."Analysis Line Line No." <> "Analysis Line Line No.") or
                               (AnalysisReportChartLine."Analysis Column Line No." <> "Analysis Column Line No.")
                            then
                                ActualNumMeasures += 1;
                        until AnalysisReportChartLine.Next() = 0;
                    if ActualNumMeasures >= BusinessChartBuffer.GetMaxNumberOfMeasures() then
                        BusinessChartBuffer.RaiseErrorMaxNumberOfMeasuresExceeded();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "User ID", "Analysis Area", Name, "Analysis Line Line No.", "Analysis Column Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure IsMeasure() Result: Boolean
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        AnalysisReportChartSetup.Get("User ID", "Analysis Area", Name);
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                Result := true;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                if "Analysis Line Line No." = 0 then
                    Result := true;
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                if "Analysis Column Line No." = 0 then
                    Result := true;
        end;
    end;

    procedure GetDefaultChartType(): Integer
    begin
        exit("Chart Type"::Column);
    end;
}

