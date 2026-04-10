namespace System.Automation;

table 1544 "Flow User Environment Buffer"
{
    Caption = 'Power Automate User Environment Buffer';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Environment ID"; Text[50])
        {
            Caption = 'Environment ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Environment Display Name"; Text[100])
        {
            Caption = 'Environment Display Name';
            DataClassification = SystemMetadata;
        }
        field(3; Default; Boolean)
        {
            Caption = 'Default';
            DataClassification = SystemMetadata;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
        field(5; Linked; Boolean)
        {
            Caption = 'Linked';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Environment ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
