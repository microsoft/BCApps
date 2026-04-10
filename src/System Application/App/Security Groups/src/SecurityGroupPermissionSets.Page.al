// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Security.User;

/// <summary>
/// View and edit the permission sets associated with a security group.
/// </summary>
page 9868 "Security Group Permission Sets"
{
    DataCaptionExpression = PageCaptionExpression;
    PageType = List;
    SourceTable = "Access Control";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Role ID"; Rec."Role ID")
                {
                    Caption = 'Permission Set';
                    ApplicationArea = All;
                    Editable = true;
                    NotBlank = true;
                    ToolTip = 'Specifies a permission set that defines the role.';
                    Lookup = true;
                    LookupPageId = "Lookup Permission Set";

                    trigger OnAfterLookup(Selected: RecordRef)
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                    begin
                        AggregatePermissionSet.Get(Selected.RecordId);
                        UpdateAccessControlFields(AggregatePermissionSet);
                    end;

                    trigger OnValidate()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                    begin
                        AggregatePermissionSet.SetRange("Role ID", Rec."Role ID");
                        if AggregatePermissionSet.Count() = 1 then begin
                            AggregatePermissionSet.FindFirst();
                            UpdateAccessControlFields(AggregatePermissionSet);
                        end;
                    end;
                }
                field("Role Name"; Rec."Role Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the permission set.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company name for the permission set.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectPermissionSets)
            {
                ApplicationArea = All;
                Caption = 'Add multiple';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more permission sets.';

                trigger OnAction()
                var
                    TempAggregatePermissionSet: Record "Aggregate Permission Set" temporary;
                    PermissionSetRelation: Codeunit "Permission Set Relation";
                    UserPermissions: Codeunit "User Permissions";
                begin
                    if not PermissionSetRelation.LookupPermissionSet(true, TempAggregatePermissionSet) then
                        exit;

                    UserPermissions.AssignPermissionSets(Rec."User Security ID", '', TempAggregatePermissionSet);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';
                ShowAs = SplitButton;

                actionref(SelectPermissionSets_Promoted; SelectPermissionSets)
                {
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."Role ID" <> '' then
            Session.LogAuditMessage(StrSubstNo(PermissionSetAddedToSecurityGroupLbl, Rec."Role ID", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 2, 0);
        exit(Rec."Role ID" <> '');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField("Role ID");
    end;

    internal procedure SetGroupCode(GroupCode: Code[20])
    begin
        PageCaptionExpression := GroupCode;
    end;

    local procedure UpdateAccessControlFields(AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        Rec.Scope := AggregatePermissionSet.Scope;
        Rec."App ID" := AggregatePermissionSet."App ID";
        Rec."Role Name" := AggregatePermissionSet.Name;
    end;

    var
        PageCaptionExpression: Text;
        PermissionSetAddedToSecurityGroupLbl: Label 'The permission set %1 has been added to the security group by UserSecurityId %2.', Locked = true;
}

