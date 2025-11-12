namespace System.TestTools.CodeCoverage;

using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Tooling;

page 9990 "Code Coverage"
{
    ApplicationArea = All;
    Caption = 'Code Coverage';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    Permissions =;
    SourceTable = "Code Coverage";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control22)
            {
                ShowCaption = false;
                field(ObjectIdFilter; ObjectIdFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Object Id Filter';
                    ToolTip = 'Specifies the object ID filter that applies when tracking which part of the application code has been exercised during test activity.';

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Object ID", ObjectIdFilter);
                        TotalCoveragePercent := CodeCoverageMgt.ObjectsCoverage(Rec, TotalNoofLines, TotalLinesHit) * 100;
                        CurrPage.Update(false);
                    end;
                }
                field(ObjectTypeFilter; ObjectTypeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Object Type Filter';
                    ToolTip = 'Specifies the object type filter that applies when tracking which part of the application code has been exercised during test activity.';

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Object Type", ObjectTypeFilter);
                        TotalCoveragePercent := CodeCoverageMgt.ObjectsCoverage(Rec, TotalNoofLines, TotalLinesHit);
                        CurrPage.Update(false);
                    end;
                }
                field(RequiredCoverage; RequiredCoveragePercent)
                {
                    ApplicationArea = All;
                    Caption = 'Required Coverage %';
                    ToolTip = 'Specifies the extent to which the application code is covered by tests.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(TotalNoofLines; TotalNoofLines)
                {
                    ApplicationArea = All;
                    Caption = 'Total # Lines';
                    Editable = false;
                    ToolTip = 'Specifies the total number of lines, when tracking which part of the application code has been exercised during test activity.';
                }
                field(TotalCoveragePercent; TotalCoveragePercent)
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
                IndentationColumn = Indent;
                ShowAsTree = true;
                field(CodeLine; CodeLine)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies which part of the application code has been exercised during test activity.';
                }
                field(CoveragePercent; CoveragePercent)
                {
                    ApplicationArea = All;
                    Caption = 'Coverage %';
                    StyleExpr = CoveragePercentStyle;
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
                field(NoofLines; NoofLines)
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
                field(LinesHit; LinesHit)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Hit Lines';
                    ToolTip = 'Specifies the number of hit lines, when tracking which part of the application code has been exercised during test activity.';
                }
                field(LinesNotHit; LinesNotHit)
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
                Enabled = not CodeCoverageRunning;
                Image = Start;

                trigger OnAction()
                begin
                    if not IsCodeCoverageEnabled() then
                        Error(RunCodeCoverageInSandboxErr);
                    CodeCoverageMgt.Start(true);
                    CodeCoverageRunning := true;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Enabled = CodeCoverageRunning;
                Image = Refresh;
                ToolTip = 'Refresh the page.';

                trigger OnAction()
                begin
                    CodeCoverageMgt.Refresh();
                end;
            }
            action(Stop)
            {
                ApplicationArea = All;
                Caption = 'Stop';
                Enabled = CodeCoverageRunning;
                Image = Stop;

                trigger OnAction()
                begin
                    CodeCoverageMgt.Stop();
                    TotalCoveragePercent := CodeCoverageMgt.ObjectsCoverage(Rec, TotalNoofLines, TotalLinesHit) * 100;
                    CodeCoverageRunning := false;
                end;
            }
        }
        area(navigation)
        {
            action("Load objects")
            {
                ApplicationArea = All;
                Caption = 'Load objects';
                Image = AddContacts;

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"Code Coverage AL Object");
                end;
            }
            action("Load country objects")
            {
                ApplicationArea = All;
                Caption = 'Load country objects';
                Image = AddContacts;

                trigger OnAction()
                var
                    AllObj: Record AllObj;
                begin
                    ObjectIdFilter := '10000..99999|1000000..98999999';
                    AllObj.SetFilter("Object ID", ObjectIdFilter);
                    CodeCoverageInclude(AllObj);
                    Rec.SetFilter("Object ID", ObjectIdFilter)
                end;
            }
        }
        area(reporting)
        {
            action("Export to XML")
            {
                ApplicationArea = All;
                Caption = 'Export to XML';
                Image = Export;

                trigger OnAction()
                var
                    CodeCoverage: Record "Code Coverage";
                    CodeCoverageSummary: XMLport "Code Coverage Summary";
                begin
                    CodeCoverage.CopyFilters(Rec);
                    CodeCoverageSummary.SetTableView(CodeCoverage);
                    CodeCoverageSummary.Run();
                end;
            }
            action("Backup/Restore")
            {
                ApplicationArea = All;
                Caption = 'Backup/Restore';
                Image = Export;
                ToolTip = 'Back up or restore the database.';

                trigger OnAction()
                var
                    CodeCoverageDetailed: XMLport "Code Coverage Detailed";
                begin
                    CodeCoverageDetailed.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Start_Promoted; Start)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
                actionref(Stop_Promoted; Stop)
                {
                }
                actionref("Load objects_Promoted"; "Load objects")
                {
                }
                actionref("Load country objects_Promoted"; "Load country objects")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Export to XML_Promoted"; "Export to XML")
                {
                }
                actionref("Backup/Restore_Promoted"; "Backup/Restore")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NoofLines := 0;
        LinesHit := 0;
        LinesNotHit := 0;
        Indent := 2;

        CodeLine := Rec.Line;

        case Rec."Line Type" of
            Rec."Line Type"::Object:
                // Sum object coverage
                begin
                    CoveragePercent := CodeCoverageMgt.ObjectCoverage(Rec, NoofLines, LinesHit) * 100;
                    LinesNotHit := NoofLines - LinesHit;
                    Indent := 0
                end;
            Rec."Line Type"::"Trigger/Function":
                // Sum method coverage
                begin
                    CoveragePercent := CodeCoverageMgt.FunctionCoverage(Rec, NoofLines, LinesHit) * 100;
                    LinesNotHit := NoofLines - LinesHit;
                    Indent := 1
                end
            else
                if Rec."No. of Hits" > 0 then
                    CoveragePercent := 100
                else
                    CoveragePercent := 0;
        end;

        SetStyles();
    end;

    trigger OnInit()
    begin
        RequiredCoveragePercent := 90;
    end;

    trigger OnOpenPage()
    begin
        if not IsCodeCoverageEnabled() then
            Error(RunCodeCoverageInSandboxErr);
    end;

    local procedure IsCodeCoverageEnabled(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
    begin
        if not ServerSetting.GetTestAutomationEnabled() then
            exit(false);

        if not EnvironmentInformation.IsSaas() then
            exit(true);

        exit(EnvironmentInformation.IsSandbox());
    end;

    var
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
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
        RunCodeCoverageInSandboxErr: Label 'Test Automation is not enabled on this system. For more information, see https://go.microsoft.com/fwlink/?linkid=2131960.';

    local procedure SetStyles()
    begin
        if Rec."Line Type" = Rec."Line Type"::Empty then
            CoveragePercentStyle := 'Standard'
        else
            if CoveragePercent < RequiredCoveragePercent then
                CoveragePercentStyle := 'Unfavorable'
            else
                CoveragePercentStyle := 'Favorable';
    end;
}

