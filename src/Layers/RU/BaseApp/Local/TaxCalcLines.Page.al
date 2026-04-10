#pragma warning disable AA0247
page 17320 "Tax Calc. Lines"
{
    Caption = 'Tax Calc. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Calc. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax calculation line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code description associated with the tax calculation line.';
                }
                field("Expression Type"; Rec."Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field(Expression; Rec.Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("Link Register No."; Rec."Link Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link register number associated with the tax calculation line.';
                }
                field(Period; Rec.Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period associated with the tax calculation line.';
                }
            }
        }
    }

    actions
    {
    }
}

