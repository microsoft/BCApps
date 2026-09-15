#pragma warning disable AA0247
page 26596 "Column Layouts"
{
    Caption = 'Column Layouts';
    PageType = List;
    SourceTable = "Column Layout";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the column in the view.';
                }
                field("Column Header"; Rec."Column Header")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

