namespace System.Automation;

table 1542 "Workflow Webhook Sub Buffer"
{
    Caption = 'Workflow Webhook Sub Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "WF Definition Id"; Code[20])
        {
            Caption = 'WF Definition Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Client Id"; Guid)
        {
            Caption = 'Client Id';
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

