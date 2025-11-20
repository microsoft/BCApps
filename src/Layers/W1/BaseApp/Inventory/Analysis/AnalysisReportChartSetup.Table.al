// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using System.Visualization;

table 770 "Analysis Report Chart Setup"
{
    Caption = 'Analysis Report Chart Setup';
    LookupPageID = "Analysis Report Chart List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(10; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
            Editable = false;
        }
        field(20; "Analysis Report Name"; Code[10])
        {
            Caption = 'Analysis Report Name';
            TableRelation = "Analysis Report Name".Name where("Analysis Area" = field("Analysis Area"));

            trigger OnValidate()
            var
                AnalysisReportName: Record "Analysis Report Name";
                AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
            begin
                AnalysisReportName.Get("Analysis Area", "Analysis Report Name");
                "Analysis Line Template Name" := AnalysisReportName."Analysis Line Template Name";
                "Analysis Column Template Name" := AnalysisReportName."Analysis Column Template Name";
                AnalysisReportChartMgt.CheckDuplicateAnalysisLineDescription("Analysis Area".AsInteger(), "Analysis Line Template Name");
                AnalysisReportChartMgt.CheckDuplicateAnalysisColumnHeader("Analysis Area".AsInteger(), "Analysis Column Template Name");

                RefreshLines(false);
            end;
        }
        field(21; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            Editable = false;
            TableRelation = "Analysis Report Name"."Analysis Line Template Name" where("Analysis Area" = field("Analysis Area"),
                                                                                        Name = field("Analysis Report Name"));

            trigger OnLookup()
            var
                AnalysisLineTemplate: Record "Analysis Line Template";
                AnalysisLineTemplate2: Record "Analysis Line Template";
            begin
                AnalysisLineTemplate.SetRange("Analysis Area", "Analysis Area");
                AnalysisLineTemplate2.Get("Analysis Area", "Analysis Line Template Name");
                AnalysisLineTemplate := AnalysisLineTemplate2;
                PAGE.RunModal(0, AnalysisLineTemplate);
            end;
        }
        field(22; "Analysis Column Template Name"; Code[10])
        {
            Caption = 'Analysis Column Template Name';
            Editable = false;
            TableRelation = "Analysis Report Name"."Analysis Column Template Name" where("Analysis Area" = field("Analysis Area"),
                                                                                          Name = field("Analysis Report Name"));

            trigger OnLookup()
            var
                AnalysisColumnTemplate: Record "Analysis Column Template";
                AnalysisColumnTemplate2: Record "Analysis Column Template";
            begin
                AnalysisColumnTemplate.SetRange("Analysis Area", "Analysis Area");
                AnalysisColumnTemplate2.Get("Analysis Area", "Analysis Column Template Name");
                AnalysisColumnTemplate := AnalysisColumnTemplate2;
                PAGE.RunModal(0, AnalysisColumnTemplate);
            end;
        }
        field(30; "Base X-Axis on"; Option)
        {
            Caption = 'Base X-Axis on';
            OptionCaption = 'Period,Line,Column';
            OptionMembers = Period,Line,Column;

            trigger OnValidate()
            begin
                RefreshLines(false);
                if "End Date" = 0D then
                    "End Date" := "Start Date";
            end;
        }
        field(31; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestField("Start Date");
            end;
        }
        field(32; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                TestField("End Date");
            end;
        }
        field(41; "Period Length"; Option)
        {
            Caption = 'Period Length';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(42; "No. of Periods"; Integer)
        {
            Caption = 'No. of Periods';
            InitValue = 12;

            trigger OnValidate()
            begin
                if "No. of Periods" < 1 then
                    Error(Text002, FieldCaption("No. of Periods"), "No. of Periods");
            end;
        }
        field(50; "Last Viewed"; Boolean)
        {
            Caption = 'Last Viewed';
            Editable = false;

            trigger OnValidate()
            var
                AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
            begin
                if (not "Last Viewed") or ("Last Viewed" = xRec."Last Viewed") then
                    exit;

                AnalysisReportChartSetup.SetRange("User ID", "User ID");
                AnalysisReportChartSetup.SetRange("Analysis Area", "Analysis Area");
                AnalysisReportChartSetup.SetFilter(Name, '<>%1', Name);
                AnalysisReportChartSetup.SetRange("Last Viewed", true);
                AnalysisReportChartSetup.ModifyAll("Last Viewed", false);
            end;
        }
    }

    keys
    {
        key(Key1; "User ID", "Analysis Area", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteLines();
    end;

    var
#pragma warning disable AA0074
        Text001: Label '%1 %2', Comment = '%1=Analysis Line_Description %2=Analysis Column_Coulmn Header';
#pragma warning disable AA0470
        Text002: Label 'You cannot set %1 to %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetAnalysisReportName(ReportName: Code[10])
    begin
        Validate("Analysis Report Name", ReportName);
        Modify(true);
    end;

    procedure SetShowPer(ShowPer: Option)
    begin
        Validate("Base X-Axis on", ShowPer);
        Modify(true);
    end;

    procedure SetPeriodLength(PeriodLength: Option)
    begin
        "Period Length" := PeriodLength;
        Modify(true);
    end;

    procedure SetLastViewed()
    begin
        Validate("Last Viewed", true);
        Modify(true);
    end;

    procedure SetLinkToLines(var AnalysisReportChartLine: Record "Analysis Report Chart Line")
    begin
        AnalysisReportChartLine.SetRange("User ID", "User ID");
        AnalysisReportChartLine.SetRange("Analysis Area", "Analysis Area");
        AnalysisReportChartLine.SetRange(Name, Name);
    end;

    procedure SetLinkToMeasureLines(var AnalysisReportChartLine: Record "Analysis Report Chart Line")
    begin
        SetLinkToLines(AnalysisReportChartLine);
        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                ;
            "Base X-Axis on"::Line:
                AnalysisReportChartLine.SetRange("Analysis Line Line No.", 0);
            "Base X-Axis on"::Column:
                AnalysisReportChartLine.SetRange("Analysis Column Line No.", 0);
        end;
    end;

    procedure SetLinkToDimensionLines(var AnalysisReportChartLine: Record "Analysis Report Chart Line")
    begin
        SetLinkToLines(AnalysisReportChartLine);
        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                begin
                    AnalysisReportChartLine.SetRange("Analysis Line Line No.", 0);
                    AnalysisReportChartLine.SetRange("Analysis Column Line No.", 0);
                end;
            "Base X-Axis on"::Line:
                AnalysisReportChartLine.SetRange("Analysis Column Line No.", 0);
            "Base X-Axis on"::Column:
                AnalysisReportChartLine.SetRange("Analysis Line Line No.", 0);
        end;
    end;

    procedure RefreshLines(Force: Boolean)
    var
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
        TempAnalysisReportChartLine: Record "Analysis Report Chart Line" temporary;
    begin
        if not Force then
            if ("Analysis Report Name" = xRec."Analysis Report Name") and
               ("Base X-Axis on" = xRec."Base X-Axis on")
            then
                exit;

        GetMeasuresInTemp(TempAnalysisReportChartLine);

        SetLinkToLines(AnalysisReportChartLine);
        AnalysisReportChartLine.DeleteAll();

        AnalysisReportChartLine.Reset();
        if TempAnalysisReportChartLine.FindSet() then
            repeat
                AnalysisReportChartLine := TempAnalysisReportChartLine;
                AnalysisReportChartLine.Insert();
            until TempAnalysisReportChartLine.Next() = 0;
    end;

    procedure FilterAnalysisLine(var AnalysisLine: Record "Analysis Line")
    begin
        AnalysisLine.SetRange("Analysis Area", "Analysis Area");
        AnalysisLine.SetRange("Analysis Line Template Name", "Analysis Line Template Name");
        AnalysisLine.SetFilter(Description, '<>%1', '');
    end;

    procedure FilterAnalysisColumn(var AnalysisColumn: Record "Analysis Column")
    begin
        AnalysisColumn.SetRange("Analysis Area", "Analysis Area");
        AnalysisColumn.SetRange("Analysis Column Template", "Analysis Column Template Name");
        AnalysisColumn.SetFilter("Column Header", '<>%1', '');
    end;

    local procedure GetMeasuresInTemp(var TempAnalysisReportChartLine: Record "Analysis Report Chart Line" temporary)
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
    begin
        FilterAnalysisLine(AnalysisLine);
        FilterAnalysisColumn(AnalysisColumn);

        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                if AnalysisColumn.FindSet() then
                    repeat
                        if AnalysisLine.FindSet() then
                            repeat
                                InsertLineIntoTemp(TempAnalysisReportChartLine, AnalysisLine, AnalysisColumn);
                            until AnalysisLine.Next() = 0;
                    until AnalysisColumn.Next() = 0;
            "Base X-Axis on"::Line,
            "Base X-Axis on"::Column:
                begin
                    if AnalysisLine.FindSet() then
                        repeat
                            InsertLineIntoTemp(TempAnalysisReportChartLine, AnalysisLine, AnalysisColumn);
                        until AnalysisLine.Next() = 0;
                    Clear(AnalysisLine);
                    if AnalysisColumn.FindSet() then
                        repeat
                            InsertLineIntoTemp(TempAnalysisReportChartLine, AnalysisLine, AnalysisColumn);
                        until AnalysisColumn.Next() = 0;
                end;
        end;

        SetChartTypesToDefault(TempAnalysisReportChartLine);
    end;

    local procedure InsertLineIntoTemp(var TempAnalysisReportChartLine: Record "Analysis Report Chart Line" temporary; AnalysisLine: Record "Analysis Line"; AnalysisColumn: Record "Analysis Column")
    var
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
    begin
        TempAnalysisReportChartLine.Init();
        TempAnalysisReportChartLine."User ID" := "User ID";
        TempAnalysisReportChartLine."Analysis Area" := "Analysis Area";
        TempAnalysisReportChartLine.Name := Name;
        TempAnalysisReportChartLine."Analysis Line Line No." := AnalysisLine."Line No.";
        TempAnalysisReportChartLine."Analysis Column Line No." := AnalysisColumn."Line No.";
        TempAnalysisReportChartLine."Analysis Line Template Name" := "Analysis Line Template Name";
        TempAnalysisReportChartLine."Analysis Column Template Name" := "Analysis Column Template Name";

        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                begin
                    TempAnalysisReportChartLine."Original Measure Name" :=
                      StrSubstNo(Text001, AnalysisLine.Description, AnalysisColumn."Column Header");
                    TempAnalysisReportChartLine."Measure Value" := StrSubstNo(Text001, AnalysisLine."Line No.", AnalysisColumn."Line No.");
                end;
            "Base X-Axis on"::Line,
          "Base X-Axis on"::Column:
                case true of
                    AnalysisLine."Line No." = 0:
                        begin
                            TempAnalysisReportChartLine."Original Measure Name" := AnalysisColumn."Column Header";
                            TempAnalysisReportChartLine."Measure Value" := Format(AnalysisColumn."Line No.");
                        end;
                    AnalysisColumn."Line No." = 0:
                        begin
                            TempAnalysisReportChartLine."Original Measure Name" := AnalysisLine.Description;
                            TempAnalysisReportChartLine."Measure Value" := Format(AnalysisLine."Line No.");
                        end;
                end;
        end;
        TempAnalysisReportChartLine."Measure Name" := TempAnalysisReportChartLine."Original Measure Name";

        if AnalysisReportChartLine.Get(TempAnalysisReportChartLine."User ID",
             TempAnalysisReportChartLine."Analysis Area",
             TempAnalysisReportChartLine.Name,
             TempAnalysisReportChartLine."Analysis Line Line No.",
             TempAnalysisReportChartLine."Analysis Column Line No.")
        then
            TempAnalysisReportChartLine."Chart Type" := AnalysisReportChartLine."Chart Type";

        TempAnalysisReportChartLine.Insert();
    end;

    local procedure SetChartTypesToDefault(var TempAnalysisReportChartLine: Record "Analysis Report Chart Line" temporary)
    var
        TempAnalysisReportChartLine2: Record "Analysis Report Chart Line" temporary;
    begin
        TempAnalysisReportChartLine2.Copy(TempAnalysisReportChartLine, true);

        SetMeasureChartTypesToDefault(TempAnalysisReportChartLine2);

        TempAnalysisReportChartLine2.Reset();
        SetLinkToDimensionLines(TempAnalysisReportChartLine2);
        TempAnalysisReportChartLine2.SetFilter("Chart Type", '<>%1', TempAnalysisReportChartLine2."Chart Type"::" ");
        if TempAnalysisReportChartLine2.IsEmpty() then
            SetDimensionChartTypesToDefault(TempAnalysisReportChartLine2);
    end;

    procedure SetMeasureChartTypesToDefault(var AnalysisReportChartLine: Record "Analysis Report Chart Line")
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        MaxNumMeasures: Integer;
        NumOfMeasuresToBeSet: Integer;
    begin
        AnalysisReportChartLine.Reset();
        SetLinkToMeasureLines(AnalysisReportChartLine);
        AnalysisReportChartLine.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
        MaxNumMeasures := BusinessChartBuffer.GetMaxNumberOfMeasures();
        NumOfMeasuresToBeSet := MaxNumMeasures - AnalysisReportChartLine.Count();
        if NumOfMeasuresToBeSet > 0 then begin
            AnalysisReportChartLine.SetRange("Chart Type", AnalysisReportChartLine."Chart Type"::" ");
            if AnalysisReportChartLine.FindSet() then
                repeat
                    AnalysisReportChartLine."Chart Type" := AnalysisReportChartLine.GetDefaultChartType();
                    AnalysisReportChartLine.Modify();
                    NumOfMeasuresToBeSet -= 1;
                until (NumOfMeasuresToBeSet = 0) or (AnalysisReportChartLine.Next() = 0);
        end;
    end;

    procedure SetDimensionChartTypesToDefault(var AnalysisReportChartLine: Record "Analysis Report Chart Line")
    begin
        AnalysisReportChartLine.Reset();
        SetLinkToDimensionLines(AnalysisReportChartLine);
        AnalysisReportChartLine.SetRange("Chart Type", AnalysisReportChartLine."Chart Type"::" ");
        AnalysisReportChartLine.ModifyAll("Chart Type", AnalysisReportChartLine.GetDefaultChartType());
    end;

    local procedure DeleteLines()
    var
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
    begin
        AnalysisReportChartLine.SetRange("User ID", "User ID");
        AnalysisReportChartLine.SetRange("Analysis Area", "Analysis Area");
        AnalysisReportChartLine.SetRange(Name, Name);
        AnalysisReportChartLine.DeleteAll();
    end;
}

