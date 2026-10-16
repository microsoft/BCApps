#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
table 11027 "Elec. VAT Decl. Buffer"
#pragma warning restore AS0011
{
    TableType = Temporary;
    LookupPageId = "Elec. VAT Decl. Overview";
    DrillDownPageId = "Elec. VAT Decl. Overview";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Amount; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; Code)
        {
        }
    }
}
