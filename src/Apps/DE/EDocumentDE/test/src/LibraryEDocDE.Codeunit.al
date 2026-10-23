// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
#if not CLEAN30
using Microsoft.eServices.EDocument;
#endif
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Reflection;

codeunit 13925 "Library - E-Doc DE"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        CapturedPaymentMeansHeaderRecordId: RecordId;
        DefaultCoarseRoutingTxt: Label '99', Locked = true;
        SEPADirectDebitMeansCodeTok: Label '59', Locked = true;
        CapturedEDocumentServiceCode: Code[20];
        EDocumentServiceEventCount: Integer;
        OverridePartyName: Text[100];
        OverrideCustomerName: Text[100];
        OverrideActualDeliveryDate: Date;
        OverrideDeliveryCity: Text[30];
        OverrideOrderReferenceID: Text[35];
        OverrideSalesOrderID: Code[20];
        AddedDeliveryPartyName: Text[100];
        AddedDespatchDocumentID: Text[35];
        CACNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        CBCNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;

    /// <summary>
    /// Resets the OnAfterFindEDocumentService capture state. Bind this codeunit with
    /// BindSubscription before the export and unbind afterwards.
    /// </summary>
    procedure ClearCapturedEDocumentService()
    begin
        Clear(CapturedEDocumentServiceCode);
        Clear(EDocumentServiceEventCount);
    end;

    /// <summary>
    /// Returns the Code of the E-Document Service carried by the last OnAfterFindEDocumentService event.
    /// </summary>
    /// <returns>The Code of the E-Document Service carried by the last captured event.</returns>
    procedure GetCapturedEDocumentServiceCode(): Code[20]
    begin
        exit(CapturedEDocumentServiceCode);
    end;

    /// <summary>
    /// Returns how many times OnAfterFindEDocumentService was raised while bound.
    /// </summary>
    /// <returns>The number of OnAfterFindEDocumentService events captured while the subscriber was bound.</returns>
    procedure GetEDocumentServiceEventCount(): Integer
    begin
        exit(EDocumentServiceEventCount);
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", 'OnAfterFindEDocumentService', '', false, false)]
    local procedure CaptureXRechnungOnAfterFindEDocumentService(var EDocumentService: Record "E-Document Service"; EDocumentFormat: Code[20])
    begin
        CapturedEDocumentServiceCode := EDocumentService.Code;
        EDocumentServiceEventCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", 'OnAfterFindEDocumentService', '', false, false)]
    local procedure CaptureZUGFeRDOnAfterFindEDocumentService(var EDocumentService: Record "E-Document Service")
    begin
        CapturedEDocumentServiceCode := EDocumentService.Code;
        EDocumentServiceEventCount += 1;
    end;
#pragma warning restore AL0432
#endif

    /// <summary>
    /// Returns the record ID of the header carried by the last payment means event of the XRechnung or
    /// ZUGFeRD export. Bind this codeunit with BindSubscription before the export and unbind afterwards.
    /// </summary>
    /// <returns>The record ID of the header carried by the last captured payment means event.</returns>
    procedure GetCapturedPaymentMeansHeaderRecordId(): RecordId
    begin
        exit(CapturedPaymentMeansHeaderRecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertPaymentMeansOnBeforeAddToRoot, '', false, false)]
    local procedure CaptureXRechnungOnInsertPaymentMeansOnBeforeAddToRoot(var PaymentMeansElement: XmlElement; HeaderRecRef: RecordRef)
    begin
        CapturedPaymentMeansHeaderRecordId := HeaderRecRef.RecordId();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", OnInsertPaymentMethodOnBeforeAddToRoot, '', false, false)]
    local procedure CaptureZUGFeRDOnInsertPaymentMethodOnBeforeAddToRoot(var PaymentMethodElement: XmlElement; HeaderRecRef: RecordRef)
    begin
        CapturedPaymentMeansHeaderRecordId := HeaderRecRef.RecordId();
    end;

    /// <summary>
    /// Resets the values that the XRechnung buyer, delivery and order reference subscribers set or add.
    /// Bind this codeunit with BindSubscription before the export and unbind afterwards.
    /// </summary>
    procedure ClearXRechnungOverrides()
    begin
        Clear(OverridePartyName);
        Clear(OverrideCustomerName);
        Clear(OverrideActualDeliveryDate);
        Clear(OverrideDeliveryCity);
        Clear(OverrideOrderReferenceID);
        Clear(OverrideSalesOrderID);
        Clear(AddedDeliveryPartyName);
        Clear(AddedDespatchDocumentID);
    end;

    /// <summary>
    /// Sets the values that the subscribers of the XRechnung buyer, delivery and order reference events pass back to the export.
    /// </summary>
    /// <param name="PartyName">The buyer name (BT-44) to pass back to the export.</param>
    /// <param name="CustomerName">The buyer legal registration name to pass back to the export.</param>
    /// <param name="ActualDeliveryDate">The actual delivery date (BT-72) to pass back to the export.</param>
    /// <param name="DeliveryCity">The deliver-to city (BT-77) to pass back to the export.</param>
    /// <param name="OrderReferenceID">The purchase order reference (BT-13) to pass back to the export.</param>
    /// <param name="SalesOrderID">The sales order reference (BT-14) to pass back to the export.</param>
    procedure SetXRechnungValueOverrides(PartyName: Text[100]; CustomerName: Text[100]; ActualDeliveryDate: Date; DeliveryCity: Text[30]; OrderReferenceID: Text[35]; SalesOrderID: Code[20])
    begin
        OverridePartyName := PartyName;
        OverrideCustomerName := CustomerName;
        OverrideActualDeliveryDate := ActualDeliveryDate;
        OverrideDeliveryCity := DeliveryCity;
        OverrideOrderReferenceID := OrderReferenceID;
        OverrideSalesOrderID := SalesOrderID;
    end;

    /// <summary>
    /// Sets the elements that the subscribers add to the XRechnung delivery (deliver-to party, BT-70)
    /// and after the order reference (despatch advice reference, BT-16).
    /// </summary>
    /// <param name="DeliveryPartyName">The deliver-to party name to add to cac:Delivery.</param>
    /// <param name="DespatchDocumentID">The despatch advice reference to add after cac:OrderReference.</param>
    procedure SetXRechnungAddedElements(DeliveryPartyName: Text[100]; DespatchDocumentID: Text[35])
    begin
        AddedDeliveryPartyName := DeliveryPartyName;
        AddedDespatchDocumentID := DespatchDocumentID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnBeforeInsertSalesInvCustomerParty, '', false, false)]
    local procedure OverrideXRechnungOnBeforeInsertSalesInvCustomerParty(var PartyName: Text[100]; var CustomerName: Text[100])
    begin
        OverrideCustomerPartyValues(PartyName, CustomerName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnBeforeInsertSalesCrMemoCustomerParty, '', false, false)]
    local procedure OverrideXRechnungOnBeforeInsertSalesCrMemoCustomerParty(var PartyName: Text[100]; var CustomerName: Text[100])
    begin
        OverrideCustomerPartyValues(PartyName, CustomerName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnBeforeInsertSalesInvDelivery, '', false, false)]
    local procedure OverrideXRechnungOnBeforeInsertSalesInvDelivery(var ActualDeliveryDate: Date; var DeliveryAddress: Record "Standard Address")
    begin
        OverrideDeliveryValues(ActualDeliveryDate, DeliveryAddress);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnBeforeInsertSalesCrMemoDelivery, '', false, false)]
    local procedure OverrideXRechnungOnBeforeInsertSalesCrMemoDelivery(var ActualDeliveryDate: Date; var DeliveryAddress: Record "Standard Address")
    begin
        OverrideDeliveryValues(ActualDeliveryDate, DeliveryAddress);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertDeliveryOnBeforeAddSalesInvDeliveryElement, '', false, false)]
    local procedure AddXRechnungDeliveryPartyOnBeforeAddSalesInvDeliveryElement(var DeliveryElement: XmlElement)
    begin
        AddDeliveryParty(DeliveryElement);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertDeliveryOnBeforeAddSalesCrMemoDeliveryElement, '', false, false)]
    local procedure AddXRechnungDeliveryPartyOnBeforeAddSalesCrMemoDeliveryElement(var DeliveryElement: XmlElement)
    begin
        AddDeliveryParty(DeliveryElement);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertOrderReferenceOnBeforeCreateSalesInvoiceElement, '', false, false)]
    local procedure OverrideXRechnungOnInsertOrderReferenceOnBeforeCreateSalesInvoiceElement(var OrderReferenceID: Text[35]; var SalesOrderID: Code[20])
    begin
        OverrideOrderReferenceValues(OrderReferenceID, SalesOrderID);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertOrderReferenceOnBeforeCreateSalesCrMemoElement, '', false, false)]
    local procedure OverrideXRechnungOnInsertOrderReferenceOnBeforeCreateSalesCrMemoElement(var OrderReferenceID: Text[35]; var SalesOrderID: Code[20])
    begin
        OverrideOrderReferenceValues(OrderReferenceID, SalesOrderID);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertOrderReferenceOnAfterInsertSalesInvoiceElement, '', false, false)]
    local procedure AddXRechnungDespatchReferenceOnAfterInsertSalesInvoiceElement(var RootElement: XmlElement)
    begin
        AddDespatchDocumentReference(RootElement);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", OnInsertOrderReferenceOnAfterInsertSalesCrMemoElement, '', false, false)]
    local procedure AddXRechnungDespatchReferenceOnAfterInsertSalesCrMemoElement(var RootElement: XmlElement)
    begin
        AddDespatchDocumentReference(RootElement);
    end;

    local procedure OverrideCustomerPartyValues(var PartyName: Text[100]; var CustomerName: Text[100])
    begin
        if OverridePartyName <> '' then
            PartyName := OverridePartyName;
        if OverrideCustomerName <> '' then
            CustomerName := OverrideCustomerName;
    end;

    local procedure OverrideDeliveryValues(var ActualDeliveryDate: Date; var DeliveryAddress: Record "Standard Address")
    begin
        if OverrideActualDeliveryDate <> 0D then
            ActualDeliveryDate := OverrideActualDeliveryDate;
        if OverrideDeliveryCity <> '' then
            DeliveryAddress.City := OverrideDeliveryCity;
    end;

    local procedure OverrideOrderReferenceValues(var OrderReferenceID: Text[35]; var SalesOrderID: Code[20])
    begin
        if OverrideOrderReferenceID <> '' then
            OrderReferenceID := OverrideOrderReferenceID;
        if OverrideSalesOrderID <> '' then
            SalesOrderID := OverrideSalesOrderID;
    end;

    local procedure AddDeliveryParty(var DeliveryElement: XmlElement)
    var
        DeliveryPartyElement: XmlElement;
        PartyNameElement: XmlElement;
    begin
        if AddedDeliveryPartyName = '' then
            exit;
        PartyNameElement := XmlElement.Create('PartyName', CACNamespaceTxt);
        PartyNameElement.Add(XmlElement.Create('Name', CBCNamespaceTxt, AddedDeliveryPartyName));
        DeliveryPartyElement := XmlElement.Create('DeliveryParty', CACNamespaceTxt);
        DeliveryPartyElement.Add(PartyNameElement);
        DeliveryElement.Add(DeliveryPartyElement);
    end;

    local procedure AddDespatchDocumentReference(var RootElement: XmlElement)
    var
        DespatchDocumentReferenceElement: XmlElement;
    begin
        if AddedDespatchDocumentID = '' then
            exit;
        DespatchDocumentReferenceElement := XmlElement.Create('DespatchDocumentReference', CACNamespaceTxt);
        DespatchDocumentReferenceElement.Add(XmlElement.Create('ID', CBCNamespaceTxt, AddedDespatchDocumentID));
        RootElement.Add(DespatchDocumentReferenceElement);
    end;

    /// <summary>
    /// Creates a payment method with the SEPA direct debit payment means code '59'.
    /// </summary>
    /// <returns>The Code of the new payment method.</returns>
    procedure CreateDirectDebitPaymentMethod(): Code[10]
    begin
        exit(CreatePaymentMethodWithMeansCode(SEPADirectDebitMeansCodeTok));
    end;

    /// <summary>
    /// Creates a payment method with the given UNCL4461 payment means code.
    /// </summary>
    /// <param name="PaymentMeansCode">The payment means code to set up on the payment method.</param>
    /// <returns>The Code of the new payment method.</returns>
    procedure CreatePaymentMethodWithMeansCode(PaymentMeansCode: Code[3]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Payment Means Code", PaymentMeansCode);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    /// <summary>
    /// Creates a customer with a bank account with an IBAN and a SEPA direct debit mandate for it.
    /// </summary>
    /// <param name="SEPADirectDebitMandate">Returns the new mandate.</param>
    /// <param name="CustomerBankAccount">Returns the new customer bank account the mandate refers to.</param>
    /// <param name="PaymentMethodCode">The payment method to set on the customer.</param>
    /// <returns>The No. of the new customer.</returns>
    procedure CreateCustomerWithDirectDebitMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; var CustomerBankAccount: Record "Customer Bank Account"; PaymentMethodCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(AddDirectDebitMandateToCustomer(SEPADirectDebitMandate, CustomerBankAccount, Customer."No.", PaymentMethodCode));
    end;

    /// <summary>
    /// Gives an existing customer a bank account with an IBAN and a SEPA direct debit mandate for it.
    /// Use this when the test needs a customer built by its own suite, for example one with the
    /// address and VAT data a format requires.
    /// </summary>
    /// <param name="SEPADirectDebitMandate">Returns the new mandate.</param>
    /// <param name="CustomerBankAccount">Returns the new customer bank account the mandate refers to.</param>
    /// <param name="CustomerNo">The customer that gets the bank account and the mandate.</param>
    /// <param name="PaymentMethodCode">The payment method to set on the customer.</param>
    /// <returns>The No. of the customer.</returns>
    procedure AddDirectDebitMandateToCustomer(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Direct Debit Mandate Nos."));
        Customer.Get(CustomerNo);
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Modify(true);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        CustomerBankAccount.Modify(true);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code, WorkDate(), CalcDate('<1Y>', WorkDate()));
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    procedure CreateValidRoutingNo(): Text[50]
    var
        FineRouting: Text[20];
        CheckDigit: Text[2];
    begin
        FineRouting := GenerateAlphanumFineRouting();
        CheckDigit := ComputeCheckDigit(DefaultCoarseRoutingTxt, FineRouting);
        exit(CopyStr(DefaultCoarseRoutingTxt + '-' + FineRouting + '-' + CheckDigit, 1, 50));
    end;

    local procedure GenerateAlphanumFineRouting(): Text[20]
    begin
        // CreateGuid() produces hex chars (0-9, A-F) which are valid alphanumeric fine routing characters
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{-}'), 1, 20));
    end;

    local procedure ComputeCheckDigit(CoarseRouting: Text; FineRouting: Text): Text[2]
    var
        NumericString: Text;
        Remainder: Integer;
        CheckDigitValue: Integer;
    begin
        NumericString := ConvertToNumericString(CoarseRouting + FineRouting) + '00';
        Remainder := ComputeMod97(NumericString);
        CheckDigitValue := 98 - Remainder;
        if CheckDigitValue < 10 then
            exit(CopyStr('0' + Format(CheckDigitValue), 1, 2));
        exit(CopyStr(Format(CheckDigitValue), 1, 2));
    end;

    local procedure ConvertToNumericString(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        UpperInput: Text;
        Result: Text;
        Ch: Char;
        i: Integer;
    begin
        UpperInput := UpperCase(Input);
        for i := 1 to StrLen(UpperInput) do begin
            Ch := UpperInput[i];
            if TypeHelper.IsLatinLetter(Ch) then
                Result += Format(Ch - 55)
            else
                Result += Format(Ch - 48);
        end;
        exit(Result);
    end;

    local procedure ComputeMod97(NumericString: Text): Integer
    var
        Remainder: Integer;
        DigitValue: Integer;
        i: Integer;
    begin
        Remainder := 0;
        for i := 1 to StrLen(NumericString) do begin
            Evaluate(DigitValue, CopyStr(NumericString, i, 1));
            Remainder := (Remainder * 10 + DigitValue) mod 97;
        end;
        exit(Remainder);
    end;
}
