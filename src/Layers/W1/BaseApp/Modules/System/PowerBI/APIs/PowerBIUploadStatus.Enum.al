namespace System.Integration.PowerBI;

enum 6305 "Power BI Upload Status"
{
    Extensible = false;

    value(0; NotStarted)
    {
        Caption = 'Not Started';
    }
    value(5; ImportStarted)
    {
        Caption = 'Import Started';
    }
    value(10; ImportFinished)
    {
        Caption = 'Import Finished';
    }
    value(15; ParametersUpdated)
    {
        Caption = 'Parameters Updated';
    }
    value(20; DataRefreshed)
    {
        Caption = 'Data Refreshed';
    }
    value(50; Completed)
    {
        Caption = 'Completed';
    }
    value(100; Failed)
    {
        Caption = 'Failed';
    }
    value(200; Skipped)
    {
        Caption = 'Skipped';
    }
    value(300; PendingDeletion)
    {
        Caption = 'Pending Deletion';
    }
}