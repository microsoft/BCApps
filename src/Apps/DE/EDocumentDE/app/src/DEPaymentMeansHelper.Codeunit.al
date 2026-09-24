// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 11043 "DE Payment Means Helper"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BankAccountNotFoundErr: Label 'Customer bank account %1 on mandate %2 does not exist.', Comment = '%1 = Bank Account Code, %2 = Mandate ID';
        IBANMissingErr: Label 'Customer bank account %1 on mandate %2 has no IBAN. Set up the IBAN before releasing the document.', Comment = '%1 = Bank Account Code, %2 = Mandate ID';
        MandateIDMissingErr: Label 'Direct debit mandate ID is missing on the document. Set it in the Payment tab before releasing.';
        MandateNotFoundErr: Label 'SEPA Direct Debit Mandate %1 does not exist.', Comment = '%1 = Mandate ID';
        SEPADDOnCrMemoErr: Label 'Payment means code %1 (SEPA direct debit) cannot be used on a credit memo or return order. Use a credit transfer code (30 or 58) instead.', Comment = '%1 = UNCL4461 payment means code';
        ShowCustomerBankAccountLbl: Label 'Show Customer Bank Account';
        UnsupportedPaymentMeansCodeErr: Label 'Payment means code %1 is not supported for German electronic documents. Use a credit transfer code (30 or 58) or a SEPA direct debit code (49 or 59), or install an extension that supplies the data that code requires.', Comment = '%1 = UNCL4461 payment means code';

    /// <summary>
    /// Returns the UNCL4461 payment means code for the given Payment Method Code.
    /// Falls back to '58' (SEPA Credit Transfer) if no code is configured.
    /// </summary>
    /// <param name="PaymentMethodCode">The Payment Method Code taken from the source document header.</param>
    /// <returns>The payment means code set up on the payment method, or '58' when none is set up.</returns>
    procedure GetPaymentMeansCode(PaymentMethodCode: Code[10]): Code[3]
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethodCode <> '' then
            if PaymentMethod.Get(PaymentMethodCode) then
                if PaymentMethod."Payment Means Code" <> '' then
                    exit(PaymentMethod."Payment Means Code");
        exit('58');
    end;

    /// <summary>
    /// Returns true when the given UNCL4461 payment means code is a SEPA direct debit code (49 or 59).
    /// Direct debit requires the BG-19 mandate data (BT-89, BT-90, BT-91) in the exported document.
    /// </summary>
    /// <param name="PaymentMeansCode">The UNCL4461 payment means code to classify.</param>
    /// <returns>True when the code is 49 or 59, otherwise false.</returns>
    procedure IsDirectDebit(PaymentMeansCode: Code[3]): Boolean
    begin
        exit(PaymentMeansCode in ['49', '59']);
    end;

    /// <summary>
    /// Returns true when the given UNCL4461 payment means code is a credit transfer code (30 or 58).
    /// Credit transfer only requires the payee account (BT-84) in the exported document.
    /// </summary>
    /// <param name="PaymentMeansCode">The UNCL4461 payment means code to classify.</param>
    /// <returns>True when the code is 30 or 58, otherwise false.</returns>
    procedure IsCreditTransfer(PaymentMeansCode: Code[3]): Boolean
    begin
        exit(PaymentMeansCode in ['30', '58']);
    end;

    /// <summary>
    /// Returns the SEPA Creditor Identifier from the company bank account.
    /// Used for SEPA Direct Debit payment means (49/59) in the SellerTradeParty/AccountingSupplierParty.
    /// </summary>
    /// <param name="CompanyBankAccountCode">The Company Bank Account Code taken from the source document header.</param>
    /// <returns>The Creditor No. of that bank account, or an empty string when no bank account is given or found.</returns>
    procedure GetCreditorNo(CompanyBankAccountCode: Code[20]): Code[35]
    var
        BankAccount: Record "Bank Account";
    begin
        if CompanyBankAccountCode <> '' then begin
            BankAccount.SetLoadFields(BankAccount."Creditor No.");
            if BankAccount.Get(CompanyBankAccountCode) then
                exit(BankAccount."Creditor No.");
        end;
        exit('');
    end;

    /// <summary>
    /// Validates that all required payment data is available for the given document before export.
    /// Called from XRechnungFormat.Check() and ZUGFeRDFormat.Check().
    /// Covers SEPA direct debit mandate completeness, and rejects payment means codes for which
    /// neither this app nor a subscribing extension supplies the required document data.
    /// </summary>
    /// <param name="SourceDocumentHeader">The source document header to check. Sales and service headers and
    /// their posted invoice and credit memo tables are checked, any other table is skipped.</param>
    procedure CheckPaymentDataAvailable(SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DirectDebitMandateIDFieldRef: FieldRef;
        PaymentMethodCodeFieldRef: FieldRef;
        PaymentMeansCode: Code[3];
        PaymentMethodCode: Code[10];
        DirectDebitMandateID: Code[35];
    begin
        if not (SourceDocumentHeader.Number() in
            [Database::"Sales Header",
             Database::"Sales Invoice Header",
             Database::"Sales Cr.Memo Header",
             Database::"Service Header",
             Database::"Service Invoice Header",
             Database::"Service Cr.Memo Header"])
        then
            exit;

        PaymentMethodCodeFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Payment Method Code"));
        PaymentMethodCode := PaymentMethodCodeFieldRef.Value();
        // Use the effective code, so that a document without a configured code keeps the '58' fallback.
        PaymentMeansCode := GetPaymentMeansCode(PaymentMethodCode);

        case true of
            IsCreditTransfer(PaymentMeansCode):
                exit;
            IsDirectDebit(PaymentMeansCode):
                begin
                    // A credit document never carries a mandate. This has to stay in front of the mandate
                    // FieldRef below, because the posted credit memo tables have no Direct Debit Mandate ID field.
                    if IsCreditDocument(SourceDocumentHeader) then
                        Error(SEPADDOnCrMemoErr, PaymentMeansCode);
                    DirectDebitMandateIDFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Direct Debit Mandate ID"));
                    DirectDebitMandateID := DirectDebitMandateIDFieldRef.Value();
                    if DirectDebitMandateID = '' then
                        Error(MandateIDMissingErr);
                    CheckMandateData(DirectDebitMandateID);
                end;
            else
                CheckPaymentMeansCodeSupported(PaymentMeansCode, SourceDocumentHeader);
        end;
    end;

    /// <summary>
    /// Returns true when the given source document header is a credit document. For the posted credit memo
    /// tables that follows from the table, for an unposted sales or service header from the document type.
    /// </summary>
    /// <param name="SourceDocumentHeader">The source document header being checked.</param>
    /// <returns>True for a credit memo and for a sales return order, otherwise false.</returns>
    local procedure IsCreditDocument(SourceDocumentHeader: RecordRef): Boolean
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
    begin
        case SourceDocumentHeader.Number() of
            Database::"Sales Cr.Memo Header",
            Database::"Service Cr.Memo Header":
                exit(true);
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    exit(SalesHeader.IsCreditDocType());
                end;
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    exit(ServiceHeader.IsCreditDocType());
                end;
        end;
        exit(false);
    end;

    local procedure CheckMandateData(DirectDebitMandateID: Code[35])
    var
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        IBANMissingErrorInfo: ErrorInfo;
    begin
        SEPADirectDebitMandate.SetLoadFields(SEPADirectDebitMandate."Customer No.", SEPADirectDebitMandate."Customer Bank Account Code");
        if not SEPADirectDebitMandate.Get(DirectDebitMandateID) then
            Error(MandateNotFoundErr, DirectDebitMandateID);
        CustomerBankAccount.SetLoadFields(CustomerBankAccount.IBAN);
        if not CustomerBankAccount.Get(SEPADirectDebitMandate."Customer No.", SEPADirectDebitMandate."Customer Bank Account Code") then
            Error(BankAccountNotFoundErr, SEPADirectDebitMandate."Customer Bank Account Code", DirectDebitMandateID);
        if CustomerBankAccount.IBAN = '' then begin
            // The bank account exists, so the user can be taken straight to the record that needs the IBAN.
            IBANMissingErrorInfo.Message := StrSubstNo(IBANMissingErr, SEPADirectDebitMandate."Customer Bank Account Code", DirectDebitMandateID);
            IBANMissingErrorInfo.RecordId := CustomerBankAccount.RecordId();
            IBANMissingErrorInfo.PageNo := Page::"Customer Bank Account Card";
            IBANMissingErrorInfo.AddNavigationAction(ShowCustomerBankAccountLbl);
            Error(IBANMissingErrorInfo);
        end;
    end;

    local procedure CheckPaymentMeansCodeSupported(PaymentMeansCode: Code[3]; SourceDocumentHeader: RecordRef)
    var
        IsHandled: Boolean;
    begin
        // The export only builds the dependent data for credit transfer and SEPA direct debit. Any other
        // code would produce a payment means block without the group that code requires, so it is rejected
        // unless an extension subscribes and supplies that data through the OnInsertPaymentMeans events.
        IsHandled := false;
        OnBeforeCheckPaymentMeansCodeSupported(PaymentMeansCode, SourceDocumentHeader, IsHandled);
        if IsHandled then
            exit;
        Error(UnsupportedPaymentMeansCodeErr, PaymentMeansCode);
    end;

    /// <summary>
    /// Fires before an unsupported payment means code is rejected during Check().
    /// Subscribe and set IsHandled to true when the extension supplies the document data that the
    /// given code requires, for example through OnInsertPaymentMeansOnBeforeAddToRoot.
    /// </summary>
    /// <param name="PaymentMeansCode">The UNCL4461 payment means code configured on the payment method.</param>
    /// <param name="SourceDocumentHeader">The source document header being checked.</param>
    /// <param name="IsHandled">Set to true to accept the code and skip the error.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentMeansCodeSupported(PaymentMeansCode: Code[3]; SourceDocumentHeader: RecordRef; var IsHandled: Boolean)
    begin
    end;
}
