namespace Microsoft.Service.History;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 10762 "Service History Subscr. ES"
{

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnLookupAppliestoDocNoOnAfterSetFilters', '', true, true)]
    local procedure CreditMemoOnLookupAppliestoDocNoOnAfterSetFilters(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Bill No.", ServiceCrMemoHeader."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', true, true)]
    local procedure CreditMemoOnCalcVATAmountLinesOnBeforeInsertLine(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if ServiceCrMemoHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterCopyToVATAmountLine', '', true, true)]
    local procedure CreditMemoOnAfterCopyToVATAmountLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."EC %" := ServiceCrMemoLine."EC %";
        VATAmountLine."EC Difference" := ServiceCrMemoLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterGetVATPct', '', true, true)]
    local procedure CreditMemoOnAfterGetVATPct(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var VATPct: Decimal)
    begin
        VATPct += ServiceCrMemoLine."EC %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnLookupAppliestoDocNoOnAfterSetFilters', '', true, true)]
    local procedure InvoiceOnLookupAppliestoDocNoOnAfterSetFilters(ServiceInvoiceHeader: Record "Service Invoice Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Bill No.", CustLedgerEntry."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', true, true)]
    local procedure InvoiceOnCalcVATAmountLinesOnBeforeInsertLine(ServInvHeader: Record "Service Invoice Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if ServInvHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterCopyToVATAmountLine', '', true, true)]
    local procedure InvoiceOnAfterCopyToVATAmountLine(ServiceInvoiceLine: Record "Service Invoice Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."EC %" := ServiceInvoiceLine."EC %";
        VATAmountLine."EC Difference" := ServiceInvoiceLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterGetVATPct', '', true, true)]
    local procedure InvoiceOnAfterGetVATPct(var ServiceInvoiceLine: Record "Service Invoice Line"; var VATPct: Decimal)
    begin
        VATPct += ServiceInvoiceLine."EC %";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Service Inv. - Update", 'OnAfterRecordChanged', '', true, true)]
    local procedure OnAfterRecordChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
          (ServiceInvoiceHeader."Country/Region Code" <> xServiceInvoiceHeader."Country/Region Code") or
          (ServiceInvoiceHeader."Bill-to Country/Region Code" <> xServiceInvoiceHeader."Bill-to Country/Region Code") or
          (ServiceInvoiceHeader."Ship-to Country/Region Code" <> xServiceInvoiceHeader."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', true, true)]
    local procedure OnOnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."Country/Region Code" := ServiceInvoiceHeaderRec."Country/Region Code";
        ServiceInvoiceHeader."Bill-to Country/Region Code" := ServiceInvoiceHeaderRec."Bill-to Country/Region Code";
        ServiceInvoiceHeader."Ship-to Country/Region Code" := ServiceInvoiceHeaderRec."Ship-to Country/Region Code";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 340 Declaration", 'OnGetCustomerDataFromServiceInvoice', '', true, true)]
    local procedure OnGetCustomerDataFromServiceInvoice(VATEntry: Record "VAT Entry"; var Customer: Record Customer; var ShouldExit: Boolean);
    var
        ServiceInvHeader: Record "Service Invoice Header";
    begin
        if ServiceInvHeader.Get(VATEntry."Document No.") then begin
            Customer.Name := ServiceInvHeader."Bill-to Name";
            Customer."VAT Registration No." := ServiceInvHeader."VAT Registration No.";
            ShouldExit := true;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 340 Declaration", 'OnGetCustomerDataFromServiceCrMemo', '', true, true)]
    local procedure OnGetCustomerDataFromServiceCrMemo(VATEntry: Record "VAT Entry"; var Customer: Record Customer; var ShouldExit: Boolean);
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceCrMemoHeader.Get(VATEntry."Document No.") then begin
            Customer.Name := ServiceCrMemoHeader."Bill-to Name";
            Customer."VAT Registration No." := ServiceCrMemoHeader."VAT Registration No.";
            exit;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 340 Declaration", 'OnRecordTypeSaleOnGetOperationDate', '', true, true)]
    local procedure OnRecordTypeSaleOnGetOperationDate(VATEntry: Record "VAT Entry"; var OperationDateText: Text; var CorrInvoiceText: Text)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvHeader: Record "Service Invoice Header";
    begin
        if ServiceCrMemoHeader.Get(VATEntry."Document No.") then
            if ServiceCrMemoHeader."Corrected Invoice No." <> '' then begin
                if ServiceInvHeader.Get(ServiceCrMemoHeader."Corrected Invoice No.") then begin
                    OperationDateText := FormatDate(ServiceInvHeader."Posting Date");
                    CorrInvoiceText := Format(ServiceCrMemoHeader."Corrected Invoice No.");
                end;
            end else
                OperationDateText := FormatDate(ServiceCrMemoHeader."Posting Date");
    end;

    local procedure FormatDate(PostingDate: Date): Text[8]
    begin
        if PostingDate <> 0D then
            exit(Format(PostingDate, 8, '<Year4><Month,2><Day,2>'));
        exit('00000000');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cartera Doc.", 'OnGetDocumentDateFromServiceInvoice', '', true, true)]
    local procedure OnGetDocumentDateFromServiceInvoice(DocumentNo: Code[20]; var DocumentDate: Date)
    var
        PaymentTerms: Record "Payment Terms";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        if ServiceInvoiceHeader.Get(DocumentNo) then begin
            PaymentTerms.Get(ServiceInvoiceHeader."Payment Terms Code");
            DocumentDate := ServiceInvoiceHeader."Document Date";
        end;
    end;
}