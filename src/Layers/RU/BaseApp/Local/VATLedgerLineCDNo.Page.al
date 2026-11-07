#pragma warning disable AA0247
page 12443 "VAT Ledger Line CD No."
{
    Caption = 'VAT Ledger Line CD No.';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Ledger Line CD No.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("CD No."; Rec."CD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
            }
        }
    }

    actions
    {
    }
}

