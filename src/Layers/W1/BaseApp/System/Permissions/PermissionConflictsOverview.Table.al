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
            Tooltip = 'Specifies the identifier for the permission set.';
        }
        field(2; Type; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = User,System;
            Tooltip = 'Specifies whether the permission set is part of standard Business Central, or a user created it.';
        }
        field(3; Basic; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Basic License.';
        }
        field(4; "Team Member"; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Team Member License.';
        }
        field(5; Essential; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Essential License.';
        }
        field(6; Premium; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Premium License.';
        }
        field(7; Device; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Device License.';
        }
        field(8; "External Accountant"; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the External Accountant License.';
        }
        field(9; "Internal Admin"; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Internal Admin License.';
        }
        field(10; "Delegated Admin"; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Delegated Admin License.';
        }
        field(11; HelpDesk; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the HelpDesk License.';
        }
        field(12; Viral; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Dynamics 365 Business Central for IWs License.';
        }
        field(13; "D365 Admin"; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether it is included in the Dynamics 365 Admin License.';
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