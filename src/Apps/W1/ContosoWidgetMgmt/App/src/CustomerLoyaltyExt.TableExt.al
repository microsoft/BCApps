// Anti-pattern: the field added to the standard Customer table carries no
// affix, so it collides with any other app that adds "Loyalty Points" to
// Customer (AS0011).
tableextension 50004 "Customer Loyalty Ext" extends Customer
{
    fields
    {
        field(50004; "Loyalty Points"; Integer)
        {
            Caption = 'Loyalty Points';
            DataClassification = CustomerContent;
        }
    }
}
