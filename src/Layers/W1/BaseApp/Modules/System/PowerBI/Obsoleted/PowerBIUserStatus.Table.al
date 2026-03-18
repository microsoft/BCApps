#if not CLEANSCHEMA26 
namespace System.Integration.PowerBI;

/// <summary>
/// Tracks status for a user, e.g. if a user has active background sessions to synchronize Power BI reports.
/// </summary>
table 6325 "Power BI User Status"
{
    Caption = 'Power BI User Status';
    ReplicateData = false;
    ObsoleteReason = 'Check if the user has a pending job queue entry for codeunit "Power BI Report Synchronizer" instead and use the status from the job queue.';
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'ID of the user, who each get one record in the table.';
        }
        field(10; "Is Synchronizing"; Boolean)
        {
            Caption = 'Is Synchronizing';
            DataClassification = SystemMetadata;
            Description = 'Whether or not reports are currently being synchronized with the Power BI service.';
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif
