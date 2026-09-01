// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.WorkCenter;

codeunit 99001519 "Subc. Work Center Extension"
{
    [EventSubscriber(ObjectType::Table, Database::"Work Center", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteWorkCenter(var Rec: Record "Work Center"; RunTrigger: Boolean)
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        SubcontractorPrice.SetCurrentKey("Work Center No.");
        SubcontractorPrice.SetRange("Work Center No.", Rec."No.");
        if not SubcontractorPrice.IsEmpty() then
            SubcontractorPrice.DeleteAll(true);
    end;
}