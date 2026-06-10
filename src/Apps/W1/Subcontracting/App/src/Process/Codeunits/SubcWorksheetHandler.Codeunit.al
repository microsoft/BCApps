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
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#endif
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;

#endif
        ReqWorksheetTemplateTypeList.Add(Enum::"Req. Worksheet Template Type"::Subcontracting);
    end;
}