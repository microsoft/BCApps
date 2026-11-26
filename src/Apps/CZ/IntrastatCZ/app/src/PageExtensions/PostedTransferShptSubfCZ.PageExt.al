#pragma warning disable AA0247
pageextension 31318 "Posted Transfer Shpt. Subf CZ" extends "Posted Transfer Shpt. Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("Statistic Indication CZ"; Rec."Statistic Indication CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the statistic indication code.';
                Visible = false;
            }
            field("Country/Reg. of Orig. Code CZ"; Rec."Country/Reg. of Orig. Code CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                Visible = false;
            }
        }
    }
}
