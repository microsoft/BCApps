page 50010 "CWM Widget List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "CWM Widget";
    Caption = 'Widgets';
    CardPageId = "CWM Widget Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the widget.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the widget.';
                }
                field("Linked Customer No."; Rec."Linked Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer linked to the widget.';
                }
            }
        }
    }
}
