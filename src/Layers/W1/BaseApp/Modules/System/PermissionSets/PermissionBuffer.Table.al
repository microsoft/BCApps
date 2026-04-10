namespace System.Security.AccessControl;

#pragma warning disable AS0109
table 9852 "Permission Buffer"
{
    Caption = 'Permission Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Source; Option)
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;
            OptionCaption = 'Normal,Entitlement,Security Group,Inherent';
            OptionMembers = Normal,Entitlement,"Security Group",Inherent;
            ToolTip = 'Specifies the origin of the permission set that gives the user permissions for the object chosen in the Permissions section. Note that rows with the type Entitlement originate from the subscription plan. The permission values of the entitlement overrule values that give increased permissions in other permission sets. In those cases, the permission level is Conflict.';
        }
        field(2; "Permission Set"; Code[20])
        {
            Caption = 'Permission Set';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the permission set that gives the user permissions to the object chosen in the Permissions section.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'User-Defined,Extension,System';
            OptionMembers = "User-Defined",Extension,System;
            ToolTip = 'Specifies the type of the permission set that gives the user permissions for the object chosen in the Permissions section. Note that you can only edit permission sets of type User-Defined.';
        }
        field(4; "Read Permission"; Option)
        {
            Caption = 'Read Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
            ToolTip = 'Specifies whether the permission set gives the user the Read permission.';
        }
        field(5; "Insert Permission"; Option)
        {
            Caption = 'Insert Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
            ToolTip = 'Specifies whether the permission set gives the user the Insert permission.';
        }
        field(6; "Modify Permission"; Option)
        {
            Caption = 'Modify Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
            ToolTip = 'Specifies whether the permission set gives the user the Modify permission.';
        }
        field(7; "Delete Permission"; Option)
        {
            Caption = 'Delete Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
            ToolTip = 'Specifies whether the permission set gives the user the Delete permission.';
        }
        field(8; "Execute Permission"; Option)
        {
            Caption = 'Execute Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
            ToolTip = 'Specifies whether the permission set gives the user the Execute permission.';
        }
        field(9; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
        }
        field(10; "Security Filter"; TableFilter)
        {
            Caption = 'Security Filter';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies a security filter that applies to this permission set to limit the access that this permission set has to the data contained in this table.';

        }
        field(11; Order; Integer)
        {
            Caption = 'Order';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "Permission Set")
        {
            Clustered = true;
        }
        key(Key2; Source)
        {
        }
    }

    fieldgroups
    {
    }

    local procedure GetScope(): Integer
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        case Type of
            Type::System:
                exit(AggregatePermissionSet.Scope::System);
            Type::"User-Defined",
          Type::Extension:
                exit(AggregatePermissionSet.Scope::Tenant);
        end;
    end;

    procedure GetAppID(): Guid
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        Scope: Integer;
        ZeroGuid: Guid;
    begin
        Scope := GetScope();
        if Type <> Type::Extension then
            exit(ZeroGuid);

        AggregatePermissionSet.SetRange(Scope, Scope);
        AggregatePermissionSet.SetRange("Role ID", "Permission Set");
        AggregatePermissionSet.FindFirst();
        exit(AggregatePermissionSet."App ID");
    end;

    procedure OpenPermissionsPage(RunAsModal: Boolean)
    var
        PermissionSetRelation: Codeunit "Permission Set Relation";
    begin
        PermissionSetRelation.OpenPermissionSetPage("Permission Set", "Permission Set", GetAppID(), GetScope());
    end;
}

