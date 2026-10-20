// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using System.Environment;
using System.Reflection;
using System.Security.User;
using System.Telemetry;
using System.Text;

page 9886 "Effective Permissions Overview"
{
    Caption = 'Effective Permissions Overview';
    UsageCategory = Administration;
    PageType = List;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Effective Permission Buffer";
    AboutTitle = 'About Effective Permission Overview';
    AboutText = 'Audit the effective permissions each user has across objects in your system, as well as which assigned permission set contributed to each effective permission. Effective permissions show the final access to objects and data, helping you verify access and troubleshoot permission issues.';

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                AboutTitle = 'Filtering users, objects, and permissions';
                AboutText = 'Start by narrowing down the effective permissions displayed by setting filters for user, object, and permission.';

                field(CompanyFilter; CompanyFilter)
                {
                    Caption = 'Company';
                    ToolTip = 'Specifies the company for which effective permissions for the chosen user will be shown.';
                    TableRelation = Company;
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(UserFilter; UserFilter)
                {
                    Caption = 'User';
                    ToolTip = 'Specifies the user filter.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        UserSelection: Codeunit "User Selection";
                        Users: Page Users;
                        RecRef: RecordRef;
                    begin
                        UserSelection.FilterSystemUserAndGroupUsers(User);
                        Users.SetTableView(User);
                        Users.LookupMode(true);
                        if Users.RunModal() = Action::LookupOK then begin
                            Users.GetSelectionFilter(User);
                            RecRef.GetTable(User);
                            Text := SelectionFilterMgt.GetSelectionFilter(RecRef, User.FieldNo("User Name"));
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(ObjTypeFilter; ObjTypeFilter)
                {
                    Caption = 'Object Type';
                    ToolTip = 'Specifies object type filter.';
                    OptionCaption = ' ,Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(ObjIDFilter; ObjIDFilter)
                {
                    Caption = 'Object ID';
                    ToolTip = 'Specifies object ID filter.';
                    TableRelation = AllObjWithCaption."Object ID";

                    trigger OnAssistEdit()
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        AllObjectsWithCaption: Page "All Objects with Caption";
                        RecRef: RecordRef;
                    begin
                        AllObjectsWithCaption.LookupMode(true);
                        if AllObjectsWithCaption.RunModal() = Action::LookupOK then begin
                            AllObjectsWithCaption.GetSelectionFilter(AllObjWithCaption);
                            RecRef.GetTable(AllObjWithCaption);
                            ObjIDFilter := SelectionFilterMgt.GetSelectionFilter(RecRef, AllObjWithCaption.FieldNo("Object ID"));
                            ApplyFilters();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(ReadFilter; ReadFilter)
                {
                    Caption = 'Read';
                    ToolTip = 'Specifies whether permissions are filtered by read access.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(InsertFilter; InsertFilter)
                {
                    Caption = 'Insert';
                    ToolTip = 'Specifies whether permissions are filtered by insert access.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(ModifyFilter; ModifyFilter)
                {
                    Caption = 'Modify';
                    ToolTip = 'Specifies whether permissions are filtered by modify access.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(DeleteFilter; DeleteFilter)
                {
                    Caption = 'Delete';
                    ToolTip = 'Specifies whether permissions are filtered by delete access.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
            }
            repeater(General)
            {
                field(Company; Rec.Company)
                {
                    Visible = false;

                }
                field(UserName; Rec."User Name") { }
                field(ObjectType; Rec."Object Type") { }
                field(ObjectID; Rec."Object ID")
                {
                    Visible = false;
                }
                field(ObjectName; Rec."Object Name") { }
                field(ReadPermission; Rec."Read Permission") { }
                field(InsertPermission; Rec."Insert Permission") { }
                field(ModifyPermission; Rec."Modify Permission") { }
                field(DeletePermission; Rec."Delete Permission") { }
                field(ExecutePermission; Rec."Execute Permission") { }
            }
        }
        area(FactBoxes)
        {
            part(EffectivePermissionBySet; "Effective Permissions By Set") { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                Caption = 'Apply Filters';
                ToolTip = 'Refresh the data based on the current filters.';
                AboutTitle = 'Applying your filters';
                AboutText = 'After setting your filters, select Apply Filters to refresh the data displayed on the page.';
                Image = Refresh;

                trigger OnAction()
                begin
                    LoadData();
                    CurrPage.Update(false);
                end;
            }
            action(PermissionSets)
            {
                ApplicationArea = All;
                Caption = 'Permission Sets';
                Image = Permission;
                RunObject = Page "Permission Sets";
                ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
            }
            action(PermissionSetByUser)
            {
                ApplicationArea = All;
                Caption = 'Permission Set by User';
                Image = Permission;
                RunObject = Page "Permission Set by User";
                ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Apply_Promoted; Apply) { }
                actionref(PermissionSets_Promoted; PermissionSets) { }
                actionref(PermissionSetByUser_Promoted; PermissionSetByUser) { }
            }
        }
    }

    var
        TempUser: Record User temporary;
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        UserFilter: Text;
        CompanyFilter: Text[30];
        ObjTypeFilter: Option " ","Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        ObjIDFilter: Text;
        ReadFilter, InsertFilter, ModifyFilter, DeleteFilter : Option " ",No,Yes,Indirect;

    trigger OnOpenPage()
    var
        AuditLog: Codeunit "Audit Log";
        EffectivePermissionsPageOpenLbl: Label 'The Effective Permissions Overview page has been opened by UserSecurityId %1.', Locked = true;
    begin
        EffectivePermissionsMgt.DisallowViewingEffectivePermissionsForNonAdminUsers(UserSecurityId());

        CompanyFilter := CopyStr(CompanyName(), 1, MaxStrLen(CompanyFilter));
        LoadUsers();
        ApplyFilters(false);

        AuditLog.LogAuditMessage(StrSubstNo(EffectivePermissionsPageOpenLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 2, 0);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if not IsNullGuid(Rec."User Security ID") then
            CurrPage.EffectivePermissionBySet.Page.SetRecordAndRefresh(
                Rec."User Security ID", Rec.Company, Rec."Object Type", Rec."Object ID");
    end;

    local procedure ApplyFilters()
    begin
        ApplyFilters(true);
    end;

    local procedure ApplyFilters(Update: Boolean)
    begin
        Rec.SetFilter("User Name", UserFilter);
        Rec.SetFilter(Company, CompanyFilter);
        if ObjTypeFilter = ObjTypeFilter::" " then
            Rec.SetRange("Object Type")
        else
            Rec.SetRange("Object Type", ObjTypeFilter - 1);
        Rec.SetFilter("Object ID", ObjIDFilter);
        if ReadFilter = ReadFilter::" " then
            Rec.SetRange("Read Permission")
        else
            Rec.SetRange("Read Permission", ReadFilter - 1);
        if InsertFilter = InsertFilter::" " then
            Rec.SetRange("Insert Permission")
        else
            Rec.SetRange("Insert Permission", InsertFilter - 1);
        if ModifyFilter = ModifyFilter::" " then
            Rec.SetRange("Modify Permission")
        else
            Rec.SetRange("Modify Permission", ModifyFilter - 1);
        if DeleteFilter = DeleteFilter::" " then
            Rec.SetRange("Delete Permission")
        else
            Rec.SetRange("Delete Permission", DeleteFilter - 1);
        if Update then
            CurrPage.Update(false);
    end;

    local procedure LoadUsers()
    var
        User: Record User;
        UserProperty: Record "User Property";
        EnvironmentInfo: Codeunit "Environment Information";
        UserSelection: Codeunit "User Selection";
        // AzureADUserManagement: Codeunit "Azure AD User Management";
        IsSaaS: Boolean;
    begin
        IsSaaS := EnvironmentInfo.IsSaaS();
        TempUser.Reset();
        TempUser.DeleteAll();
        UserProperty.SetLoadFields("Authentication Object ID");
        UserSelection.FilterSystemUserAndGroupUsers(User);
        User.SetLoadFields("User Security ID", "User Name");
        if User.FindSet() then
            repeat
                // FIXME: TEMP DEV
                // if IsSaaS then
                //     if not AzureADUserManagement.IsUserDelegated(User."User Security ID") then
                //         if (not UserProperty.Get(User."User Security ID")) or (UserProperty."Authentication Object ID" = '') then
                //             continue;
                TempUser."User Security ID" := User."User Security ID";
                TempUser."User Name" := User."User Name";
                TempUser.Insert();
            until User.Next() = 0;
    end;

    local procedure LoadData()
    var
        AllObj: Record AllObj;
        TempPermission: Record Permission temporary;
        Window: Dialog;
        ProcessCount, TotalCount : Integer;
        LastUpdateDateTime: DateTime;
        LoadDataMsg: Label 'Reading Permissions...@1@@@@@';
    begin
        LoadUsers();
        TempUser.Reset();
        TempUser.SetFilter("User Name", UserFilter);
        if TempUser.IsEmpty() then
            exit;

        AllObj.SetLoadFields("Object Type", "Object ID", "Object Name");
        if ObjTypeFilter <> ObjTypeFilter::" " then
            AllObj.SetRange("Object Type", ObjTypeFilter - 1);
        AllObj.SetFilter("Object ID", ObjIDFilter);
        if not AllObj.FindSet() then
            exit;

        Window.Open(LoadDataMsg);

        TotalCount := AllObj.Count() * TempUser.Count();
        LastUpdateDateTime := CurrentDateTime();
        repeat
            TempUser.FindSet();
            repeat
                EffectivePermissionsMgt.PopulatePermissionRecordWithEffectivePermissionsForObject(
                    TempPermission, TempUser."User Security ID", CompanyFilter, AllObj."Object Type", AllObj."Object ID");

                Rec.Init();
                Rec.Company := CompanyFilter;
                Rec."User Name" := TempUser."User Name";
                Rec."User Security ID" := TempUser."User Security ID";
                Rec."Object Type" := AllObj."Object Type";
                Rec."Object ID" := AllObj."Object ID";
                Rec."Object Name" := AllObj."Object Name";
                Rec."Read Permission" := TempPermission."Read Permission";
                Rec."Insert Permission" := TempPermission."Insert Permission";
                Rec."Modify Permission" := TempPermission."Modify Permission";
                Rec."Delete Permission" := TempPermission."Delete Permission";
                Rec."Execute Permission" := TempPermission."Execute Permission";
                if Rec.Insert() then;

                ProcessCount += 1;
                if CurrentDateTime() - LastUpdateDateTime > 1000 then begin
                    Window.Update(1, Round(ProcessCount * 10000 / TotalCount, 1));
                    LastUpdateDateTime := CurrentDateTime();
                end;
            until TempUser.Next() = 0;
        until AllObj.Next() = 0;
        if Rec.FindFirst() then;

        Window.Close();
    end;
}