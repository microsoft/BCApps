// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

codeunit 20568 "Subc. Routing Line Ext."
{
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Routing Line-Copy Lines", OnCopyRountingOnAfterRoutingLineInsert, '', false, false)]
    local procedure OnCopyRountingOnAfterRoutingLineInsert(var RoutingLineTo: Record "Routing Line"; var RoutingLineFrom: Record "Routing Line")
    var
        FromRoutingComment: Record "Subc. Routing Comment Line";
        ToRoutingComment: Record "Subc. Routing Comment Line";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        FromRoutingComment.SetRange("Routing No.", RoutingLineFrom."Routing No.");
        FromRoutingComment.SetRange("Version Code", RoutingLineFrom."Version Code");
        FromRoutingComment.SetRange("Operation No.", RoutingLineFrom."Operation No.");
        if FromRoutingComment.FindSet() then
            repeat
                ToRoutingComment := FromRoutingComment;
                ToRoutingComment."Routing No." := RoutingLineTo."Routing No.";
                ToRoutingComment."Version Code" := RoutingLineTo."Version Code";
                ToRoutingComment."Operation No." := RoutingLineTo."Operation No.";
                ToRoutingComment.Insert();
            until FromRoutingComment.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Line", OnAfterDeleteRelations, '', false, false)]
    local procedure OnAfterDeleteRoutingLineRelations(RoutingLine: Record "Routing Line")
    var
        RoutingComment: Record "Subc. Routing Comment Line";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if RoutingLine.IsTemporary() then
            exit;

        RoutingComment.SetRange("Routing No.", RoutingLine."Routing No.");
        RoutingComment.SetRange("Version Code", RoutingLine."Version Code");
        RoutingComment.SetRange("Operation No.", RoutingLine."Operation No.");
        RoutingComment.DeleteAll();
    end;
}