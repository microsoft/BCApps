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
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if SubContractorWorkCenterNo = '' then
            SubContractorWorkCenterNo := CopyStr(SingleInstanceDictionary.GetCode(SubcontractingManagement.GetDictionaryKey_Sub_CreateProdOrderProcess()), 1, 20);
    end;
}