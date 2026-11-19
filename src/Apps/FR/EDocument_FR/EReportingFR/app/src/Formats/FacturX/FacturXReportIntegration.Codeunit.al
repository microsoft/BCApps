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

    procedure SetServiceContext(SourceRecordId: RecordId; ServiceCode: Code[20])
    begin
        ExportRecordId := SourceRecordId;
        ExportServiceCode := ServiceCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export Factur-X Document", OnGetEDocumentService, '', false, false)]
    local procedure GetEDocumentService(SourceRecordId: RecordId; var ServiceCode: Code[20])
    begin
        if SourceRecordId <> ExportRecordId then
            exit;
        if (ServiceCode <> '') and (ServiceCode <> ExportServiceCode) then
            Error(AmbiguousServiceErr);
        ServiceCode := ExportServiceCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export Factur-X Document", OnIsFacturXFRPrintProcess, '', false, false)]
    local procedure EnableOnIsFacturXFRPrintProcess(var Result: Boolean)
    begin
        Result := true;
    end;

    var
        ExportRecordId: RecordId;
        ExportServiceCode: Code[20];
        AmbiguousServiceErr: Label 'More than one E-Document service is active for this Factur-X export.';
}
