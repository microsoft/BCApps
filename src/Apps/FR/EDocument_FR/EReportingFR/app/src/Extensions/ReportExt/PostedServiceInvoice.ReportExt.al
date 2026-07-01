// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Service.History;

reportextension 10972 "Posted Service Invoice" extends "Service - Invoice"
{
    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        AddXMLAttachmentForFacturXFRExport(RenderingPayload);
    end;

    local procedure AddXMLAttachmentForFacturXFRExport(var RenderingPayload: JsonObject)
    var
        ExportFacturXFRDocument: Codeunit "Export Factur-X Document";
    begin
        if CurrReport.TargetFormat() <> ReportFormat::PDF then
            exit;

        if not ExportFacturXFRDocument.IsFacturXFRPrintProcess() then
            exit;

        ExportFacturXFRDocument.CreateAndAddXMLAttachmentToRenderingPayload("Service Invoice Header", RenderingPayload);
    end;
}
