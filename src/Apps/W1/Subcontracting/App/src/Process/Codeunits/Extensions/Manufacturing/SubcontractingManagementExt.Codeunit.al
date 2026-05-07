// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

codeunit 99001527 "Subcontracting Management Ext."
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subc. Purchase Order Creator", OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor, '', false, false)]
    local procedure OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor(var SubContractorWorkCenterNo: Code[20])
    var
        SubcSessionState: Codeunit "Subc. Session State";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if SubContractorWorkCenterNo = '' then
            SubContractorWorkCenterNo := CopyStr(SubcSessionState.GetCode(SubcontractingManagement.GetKeyCreateProdOrderProcess()), 1, 20);
    end;
}