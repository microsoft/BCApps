// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

codeunit 99001527 "Subcontracting Management Ext."
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subcontracting Management", OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor, '', false, false)]
    local procedure OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor(var SubContractorWorkCenterNo: Code[20])
    var
        SingleInstanceDict: Codeunit "Single Instance Dictionary";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
    begin
        if SubContractorWorkCenterNo = '' then
            SubContractorWorkCenterNo := CopyStr(SingleInstanceDict.GetCode(SubcontractingMgmt.GetDictionaryKey_Sub_CreateProdOrderProcess()), 1, 20);
    end;
}