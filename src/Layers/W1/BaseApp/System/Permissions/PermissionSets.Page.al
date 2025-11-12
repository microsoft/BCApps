namespace System.Security.AccessControl;

using System.Agents;
using System.Environment;
using System.IO;
using System.Reflection;
using System.Security.User;
using System.Utilities;

page 9802 "Permission Sets"
{
    AdditionalSearchTerms = 'access rights privilege';
    ApplicationArea = Basic, Suite;
    Caption = 'Permission Sets';
    DelayedInsert = true;
    PageType = List;
    Permissions = TableData "Permission Set Link" = rd,
                  TableData "Aggregate Permission Set" = rimd;
    SourceTable = "Permission Set Buffer";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    AboutTitle = 'About permissions';
    AboutText = 'You manage permissions by assigning permission sets to individual users and to security groups. You can only modify permission sets that you created, not the predefined ones.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Permission Set';
                field(PermissionSet; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Editable = IsPermissionSetEditable;
                    ToolTip = 'Specifies the name of the permission set.';

                    trigger OnValidate()
                    var
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                    begin
                        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
                        PermissionPagesMgt.VerifyPermissionSetRoleID(Rec."Role ID");
                        Rec.RenameTenantPermissionSet();
                    end;

                    trigger OnDrillDown()
                    var
                        PermisssionSetRelation: Codeunit "Permission Set Relation";
                    begin
                        PermisssionSetRelation.OpenPermissionSetPage(Rec.Name, Rec."Role ID", Rec."App ID", Rec.Scope);
                    end;
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ApplicationArea = Basic, Suite;
                    Editable = IsPermissionSetEditable;
                    ToolTip = 'Specifies the description of the record.';

                    trigger OnValidate()
                    var
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                    begin
                        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies if the permission set is defined by your organization, the base application, or an extension. You can only edit or delete permission sets that you have created.';
                    AboutTitle = 'The source of the permission set';
                    AboutText = 'You can modify or delete permission sets that your organization created but not those that are built-in (System). Extensions can define permission sets that are also not editable and that will be removed if the extension is uninstalled.';
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
            }
            part(ExpandedPermissions; "Expanded Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Editable = false;
                SubPageLink = "Role ID" = field("Role ID"),
                              "App ID" = field("App ID");
            }
            part("Included Permission Sets"; "Included PermissionSet FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Included Permission Sets';
                Editable = false;
            }
            part("Permission Set Assignments"; "Perm. Set Assignments Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users';
                SubPageLink = "Role ID" = field("Role ID"), "App ID" = field("App ID"), Scope = field(Scope);
                AboutTitle = 'Permission set assignments';
                AboutText = 'View or edit the list of users who are assigned a permission set.';
                Visible = CanManageUsersOnTenant;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ShowPermissions)
            {
                Caption = 'Permissions';
                Image = Permission;
                action(PermissionSetContent)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permissions';
                    Image = Permission;
                    Scope = Repeater;
                    ToolTip = 'View or edit which feature objects users need to access, and set up the related permissions in permission sets that you can assign to the users.';
                    AboutTitle = 'View permission set details';
                    AboutText = 'Go here to see which permissions the selected permission set defines for which objects.';

                    trigger OnAction()
                    var
                        PermissionSetRelation: Codeunit "Permission Set Relation";
                    begin
                        PermissionSetRelation.OpenPermissionSetPage(Rec.Name, Rec."Role ID", Rec."App ID", Rec.Scope);
                    end;
                }
                action("Permission Set by User")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User';
                    Image = Permission;
                    RunObject = Page "Permission Set by User";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
                }
                action("Permission Set By Security Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by Security Group';
                    Image = Permission;
                    RunObject = Page "Permission Set By Sec. Group";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing security groups.';
                }
                action("Show Permission Conflicts Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Permission Conflicts Overview';
                    Image = Permission;
                    RunObject = Page "Permission Conflicts Overview";
                    ToolTip = 'View the permission sets that provide more permissions than product licenses allow.';
                    Visible = IsSaaS;
                }
                action("Show Permission Conflicts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Permission Conflicts';
                    Image = Permission;
                    ToolTip = 'View details about the permission set that provides more permissions than the license allows.';
                    Visible = IsSaas;

                    trigger OnAction()
                    var
                        PermissionConflict: Page "Permission Conflicts";
                    begin
                        PermissionConflict.SetPermissionSetId(Rec."Role ID");
                        PermissionConflict.Run();
                    end;
                }
            }
            group("User Groups")
            {
                Caption = 'Security Groups';
                Image = Users;
                action(SecurityGroups)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Security Groups';
                    Image = Users;
                    RunObject = Page "Security Groups";
                    ToolTip = 'Set up or modify security groups as a fast way of giving users access to the functionality that is relevant to their work.';
                }
            }
        }
        area(processing)
        {
            group("<Functions>")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyPermissionSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Permission Set';
                    Ellipsis = true;
                    Enabled = CanManageUsersOnTenant;
                    Image = Copy;
                    ToolTip = 'Create a copy of the selected permission set with a name that you specify.';

                    trigger OnAction()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                        CopyPermissionSet: Report "Copy Permission Set";
                        ZeroGuid: Guid;
                    begin
                        AggregatePermissionSet.SetRange(Scope, Rec.Scope);
                        AggregatePermissionSet.SetRange("App ID", Rec."App ID");
                        AggregatePermissionSet.SetRange("Role ID", Rec."Role ID");

                        CopyPermissionSet.SetTableView(AggregatePermissionSet);
                        CopyPermissionSet.RunModal();

                        if AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, CopyPermissionSet.GetNewRoleID()) then begin
                            Rec.Init();
                            Rec.TransferFields(AggregatePermissionSet);
                            Rec.SetType();
                            Rec.Insert();
                            Rec.Get(Rec.Type, Rec."Role ID");
                        end;
                    end;
                }
                action(ImportPermissionSets)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Permission Sets';
                    Enabled = CanManageUsersOnTenant;
                    Image = Import;
                    ToolTip = 'Import a file with permissions.';

                    trigger OnAction()
                    var
                        PermissionSetBuffer: Record "Permission Set Buffer";
                        TempBlob: Codeunit "Temp Blob";
                        ImportPermissionSets: XmlPort "Import Permission Sets";
                        FileName: Text;
                        InStream: InStream;
                        OutStream: OutStream;
                        UpdateExistingPermissions: Boolean;
                    begin
                        if not UploadIntoStream('Import', '', '', FileName, InStream) then
                            exit;

                        TempBlob.CreateOutStream(OutStream);
                        CopyStream(OutStream, InStream);

                        TempBlob.CreateInStream(InStream);
                        UpdateExistingPermissions := Confirm(UpdateExistingPermissionsLbl, true);
                        ImportPermissionSets.SetSource(InStream);
                        ImportPermissionSets.SetUpdatePermissions(UpdateExistingPermissions);
                        ImportPermissionSets.Import();

                        PermissionSetBuffer := Rec;
                        Rec.FillRecordBuffer();
                        if Rec.Get(PermissionSetBuffer.Type, PermissionSetBuffer."Role ID") then;
                    end;
                }
                action(ExportPermissionSets)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Permission Sets';
                    Image = Export;
                    ToolTip = 'Export one or more permission sets to a file.';

                    trigger OnAction()
                    var
                        TenantPermissionSet: Record "Tenant Permission Set";
                        MetadataPermissionSet: Record "Metadata Permission Set";
                        TempBlob: Codeunit "Temp Blob";
                        EnvironmentInformation: Codeunit "Environment Information";
                        FileManagement: Codeunit "File Management";
                        OutStream: OutStream;
                        ExportToExtension, ExportSystem, ExportTenant : Boolean;
                    begin
                        ExportToExtension := false;

                        if EnvironmentInformation.IsSandbox() then
                            if Confirm(ExportExtensionSchemaQst) then
                                ExportToExtension := true;

                        GetSelectionFilter(MetadataPermissionSet);
                        GetSelectionFilter(TenantPermissionSet);

                        ExportSystem := MetadataPermissionSet.Count() > 0;
                        ExportTenant := TenantPermissionSet.Count() > 0;

                        TempBlob.CreateOutStream(OutStream);

                        if ExportSystem then
                            Message(ExportSystemPermissionSetsMsg);

                        if ExportSystem and ExportTenant then begin
                            ExportMixedPermissionSets(ExportToExtension, MetadataPermissionSet, TenantPermissionSet, OutStream);
                            FileManagement.BLOBExport(TempBlob, PermissionSetsLbl, true);
                            exit;
                        end;

                        if ExportSystem then begin
                            ExportSystemPermissionSets(ExportToExtension, MetadataPermissionSet, OutStream);
                            FileManagement.BLOBExport(TempBlob, PermissionSetsSystemLbl, true);
                        end else begin
                            ExportTenantPermissionSets(ExportToExtension, TenantPermissionSet, OutStream);
                            FileManagement.BLOBExport(TempBlob, PermissionSetsTenantLbl, true);
                        end;
                    end;
                }
                action(RemoveObsoletePermissions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Obsolete Permissions';
                    Enabled = CanManageUsersOnTenant;
                    Image = Delete;
                    ToolTip = 'Remove all permissions related to the objects which are obsolete or removed.';

                    trigger OnAction()
                    var
                        TableMetadata: Record "Table Metadata";
                        Permission: Record Permission;
                        TenantPermission: Record "Tenant Permission";
                        AllObjWithCaption: Record AllObjWithCaption;
                        PermissionToDelete: Record Permission;
                        TenantPermissionToDelete: Record "Tenant Permission";
                        PermissionsCount: Integer;
                    begin
                        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
                        if TableMetadata.FindSet() then begin
                            Permission.SetRange("Object Type", Permission."Object Type"::"Table Data", Permission."Object Type"::Table);
                            TenantPermission.SetRange("Object Type", Permission."Object Type"::"Table Data", Permission."Object Type"::Table);
                            repeat
                                Permission.SetRange("Object ID", TableMetadata.ID);
                                TenantPermission.SetRange("Object ID", TableMetadata.ID);
                                PermissionsCount += Permission.Count + TenantPermission.Count();
                                Permission.DeleteAll();
                                TenantPermission.DeleteAll();
                            until TableMetadata.Next() = 0;
                        end;
                        Permission.SetFilter(
                            "Object Type", '%1|%2|%3|%4|%5',
                            Permission."Object Type"::Codeunit, Permission."Object Type"::Page, Permission."Object Type"::Query,
                            Permission."Object Type"::Report, Permission."Object Type"::XMLport);
                        Permission.SetFilter("Object ID", '<>0');
                        if Permission.FindSet() then
                            repeat
                                if not AllObjWithCaption.Get(Permission."Object Type", Permission."Object ID") then begin
                                    PermissionToDelete.Get(Permission."Role ID", Permission."Object Type", Permission."Object ID");
                                    PermissionToDelete.Delete();
                                    PermissionsCount += 1;
                                end;
                            until Permission.Next() = 0;
                        TenantPermission.SetFilter(
                            "Object Type", '%1|%2|%3|%4|%5',
                            TenantPermission."Object Type"::Codeunit, TenantPermission."Object Type"::Page, TenantPermission."Object Type"::Query,
                            TenantPermission."Object Type"::Report, TenantPermission."Object Type"::XMLport);
                        TenantPermission.SetFilter("Object ID", '<>0');
                        if TenantPermission.FindSet() then
                            repeat
                                if not AllObjWithCaption.Get(TenantPermission."Object Type", TenantPermission."Object ID") then begin
                                    TenantPermissionToDelete.Get(TenantPermission."App ID", TenantPermission."Role ID", TenantPermission."Object Type", TenantPermission."Object ID");
                                    TenantPermissionToDelete.Delete();
                                    PermissionsCount += 1;
                                end;
                            until TenantPermission.Next() = 0;

                        if PermissionsCount > 0 then
                            Message(StrSubstNo(ObsoletePermissionsMsg, PermissionsCount))
                        else
                            Message(NothingToRemoveMsg);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Permissions_Promoted; PermissionSetContent)
                {
                }
                actionref(CopyPermissionSet_Promoted; CopyPermissionSet)
                {
                }
                actionref(ImportPermissionSets_Promoted; ImportPermissionSets)
                {
                }
                actionref(ExportPermissionSets_Promoted; ExportPermissionSets)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsPermissionSetEditable := Rec.Type = Rec.Type::"User-Defined";
        CurrPage."Included Permission Sets".Page.UpdateIncludedPermissionSets(Rec."Role ID");
    end;

    trigger OnAfterGetRecord()
    begin
        IsPermissionSetEditable := Rec.Type = Rec.Type::"User-Defined";
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        if Rec.Type <> Rec.Type::"User-Defined" then
            Error(CannotDeletePermissionSetErr);

        TenantPermissionSet.Get(Rec."App ID", Rec."Role ID");
        TenantPermissionSet.Delete();

        CurrPage.Update();
        exit(true);
    end;

    trigger OnInit()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ZeroGUID: Guid;
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        PermissionPagesMgt.VerifyPermissionSetRoleID(Rec."Role ID");

        TenantPermissionSet.Init();
        TenantPermissionSet."App ID" := ZeroGUID;
        TenantPermissionSet."Role ID" := Rec."Role ID";
        TenantPermissionSet.Name := Rec.Name;
        TenantPermissionSet.Insert();

        Rec.Insert();
        Rec.Get(Rec.Type::"User-Defined", Rec."Role ID");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        if Rec.Type = Rec.Type::"User-Defined" then begin
            PermissionPagesMgt.VerifyPermissionSetRoleID(Rec."Role ID");
            TenantPermissionSet.Get(xRec."App ID", xRec."Role ID");
            if xRec."Role ID" <> Rec."Role ID" then begin
                TenantPermissionSet.Rename(xRec."App ID", Rec."Role ID");
                TenantPermissionSet.Get(xRec."App ID", Rec."Role ID");
            end;
            TenantPermissionSet.Name := Rec.Name;
            TenantPermissionSet.Modify();
            CurrPage.Update(false);
            exit(true);
        end;
        exit(false); // Causes UI to stop processing the action - we handled it manually
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := Rec.Type::"User-Defined";
        IsPermissionSetEditable := true;
        Rec.Scope := Rec.Scope::Tenant;
    end;

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        IsSaas := EnvironmentInfo.IsSaaS();

        PermissionPagesMgt.CheckAndRaiseNotificationIfAppDBPermissionSetsChanged();
        Rec.FillRecordBuffer();

        if PermissionManager.IsIntelligentCloud() then
            Rec.SetRange("Role ID", IntelligentCloudTok);
    end;

    local procedure ExportMixedPermissionSets(ExportToExtension: Boolean; var MetadataPermissionSet: Record "Metadata Permission Set"; var TenantPermissionSet: Record "Tenant Permission Set"; var OutStreamDest: OutStream)
    var
        DataCompression: Codeunit "Data Compression";
        TempBlobTenant: Codeunit "Temp Blob";
        TempBlobSystem: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        DataCompression.CreateZipArchive();

        TempBlobSystem.CreateOutStream(OutStream);
        ExportSystemPermissionSets(ExportToExtension, MetadataPermissionSet, OutStream);
        TempBlobSystem.CreateInStream(InStream);
        DataCompression.AddEntry(InStream, PermissionSetsSystemLbl);

        TempBlobTenant.CreateOutStream(OutStream);
        ExportTenantPermissionSets(ExportToExtension, TenantPermissionSet, OutStream);
        TempBlobTenant.CreateInStream(InStream);
        DataCompression.AddEntry(InStream, PermissionSetsTenantLbl);

        DataCompression.SaveZipArchive(OutStreamDest);
    end;

    local procedure ExportTenantPermissionSets(ExportToExtension: Boolean; var TenantPermissionSet: Record "Tenant Permission Set"; var OutStream: OutStream)
    var
        ExportPermissionSetsTenant: XmlPort "Export Permission Sets Tenant";
    begin
        ExportPermissionSetsTenant.SetExportToExtensionSchema(ExportToExtension);
        ExportPermissionSetsTenant.SetTableView(TenantPermissionSet);
        ExportPermissionSetsTenant.SetDestination(OutStream);
        ExportPermissionSetsTenant.Export();
    end;

    local procedure ExportSystemPermissionSets(ExportToExtension: Boolean; var MetadataPermissionSet: Record "Metadata Permission Set"; var OutStream: OutStream)
    var
        ExportPermissionSetsSystem: Xmlport "Export Permission Sets System";
    begin
        ExportPermissionSetsSystem.SetExportToExtensionSchema(ExportToExtension);
        ExportPermissionSetsSystem.SetTableView(MetadataPermissionSet);
        ExportPermissionSetsSystem.SetDestination(OutStream);
        ExportPermissionSetsSystem.Export();
    end;

    local procedure GetSelectionFilter(var TenantPermissionSet: Record "Tenant Permission Set")
    var
        PermissionSetBuffer: Record "Permission Set Buffer";
    begin
        TenantPermissionSet.Reset();
        PermissionSetBuffer.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if Rec.FindSet() then
            repeat
                if TenantPermissionSet.Get(Rec."App ID", Rec."Role ID") then
                    TenantPermissionSet.Mark(true);
            until Rec.Next() = 0;
        TenantPermissionSet.MarkedOnly(true);
        Rec.Reset();
        Rec.CopyFilters(PermissionSetBuffer);
    end;

    local procedure GetSelectionFilter(var MetadataPermissionSet: Record "Metadata Permission Set")
    var
        PermissionSetBuffer: Record "Permission Set Buffer";
    begin
        MetadataPermissionSet.Reset();
        PermissionSetBuffer.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if Rec.FindSet() then
            repeat
                if MetadataPermissionSet.Get(Rec."App ID", Rec."Role ID") then
                    MetadataPermissionSet.Mark(true);
            until Rec.Next() = 0;
        MetadataPermissionSet.MarkedOnly(true);
        Rec.Reset();
        Rec.CopyFilters(PermissionSetBuffer);
    end;

    internal procedure GetSelectedRecords(var CurrSelectedRecords: Record "Permission Set Buffer")
    begin
        CurrPage.SetSelectionFilter(Rec);

        if Rec.FindSet() then
            repeat
                CurrSelectedRecords.Copy(Rec);
                CurrSelectedRecords.Insert();
            until Rec.Next() = 0;
    end;

    var
        PermissionManager: Codeunit "Permission Manager";
        CanManageUsersOnTenant: Boolean;
        IsPermissionSetEditable: Boolean;
        IsSaas: Boolean;
        CannotDeletePermissionSetErr: Label 'You can only delete user-created or copied permission sets.';
        ExportExtensionSchemaQst: Label 'Do you want to export permission sets in a schema that is supported by the extension package?';
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
        ObsoletePermissionsMsg: Label '%1 obsolete permissions were removed.', Comment = '%1 = number of deleted records.';
        NothingToRemoveMsg: Label 'There is nothing to remove.';
        UpdateExistingPermissionsLbl: Label 'Do you want to update the existing permission sets with those from the file? If you choose ''No'', the permissions from the import file will overwrite the existing ones for the included permission sets.';
        ExportSystemPermissionSetsMsg: Label 'You are exporting system permission sets. These permission sets will become user-defined permission sets when they are imported.';
        PermissionSetsLbl: Label 'PermissionSets.zip', Locked = true;
        PermissionSetsTenantLbl: Label 'UserDefinedPermissionSets.xml', Locked = true;
        PermissionSetsSystemLbl: Label 'SystemPermissionSets.xml', Locked = true;
}

