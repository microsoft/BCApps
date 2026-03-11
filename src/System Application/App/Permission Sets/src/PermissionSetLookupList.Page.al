// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

/// <summary>
/// Look up page for selecting a permission set from Tenant Permission Set or Metadata Permission Set.
/// </summary>
page 9878 "Permission Set Lookup List"
{
    Caption = 'Permission Set Lookup';
    Editable = false;
    PageType = List;
    SourceTable = "PermissionSet Buffer";
    SourceTableView = sorting(Scope, "Role ID", "App ID")
                      order(ascending);

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
                    ToolTip = 'Specifies a permission set that defines the role.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the permission set.';
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = All;
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of the extension that provides the permission set.';
                }
                field(Scope; Rec.Scope)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the permission set is specific to your tenant or generally available in the system.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PermissionSetRelationImpl: Codeunit "Permission Set Relation Impl.";
    begin
        PermissionSetRelationImpl.GetPermissionSets(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SelectedRecord := Rec;
    end;

    var
        SelectedRecord: Record "PermissionSet Buffer";

    internal procedure GetSelectedRecord(var CurrSelectedRecord: Record "PermissionSet Buffer")
    begin
        CurrSelectedRecord := SelectedRecord;
    end;

    internal procedure GetSelectedRecords(var CurrSelectedRecords: Record "PermissionSet Buffer")
    begin
        Clear(CurrSelectedRecords);
        CurrPage.SetSelectionFilter(Rec);

        if not Rec.FindSet() then
            exit;

        repeat
            CurrSelectedRecords.Copy(Rec);
            CurrSelectedRecords.Insert();
        until Rec.Next() = 0;
    end;
}
