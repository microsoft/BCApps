#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
page 11028 "Elec. VAT Decl. Overview"
#pragma warning restore AS0011
{
    Caption = 'Elec. VAT Decl. Overview';
    Editable = false;
    PageType = List;
    SourceTable = "Elec. VAT Decl. Buffer";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Caption = 'General';
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT code to report.';
                }

                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount to report.';
                }

            }
        }
    }
}
