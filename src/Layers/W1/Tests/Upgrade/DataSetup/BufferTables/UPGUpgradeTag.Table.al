#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 132801 "UPG - Upgrade Tag"
#pragma warning restore AS0103, PTE0004
{
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Tag; Code[250])
        {
            Caption = 'Tag';
            DataClassification = SystemMetadata;
        }
        field(2; "Tag Timestamp"; DateTime)
        {
            Caption = 'Tag Timestamp';
            DataClassification = SystemMetadata;
        }
        field(3; Company; Code[30])
        {
            Caption = 'Company';
            DataClassification = SystemMetadata;
        }

        field(4; "Skipped Upgrade"; Boolean)
        {
            Caption = 'Skipped Upgrade';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Tag, Company)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
