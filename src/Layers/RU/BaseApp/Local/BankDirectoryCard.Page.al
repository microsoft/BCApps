#pragma warning disable AA0247
page 12421 "Bank Directory Card"
{
    Caption = 'Bank Directory Card';
    PageType = Card;
    SourceTable = "Bank Directory";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BIC; Rec.BIC)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT BIC code of the bank.';
                }
                field("Corr. Account No."; Rec."Corr. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corresponding bank account number.';
                }
                field("Short Name"; Rec."Short Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the short name associated with the bank.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full name associated with the bank.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank type.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field("Area Type"; Rec."Area Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area type associated with the bank.';
                }
                field("Area Name"; Rec."Area Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area name associated with the bank.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address associated with the bank.';
                }
                field(Telephone; Rec.Telephone)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number associated with the bank.';
                }
                field("Registration No."; Rec."Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number associated with the bank.';
                }
                field(RKC; Rec.RKC)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the RKC number associated with the bank.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank status information.';
                }
                field("Last Modify Date"; Rec."Last Modify Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the bank records were last modified.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

