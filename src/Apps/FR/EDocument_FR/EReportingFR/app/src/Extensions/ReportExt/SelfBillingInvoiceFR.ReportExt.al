// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Purchases.History;

reportextension 10976 "Self Billing Invoice FR" extends "Self Billing Invoice"
{
    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        ExportFacturXDocument: Codeunit "Export Factur-X Document";
    begin
        if CurrReport.TargetFormat() <> ReportFormat::PDF then
            exit;
        if not ExportFacturXDocument.IsFacturXFRPrintProcess() then
            exit;

        ExportFacturXDocument.CreateAndAddXMLAttachmentToRenderingPayload("Purch. Inv. Header", RenderingPayload);
    end;
}
