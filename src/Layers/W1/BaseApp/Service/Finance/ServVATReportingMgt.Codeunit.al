// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Service.History;
using Microsoft.Finance.VAT.Ledger;

codeunit 6470 "Serv. VAT Reporting Mgt."
{
    Permissions = TableData "Service Invoice Header" = rm,
                  TableData "Service Cr.Memo Header" = rm;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Reporting Date Mgt", 'OnUpdatePostedDocumentsOnAfterUpdateSalesInvoice', '', false, false)]
    local procedure OnUpdatePostedDocumentsOnAfterUpdateSalesInvoice(VATEntry: Record "VAT Entry"; var Updated: Boolean)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        RecordRef: RecordRef;
    begin
        if not Updated then begin
            FilterServInvoiceHeader(VATEntry, ServiceInvHeader);
            RecordRef.GetTable(ServiceInvHeader);
            Updated := UpdateVATDateFromRecordRef(RecordRef, ServiceInvHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
        end;
    end;

    local procedure FilterServInvoiceHeader(VATEntry: Record "VAT Entry"; var ServiceInvHeader: Record "Service Invoice Header")
    begin
        ServiceInvHeader.Reset();
        ServiceInvHeader.SetRange("No.", VATEntry."Document No.");
        ServiceInvHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Reporting Date Mgt", 'OnUpdatePostedDocumentsOnAfterUpdateSalesCreditMemo', '', false, false)]
    local procedure OnUpdatePostedDocumentsOnAfterUpdateSalesCreditMemo(VATEntry: Record "VAT Entry"; var Updated: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        RecordRef: RecordRef;
    begin
        if not Updated then begin
            FilterServCrMemoHeader(VATEntry, ServiceCrMemoHeader);
            RecordRef.GetTable(ServiceCrMemoHeader);
            Updated := UpdateVATDateFromRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
        end;
    end;

    local procedure FilterServCrMemoHeader(VATEntry: Record "VAT Entry"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header");
    begin
        ServiceCrMemoHeader.Reset();
        ServiceCrMemoHeader.SetRange("No.", VATEntry."Document No.");
        ServiceCrMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure UpdateVATDateFromRecordRef(var RecordRef: RecordRef; FieldId: Integer; VATDate: Date): Boolean
    var
        FieldRef: FieldRef;
    begin
        if RecordRef.FindFirst() then begin
            FieldRef := RecordRef.Field(FieldId);
            FieldRef.Value := VATDate;
            exit(true);
        end;
        exit(false);
    end;
}
