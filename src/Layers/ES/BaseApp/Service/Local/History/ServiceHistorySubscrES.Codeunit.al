namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
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
          (ServiceInvoiceHeader."Ship-to Country/Region Code" <> xServiceInvoiceHeader."Ship-to Country/Region Code") or
          (ServiceInvoiceHeader."Operation Description" <> xServiceInvoiceHeader."Operation Description") or
          (ServiceInvoiceHeader."Operation Description 2" <> xServiceInvoiceHeader."Operation Description 2") or
          (ServiceInvoiceHeader."Special Scheme Code" <> xServiceInvoiceHeader."Special Scheme Code") or
          (ServiceInvoiceHeader."Invoice Type" <> xServiceInvoiceHeader."Invoice Type") or
          (ServiceInvoiceHeader."ID Type" <> xServiceInvoiceHeader."ID Type") or
          (ServiceInvoiceHeader."Succeeded Company Name" <> xServiceInvoiceHeader."Succeeded Company Name") or
          (ServiceInvoiceHeader."Succeeded VAT Registration No." <> xServiceInvoiceHeader."Succeeded VAT Registration No.") or
          (ServiceInvoiceHeader."Issued By Third Party" <> xServiceInvoiceHeader."Issued By Third Party") or
          (ServiceInvoiceHeader.GetSIIFirstSummaryDocNo() <> xServiceInvoiceHeader.GetSIIFirstSummaryDocNo()) or
          (ServiceInvoiceHeader.GetSIILastSummaryDocNo() <> xServiceInvoiceHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', true, true)]
    local procedure OnOnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."Country/Region Code" := ServiceInvoiceHeaderRec."Country/Region Code";
        ServiceInvoiceHeader."Bill-to Country/Region Code" := ServiceInvoiceHeaderRec."Bill-to Country/Region Code";
        ServiceInvoiceHeader."Ship-to Country/Region Code" := ServiceInvoiceHeaderRec."Ship-to Country/Region Code";
        ServiceInvoiceHeader."Operation Description" := ServiceInvoiceHeaderRec."Operation Description";
        ServiceInvoiceHeader."Operation Description 2" := ServiceInvoiceHeaderRec."Operation Description 2";
        ServiceInvoiceHeader."Special Scheme Code" := ServiceInvoiceHeaderRec."Special Scheme Code";
        ServiceInvoiceHeader."Invoice Type" := ServiceInvoiceHeaderRec."Invoice Type";
        ServiceInvoiceHeader."ID Type" := ServiceInvoiceHeaderRec."ID Type";
        ServiceInvoiceHeader."Succeeded Company Name" := ServiceInvoiceHeaderRec."Succeeded Company Name";
        ServiceInvoiceHeader."Succeeded VAT Registration No." := ServiceInvoiceHeaderRec."Succeeded VAT Registration No.";
        ServiceInvoiceHeader."Issued By Third Party" := ServiceInvoiceHeaderRec."Issued By Third Party";
        ServiceInvoiceHeader.SetSIIFirstSummaryDocNo(ServiceInvoiceHeaderRec.GetSIIFirstSummaryDocNo());
        ServiceInvoiceHeader.SetSIILastSummaryDocNo(ServiceInvoiceHeaderRec.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnRunOnAfterServiceInvoiceHeaderEdit', '', true, true)]
    local procedure OnRunOnAfterServiceInvoiceHeaderEdit(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        UpdateSIIDocUploadState(ServiceInvoiceHeader);
    end;

    local procedure UpdateSIIDocUploadState(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::Invoice.AsInteger(),
             ServiceInvoiceHeader."Posting Date",
             ServiceInvoiceHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignSalesInvoiceType(ServiceInvoiceHeader."Invoice Type");
        SIIDocUploadState.AssignSalesSchemeCode(ServiceInvoiceHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidateServiceSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := ServiceInvoiceHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := ServiceInvoiceHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := ServiceInvoiceHeader."Succeeded VAT Registration No.";
        SIIDocUploadState."Issued By Third Party" := ServiceInvoiceHeader."Issued By Third Party";
        SIIDocUploadState."First Summary Doc. No." := CopyStr(ServiceInvoiceHeader.GetSIIFirstSummaryDocNo(), 1, 35);
        SIIDocUploadState."Last Summary Doc. No." := CopyStr(ServiceInvoiceHeader.GetSIILastSummaryDocNo(), 1, 35);
        SIIDocUploadState.Modify();
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