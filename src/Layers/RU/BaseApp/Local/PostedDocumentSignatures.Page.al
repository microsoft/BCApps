#pragma warning disable AA0247
page 12464 "Posted Document Signatures"
{
    Caption = 'Posted Document Signatures';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Document Signature";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Employee Type"; Rec."Employee Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee type associated with the posted document signature information.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Name"; Rec."Employee Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee name associated with the posted document signature information.';
                }
                field("Employee Job Title"; Rec."Employee Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee position associated with the posted document signature information.';
                }
                field("Employee Org. Unit"; Rec."Employee Org. Unit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee department associated with the posted document signature information.';
                }
                field("Warrant Description"; Rec."Warrant Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant description associated with the posted document signature information.';
                }
                field("Warrant No."; Rec."Warrant No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant number associated with the posted document signature information.';
                }
                field("Warrant Date"; Rec."Warrant Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warranty date of the posted document.';
                }
            }
        }
    }

    actions
    {
    }
}

