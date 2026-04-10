#pragma warning disable AA0247
page 17284 "Tax Reg. Norm Template Lines"
{
    Caption = 'Norm Template Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Reg. Norm Template Line";

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
                    ToolTip = 'Specifies the line code associated with the norm template line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the norm template line.';
                }
                field("Expression Type"; Rec."Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = ExpressionTypeHideValue;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field(Expression; Rec.Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("Link Group Code"; Rec."Link Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link group code associated with the norm template line.';
                }
                field(Period; Rec.Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period associated with the norm template line.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ExpressionTypeHideValue := false;
        ExpressionTypeOnFormat();
    end;

    var
        ExpressionTypeHideValue: Boolean;

    local procedure ExpressionTypeOnFormat()
    begin
        if Rec."Expression Type" = Rec."Expression Type"::Norm then
            ExpressionTypeHideValue := true;
    end;
}

