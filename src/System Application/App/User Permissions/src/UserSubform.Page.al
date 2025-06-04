// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Security.AccessControl;

page 9801 "User Subform"
{
    Caption = 'User Permission Sets';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Access Control";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'User Permissions';
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
                        PermissionSetLookupRecord.SetRange("Role ID", Rec."Role ID");
                        PermissionSetLookupRecord.FindFirst();

                        if PermissionSetLookupRecord.Count > 1 then
                            Error(MultipleRoleIDErr, Rec."Role ID");

                        Rec.Scope := PermissionSetLookupRecord.Scope;
                        Rec."App ID" := PermissionSetLookupRecord."App ID";
                        PermissionScope := Format(PermissionSetLookupRecord.Scope);

                        Rec.CalcFields("App Name", "Role Name");
                        PermissionSetLookupRecord.Reset();
                    end;
                }
                field(Description; Rec."Role Name")
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
                }
                field(ExtensionName; Rec."App Name")
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

    var
        PermissionSetLookupRecord: Record "Aggregate Permission Set";
        User: Record User;
        MultipleRoleIDErr: Label 'The permission set %1 is defined multiple times in this context. Use the lookup button to select the relevant permission set.', Comment = '%1 will be replaced with a Role ID code value from the Permission Set table';
        PermissionSetAddedToUserLbl: Label 'The permission set %1 has been added to the user %2 by UserSecurityId %3.', Comment = '%1 - Role ID, %2 - UserSecurityId, %3 - Current UserSecurityId';
        PermissionScope: Text;
        PermissionSetNotFound: Boolean;
        UserPermissionsTok: Label 'User Permissions', Locked = true;

    trigger OnAfterGetRecord()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if User."User Name" <> '' then
            CurrPage.Caption := User."User Name";

        PermissionScope := Format(Rec.Scope);

        PermissionSetNotFound := false;
        if not (Rec."Role ID" in ['SUPER', 'SECURITY']) then begin
            PermissionSetNotFound := not AggregatePermissionSet.Get(Rec.Scope, Rec."App ID", Rec."Role ID");

            if PermissionSetNotFound then
                OnPermissionSetNotFound();
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        User.TestField("User Name");
        Rec.CalcFields("App Name", Rec."Role Name");
        Session.LogSecurityAudit(UserPermissionsTok, SecurityOperationResult::Success, StrSubstNo(PermissionSetAddedToUserLbl, Rec."Role ID", Rec."User Security ID", UserSecurityId()), AuditCategory::UserManagement);
        Session.LogAuditMessage(StrSubstNo(PermissionSetAddedToUserLbl, Rec."Role ID", Rec."User Security ID", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::UserManagement, 2, 0);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.CalcFields("App Name", Rec."Role Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if User.Get(Rec."User Security ID") then;
        Rec.CalcFields("App Name", Rec."Role Name");
        PermissionScope := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPermissionSetNotFound()
    begin
    end;
}

