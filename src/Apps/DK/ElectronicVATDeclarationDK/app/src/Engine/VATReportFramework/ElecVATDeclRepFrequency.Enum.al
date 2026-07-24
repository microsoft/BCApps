namespace Microsoft.Finance.VAT.Reporting;

enum 13605 "Elec. VAT Decl. Rep. Frequency"
{
    Extensible = false;

    value(0; Monthly)
    {
        Caption = 'Monthly';
    }
    value(1; Quarterly)
    {
        Caption = 'Quarterly';
    }
    value(2; "Semi-Annual")
    {
        Caption = 'Semi-Annual';
    }
}
