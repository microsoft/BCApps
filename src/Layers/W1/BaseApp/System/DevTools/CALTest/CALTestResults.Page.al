namespace System.TestTools.TestRunner;

page 130405 "CAL Test Results"
{
    Caption = 'CAL Test Results';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CAL Test Result";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Repeater';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field("Test Run No."; Rec."Test Run No.")
                {
                    ApplicationArea = All;
                }
                field("Codeunit ID"; Rec."Codeunit ID")
                {
                    ApplicationArea = All;
                }
                field("Codeunit Name"; Rec."Codeunit Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Function Name"; Rec."Function Name")
                {
                    ApplicationArea = All;
                }
                field(Platform; Rec.Platform)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Result; Rec.Result)
                {
                    ApplicationArea = All;
                    StyleExpr = Style;
                }
                field(Restore; Rec.Restore)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                }
                field("Execution Time"; Rec."Execution Time")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = true;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field(File; Rec.File)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Call Stack")
            {
                ApplicationArea = All;
                Caption = 'Call Stack';
                Image = DesignCodeBehind;

                trigger OnAction()
                var
                    InStr: InStream;
                    CallStack: Text;
                begin
                    if Rec."Call Stack".HasValue() then begin
                        Rec.CalcFields("Call Stack");
                        Rec."Call Stack".CreateInStream(InStr);
                        InStr.ReadText(CallStack);
                        Message(CallStack)
                    end;
                end;
            }
            action(Export)
            {
                ApplicationArea = All;
                Caption = 'E&xport';
                Image = Export;

                trigger OnAction()
                var
                    CALExportTestResult: XMLport "CAL Export Test Result";
                begin
                    CALExportTestResult.SetTableView(Rec);
                    CALExportTestResult.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Export_Promoted; Export)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Call Stack', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Call Stack_Promoted"; "Call Stack")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Style := GetStyle();
    end;

    var
        Style: Text;

    local procedure GetStyle(): Text
    begin
        case Rec.Result of
            Rec.Result::Passed:
                exit('Favorable');
            Rec.Result::Failed:
                exit('Unfavorable');
            Rec.Result::Inconclusive:
                exit('Ambiguous');
            else
                exit('Standard');
        end;
    end;
}

