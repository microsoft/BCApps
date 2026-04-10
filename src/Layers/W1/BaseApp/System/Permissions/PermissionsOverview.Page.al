// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using System.Apps;
using System.Reflection;

page 9883 "Permissions Overview"
{
    AboutText = 'Audit how permissions are distributed across permission sets in your system, as well as which users and security groups have been assigned with those permission sets.';
    AboutTitle = 'About Permissions Overview';
    ApplicationArea = Basic, Suite;
    Caption = 'Permissions Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = tabledata "NAV App Installed App" = r;
    SourceTable = "Expanded Permission";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                group(ObjectFilters)
                {
                    ShowCaption = false;
                    field(ObjTypeFilter; ObjTypeFilter)
                    {
                        Caption = 'Object Type';
                        OptionCaption = ' ,Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
                        ToolTip = 'Specifies object type filter.';

                        trigger OnValidate()
                        begin
                            Rec.FilterGroup(2);
                            if ObjTypeFilter = ObjTypeFilter::None then
                                Rec.SetRange("Object Type")
                            else
                                Rec.SetRange("Object Type", ObjTypeFilter - 1);
                            Rec.FilterGroup(0);
                            CurrPage.Update(false);
                        end;
                    }
                    field(ObjIDFilter; ObjIDFilter)
                    {
                        Caption = 'Object ID';
                        TableRelation = AllObjWithCaption."Object ID";
                        ToolTip = 'Specifies the object ID filter.';

                        trigger OnValidate()
                        begin
                            Rec.FilterGroup(2);
                            if ObjIDFilter = '' then
                                Rec.SetRange("Object ID")
                            else
                                Rec.SetFilter("Object ID", ObjIDFilter);
                            Rec.FilterGroup(0);
                            CurrPage.Update(false);
                        end;
                    }
                }
                group(RoleIDFilterGroup)
                {
                    ShowCaption = false;
                    field(RoleIDFilter; RoleIDFilter)
                    {
                        Caption = 'Permission Set';
                        TableRelation = "Aggregate Permission Set"."Role ID";
                        ToolTip = 'Specifies the permission set filter.';

                        trigger OnAfterLookup(Selected: RecordRef)
                        var
                            AggregatePermissionSet: Record "Aggregate Permission Set";
                        begin
                            Selected.SetTable(AggregatePermissionSet);
                            RoleIDFilter := AggregatePermissionSet."Role ID";
                            AppIDFilter := AggregatePermissionSet."App ID";
                        end;

                        trigger OnValidate()
                        begin
                            ScopeFilter := ScopeFilter::Blank;
                            SetPageFilter(ScopeFilter, AppIDFilter, AppNameFilter, RoleIDFilter);
                        end;
                    }
                }
                group(ScopeFilters)
                {
                    ShowCaption = false;
                    field(ScopeFilter; ScopeFilter)
                    {
                        Caption = 'Scope';
                        ToolTip = 'Specifies the scope filter.';

                        trigger OnValidate()
                        begin
                            SetPageFilter(ScopeFilter, AppIDFilter, '', RoleIDFilter);
                        end;
                    }
                    field(AppNameFilter; AppNameFilter)
                    {
                        Caption = 'Extension Name';
                        ToolTip = 'Specifies the extension name filter. This will filter for permission sets included in the extension.';

                        trigger OnAssistEdit()
                        var
                            PublishedApplication: Record "Published Application";
                            ExtensionManagement: Page "Extension Management";
                        begin
                            PublishedApplication.SetRange(Installed, true);
                            ExtensionManagement.LookupMode := true;
                            ExtensionManagement.SetTableView(PublishedApplication);
                            if ExtensionManagement.RunModal() = Action::LookupOK then begin
                                ExtensionManagement.GetRecord(PublishedApplication);
                                SetPageFilter(ScopeFilter::Blank, PublishedApplication.ID, PublishedApplication.Name, '');
                            end;
                        end;

                        trigger OnValidate()
                        var
                            PublishedApplication: Record "Published Application";
                        begin
                            if AppNameFilter <> '' then begin
                                PublishedApplication.SetRange(ID);
                                PublishedApplication.SetFilter(Name, AppNameFilter);
                                PublishedApplication.FindFirst();
                            end;
                            SetPageFilter(ScopeFilter::Blank, PublishedApplication.ID, PublishedApplication.Name, '');
                        end;
                    }
                }
            }
            repeater(Group)
            {
                Caption = 'Permissions';
                Editable = false;
                field(RoleID; Rec."Role ID")
                {
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of the permission set that exist in the current database. This field is used internally.';
                }
                field(RoleName; Rec."Role Name")
                {
                    ToolTip = 'Specifies the name of the permission set.';
                }
                field(ObjectType; Rec."Object Type")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies the type of object that the permissions apply to in the current database.';
                }
                field(ObjectID; Rec."Object ID")
                {
                    LookupPageId = "All Objects with Caption";
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies the ID of the object the permission applies to.';
                }
                field(ObjectName; Rec."Object Name")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies the name of the object the permission applies to.';
                }
                field(ReadPermission; Rec."Read Permission")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies if the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
                }
                field(InsertPermission; Rec."Insert Permission")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies if the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
                }
                field(ModifyPermission; Rec."Modify Permission")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies if the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
                }
                field(DeletePermission; Rec."Delete Permission")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies if the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
                }
                field(ExecutePermission; Rec."Execute Permission")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies if the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
                }
                field(SecurityFilter; Rec."Security Filter")
                {
                    Style = Strong;
                    StyleExpr = Rec."Object ID" = 0;
                    ToolTip = 'Specifies a security filter that applies to this permission set to limit the access that this permission set has to the data contained in this table.';
                }
                field(Scope; PermSetScope)
                {
                    Caption = 'Scope';
                    ToolTip = 'Specifies the scope of the permission set.';
                }
                field(ExtensionName; AppName)
                {
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of the extension which defined the permission set.';
                }
            }
        }
        area(FactBoxes)
        {
            part(PermissionSetSecurityGroups; "Permission Set Security Groups")
            {
                AboutText = 'Security Group Assignments';
                AboutTitle = 'View list of security groups that are assigned to a permission set.';
                Caption = 'Security Groups';
            }
            part(PermissionSetUsers; "Permission Set Users")
            {
                AboutText = 'View list of users who are assigned a permission set, including if the user inherits the permission sets from a security group they are apart of.';
                AboutTitle = 'User Assignments';
                Caption = 'Users';
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(PermissionSetPermissions)
            {
                ApplicationArea = All;
                Caption = 'Permission Set Permissions';
                Image = Permission;
                Scope = Repeater;
                ToolTip = 'View or edit the permissions in the permission set.';

                trigger OnAction()
                var
                    PermissionSetRelation: Codeunit "Permission Set Relation";
                begin
                    PermissionSetRelation.OpenPermissionSetPage(Rec."Role Name", Rec."Role ID", Rec."App ID", Rec.Scope);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(PermissionSetPermissions_Promoted; PermissionSetPermissions) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Clear(AppName);
        if not IsNullGuid(Rec."App ID") then
            AppName := GetNavAppName(Rec."App ID");
        SetScope();
        if (Rec."App ID" = InherentAppIDTok) and (Rec."Role ID" = InherentRoleIDLbl) then
            Rec."Role Name" := InherentRoleNameLbl;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadPermAssignmentBuffer();
        CurrPage.PermissionSetSecurityGroups.Page.SetSource(PermSetAssignmentBuffer);
        CurrPage.PermissionSetUsers.Page.SetSource(PermSetAssignmentBuffer);
    end;

    trigger OnOpenPage()
    var
        ExpandedPermission: Record "Expanded Permission";
        TableMetadata: Record "Table Metadata";
        PageMetadata: Record "Page Metadata";
        ReportMetadata: Record "Report Metadata";
        CodeunitMetadata: Record "Codeunit Metadata";
        XMLportMetadata: Record "XMLport Metadata";
        QueryMetadata: Record "Query Metadata";
    begin
        PublishedApplication.SetLoadFields(Name);

        if ExpandedPermission.FindSet() then
            repeat
                Rec := ExpandedPermission;
                Rec.Insert();
            until ExpandedPermission.Next() = 0;

        AddInherentPermissions(Rec."Object Type"::"Table Data", Database::"Table Metadata", TableMetadata.FieldNo(ID), TableMetadata.FieldNo(InherentPermissions));
        AddInherentPermissions(Rec."Object Type"::Page, Database::"Page Metadata", PageMetadata.FieldNo(ID), PageMetadata.FieldNo(InherentPermissions));
        AddInherentPermissions(Rec."Object Type"::Report, Database::"Report Metadata", ReportMetadata.FieldNo(ID), ReportMetadata.FieldNo(InherentPermissions));
        AddInherentPermissions(Rec."Object Type"::Codeunit, Database::"Codeunit Metadata", CodeunitMetadata.FieldNo(ID), CodeunitMetadata.FieldNo(InherentPermissions));
        AddInherentPermissions(Rec."Object Type"::XMLport, Database::"XMLport Metadata", XMLportMetadata.FieldNo(ID), XMLportMetadata.FieldNo(InherentPermissions));
        AddInherentPermissions(Rec."Object Type"::Query, Database::"Query Metadata", QueryMetadata.FieldNo(ID), QueryMetadata.FieldNo(InherentPermissions));

        if Rec.FindFirst() then;
    end;

    var
        PublishedApplication: Record "Published Application";
        SecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        PermSetAssignmentBuffer: Record "Perm. Set Assignment Buffer";
        LastExpandedPermission: Record "Expanded Permission";
        TempAccessControl: Record "Access Control" temporary;
        PermSetScope: Enum "Permission Set Scope";
        ScopeFilter: Enum "Permission Set Scope";
        AppIDFilter: Guid;
        NullGuid: Guid;
        InherentAppIDTok: Label '{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}', Locked = true;
        InherentRoleIDLbl: Label 'INHERENT', MaxLength = 30;
        InherentRoleNameLbl: Label 'Inherited from Object', MaxLength = 30;
        ObjTypeFilter: Option None,"Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        ObjIDFilter: Text;
        RoleIDFilter: Text[30];
        AppName: Text[250];
        AppNameFilter: Text[250];
        ExtUserFilterText: Text;
        IsBuffered: Boolean;

    local procedure AddInherentPermissions(ForObjectType: Option; MetadataTableId: Integer; ObjectIdFieldId: Integer; InherentPermissionFieldId: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(MetadataTableId);
        RecRef.Field(InherentPermissionFieldId).SetFilter('<>%1', '');
        if RecRef.FindSet() then
            repeat
                AddInherentPermission(ForObjectType, RecRef.Field(ObjectIdFieldId).Value, RecRef.Field(InherentPermissionFieldId).Value);
            until RecRef.Next() = 0;
    end;

    local procedure AddInherentPermission(ForObjectType: Option; ForObjectId: Integer; Permissions: Text[5])
    var
        Perm: Text[1];
    begin
        if Permissions = '' then
            exit;

        Rec.Init();
        Rec."Read Permission" := Rec."Read Permission"::" ";
        Rec."Insert Permission" := Rec."Insert Permission"::" ";
        Rec."Modify Permission" := Rec."Modify Permission"::" ";
        Rec."Delete Permission" := Rec."Delete Permission"::" ";
        Rec."Execute Permission" := Rec."Execute Permission"::" ";
        foreach Perm in Permissions do
            case Perm of
                'R':
                    Rec."Read Permission" := Rec."Read Permission"::Yes;
                'r':
                    Rec."Read Permission" := Rec."Read Permission"::Indirect;
                'I':
                    Rec."Insert Permission" := Rec."Insert Permission"::Yes;
                'i':
                    Rec."Insert Permission" := Rec."Insert Permission"::Indirect;
                'M':
                    Rec."Modify Permission" := Rec."Modify Permission"::Yes;
                'm':
                    Rec."Modify Permission" := Rec."Modify Permission"::Indirect;
                'D':
                    Rec."Delete Permission" := Rec."Delete Permission"::Yes;
                'd':
                    Rec."Delete Permission" := Rec."Delete Permission"::Indirect;
                'X':
                    Rec."Execute Permission" := Rec."Execute Permission"::Yes;
                'x':
                    Rec."Execute Permission" := Rec."Execute Permission"::Indirect;
            end;
        Rec."Object Type" := ForObjectType;
        Rec."Object ID" := ForObjectId;
        Rec."App ID" := InherentAppIDTok;
        Rec."Role ID" := InherentRoleIDLbl;
        Rec.Scope := Rec.Scope::System;
        Rec.Insert();
    end;

    local procedure LoadPermAssignmentBuffer()
    var
        User: Record User;
        SecurityGroup: Codeunit "Security Group";
        FilterTextBuilder: TextBuilder;
    begin
        if not IsBuffered then begin
            SecurityGroup.GetGroups(SecurityGroupBuffer);
            SecurityGroup.GetMembers(SecurityGroupMemberBuffer);
            SecurityGroupMemberBuffer.SetAutoCalcFields("User Name");

            User.SetLoadFields("User Security ID");
            User.SetFilter("License Type", '<>%1', User."License Type"::"External User");
            if User.FindSet() then
                repeat
                    FilterTextBuilder.Append(User."User Security ID");
                    FilterTextBuilder.Append('|');
                until User.Next() = 0;
            ExtUserFilterText := FilterTextBuilder.ToText().TrimEnd('|');

            IsBuffered := true;
        end;

        if (Rec."Role ID" = LastExpandedPermission."Role ID") and (Rec."App ID" = LastExpandedPermission."App ID") then
            exit;

        PermSetAssignmentBuffer.Reset();
        PermSetAssignmentBuffer.DeleteAll();
        Clear(PermSetAssignmentBuffer);

        LoadPermissionBuffer(Rec."App ID", Rec."Role ID");

        LastExpandedPermission := Rec;
    end;

    local procedure LoadPermissionBuffer(ByAppId: Guid; ByRoleId: Text[30])
    var
        User: Record User;
    begin
        LoadIncludedPermissions(ByAppId, ByRoleId);

        if StrLen(ByRoleId) > MaxStrLen(TempAccessControl."Role ID") then
            exit; // Permissions sets with Id over 20 characters cannot be assigned via access control;

        LoadAccessControlBuffer(ByAppId, ByRoleId);
        User.SetLoadFields("Full Name");

        TempAccessControl.Reset();
        TempAccessControl.SetLoadFields("User Security ID");
        TempAccessControl.SetAutoCalcFields("User Name");
        TempAccessControl.SetRange("App ID", ByAppId);
        TempAccessControl.SetRange("Role ID", ByRoleId);
        TempAccessControl.SetFilter("User Security ID", ExtUserFilterText);
        if TempAccessControl.FindSet() then
            repeat
                PermSetAssignmentBuffer.CompanyName := TempAccessControl."Company Name";
                SecurityGroupBuffer.SetRange("Group User SID", TempAccessControl."User Security ID");
                if SecurityGroupBuffer.FindFirst() then begin
                    PermSetAssignmentBuffer.SecurityId := SecurityGroupBuffer."Group User SID";
                    PermSetAssignmentBuffer.Type := PermSetAssignmentBuffer.Type::SecurityGroup;
                    PermSetAssignmentBuffer.Code := SecurityGroupBuffer.Code;
                    PermSetAssignmentBuffer.Name := PermSetAssignmentBuffer.Name;
                    if PermSetAssignmentBuffer.Insert() then;

                    SecurityGroupMemberBuffer.SetRange("Security Group Code", SecurityGroupBuffer.Code);
                    if SecurityGroupMemberBuffer.FindSet() then
                        repeat
                            PermSetAssignmentBuffer.SecurityId := SecurityGroupMemberBuffer."User Security ID";
                            PermSetAssignmentBuffer.Type := PermSetAssignmentBuffer.Type::User;
                            PermSetAssignmentBuffer.Code := SecurityGroupMemberBuffer."User Name";
                            PermSetAssignmentBuffer.Name := SecurityGroupMemberBuffer."User Full Name";
                            if PermSetAssignmentBuffer.Insert() then;
                        until SecurityGroupMemberBuffer.Next() = 0;
                end else begin
                    PermSetAssignmentBuffer.SecurityId := TempAccessControl."User Security ID";
                    PermSetAssignmentBuffer.Type := PermSetAssignmentBuffer.Type::User;
                    PermSetAssignmentBuffer.Code := TempAccessControl."User Name";
                    if User.Get(TempAccessControl."User Security ID") then
                        PermSetAssignmentBuffer.Name := User."Full Name";
                    if PermSetAssignmentBuffer.Insert() then;
                end;
            until TempAccessControl.Next() = 0;
    end;

    local procedure LoadAccessControlBuffer(ByAppId: Guid; ByRoleId: Text[30])
    var
        AccessControl: Record "Access Control";
    begin
        TempAccessControl.Reset();
        TempAccessControl.SetRange("App ID", ByAppId);
        TempAccessControl.SetRange("Role ID", ByRoleId);
        if TempAccessControl.IsEmpty() then begin
            AccessControl.SetRange("App ID", ByAppId);
            AccessControl.SetRange("Role ID", ByRoleId);
            if AccessControl.FindSet() then
                repeat
                    TempAccessControl := AccessControl;
                    TempAccessControl.Insert();
                until AccessControl.Next() = 0
            else begin
                TempAccessControl."App ID" := ByAppId;
                TempAccessControl."Role ID" := CopyStr(ByRoleId, 1, MaxStrLen(TempAccessControl."Role ID"));
                TempAccessControl."User Security ID" := '{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}';
                TempAccessControl.Insert()
            end;
        end;
    end;

    local procedure LoadIncludedPermissions(ByAppId: Guid; ByRoleId: Text[30])
    var
        MetadataPermSetRel: Record "Metadata Permission Set Rel.";
        TenantPermSetRel: Record "Tenant Permission Set Rel.";
    begin
        TenantPermSetRel.SetLoadFields("App ID", "Role ID");
        TenantPermSetRel.SetRange("Related App ID", ByAppId);
        TenantPermSetRel.SetRange("Related Role ID", ByRoleId);
        if TenantPermSetRel.FindSet() then
            repeat
                LoadPermissionBuffer(TenantPermSetRel."App ID", TenantPermSetRel."Role ID");
            until TenantPermSetRel.Next() = 0;

        MetadataPermSetRel.SetLoadFields("App ID", "Role ID");
        MetadataPermSetRel.SetRange("Related App ID", ByAppId);
        MetadataPermSetRel.SetRange("Related Role ID", ByRoleId);
        if MetadataPermSetRel.FindSet() then
            repeat
                LoadPermissionBuffer(MetadataPermSetRel."App ID", MetadataPermSetRel."Role ID");
            until MetadataPermSetRel.Next() = 0;
    end;

    local procedure SetPageFilter(NewScopeFilter: Enum "Permission Set Scope"; NewAppIDFilter: Guid; NewAppNameFilter: Text[250]; NewRoleIDFilter: Text[30])
    begin
        ScopeFilter := NewScopeFilter;
        AppIDFilter := NewAppIDFilter;
        AppNameFilter := NewAppNameFilter;
        RoleIDFilter := NewRoleIDFilter;

        Rec.FilterGroup(2);
        case ScopeFilter of
            ScopeFilter::Blank:
                begin
                    Rec.SetRange("App ID");
                    Rec.SetRange(Scope);
                end;
            ScopeFilter::System:
                begin
                    Rec.SetRange("App ID");
                    Rec.SetRange(Scope, Rec.Scope::System);
                end;
            ScopeFilter::UserDefined:
                begin
                    Rec.SetRange("App ID", NullGuid);
                    Rec.SetRange(Scope, Rec.Scope::Tenant);
                    AppIDFilter := NullGuid;
                end;
            ScopeFilter::Extension:
                begin
                    Rec.SetFilter("App ID", '<>%1', NullGuid);
                    Rec.SetRange(Scope, Rec.Scope::Tenant);
                end;
        end;

        if not IsNullGuid(AppIDFilter) then begin
            Rec.SetRange("App ID", AppIDFilter);
            if AppNameFilter = '' then
                AppNameFilter := GetNavAppName(AppIDFilter);
        end;

        Rec.SetFilter("Role ID", RoleIDFilter);
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure GetNavAppName(AppID: Guid): Text[250]
    begin
        if PublishedApplication.ID <> AppID then begin
            PublishedApplication.SetRange(ID, AppID);
            if not PublishedApplication.FindFirst() then
                exit('');
        end;
        exit(PublishedApplication.Name);
    end;

    local procedure SetScope()
    begin
        case true of
            (Rec.Scope = Rec.Scope::Tenant) and IsNullGuid(Rec."App ID"):
                PermSetScope := PermSetScope::UserDefined;
            Rec.Scope = Rec.Scope::Tenant:
                PermSetScope := PermSetScope::Extension;
            else
                PermSetScope := PermSetScope::System;
        end;
    end;
}

