// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using System.Azure.Identity;
using System.Environment;
using System.Reflection;

page 9886 "Effective Permissions Overview"
{
    Caption = 'Effective Permission Overview';
    AdditionalSearchTerms = 'YSX';
    UsageCategory = Administration;
    PageType = List;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Effective Permission Buffer";
    AboutTitle = 'About Effective Permission Overview';
    AboutText = 'Audit the effective permissions each user has across objects in your system, as well as which assigned permission set contributed to each effective permission. Effective permissions show the final access to objects and data, helping you verify access, troubleshoot permission issues.';

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                field(UserFilter; UserFilter)
                {
                    Caption = 'User';
                    TableRelation = User."User Name";
                }
                field(CompanyFilter; CompanyFilter)
                {
                    Caption = 'Company';
                    TableRelation = Company;
                }
                field(ObjTypeFilter; ObjTypeFilter)
                {
                    Caption = 'Object Type';
                    OptionCaption = ' ,Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
                }
                field(ObjIDFilter; ObjIDFilter)
                {
                    Caption = 'Object ID';
                    TableRelation = AllObjWithCaption;
                }
                field(ReadFilter; ReadFilter)
                {
                    Caption = 'Read';
                }
                field(InsertFilter; InsertFilter)
                {
                    Caption = 'Insert';
                }
                field(ModifyFilter; ModifyFilter)
                {
                    Caption = 'Modify';
                }
                field(DeleteFilter; DeleteFilter)
                {
                    Caption = 'Delete';
                }
            }
            repeater(General)
            {
                field(Company; Rec.Company) { }
                field(UserName; Rec."User Name") { }
                field(ObjectType; Rec."Object Type") { }
                field(ObjectID; Rec."Object ID") { }
                field(ObjectName; Rec."Object Name") { }
                field(ReadPermission; Rec."Read Permission") { }
                field(InsertPermission; Rec."Insert Permission") { }
                field(ModifyPermission; Rec."Modify Permission") { }
                field(DeletePermission; Rec."Delete Permission") { }
                field(ExecutePermission; Rec."Execute Permission") { }
            }
        }
        // TODO: to be implemented later
        // area(FactBoxes)
        // {
        //     part(YS_EffectivePermissionBySet; YS_EffectivePermissionBySet)
        //     {

        //     }
        // }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';

                trigger OnAction()
                begin
                    LoadData();
                    CurrPage.Update(false);
                end;

            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    var
        UserFilter: Text;
        CompanyFilter: Text[30];
        ObjTypeFilter: Option " ","Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        ObjIDFilter: Text;
        ReadFilter, InsertFilter, ModifyFilter, DeleteFilter : Option " ",Yes,Indirect;

    trigger OnOpenPage()
    begin
        // Rec.SetRange(Company, 'CRONUS International Ltd.');
        CompanyFilter := CopyStr(CompanyName(), 1, MaxStrLen(CompanyFilter));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        // CurrPage.YS_EffectivePermissionBySet.Page.SetSource(Rec);
    end;

    local procedure LoadData()
    var
        AllObj: Record AllObj;
        User: Record User;
        TempUser: Record User temporary;
        UserProperty: Record "User Property";

        TempPermission: Record Permission temporary;
        EnvironmentInfo: Codeunit "Environment Information";
        AzureADUserManagement: Codeunit "Azure AD User Management";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        IsSaaS: Boolean;
        Window: Dialog;
        ProcessCount, TotalCount : Integer;
        LastUpdateDateTime: DateTime;
        ProcessingMsg: Label 'Reading Permissions...@1@@@@@';
    begin
        Window.Open(ProcessingMsg);

        User.SetLoadFields("User Security ID", "User Name");
        UserProperty.SetLoadFields("Authentication Object ID");
        IsSaaS := EnvironmentInfo.IsSaaS();
        User.SetRange("User Name", UserFilter);
        if User.FindSet() then
            repeat
                if IsSaaS then
                    if not AzureADUserManagement.IsUserDelegated(User."User Security ID") then
                        if (not UserProperty.Get(User."User Security ID")) or (UserProperty."Authentication Object ID" = '') then
                            continue;
                TempUser."User Security ID" := User."User Security ID";
                TempUser.Insert();
            until User.Next() = 0;

        AllObj.SetRange("Object Type", ObjTypeFilter);
        AllObj.SetFilter("Object ID", ObjIDFilter);
        if AllObj.FindSet() then begin
            TotalCount := AllObj.Count();
            LastUpdateDateTime := CurrentDateTime();
            repeat
                EffectivePermissionsMgt.PopulatePermissionRecordWithEffectivePermissionsForObject(
                    TempPermission, User."User Security ID", CompanyFilter, AllObj."Object Type", AllObj."Object ID");

                Rec.Init();
                Rec.Company := CompanyFilter;
                Rec."User Name" := User."User Name";
                Rec."User Security ID" := User."User Security ID";
                Rec."Object Type" := AllObj."Object Type";
                Rec."Object ID" := AllObj."Object ID";
                Rec."Read Permission" := TempPermission."Read Permission";
                Rec."Insert Permission" := TempPermission."Insert Permission";
                Rec."Modify Permission" := TempPermission."Modify Permission";
                Rec."Delete Permission" := TempPermission."Delete Permission";
                Rec."Execute Permission" := TempPermission."Execute Permission";
                Rec.Insert();

                ProcessCount += 1;
                if CurrentDateTime() - LastUpdateDateTime > 1000 then begin
                    Window.Update(1, Round(ProcessCount * 10000 / TotalCount, 1));
                    LastUpdateDateTime := CurrentDateTime();
                end;
            until AllObj.Next() = 0;
        end;

        Window.Close();
    end;
}