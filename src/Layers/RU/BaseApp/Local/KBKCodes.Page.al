#pragma warning disable AA0247
page 12428 "KBK Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Budget Classification Codes';
    DataCaptionExpression = Rec."Name 1" + Rec."Name 2" + Rec."Name 3";
    PageType = Document;
    SourceTable = KBK;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                IndentationColumn = Name1Indent;
                IndentationControls = "Name 1";
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = CodeEmphasize;
                    ToolTip = 'Specifies the standard budget classification code.';
                }
                field("Name 1"; Rec."Name 1")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = Name1Emphasize;
                    ToolTip = 'Specifies a value for the standard budget classification description.';
                }
                field(Header; Rec.Header)
                {
                    ToolTip = 'Specifies if the budget classification code is a header.';
                    Visible = false;
                }
                field(Indentation; Rec.Indentation)
                {
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Name1Indent := 0;
        CodeOnFormat();
        Name1OnFormat();
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable(not CurrPage.LookupMode);
    end;

    var
        CodeEmphasize: Boolean;
        Name1Emphasize: Boolean;
        Name1Indent: Integer;

    local procedure CodeOnFormat()
    begin
        CodeEmphasize := Rec.Header;
    end;

    local procedure Name1OnFormat()
    begin
        Name1Indent := Rec.Indentation;
        Name1Emphasize := Rec.Header;
    end;
}

