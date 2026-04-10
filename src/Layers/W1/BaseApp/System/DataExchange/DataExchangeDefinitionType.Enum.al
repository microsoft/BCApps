namespace System.IO;

enum 1222 "Data Exchange Definition Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Bank Statement Import")
    {
        Caption = 'Bank Statement Import';
    }
    value(1; "Payment Export")
    {
        Caption = 'Payment Export';
    }
    value(2; "Payroll Import")
    {
        Caption = 'Payroll Import';
    }
    value(3; "Generic Import")
    {
        Caption = 'Generic Import';
    }
    value(4; "Positive Pay Export")
    {
        Caption = 'Positive Pay Export';
    }
    value(5; "Generic Export")
    {
        Caption = 'Generic Export';
    }
}