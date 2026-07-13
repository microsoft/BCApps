#pragma warning disable AA0247
page 12420 "Bank Directory List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'CBR Bank Directories';
    CardPageID = "Bank Directory Card";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Directory";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(BIC; Rec.BIC)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT BIC code of the bank.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank status information.';
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
                field("Corr. Account No."; Rec."Corr. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corresponding bank account number.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
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
                field("Last Modify Date"; Rec."Last Modify Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the bank records were last modified.';
                }
                field(RKC; Rec.RKC)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the RKC number associated with the bank.';
                }
            }
        }
    }

    actions
    {
    }
}

