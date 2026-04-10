// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;

codeunit 902 "PostedAssemblyLines-Delete"
{
    Permissions = TableData "Posted Assembly Line" = d;

    trigger OnRun()
    begin
    end;

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MoveEntries: Codeunit MoveEntries;

    procedure DeleteLines(PostedAssemblyHeader: Record "Posted Assembly Header")
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        PostedAssemblyLine.SetCurrentKey("Document No.");
        PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
        if PostedAssemblyLine.Find('-') then
            repeat
                PostedAssemblyLine.Delete(true);
            until PostedAssemblyLine.Next() = 0;
        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Posted Assembly Line", 0, PostedAssemblyHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Posted Assembly Header", PostedAssemblyHeader."No.");
    end;
}

