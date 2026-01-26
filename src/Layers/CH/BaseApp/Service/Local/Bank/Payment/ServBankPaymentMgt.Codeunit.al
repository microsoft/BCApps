// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Service.History;

codeunit 11523 "Serv. Bank Payment Mgt."
{
    procedure PrepareEsrService(ServiceInvHeader: Record "Service Invoice Header"; var ESRSetup: Record "ESR Setup"; var EsrType: Option Default,ESR,"ESR+"; var Adr: array[8] of Text[100]; var AmtTxt: Text[30]; var CurrencyCode: Code[10]; var DocType: Text[10]; var RefNo: Text[35]; var CodingLine: Text[100])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        CHMgt: Codeunit CHMgt;
        Amt: Decimal;
    begin
        Adr[1] := ServiceInvHeader."Bill-to Name";
        Adr[2] := ServiceInvHeader."Bill-to Contact";
        Adr[3] := ServiceInvHeader."Bill-to Address";
        Adr[4] := ServiceInvHeader."Bill-to Address 2";
        Adr[5] := ServiceInvHeader."Bill-to Post Code" + ' ' + ServiceInvHeader."Bill-to City";
        CompressArray(Adr);

        ServiceInvoiceLine.SetRange("Document No.", ServiceInvHeader."No.");
        ServiceInvoiceLine.CalcSums("Amount Including VAT");
        Amt := ServiceInvoiceLine."Amount Including VAT";

        OnPrepareEsrServiceOnBeforeCompressArray(ServiceInvHeader, Adr);
        CHMgt.PrepareEsrConsolidate(
            ESRSetup, EsrType, AmtTxt, CurrencyCode, DocType, RefNo, CodingLine, ServiceInvHeader."Currency Code",
            ServiceInvHeader."Payment Method Code", ServiceInvHeader."No.", Amt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareEsrServiceOnBeforeCompressArray(var ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header"; var Adr: array[8] of Text[100])
    begin
    end;
}