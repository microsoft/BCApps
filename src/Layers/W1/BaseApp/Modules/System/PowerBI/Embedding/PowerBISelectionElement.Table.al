namespace System.Integration.PowerBI;

/// <summary>
/// Represents a Power BI Element (such as report, workspace or dashboard) as returned by the Power BI backend.
/// </summary>
table 6313 "Power BI Selection Element"
{
    Caption = 'Power BI Selection Element';
    TableType = Temporary;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; "Type"; Enum "Power BI Element Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(5; Name; Text[200])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(7; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
        field(10; EmbedUrl; Text[2048])
        {
            Caption = 'EmbedUrl';
            DataClassification = CustomerContent;
        }
        field(20; WorkspaceID; Guid)
        {
            Caption = 'Workspace ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(21; WorkspaceName; Text[200])
        {
            Caption = 'Workspace Display Name';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; ID, Type)
        {
            Clustered = true;
        }
        key(Key2; WorkspaceID, Type, Name)
        {
        }
    }
}