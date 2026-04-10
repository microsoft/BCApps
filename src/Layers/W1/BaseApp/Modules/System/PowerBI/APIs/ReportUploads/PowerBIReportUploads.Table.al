namespace System.Integration.PowerBI;

using System.Integration;
using System.Security.AccessControl;

/// <summary>
/// Persists information about the reports that Business Central has uploaded to the user's Power BI personal workspace.
/// </summary>
table 6307 "Power BI Report Uploads"
{
    Caption = 'Power BI Report Uploads';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "PBIX BLOB ID"; Guid)
        {
            Caption = 'PBIX BLOB ID';
            DataClassification = CustomerContent;
            Description = 'ID from Default Report table.';
            TableRelation = "Power BI Blob".Id;
        }
        field(2; "Uploaded Report ID"; Guid)
        {
            Caption = 'Uploaded Report ID';
            DataClassification = CustomerContent;
            Description = 'Report''s ID after finishing upload to the PBI workspace.';
        }
        field(3; "User ID"; Guid)
        {
            Caption = 'User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'User who the report was uploaded for.';
            TableRelation = User."User Security ID";
        }
        field(4; "Import ID"; Guid)
        {
            Caption = 'Import ID';
            DataClassification = CustomerContent;
            Description = 'ID of in-progress upload request, used for referencing progress later.';
        }
        field(5; "Deployed Version"; Integer)
        {
            Caption = 'Deployed Version';
            DataClassification = CustomerContent;
            Description = 'The version that was uploaded, so we know when to overwrite with newer reports.';
        }
#if not CLEANSCHEMA26
        field(6; "Is Selection Done"; Boolean)
        {
            Caption = 'Is Selection Done';
            DataClassification = CustomerContent;
            Description = 'Whether or not the one-time selection process has been done after uploading.';
            ObsoleteReason = 'Use Report Upload Status instead to track the upload status.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
#if not CLEANSCHEMA26
        field(8; "Should Retry"; Boolean)
        {
            Caption = 'Should Retry';
            DataClassification = CustomerContent;
            Description = 'Whether or not we expect the upload to succeed if we try again.';
            ObsoleteReason = 'Use Report Upload Status instead to track the upload status.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(9; "Retry After"; DateTime)
        {
            Caption = 'Retry After';
            DataClassification = CustomerContent;
            Description = 'The point in time after which it''s ok to retry this upload.';
        }
#if not CLEANSCHEMA26
        field(10; "Needs Deletion"; Boolean)
        {
            Caption = 'Needs Deletion';
            DataClassification = CustomerContent;
            Description = 'Determines if the report needs to be deleted.';
            ObsoleteReason = 'Use Report Upload Status instead to track the upload status.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(11; IsGP; Boolean)
        {
            Caption = 'IsGP';
            DataClassification = CustomerContent;
            Description = 'Specifies whether a report uses GP or Business Central datasets.';
        }
        field(20; "Report Embed Url"; Text[2048])
        {
            Caption = 'Report Embed Url';
            DataClassification = CustomerContent;
            Description = 'URL to cache when selecting the reporting.';
        }
        field(23; "Report Upload Status"; Enum "Power BI Upload Status")
        {
            Caption = 'Report Upload Status';
            DataClassification = SystemMetadata;
            Description = 'Specifies the stage of the upload process that this report upload reached.';
        }
    }

    keys
    {
        key(Key1; "PBIX BLOB ID", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}