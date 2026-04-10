#pragma warning disable AA0247
page 14918 "Payment Order Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Order Codes';
    PageType = List;
    SourceTable = "Payment Order Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Reason Document No."; Rec."Reason Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Document Type"; Rec."Reason Document Type")
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

