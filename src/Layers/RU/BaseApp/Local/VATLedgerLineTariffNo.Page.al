#pragma warning disable AA0247
page 12444 "VAT Ledger Line Tariff No."
{
    Caption = 'VAT Ledger Line Tariff No.';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Ledger Line Tariff No.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Tariff No."; Rec."Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s tariff number for use in VAT ledger export.';
                }
            }
        }
    }

    actions
    {
    }
}

