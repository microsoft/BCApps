#pragma warning disable AA0247
page 17217 "Tax Register Template Subform"
{
    AutoSplitKey = true;
    Caption = 'Template Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Register Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Report Line Code"; Rec."Report Line Code")
                {
                    ToolTip = 'Specifies the report line code associated with the tax register template.';
                    Visible = false;
                }
                field("Link Tax Register No."; Rec."Link Tax Register No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the link tax register number associated with the tax register template.';
                    Visible = false;
                }
                field("Sum Field No."; Rec."Sum Field No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the sum field number associated with the tax register template.';
                    Visible = false;
                }
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax register template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the tax register template.';
                }
                field(Expression; Rec.Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field(Period; Rec.Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period associated with the tax register template.';
                }
                field(Indentation; Rec.Indentation)
                {
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field(Bold; Rec.Bold)
                {
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                    Visible = false;
                }
                field("Result on Disposal"; Rec."Result on Disposal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the result on disposal associated with the tax register template.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Expression Type" := Rec."Expression Type"::SumField;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Expression Type" := Rec."Expression Type"::SumField;
    end;

    var
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
        DescriptionEmphasize := Rec.Bold;
    end;
}

