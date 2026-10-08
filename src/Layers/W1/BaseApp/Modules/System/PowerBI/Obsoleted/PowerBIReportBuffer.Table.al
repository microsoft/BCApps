#if not CLEANSCHEMA26 
namespace System.Integration.PowerBI;

table 6302 "Power BI Report Buffer"
{
    Caption = 'Power BI Report Buffer';
    ReplicateData = false;
    TableType = Temporary;

    // This table was marked as obsolete before, when its type was changed to temporary. Because of limitations in AppSourceCop, there needs to
    // be a full major release where it is not obsolete, before it can be obsoleted again. Hence the tag 21.0 will be added in 22.0 instead of 21.0.
    ObsoleteReason = 'This table is no longer used. Use table 6313 "Power BI Selection Element" instead.';
#pragma warning disable AS0072
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
#pragma warning restore AS0072

    Description = 'This table will be marked as obsolete. Use table 6313 "Power BI Selection Element" instead.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ReportID; Guid)
        {
            Caption = 'ReportID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; ReportName; Text[100])
        {
            Caption = 'ReportName';
            DataClassification = CustomerContent;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
        field(10; ReportEmbedUrl; Text[2048])
        {
            Caption = 'ReportEmbedUrl';
            DataClassification = CustomerContent;
        }
        field(20; "Workspace ID"; Guid)
        {
            Caption = 'Workspace ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(21; "Workspace Name"; Text[200])
        {
            Caption = 'Workspace Name';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; ReportID)
        {
            Clustered = true;
        }
        key(Key2; ReportName)
        {
        }
    }

    fieldgroups
    {
    }
}

#endif