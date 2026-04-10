page 130026 "Changelist Code"
{
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Changelist Code";

    layout
    {
        area(content)
        {
            field(ExcludeEmptyLines; ExcludeEmptyLines)
            {
                ApplicationArea = All;
                Caption = 'Exclude Empty Lines';

                trigger OnValidate()
                begin
                    if ExcludeEmptyLines then
                        SetFilter("Line Type", '<>%1', "Line Type"::Empty)
                    else
                        SetRange("Line Type");
                    CurrPage.Update(false);
                end;
            }
            field(ShowOnlyLinesNotCovered; ShowOnlyLinesNotCovered)
            {
                ApplicationArea = All;
                Caption = 'Show Only Lines not Covered';

                trigger OnValidate()
                begin
                    if ShowOnlyLinesNotCovered then begin
                        SetFilter("Line Type", '<>%1', "Line Type"::Empty);
                        SetFilter(Coverage, '%1|%2', Coverage::Partial, Coverage::None)
                    end else begin
                        SetRange("Line Type");
                        SetRange(Coverage);
                    end;
                    CurrPage.Update(false);
                end;
            }
            repeater(Group)
            {
                IndentationColumn = CodeLineIndent;
                ShowAsTree = true;
                field(Line; Line)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = LineStyleExpr;
                }
                field(Change; Change)
                {
                    ApplicationArea = All;
                }
                field("Line Type"; "Line Type")
                {
                    ApplicationArea = All;
                }
                field(Coverage; Coverage)
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = CoverageStyleExpr;
                }
                field("Coverage %"; "Coverage %")
                {
                    ApplicationArea = All;
                }
                field(TotalNoOfObjectCodeLines; TotalNoOfObjectCodeLines)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'No. of Code Lines in Object';
                    Visible = false;
                }
                field(NoOfCodeLinesNotHit; NoOfCodeLinesNotHit)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'No. of Code Lines not Hit in Object';
                }
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Object No."; "Object No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Checkins"; "No. of Checkins")
                {
                    ApplicationArea = All;
                }
                field("Cyclomatic Complexity"; "Cyclomatic Complexity")
                {
                    ApplicationArea = All;
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                field(TotalNoOfCodeLines; TotalNoOfCodeLines)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Code Lines';
                }
                field(TotalNoOfCodeLinesHit; TotalNoOfCodeLinesHit)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Code Lines Hit';
                }
                field(TotalCodeCoveragePct; TotalCodeCoveragePct)
                {
                    ApplicationArea = All;
                    Caption = 'Code Coverage %';
                    AutoFormatType = 0;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Get Changelist")
                {
                    ApplicationArea = All;
                    Caption = 'Get Changelist';
                    Image = SelectEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Get Changelist Code";
                }
                action("<Codeunit 130029>")
                {
                    ApplicationArea = All;
                    Caption = 'Get Coverage';
                    Image = SelectEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Get Build Coverage";
                }
                action(Clear)
                {
                    ApplicationArea = All;
                    Caption = 'Clear';

                    trigger OnAction()
                    begin
                        ClearStatus();
                    end;
                }
                action("Delete Line")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Line';

                    trigger OnAction()
                    begin
                        Delete(true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TotalCodeCoveragePct := CalcOverallCoverage(TotalNoOfCodeLines, TotalNoOfCodeLinesHit);
        NoOfCodeLinesNotHit := 0;
        TotalNoOfObjectCodeLines := 0;
        TotalNoOfObjectCodeLinesHit := 0;
        if "Line Type" = "Line Type"::Object then begin
            CalcObjectCoverage(TotalNoOfObjectCodeLines, TotalNoOfObjectCodeLinesHit);
            NoOfCodeLinesNotHit := TotalNoOfObjectCodeLines - TotalNoOfObjectCodeLinesHit;
        end;

        CodeLineIndent := Indentation;
        LineStyleExpr := "Line Type" in ["Line Type"::Object, "Line Type"::"Trigger/Function"];
        CoverageStyleExpr := Coverage = Coverage::Full;
    end;

    var
        LineStyleExpr: Boolean;
        CodeLineIndent: Integer;
        CoverageStyleExpr: Boolean;
        ExcludeEmptyLines: Boolean;
        TotalCodeCoveragePct: Decimal;
        TotalNoOfCodeLines: Integer;
        TotalNoOfCodeLinesHit: Integer;
        TotalNoOfObjectCodeLines: Integer;
        TotalNoOfObjectCodeLinesHit: Integer;
        NoOfCodeLinesNotHit: Integer;
        ShowOnlyLinesNotCovered: Boolean;

    local procedure ClearStatus()
    var
        ChangelistCode: Record "Changelist Code";
    begin
        ChangelistCode.SetFilter("Coverage %", '<>0');
        ChangelistCode.ModifyAll(Coverage, ChangelistCode.Coverage::None);
        ChangelistCode.ModifyAll("Coverage %", 0);
    end;

    local procedure CalcOverallCoverage(var NoOfCodeLines: Integer; var NoOfCodeLinesHit: Integer): Decimal
    var
        ChangelistCode: Record "Changelist Code";
    begin
        ChangelistCode.SetRange("Line Type", "Line Type"::Code);
        NoOfCodeLines := ChangelistCode.Count();
        ChangelistCode.SetRange(Coverage, Coverage::Full);
        NoOfCodeLinesHit := ChangelistCode.Count();
        exit(CalcPct(NoOfCodeLinesHit, NoOfCodeLines));
    end;

    local procedure CalcObjectCoverage(var NoOfCodeLines: Integer; var NoOfCodeLinesHit: Integer): Decimal
    var
        ChangelistCode: Record "Changelist Code";
    begin
        ChangelistCode.SetRange("Object Type", "Object Type");
        ChangelistCode.SetRange("Object No.", "Object No.");
        ChangelistCode.SetRange("Line Type", "Line Type"::Code);
        NoOfCodeLines := ChangelistCode.Count();
        ChangelistCode.SetRange(Coverage, Coverage::Full);
        NoOfCodeLinesHit := ChangelistCode.Count();
        exit(CalcPct(NoOfCodeLinesHit, NoOfCodeLines));
    end;

    local procedure CalcPct(Numerator: Decimal; Denominator: Decimal): Decimal
    begin
        if Denominator = 0 then
            exit(0);
        exit(Round(Numerator / Denominator * 100, 0.01));
    end;
}
