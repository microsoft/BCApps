// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4340 "Select Agent Permissions Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Access Control Buffer";
    SourceTableTemporary = true;
    Caption = 'Agent permissions';
    MultipleNewLines = false;
    Editable = true;
    DataCaptionExpression = '';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                Caption = 'Agent permissions';

                field(PermissionSet; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of a security role that has been assigned to this Windows login in the current database.';
                    Style = Unfavorable;
                    StyleExpr = PermissionSetNotFound;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LookupPermissionSet: Page "Lookup Permission Set";
                    begin
                        LookupPermissionSet.LookupMode := true;
                        if LookupPermissionSet.RunModal() = ACTION::LookupOK then begin
                            LookupPermissionSet.GetRecord(PermissionSetLookupRecord);
                            Text := PermissionSetLookupRecord."Role ID";
                            PermissionSetLookupRecord.SetRecFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if Rec."Role ID" = '' then
                            Error(RoleIdMustBeFilledInErr);

                        PermissionSetLookupRecord.SetRange("Role ID", Rec."Role ID");
                        if PermissionSetLookupRecord.FindFirst() then begin
                            if PermissionSetLookupRecord.Count() > 1 then
                                Error(MultipleRoleIDErr, Rec."Role ID");

                            PermissionSetNotFound := false;
                            Rec.Scope := PermissionSetLookupRecord.Scope;
                            Rec."App ID" := PermissionSetLookupRecord."App ID";
                            PermissionScope := Format(PermissionSetLookupRecord.Scope);
                            PermissionAppName := PermissionSetLookupRecord."App Name";
                            PermissionRoleName := PermissionSetLookupRecord.Name;
                        end;

                        PermissionSetLookupRecord.Reset();
                    end;
                }
                field(Description; PermissionRoleName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the security role that has been given to this Windows login in the current database.';
                }
                field(Company; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the name of the company that this role is limited to for this Windows login.';
                    Visible = ShowCompanyField;
                }
                field(ExtensionName; PermissionAppName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(PermissionScope; PermissionScope)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Scope';
                    Editable = false;
                    ToolTip = 'Specifies the scope of the permission set.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AgentShowHideCompany)
            {
                ApplicationArea = All;
                Caption = 'Show/hide company';
                Image = CompanyInformation;
                ToolTip = 'Show or hide the company name.';

                trigger OnAction()
                begin
                    if (not ShowCompanyField and (GlobalSingleCompanyName <> '')) then
                        // A confirmation dialog is raised when the user shows the company field
                        // for an agent that operates in a single company.
                        if not Confirm(ShowSingleCompanyQst, false) then
                            exit;

                    ShowCompanyFieldOverride := true;
                    ShowCompanyField := not ShowCompanyField;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PermissionSetNotFound := false;
        PermissionAppName := '';
        PermissionRoleName := '';
        PermissionScope := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        HandleCompanyNameOnInsert();
    end;

    internal procedure Initialize(NewAgentUserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AgentSingleCompany: Boolean;
    begin
        AgentUserSecurityID := NewAgentUserSecurityID;
        Rec.Copy(TempAccessControlBuffer, true);

        AgentSingleCompany := GetAccessControlForSingleCompany(GlobalSingleCompanyName);
        if not ShowCompanyFieldOverride then
            ShowCompanyField := not AgentSingleCompany;
    end;

    local procedure HandleCompanyNameOnInsert()
    begin
        if GlobalSingleCompanyName <> '' then begin
            if (Rec."Company Name" = '') and not ShowCompanyField then
                // Default the company name for the inserted record when all these conditions are met:
                // 1. The agent operates in a single company,
                // 2. The company name is not explicit specified,
                // 3. The user didn't toggle to view the company name field on permissions.
                Rec."Company Name" := GlobalSingleCompanyName;

            if (Rec."Company Name" <> GlobalSingleCompanyName) then
                // The agent used to operation in a single company, but operates in multiple ones now.
                // Ideally, other scenarios should also trigger an update (delete, modify), but insert
                // was identified as the main one.
                GlobalSingleCompanyName := '';
        end;
    end;

    local procedure UpdateGlobalVariables()
    begin
        if PermissionSetLookupRecord.Get(Rec.Scope, Rec."App ID", Rec."Role ID") then begin
            PermissionSetNotFound := false;
            PermissionAppName := PermissionSetLookupRecord."App Name";
            PermissionRoleName := PermissionSetLookupRecord.Name;
            PermissionScope := Format(PermissionSetLookupRecord.Scope);
        end
        else begin
            PermissionSetNotFound := true;
            PermissionAppName := '';
            PermissionRoleName := '';
            PermissionScope := '';
        end;

        if not ShowCompanyFieldOverride then begin
            ShowCompanyField := not GetAccessControlForSingleCompany(GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    protected procedure GetAccessControlForSingleCompany(var SingleCompanyName: Text[30]): Boolean
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        exit(AgentImpl.GetAccessControlForSingleCompany(AgentUserSecurityID, SingleCompanyName));
    end;

    var
        PermissionSetLookupRecord: Record "Aggregate Permission Set";
        AgentUserSecurityID: Guid;
        PermissionScope, PermissionAppName, PermissionRoleName : Text;
        PermissionSetNotFound: Boolean;
        ShowCompanyField, ShowCompanyFieldOverride : Boolean;
        GlobalSingleCompanyName: Text[30];
        MultipleRoleIDErr: Label 'The permission set %1 is defined multiple times in this context. Use the lookup button to select the relevant permission set.', Comment = '%1 will be replaced with a Role ID code value from the Permission Set table';
        ShowSingleCompanyQst: Label 'This agent currently has permissions in only one company. By showing the Company field, you will be able to assign permissions in other companies, making the agent available there. The agent may not have been designed to work cross companies.\\Do you want to continue?';
        RoleIdMustBeFilledInErr: Label 'Role ID must be filled in.';
}