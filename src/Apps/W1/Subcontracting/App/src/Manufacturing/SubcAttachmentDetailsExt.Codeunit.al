// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Attachment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;

codeunit 20578 "Subc. Attachment Details Ext."
{
    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", OnAfterOpenForRecRef, '', false, false)]
    local procedure OnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FlowFieldsEditable: Boolean; var PurchaseDocumentFlow: Boolean)
    begin
        if RecRef.Number in [Database::"Routing Header", Database::"Prod. Order Line"] then
            PurchaseDocumentFlow := true;
        if RecRef.Number = Database::"Prod. Order Line" then
            FlowFieldsEditable := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterIsFlowFieldsEditable', '', false, false)]
    local procedure OnAfterIsFlowFieldsEditable(TableNo: Integer; var Editable: Boolean)
    begin
        if TableNo = Database::"Prod. Order Line" then
            Editable := false;
    end;
}