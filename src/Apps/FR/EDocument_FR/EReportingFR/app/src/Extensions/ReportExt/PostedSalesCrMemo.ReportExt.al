// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;
using Microsoft.Sales.History;

reportextension 10971 "Posted Sales Cr.Memo" extends "Standard Sales - Credit Memo"
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

        ExportFacturXFRDocument.CreateAndAddXMLAttachmentToRenderingPayload(Header, RenderingPayload);
    end;
}
