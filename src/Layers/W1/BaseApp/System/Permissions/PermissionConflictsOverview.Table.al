namespace System.Security.AccessControl;

table 5555 "Permission Conflicts Overview"
{
    access = Internal;
    Extensible = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; PermissionSetID; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Type; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = User,System;
        }
        field(3; Basic; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Team Member"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(5; Essential; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(6; Premium; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(7; Device; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "External Accountant"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(9; "Internal Admin"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Delegated Admin"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(11; HelpDesk; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(12; Viral; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(13; "D365 Admin"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; PermissionSetID, Type)
        {
            Clustered = true;
        }
    }
}