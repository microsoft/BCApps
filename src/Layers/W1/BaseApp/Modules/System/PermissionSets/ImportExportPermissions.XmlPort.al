namespace System.Security.AccessControl;

xmlport 9172 "Import/Export Permissions"
{
    Caption = 'Import/Export Permissions';
    Format = VariableText;

    schema
    {
        textelement(Root)
        {
#pragma warning disable AL0432
            tableelement(Permission; Permission)
#pragma warning restore AL0432
            {
                XmlName = 'Permission';
                fieldelement(RoleID; Permission."Role ID")
                {
                    FieldValidate = no;
                }
                fieldelement(RoleName; Permission."Role Name")
                {
                }
                fieldelement(ObjectType; Permission."Object Type")
                {
                }
                fieldelement(ObjectID; Permission."Object ID")
                {
                    FieldValidate = no;
                }
                fieldelement(ObjectName; Permission."Object Name")
                {
                }
                fieldelement(ReadPermission; Permission."Read Permission")
                {
                }
                fieldelement(InsertPermission; Permission."Insert Permission")
                {
                }
                fieldelement(ModifyPermission; Permission."Modify Permission")
                {
                }
                fieldelement(DeletePermission; Permission."Delete Permission")
                {
                }
                fieldelement(ExecutePermission; Permission."Execute Permission")
                {
                }
                fieldelement(SecurityFilter; Permission."Security Filter")
                {
                }

                trigger OnBeforeInsertRecord()
                begin
                    if (RoleID <> '') and (Permission."Role ID" <> RoleID) then
                        currXMLport.Skip();

                    if Permission.Get(Permission."Role ID", Permission."Object Type", Permission."Object ID") then
                        currXMLport.Skip();

                    InsertPermissionSet(Permission);
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    begin
        if Permission.GetFilter("Role ID") <> '' then
            RoleID := Permission.GetRangeMin("Role ID");
    end;

    var
        RoleID: Code[20];

#pragma warning disable AL0432
    local procedure InsertPermissionSet(Permission: Record Permission)
#pragma warning restore AL0432
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        if not MetadataPermissionSet.Get(Permission."Role ID") then begin
            MetadataPermissionSet.Init();
            MetadataPermissionSet."Role ID" := Permission."Role ID";
            MetadataPermissionSet.Name := Permission."Role Name";
            MetadataPermissionSet.Insert();
        end;
    end;
}

