// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Intrastat;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 10789 "Service Posting Subscr. ES"
{
    var
#if not CLEAN27
        ServPostingJournalsMgt: Codeunit "Serv-Posting Journals Mgt.";
#endif
        CannotCreateCarteraDocErr: Label 'You do not have permissions to create Documents in Cartera.\Please, change the Payment Method.';
        Text1100000: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        Text1100001: Label 'The posting process has been cancelled by the user.';
        Text1100002: Label 'Corrective Invoice';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostWithLines', '', true, true)]
    local procedure OnAfterPostWithLines(var PassedServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    var
        ServSIIManagement: Codeunit "Serv. SII Management";
    begin
        ServSIIManagement.OnAfterPostServiceDoc(PassedServiceHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnCheckAndSetConstantsOnBeforeSetPostingOptions', '', true, true)]
    local procedure OnCheckAndSetConstantsOnBeforeSetPostingOptions(var ServiceHeader: Record "Service Header"; Invoice: Boolean; Ship: Boolean)
    var
        TransportMethod: Record "Transport Method";
        PaymentTerms: Record "Payment Terms";
    begin
        if Invoice and (ServiceHeader."Document Type" <> ServiceHeader."Document Type"::"Credit Memo") then begin
            PaymentTerms.Get(ServiceHeader."Payment Terms Code");
            PaymentTerms.VerifyMaxNoDaysTillDueDate(ServiceHeader."Due Date", ServiceHeader."Document Date", ServiceHeader.FieldCaption(ServiceHeader."Due Date"));
        end;

        if TransportMethod.Get(ServiceHeader."Transport Method") and TransportMethod."Port/Airport" then
            ServiceHeader.TestField(ServiceHeader."Exit Point");

        if (Ship or Invoice) and (ServiceHeader."Document Type" <> ServiceHeader."Document Type"::"Credit Memo") then begin
            ServiceHeader.TestField(ServiceHeader."Payment Method Code");
            ServiceHeader.TestField(ServiceHeader."Payment Terms Code");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnValidatePostingAndDocumentDateOnAfterValidateDocumentDate', '', true, true)]
    local procedure OnValidatePostingAndDocumentDateOnAfterValidateDocumentDate(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.ValidatePaymentTerms();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnPostDocumentLinesOnAfterPostSalesAndVAT', '', true, true)]
    local procedure OnPostDocumentLinesOnAfterPostSalesAndVAT(var ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var Window: Dialog; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Text[35]; Invoice: Boolean)
    begin
        CreateBills(ServiceHeader, TotalServiceLine, Window, GenJnlLineDocNo, GenJnlLineExtDocNo, Invoice);
    end;

    local procedure CreateBills(ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var Window: Dialog; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; Invoice: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PaymentMethod: Record "Payment Method";
        CarteraSetup: Record "Cartera Setup";
        SourceCodeSetup: Record "Source Code Setup";
        ServInvoiceSplitPayment: Codeunit "Serv. Invoice-Split Payment";
    begin
        CustLedgEntry.Find('+');
        if PaymentMethod.Get(ServiceHeader."Payment Method Code") then
            if (PaymentMethod."Create Bills" or PaymentMethod."Invoices to Cartera") and
               (not CarteraSetup.ReadPermission) and Invoice
            then
                Error(CannotCreateCarteraDocErr);
        OnCreateBillsOnBeforeSplitServiceInv(ServiceHeader, CustLedgEntry, TotalServiceLine);
#if not CLEAN27
        ServPostingJournalsMgt.RunOnCreateBillsOnBeforeSplitServiceInv(ServiceHeader, CustLedgEntry, TotalServiceLine);
#endif
        SourceCodeSetup.Get();
        if (ServiceHeader."Bal. Account No." = '') and (ServiceHeader."Document Type" <> ServiceHeader."Document Type"::"Credit Memo") and CarteraSetup.ReadPermission then
            ServInvoiceSplitPayment.SplitServiceInvoice(
              ServiceHeader, CustLedgEntry, Window, SourceCodeSetup."Service Management", GenJnlLineExtDocNo, GenJnlLineDocNo,
              -(TotalServiceLine."Amount Including VAT" - TotalServiceLine.Amount));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBillsOnBeforeSplitServiceInv(ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var TotalServiceLine: Record "Service Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterGetAndCheckCustomer', '', true, true)]
    local procedure OnAfterGetAndCheckCustomer(var ServiceHeader: Record "Service Header")
    begin
        TestSalesEfects(ServiceHeader);
    end;

    local procedure TestSalesEfects(ServiceHeader: Record "Service Header")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ShowError: Boolean;
        Text1100000: Label 'At least one document of %1 No. %2 is closed or in a Bill Group.';
        Text1100001: Label 'This will avoid the document to be settled.\';
        Text1100002: Label 'The posting process of %3 No. %4 will not settle any document.\';
        Text1100003: Label 'Due this customer is using Apply to Oldest Application Method, please remove the lines for the Bill Group before posting.';
    begin
        ShowError := false;
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then begin
            CustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
            CustLedgEntry.SetFilter("Document Type", '%1|%2', CustLedgEntry."Document Type"::Invoice,
              CustLedgEntry."Document Type"::Bill);
            CustLedgEntry.SetFilter("Document Situation", '<>%1', CustLedgEntry."Document Situation"::" ");
            CustLedgEntry.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
            CustLedgEntry.SetRange(Open, true);

            if CustLedgEntry.Find('-') then
                repeat
                    if CustLedgEntry."Document Situation" <> CustLedgEntry."Document Situation"::Cartera then
                        if not ((CustLedgEntry."Document Situation" in
                                 [CustLedgEntry."Document Situation"::"Closed Documents",
                                  CustLedgEntry."Document Situation"::"Closed BG/PO"]) and
                                (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Rejected))
                        then
                            ShowError := true;
                until CustLedgEntry.Next() = 0;

            if ShowError then
                Error(Text1100000 +
                  Text1100001 +
                  Text1100002 +
                  Text1100003,
                  Format(CustLedgEntry."Document Type"),
                  Format(CustLedgEntry."Document No."),
                  Format(ServiceHeader."Document Type"),
                  Format(ServiceHeader."No."));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeInvoiceDocumentOnBeforeServiceInvoiceHeaderInsert', '', true, true)]
    local procedure OnFinalizeInvoiceDocumentOnBeforeServiceInvoiceHeaderInsert(var ServiceInvoiceHeaderToInsert: Record "Service Invoice Header"; var TempServiceInvoiceHeader: Record "Service Invoice Header" temporary; var TempServiceHeader: Record "Service Header" temporary)
    begin
        ServiceInvoiceHeaderToInsert.SetSIIFirstSummaryDocNo(ServiceInvoiceHeaderToInsert.GetSIIFirstSummaryDocNo());
        ServiceInvoiceHeaderToInsert.SetSIILastSummaryDocNo(ServiceInvoiceHeaderToInsert.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeCrMemoDocumentOnBeforeServiceCreditMemoHeaderInsert', '', true, true)]
    local procedure OnFinalizeCrMemoDocumentOnBeforeServiceCreditMemoHeaderInsert(var ServiceCrMemoHeaderToInsert: Record "Service Cr.Memo Header"; var TempServiceCrMemoHeader: Record "Service Cr.Memo Header" temporary; var TempServiceHeader: Record "Service Header" temporary)
    begin
        ServiceCrMemoHeaderToInsert.SetSIIFirstSummaryDocNo(ServiceCrMemoHeaderToInsert.GetSIIFirstSummaryDocNo());
        ServiceCrMemoHeaderToInsert.SetSIILastSummaryDocNo(ServiceCrMemoHeaderToInsert.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnGetAndCheckCustomerOnAfterCheckBlocked', '', true, true)]
    local procedure OnGetAndCheckCustomerOnAfterCheckBlocked(var ServiceHeader: Record "Service Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then begin
            SalesSetup.Get();
            if SalesSetup."Correct. Doc. No. Mandatory" then
                ServiceHeader.TestField(ServiceHeader."Corrected Invoice No.")
            else
                if ServiceHeader."Corrected Invoice No." = '' then
                    if not Confirm(Text1100000, false) then
                        Error(Text1100001);
            if (ServiceHeader."Corrected Invoice No." <> '') and (ServiceHeader."Posting Description" = '') then
                ServiceHeader."Posting Description" := Format(Text1100002) + ' ' + ServiceHeader."No."
        end;
    end;
}