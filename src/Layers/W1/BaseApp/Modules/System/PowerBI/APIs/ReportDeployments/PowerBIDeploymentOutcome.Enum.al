namespace System.Integration.PowerBI;

enum 6318 "Power BI Deployment Outcome"
{
    Access = Public;
    Extensible = false;

    value(0; "Not Deployed")
    {
        Caption = 'Not deployed';
    }
    value(1; "In Progress")
    {
        Caption = 'In progress';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
    value(3; Finished)
    {
        Caption = 'Finished';
    }
}
