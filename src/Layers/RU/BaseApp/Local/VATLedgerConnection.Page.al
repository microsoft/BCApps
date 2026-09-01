#pragma warning disable AA0247
page 12415 "VAT Ledger Connection"
{
    Caption = 'VAT Ledger Connection';
    PageType = Worksheet;
    SourceTable = "VAT Ledger Connection";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Connection Type"; Rec."Connection Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the connection type associated with this VAT ledger connection.';
                }
                field("Sales Ledger Code"; Rec."Sales Ledger Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales ledger code associated with this VAT ledger connection.';
                }
                field("Sales Ledger Line No."; Rec."Sales Ledger Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales ledger line number associated with this VAT ledger connection.';
                }
                field("Purch. Ledger Code"; Rec."Purch. Ledger Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase ledger code associated with this VAT ledger connection.';
                }
                field("Purch. Ledger Line No."; Rec."Purch. Ledger Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase ledger line number associated with this VAT ledger connection.';
                }
                field("VAT Entry No."; Rec."VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT entry number associated with this VAT ledger connection.';
                }
            }
        }
    }

    actions
    {
    }
}

