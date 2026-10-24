// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.WorkCenter;

codeunit 20519 "Subc. Work Center Extension"
{
    [EventSubscriber(ObjectType::Table, Database::"Work Center", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyWorkCenter(var Rec: Record "Work Center"; var xRec: Record "Work Center"; RunTrigger: Boolean)
    var
        SubcFeatureTelemetry: Codeunit "Subc. Feature Telemetry";
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        if (Rec."Subcontractor No." = '') or (Rec."Subcontractor No." = xRec."Subcontractor No.") then
            exit;

        SubcFeatureTelemetry.LogFeatureUptakeSetup();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteWorkCenter(var Rec: Record "Work Center"; RunTrigger: Boolean)
    var
        SubcontractorPrice: Record "Subcontractor Price";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        SubcontractorPrice.DeletePricesForWorkCenter(Rec."No.");
    end;
}
