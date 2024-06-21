// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.CodeCoverage;

using System.Tooling;

page 130460 "AL Code Coverage"
{
    ApplicationArea = All;
    Caption = 'Code Coverage';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Code Coverage";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control22)
            {
                ShowCaption = false;
                field(ObjectIdFilter; this.ObjectIdFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Object Id Filter';
                    ToolTip = 'Specifies the object ID filter that applies when tracking which part of the application code has been exercised during test activity.';

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Object ID", this.ObjectIdFilter);
                        this.TotalCoveragePercent := this.ALCodeCoverageMgt.ObjectsCoverage(Rec, this.TotalNoofLines, this.TotalLinesHit) * 100;
                        CurrPage.Update(false);
                    end;
                }
                field(ObjectTypeFilter; this.ObjectTypeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Object Type Filter';
                    ToolTip = 'Specifies the object type filter that applies when tracking which part of the application code has been exercised during test activity.';

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Object Type", this.ObjectTypeFilter);
                        this.TotalCoveragePercent := this.ALCodeCoverageMgt.ObjectsCoverage(Rec, this.TotalNoofLines, this.TotalLinesHit);
                        CurrPage.Update(false);
                    end;
                }
                field(RequiredCoverage; this.RequiredCoveragePercent)
                {
                    ApplicationArea = All;
                    Caption = 'Required Coverage %';
                    ToolTip = 'Specifies the extent to which the application code is covered by tests.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(TotalNoofLines; this.TotalNoofLines)
                {
                    ApplicationArea = All;
                    Caption = 'Total # Lines';
                    Editable = false;
                    ToolTip = 'Specifies the total number of lines, when tracking which part of the application code has been exercised during test activity.';
                }
                field(TotalCoveragePercent; this.TotalCoveragePercent)
                {
                    ApplicationArea = All;
                    Caption = 'Total Coverage %';
                    DecimalPlaces = 2 : 2;
                    Editable = false;
                    ToolTip = 'Specifies the extent to which the application code is covered by tests.';
                }
            }
            repeater("Object")
            {
                Caption = 'Object';
                Editable = false;
#pragma warning disable AA0205
                IndentationColumn = this.Indent;
#pragma warning restore AA0205
                ShowAsTree = true;
                field(CodeLine; this.CodeLine)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies which part of the application code has been exercised during test activity.';
                }
                field(CoveragePercent; this.CoveragePercent)
                {
                    ApplicationArea = All;
                    Caption = 'Coverage %';
                    StyleExpr = this.CoveragePercentStyle;
                    ToolTip = 'Specifies the percentage applied to the code coverage line.';
                }
                field(LineType; Rec."Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Line Type';
                    ToolTip = 'Specifies the line type, when tracking which part of the application code has been exercised during test activity.';
                }
                field(ObjectType; Rec."Object Type")
                {
                    ApplicationArea = All;
                    Caption = 'Object Type';
                    ToolTip = 'Specifies the average coverage of all code lines inside the object, when tracking which part of the application code has been exercised during test activity.';
                }
                field(ObjectID; Rec."Object ID")
                {
                    ApplicationArea = All;
                    Caption = 'Object ID';
                    ToolTip = 'Specifies the ID of the object.';
                }
                field(LineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                    ToolTip = 'Specifies the line number, when tracking which part of the application code has been exercised during test activity.';
                }
                field(NoofLines; this.NoofLines)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Lines';
                    ToolTip = 'Specifies the number of lines, when tracking which part of the application code has been exercised during test activity.';
                }
                field("No. of Hits"; Rec."No. of Hits")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Hits';
                    ToolTip = 'Specifies the number of hits, when tracking which part of the application code has been exercised during test activity.';
                }
                field(LinesHit; this.LinesHit)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Hit Lines';
                    ToolTip = 'Specifies the number of hit lines, when tracking which part of the application code has been exercised during test activity.';
                }
                field(LinesNotHit; this.LinesNotHit)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Skipped Lines';
                    ToolTip = 'Specifies the number of skipped lines, when tracking which part of the application code has been exercised during test activity.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Start)
            {
                ApplicationArea = All;
                Caption = 'Start';
                Enabled = not this.CodeCoverageRunning;
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Start Code Coverage.';

                trigger OnAction()
                begin
                    this.ALCodeCoverageMgt.Start(true);
                    this.CodeCoverageRunning := true;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Enabled = this.CodeCoverageRunning;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                ToolTip = 'Refresh the page.';

                trigger OnAction()
                begin
                    this.ALCodeCoverageMgt.Refresh();
                end;
            }
            action(Stop)
            {
                ApplicationArea = All;
                Caption = 'Stop';
                Enabled = this.CodeCoverageRunning;
                Image = Stop;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Stop Code Coverage.';

                trigger OnAction()
                begin
                    this.ALCodeCoverageMgt.Stop();
                    this.TotalCoveragePercent := this.ALCodeCoverageMgt.ObjectsCoverage(Rec, this.TotalNoofLines, this.TotalLinesHit) * 100;
                    this.CodeCoverageRunning := false;
                end;
            }
        }
        area(reporting)
        {
            action("Backup/Restore")
            {
                ApplicationArea = All;
                Caption = 'Backup/Restore';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                ToolTip = 'Back up or restore the database.';

                trigger OnAction()
                var
                    CodeCoverageDetailed: XmlPort "Code Coverage Detailed";
                begin
                    CodeCoverageDetailed.Run();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        this.NoofLines := 0;
        this.LinesHit := 0;
        this.LinesNotHit := 0;
        this.Indent := 2;

        this.CodeLine := Rec.Line;

        case Rec."Line Type" of
            Rec."Line Type"::Object:
                // Sum object coverage
                begin
                    this.CoveragePercent := this.ALCodeCoverageMgt.ObjectCoverage(Rec, this.NoofLines, this.LinesHit) * 100;
                    this.LinesNotHit := this.NoofLines - this.LinesHit;
                    this.Indent := 0
                end;
            Rec."Line Type"::"Trigger/Function":
                // Sum method coverage
                begin
                    this.CoveragePercent := this.ALCodeCoverageMgt.FunctionCoverage(Rec, this.NoofLines, this.LinesHit) * 100;
                    this.LinesNotHit := this.NoofLines - this.LinesHit;
                    this.Indent := 1
                end
            else
                if Rec."No. of Hits" > 0 then
                    this.CoveragePercent := 100
                else
                    this.CoveragePercent := 0;
        end;

        this.SetStyles();
    end;

    trigger OnInit()
    begin
        this.RequiredCoveragePercent := 90;
    end;

    var
        ALCodeCoverageMgt: Codeunit "AL Code Coverage Mgt.";
        LinesHit: Integer;
        LinesNotHit: Integer;
        Indent: Integer;
        CodeCoverageRunning: Boolean;
        CodeLine: Text[1024];
        NoofLines: Integer;
        CoveragePercent: Decimal;
        TotalNoofLines: Integer;
        TotalCoveragePercent: Decimal;
        TotalLinesHit: Integer;
        ObjectIdFilter: Text;
        ObjectTypeFilter: Text;
        RequiredCoveragePercent: Integer;
        CoveragePercentStyle: Text;

    local procedure SetStyles()
    begin
        if Rec."Line Type" = Rec."Line Type"::Empty then
            this.CoveragePercentStyle := 'Standard'
        else
            if this.CoveragePercent < this.RequiredCoveragePercent then
                this.CoveragePercentStyle := 'Unfavorable'
            else
                this.CoveragePercentStyle := 'Favorable';
    end;
}