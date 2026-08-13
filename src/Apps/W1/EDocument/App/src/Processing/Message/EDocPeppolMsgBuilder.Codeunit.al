// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocument.Processing.Import.Sales;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Peppol.Response;
using System.Utilities;

/// <summary>
/// Builds a PEPPOL Order Response message payload for an inbound Sales Order that was read into draft.
/// Core-hosted implementation for the "PEPPOL Order Response" message type; delegates the XML
/// construction to the PEPPOL app's pure builder, passing only primitives.
/// </summary>
codeunit 6434 "E-Doc. PEPPOL Msg. Builder" implements IEDocMessageBuilder
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure BuildMessage(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob")
    var
        EDocSalesHeader: Record "E-Document Sales Header";
        PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        BuyerOrderNo: Code[20];
        SellerName: Text[100];
        BuyerName: Text[100];
    begin
        EDocSalesHeader.GetFromEDocument(EDocument);
        PEPPOLOrderRespBuilder.Build(
            EDocSalesHeader."E-Document Entry No.",
            CopyStr(EDocSalesHeader."Buyer Order No.", 1, MaxStrLen(BuyerOrderNo)),
            CopyStr(EDocSalesHeader."Seller Company Name", 1, MaxStrLen(SellerName)),
            CopyStr(EDocSalesHeader."Buyer Company Name", 1, MaxStrLen(BuyerName)),
            ResponseTypeToCode(ResponseType),
            TempBlob);
    end;

    local procedure ResponseTypeToCode(ResponseType: Enum "E-Doc. Response Type"): Code[10]
    begin
        // UNCL4343 OrderResponseCode values used on thethis  wire.
        case ResponseType of
            "E-Doc. Response Type"::Acknowledged:
                exit('AB');
            "E-Doc. Response Type"::Accepted:
                exit('AC');
            "E-Doc. Response Type"::Rejected:
                exit('RE');
        end;
    end;
}
