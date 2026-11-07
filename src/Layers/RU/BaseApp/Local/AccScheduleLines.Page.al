#pragma warning disable AA0247
page 26595 "Acc. Schedule Lines"
{
    Caption = 'Acc. Schedule Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Schedule Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Totaling Type"; Rec."Totaling Type")
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

