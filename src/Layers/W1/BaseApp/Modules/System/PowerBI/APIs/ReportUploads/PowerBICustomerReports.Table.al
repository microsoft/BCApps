namespace System.Integration.PowerBI;

/// <summary>
/// Stores in a BLOB the reports uploaded to Power BI using the Business Central pages.
/// </summary>
/// <remarks>
/// The schema of this table mirrors the one for table 2000000144 "Power BI Blob". 
/// Table 2000000144 contains the demo reports provided by Microsoft, wereas table 6310 (this table) contains the reports uploaded by the users.
/// </remarks>
table 6310 "Power BI Customer Reports"
{
    Caption = 'Power BI Customer Reports';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Blob File"; BLOB)
        {
            Caption = 'Blob File';
            DataClassification = SystemMetadata;
        }
        field(3; Name; Text[200])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(4; Version; Integer)
        {
            Caption = 'Version';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

