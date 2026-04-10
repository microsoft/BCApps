namespace Microsoft.CRM.Outlook;

table 7101 "Contact Sync Folder"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }

        field(2; "Folder ID"; Text[2048])
        {
            Caption = 'Folder ID';
            DataClassification = CustomerContent;
        }

        field(3; "Display Name"; Text[250])
        {
            Caption = 'Display Name';
            ToolTip = 'Select this folder';
            DataClassification = CustomerContent;
        }

        field(4; "Parent Id"; Text[2048])
        {
            Caption = 'Parent Id';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
