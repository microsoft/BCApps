// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
codeunit 99001558 "Subc. Worksheet Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReqJnlManagement, OnOpenJnlBatchOnBeforeTemplateSelection, '', false, false)]
    local procedure OnOpenJnlBatchOnBeforeTemplateSelection(var RequisitionWkshName: Record "Requisition Wksh. Name"; var ReqWorksheetTemplateTypeList: List of [Enum Microsoft.Inventory.Requisition."Req. Worksheet Template Type"])
#if not CLEAN29
    var
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
        ReqWorksheetTemplateTypeList.Add(Enum::"Req. Worksheet Template Type"::Subcontracting);
    end;
}