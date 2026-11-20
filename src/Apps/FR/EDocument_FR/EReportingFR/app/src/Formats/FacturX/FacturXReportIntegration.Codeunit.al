// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

codeunit 10984 "Factur-X Report Integration"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        ServiceCode: Code[20];
        XMLAttachmentAdded: Boolean;

    procedure Initialize(EDocumentServiceCode: Code[20])
    begin
        ServiceCode := EDocumentServiceCode;
        XMLAttachmentAdded := false;
    end;

    procedure HasXMLAttachment(): Boolean
    begin
        exit(XMLAttachmentAdded);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export Factur-X Document", OnGetFacturXServiceCode, '', false, false)]
    local procedure GetFacturXServiceCode(var EDocumentServiceCode: Code[20])
    begin
        EDocumentServiceCode := ServiceCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export Factur-X Document", OnAfterAddXMLAttachmentToRenderingPayload, '', false, false)]
    local procedure MarkXMLAttachmentAdded()
    begin
        XMLAttachmentAdded := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export Factur-X Document", OnIsFacturXFRPrintProcess, '', false, false)]
    local procedure EnableOnIsFacturXFRPrintProcess(var Result: Boolean)
    begin
        Result := true;
    end;
}
