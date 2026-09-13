// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using System.Security.AccessControl;

page 6534 "Item Tracking Code Change Log"
{
    ApplicationArea = ItemTracking;
    Caption = 'Item Tracking Code Change Log';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Item Tracking Code Change Log";
    SourceTableView = sorting("Item No.", "Change Date") order(descending);
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(ChangeLogEntries)
            {
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the item whose item tracking code was changed.';
                }
                field("Change Date"; Rec."Change Date")
                {
                    ToolTip = 'Specifies the date when the item tracking code was changed.';
                }
                field("Previous Item Tracking Code"; Rec."Previous Item Tracking Code")
                {
                    ToolTip = 'Specifies the item tracking code before the change.';
                }
                field("New Item Tracking Code"; Rec."New Item Tracking Code")
                {
                    ToolTip = 'Specifies the item tracking code after the change.';
                }
                field(ChangedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Changed At';
                    ToolTip = 'Specifies the date and time when the item tracking code was changed.';
                }
                field(ChangedBy; ChangedByUserName)
                {
                    Caption = 'Changed By';
                    Editable = false;
                    ToolTip = 'Specifies the user who changed the item tracking code.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateChangedByUserName();
    end;

    local procedure UpdateChangedByUserName()
    var
        User: Record User;
    begin
        ChangedByUserName := Format(Rec.SystemCreatedBy);
        if User.ReadPermission() then
            if User.Get(Rec.SystemCreatedBy) then
                ChangedByUserName := User."User Name";
    end;

    var
        ChangedByUserName: Text;
}
