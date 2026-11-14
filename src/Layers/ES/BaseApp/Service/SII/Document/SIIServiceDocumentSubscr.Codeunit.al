// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;

#pragma warning disable AS0088
codeunit 7000077 "SII Service Document Subscr."
{
    Access = Internal;
    SingleInstance = true;

    var
        SIIManagement: Codeunit "SII Management";
        ServSIIManagement: Codeunit "Serv. SII Management";

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateBillToCustomerNo', '', true, true)]
    local procedure OnAfterValidateBillToCustomerNo(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var Customer: Record Customer)
    begin
        ServiceHeader.Validate(
            "ID Type",
            SIIManagement.GetSalesIDType(ServiceHeader."Bill-to Customer No.", ServiceHeader."Correction Type", ServiceHeader."Corrected Invoice No."));
        ServSIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInitRecord', '', true, true)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
        ServSIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'VAT Prod. Posting Group', true, true)]
    local procedure OnAfterValidateVATProdPostingGroup(var Rec: Record "Service Line")
    begin
        ServSIIManagement.UpdatePurchSpecialSchemeCodeInServiceine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLine', '', true, true)]
    local procedure OnAfterCopyToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Sales Invoice Type" := ServiceHeader."Invoice Type";
        GenJournalLine."Sales Cr. Memo Type" := ServiceHeader."Cr. Memo Type";
        GenJournalLine."Sales Special Scheme Code" := ServiceHeader."Special Scheme Code";
        GenJournalLine."Succeeded Company Name" := ServiceHeader."Succeeded Company Name";
        GenJournalLine."Succeeded VAT Registration No." := ServiceHeader."Succeeded VAT Registration No.";
        GenJournalLine."Issued By Third Party" := ServiceHeader."Issued By Third Party";

        ServiceHeader.SetSIIFirstSummaryDocNo(ServiceHeader.GetSIIFirstSummaryDocNo());
        ServiceHeader.SetSIILastSummaryDocNo(ServiceHeader.GetSIILastSummaryDocNo());

        GenJournalLine."Do Not Send To SII" := ServiceHeader."Do Not Send To SII";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateCorrectedInvoiceNoOnSII', '', true, false)]
    local procedure OnAfterValidateCorrectedInvoiceNo(var ServiceHeader: Record "Service Header")
    var
        SIIMgt: Codeunit "SII Management";
    begin
        ServiceHeader.Validate("ID Type", SIIMgt.GetSalesIDType(ServiceHeader."Bill-to Customer No.", ServiceHeader."Correction Type", ServiceHeader."Corrected Invoice No."));
    end;
}
