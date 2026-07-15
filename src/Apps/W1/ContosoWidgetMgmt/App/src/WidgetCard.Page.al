page 50011 "CWM Widget Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "CWM Widget";
    Caption = 'Widget Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the widget.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = '';
                }
                field("Contact Email"; Rec."Contact Email")
                {
                    ToolTip = 'Specifies the contact email for the widget.';
                }
            }
        }
    }
}
