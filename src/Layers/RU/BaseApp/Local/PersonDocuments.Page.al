#pragma warning disable AA0247
page 17353 "Person Documents"
{
    Caption = 'Person Documents';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Person Document";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Valid from Date"; Rec."Valid from Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Valid to Date"; Rec."Valid to Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Series"; Rec."Document Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Issue Authority"; Rec."Issue Authority")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Issue Date"; Rec."Issue Date")
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

