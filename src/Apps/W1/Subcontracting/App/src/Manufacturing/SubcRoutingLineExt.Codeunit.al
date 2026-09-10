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