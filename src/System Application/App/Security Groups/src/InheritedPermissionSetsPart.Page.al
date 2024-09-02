// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

page 9821 "Inherited Permission Sets Part"
{
    Caption = 'Permission Sets from Security Groups';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Access Control";
    SourceTableTemporary = true;

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
                    ToolTip = 'Specifies the ID of a permission set.';
                    Style = Unfavorable;
                    StyleExpr = PermissionSetNotFound;

                    trigger OnDrillDown()
                    var
                        PermissionSetRelation: Codeunit "Permission Set Relation";
                    begin
                        PermissionSetRelation.OpenPermissionSetPage('', Rec."Role ID", Rec."App ID", Rec.Scope);
                    end;
                }
                field(Company; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that the permission set applies to.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        PermissionSetNotFound := not AggregatePermissionSet.Get(Rec.Scope, Rec."App ID", Rec."Role ID");
    end;

    trigger OnOpenPage()
    begin
        if not IsInitializedByCaller then
            Refresh();
    end;

    [Scope('OnPrem')]
    procedure Refresh()
    var
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        SecurityGroup: Codeunit "Security Group";
    begin
        SecurityGroup.GetMembers(SecurityGroupMemberBufferToRefresh);
        SecurityGroupMemberBuffer.Copy(SecurityGroupMemberBufferToRefresh, true);
        Refresh(SecurityGroupMemberBuffer);
    end;

    [Scope('OnPrem')]
    procedure Refresh(var SecurityGroupMemberBuffer: Record "Security Group Member Buffer")
    var
        AccessControl: Record "Access Control";
        TempDummyAccessControl: Record "Access Control" temporary;
        SecurityGroup: Codeunit "Security Group";
        GroupUserSecId: Guid;
    begin
        if not SecurityGroupMemberBuffer.FindSet() then
            exit;

        TempDummyAccessControl.Copy(Rec, true);
        TempDummyAccessControl.Reset();
        TempDummyAccessControl.DeleteAll();

        repeat
            GroupUserSecId := SecurityGroup.GetGroupUserSecurityId(SecurityGroupMemberBuffer."Security Group Code");
            AccessControl.SetRange("User Security ID", GroupUserSecId);
            if AccessControl.FindSet() then
                repeat
                    if not Rec.Get(SecurityGroupMemberBuffer."User Security ID", AccessControl."Role ID", AccessControl."Company Name", AccessControl.Scope, AccessControl."App ID") then begin
                        Rec.TransferFields(AccessControl);
                        Rec."User Security ID" := SecurityGroupMemberBuffer."User Security ID";
                        Rec.Insert();
                    end;
                until AccessControl.Next() = 0;
        until SecurityGroupMemberBuffer.Next() = 0;

        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetRecordToRefresh(var SecurityGroupMemberBuffer: Record "Security Group Member Buffer")
    begin
        SecurityGroupMemberBufferToRefresh.Copy(SecurityGroupMemberBuffer, true);
    end;

    [Scope('OnPrem')]
    procedure SetInitializedByCaller()
    begin
        IsInitializedByCaller := true;
    end;

    var
        SecurityGroupMemberBufferToRefresh: Record "Security Group Member Buffer";
        PermissionSetNotFound: Boolean;
        IsInitializedByCaller: Boolean;
}

