#if not CLEANSCHEMA25 
namespace System.Integration.PowerBI;

/// <summary>
/// Contains only one record that tracks whether the Power BI service is throttling the calls coming from Business Central, and when the service will be available again.
/// </summary>
table 6309 "Power BI Service Status Setup"
{
    Caption = 'Power BI Service Status Setup';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteReason = 'Power BI service status is no longer cached.';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
            Description = 'Just a key value for SQL.';
        }
        field(2; "Retry After"; DateTime)
        {
            Caption = 'Retry After';
            DataClassification = CustomerContent;
            Description = 'Indicates when the PBI service should be available again.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Count > 1 then
            Error(SingletonErr);
    end;

    var
        SingletonErr: Label 'There should be only one record for Power BI Service Status Setup.';
}

 
#endif
