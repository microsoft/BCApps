// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Service.History;

reportextension 13920 "Posted Service Invoice" extends "Service - Invoice"
{

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        AddXMLAttachmentforZUGFeRDExport(RenderingPayload);
    end;

    local procedure AddXMLAttachmentforZUGFeRDExport(var RenderingPayload: JsonObject)
    var
        EDocumentService: Record "E-Document Service";
        ExportZUGFeRDDocument: Codeunit "Export ZUGFeRD Document";
        ZUGFeRDExportContext: Codeunit "ZUGFeRD Export Context";
    begin
        if CurrReport.TargetFormat() <> ReportFormat::PDF then
            exit;

        if not ExportZUGFeRDDocument.IsZUGFeRDPrintProcess() then
            exit;

        // Only push a real service: providing one suppresses the legacy FindLast fallback.
        if ZUGFeRDExportContext.HasContext() then begin
            ZUGFeRDExportContext.GetEDocumentService(EDocumentService);
            if EDocumentService.Code <> '' then
                ExportZUGFeRDDocument.SetEDocumentService(EDocumentService);
        end;

        ExportZUGFeRDDocument.CreateAndAddXMLAttachmentToRenderingPayload("Service Invoice Header", RenderingPayload);
    end;
}
