// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Visualization;

table 762 "Account Schedules Chart Setup"
{
    Caption = 'Account Schedules Chart Setup';
    LookupPageID = "Account Schedule Chart List";
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
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Account Schedule Name"; Code[10])
        {
            Caption = 'Account Schedule Name';
            TableRelation = "Acc. Schedule Name".Name;

            trigger OnValidate()
            var
                AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
            begin
                AccSchedChartManagement.CheckDuplicateAccScheduleLineDescription("Account Schedule Name");
                RefreshLines(false);
            end;
        }
        field(20; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name".Name;

            trigger OnValidate()
            var
                AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
            begin
                AccSchedChartManagement.CheckDuplicateColumnLayoutColumnHeader("Column Layout Name");
                RefreshLines(false);
            end;
        }
        field(30; "Base X-Axis on"; Option)
        {
            Caption = 'Base X-Axis on';
            OptionCaption = 'Period,Acc. Sched. Line,Acc. Sched. Column';
            OptionMembers = Period,"Acc. Sched. Line","Acc. Sched. Column";

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
                AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
            begin
                if (not "Last Viewed") or ("Last Viewed" = xRec."Last Viewed") then
                    exit;

                AccountSchedulesChartSetup.SetRange("User ID", "User ID");
                AccountSchedulesChartSetup.SetFilter(Name, '<>%1', Name);
                AccountSchedulesChartSetup.SetRange("Last Viewed", true);
                AccountSchedulesChartSetup.ModifyAll("Last Viewed", false);
            end;
        }
        field(51; "Look Ahead"; Boolean)
        {
            Caption = 'Look Ahead';
        }
    }

    keys
    {
        key(Key1; "User ID", Name)
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
        Text001: Label '%1 %2', Comment = '%1=Account Schdule Line_Description %2=Column Layout_Coulmn Header';
#pragma warning disable AA0470
        Text002: Label 'You cannot set %1 to %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetAccScheduleName(AccSchedName: Code[10])
    begin
        Validate("Account Schedule Name", AccSchedName);
        Modify(true);
    end;

    procedure SetColumnLayoutName(ColumnLayoutName: Code[10])
    begin
        Validate("Column Layout Name", ColumnLayoutName);
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

    procedure SetLinkToLines(var AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line")
    begin
        AccSchedChartSetupLine.SetRange("User ID", "User ID");
        AccSchedChartSetupLine.SetRange(Name, Name);
    end;

    procedure SetLinkToMeasureLines(var AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line")
    begin
        SetLinkToLines(AccSchedChartSetupLine);
        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                ;
            "Base X-Axis on"::"Acc. Sched. Line":
                AccSchedChartSetupLine.SetRange("Account Schedule Line No.", 0);
            "Base X-Axis on"::"Acc. Sched. Column":
                AccSchedChartSetupLine.SetRange("Column Layout Line No.", 0);
        end;
    end;

    procedure SetLinkToDimensionLines(var AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line")
    begin
        SetLinkToLines(AccSchedChartSetupLine);
        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                begin
                    AccSchedChartSetupLine.SetRange("Account Schedule Line No.", 0);
                    AccSchedChartSetupLine.SetRange("Column Layout Line No.", 0);
                end;
            "Base X-Axis on"::"Acc. Sched. Line":
                AccSchedChartSetupLine.SetRange("Column Layout Line No.", 0);
            "Base X-Axis on"::"Acc. Sched. Column":
                AccSchedChartSetupLine.SetRange("Account Schedule Line No.", 0);
        end;
    end;

    procedure RefreshLines(Force: Boolean)
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        TempAccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line" temporary;
    begin
        if not Force then
            if ("Account Schedule Name" = xRec."Account Schedule Name") and
               ("Column Layout Name" = xRec."Column Layout Name") and
               ("Base X-Axis on" = xRec."Base X-Axis on")
            then
                exit;

        GetMeasuresInTemp(TempAccSchedChartSetupLine);

        SetLinkToLines(AccSchedChartSetupLine);
        AccSchedChartSetupLine.DeleteAll();

        AccSchedChartSetupLine.Reset();
        if TempAccSchedChartSetupLine.FindSet() then
            repeat
                AccSchedChartSetupLine := TempAccSchedChartSetupLine;
                AccSchedChartSetupLine.Insert();
            until TempAccSchedChartSetupLine.Next() = 0;
    end;

    procedure FilterAccSchedLines(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
        AccScheduleLine.SetRange("Schedule Name", "Account Schedule Name");
        AccScheduleLine.SetFilter(Description, '<>%1', '');
    end;

    procedure FilterColumnLayout(var ColumnLayout: Record "Column Layout")
    begin
        ColumnLayout.SetRange("Column Layout Name", "Column Layout Name");
        ColumnLayout.SetFilter("Column Header", '<>%1', '');
    end;

    local procedure GetMeasuresInTemp(var TempAccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line" temporary)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        FilterAccSchedLines(AccScheduleLine);
        FilterColumnLayout(ColumnLayout);

        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                if ColumnLayout.FindSet() then
                    repeat
                        if AccScheduleLine.FindSet() then
                            repeat
                                InsertLineIntoTemp(TempAccSchedChartSetupLine, AccScheduleLine, ColumnLayout);
                            until AccScheduleLine.Next() = 0;
                    until ColumnLayout.Next() = 0;
            "Base X-Axis on"::"Acc. Sched. Line",
            "Base X-Axis on"::"Acc. Sched. Column":
                begin
                    if AccScheduleLine.FindSet() then
                        repeat
                            InsertLineIntoTemp(TempAccSchedChartSetupLine, AccScheduleLine, ColumnLayout);
                        until AccScheduleLine.Next() = 0;
                    Clear(AccScheduleLine);
                    if ColumnLayout.FindSet() then
                        repeat
                            InsertLineIntoTemp(TempAccSchedChartSetupLine, AccScheduleLine, ColumnLayout);
                        until ColumnLayout.Next() = 0;
                end;
        end;

        SetChartTypesToDefault(TempAccSchedChartSetupLine);
    end;

    local procedure InsertLineIntoTemp(var TempAccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line" temporary; AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout")
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
    begin
        TempAccSchedChartSetupLine.Init();
        TempAccSchedChartSetupLine."User ID" := "User ID";
        TempAccSchedChartSetupLine.Name := Name;
        TempAccSchedChartSetupLine."Account Schedule Name" := "Account Schedule Name";
        TempAccSchedChartSetupLine."Account Schedule Line No." := AccScheduleLine."Line No.";
        TempAccSchedChartSetupLine."Column Layout Name" := "Column Layout Name";
        TempAccSchedChartSetupLine."Column Layout Line No." := ColumnLayout."Line No.";

        case "Base X-Axis on" of
            "Base X-Axis on"::Period:
                begin
                    TempAccSchedChartSetupLine."Original Measure Name" :=
                      StrSubstNo(Text001, AccScheduleLine.Description, ColumnLayout."Column Header");
                    TempAccSchedChartSetupLine."Measure Value" := StrSubstNo(Text001, AccScheduleLine."Line No.", ColumnLayout."Line No.");
                end;
            "Base X-Axis on"::"Acc. Sched. Line",
          "Base X-Axis on"::"Acc. Sched. Column":
                case true of
                    AccScheduleLine."Line No." = 0:
                        begin
                            TempAccSchedChartSetupLine."Original Measure Name" := ColumnLayout."Column Header";
                            TempAccSchedChartSetupLine."Measure Value" := Format(ColumnLayout."Line No.");
                        end;
                    ColumnLayout."Line No." = 0:
                        begin
                            TempAccSchedChartSetupLine."Original Measure Name" := AccScheduleLine.Description;
                            TempAccSchedChartSetupLine."Measure Value" := Format(AccScheduleLine."Line No.");
                        end;
                end;
        end;
        TempAccSchedChartSetupLine."Measure Name" := TempAccSchedChartSetupLine."Original Measure Name";

        if AccSchedChartSetupLine.Get(TempAccSchedChartSetupLine."User ID",
             TempAccSchedChartSetupLine.Name,
             TempAccSchedChartSetupLine."Account Schedule Line No.",
             TempAccSchedChartSetupLine."Column Layout Line No.")
        then
            TempAccSchedChartSetupLine."Chart Type" := AccSchedChartSetupLine."Chart Type";

        TempAccSchedChartSetupLine.Insert();
    end;

    local procedure SetChartTypesToDefault(var TempAccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line" temporary)
    var
        TempAccSchedChartSetupLine2: Record "Acc. Sched. Chart Setup Line" temporary;
    begin
        TempAccSchedChartSetupLine2.Copy(TempAccSchedChartSetupLine, true);

        SetMeasureChartTypesToDefault(TempAccSchedChartSetupLine2);

        TempAccSchedChartSetupLine2.Reset();
        SetLinkToDimensionLines(TempAccSchedChartSetupLine2);
        TempAccSchedChartSetupLine2.SetFilter("Chart Type", '<>%1', TempAccSchedChartSetupLine2."Chart Type"::" ");
        if TempAccSchedChartSetupLine2.IsEmpty() then
            SetDimensionChartTypesToDefault(TempAccSchedChartSetupLine2);
    end;

    procedure SetMeasureChartTypesToDefault(var AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line")
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        MaxNumMeasures: Integer;
        NumOfMeasuresToBeSet: Integer;
    begin
        AccSchedChartSetupLine.Reset();
        SetLinkToMeasureLines(AccSchedChartSetupLine);
        AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
        MaxNumMeasures := BusinessChartBuffer.GetMaxNumberOfMeasures();
        NumOfMeasuresToBeSet := MaxNumMeasures - AccSchedChartSetupLine.Count();
        if NumOfMeasuresToBeSet > 0 then begin
            AccSchedChartSetupLine.SetRange("Chart Type", AccSchedChartSetupLine."Chart Type"::" ");
            if AccSchedChartSetupLine.FindSet() then
                repeat
                    AccSchedChartSetupLine."Chart Type" := AccSchedChartSetupLine.GetDefaultAccSchedChartType();
                    AccSchedChartSetupLine.Modify();
                    NumOfMeasuresToBeSet -= 1;
                until (NumOfMeasuresToBeSet = 0) or (AccSchedChartSetupLine.Next() = 0);
        end;
    end;

    procedure SetDimensionChartTypesToDefault(var AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line")
    begin
        AccSchedChartSetupLine.Reset();
        SetLinkToDimensionLines(AccSchedChartSetupLine);
        AccSchedChartSetupLine.SetRange("Chart Type", AccSchedChartSetupLine."Chart Type"::" ");
        AccSchedChartSetupLine.ModifyAll("Chart Type", AccSchedChartSetupLine.GetDefaultAccSchedChartType());
    end;

    local procedure DeleteLines()
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
    begin
        AccSchedChartSetupLine.SetRange("User ID", "User ID");
        AccSchedChartSetupLine.SetRange(Name, Name);
        AccSchedChartSetupLine.DeleteAll();
    end;
}

