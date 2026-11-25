// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.History;

reportextension 13919 "Posted Sales Cr.Memo" extends "Standard Sales - Credit Memo"
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

        ExportZUGFeRDDocument.CreateAndAddXMLAttachmentToRenderingPayload(Header, RenderingPayload);
    end;

#pragma warning disable AS0072
#if not CLEAN27
    [Obsolete('Event not used anymore. If you need to know whether the report is being called for ZUGFeRD Export then use IsZUGFeRDPrintProcess in Codeunit "Export ZUGFeRD Document"', '27.2')]
    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeInitializePDF(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var CreateZUGFeRDXML: Boolean)
    begin
    end;
#endif
#pragma warning restore AS0072

}