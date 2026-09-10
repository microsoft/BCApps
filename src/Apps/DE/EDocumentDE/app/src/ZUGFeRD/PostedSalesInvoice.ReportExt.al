// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Sales.History;
reportextension 13918 "Posted Sales Invoice" extends "Standard Sales - Invoice"
{
    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        AddXMLAttachmentforZUGFeRDExport(RenderingPayload);
    end;

    local procedure AddXMLAttachmentforZUGFeRDExport(var RenderingPayload: JsonObject)
    var
        ExportZUGFeRDDocument: Codeunit "Export ZUGFeRD Document";
    begin
        if CurrReport.TargetFormat() <> ReportFormat::PDF then
            exit;

        if not ExportZUGFeRDDocument.IsZUGFeRDPrintProcess() then
            exit;

        ExportZUGFeRDDocument.CreateAndAddXMLAttachmentToRenderingPayload(Header, RenderingPayload);
    end;

#pragma warning disable AS0072 
#pragma warning restore AS0072

}