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
        CapturedTradeAgreementHeaderRecordId: RecordId;
        CapturedTradeDeliveryValuesHeaderRecordId: RecordId;
        CapturedTradeDeliveryElementHeaderRecordId: RecordId;
        OverrideZUGFeRDCustomerName: Text[100];
        OverrideZUGFeRDExternalDocumentNo: Code[35];
        OverrideZUGFeRDShipToName: Text[100];
        OverrideZUGFeRDShipToCity: Text[30];
        OverrideZUGFeRDActualDeliveryDate: Date;
        AddedZUGFeRDDespatchAdviceID: Text[35];
        RAMNamespaceTxt: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        DefaultCoarseRoutingTxt: Label '99', Locked = true;
        SEPADirectDebitMeansCodeTok: Label '59', Locked = true;
        CapturedEDocumentServiceCode: Code[20];
        EDocumentServiceEventCount: Integer;

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

    /// <summary>
    /// Resets the values that the ZUGFeRD trade agreement and trade delivery subscribers set or add, and the headers they captured.
    /// Bind this codeunit with BindSubscription before the export and unbind afterwards.
    /// </summary>
    procedure ClearZUGFeRDOverrides()
    begin
        Clear(CapturedTradeAgreementHeaderRecordId);
        Clear(CapturedTradeDeliveryValuesHeaderRecordId);
        Clear(CapturedTradeDeliveryElementHeaderRecordId);
        Clear(OverrideZUGFeRDCustomerName);
        Clear(OverrideZUGFeRDExternalDocumentNo);
        Clear(OverrideZUGFeRDShipToName);
        Clear(OverrideZUGFeRDShipToCity);
        Clear(OverrideZUGFeRDActualDeliveryDate);
        Clear(AddedZUGFeRDDespatchAdviceID);
    end;

    /// <summary>
    /// Sets the values that the subscribers of the ZUGFeRD trade agreement and trade delivery events pass back to the export.
    /// </summary>
    /// <param name="CustomerName">The buyer name (BT-44) to pass back to the export.</param>
    /// <param name="ExternalDocumentNo">The purchase order reference (BT-13) to pass back to the export.</param>
    /// <param name="ShipToName">The deliver-to party name (BT-70) to pass back to the export.</param>
    /// <param name="ShipToCity">The deliver-to city (BT-77) to pass back to the export.</param>
    /// <param name="ActualDeliveryDate">The actual delivery date (BT-72) to pass back to the export.</param>
    procedure SetZUGFeRDValueOverrides(CustomerName: Text[100]; ExternalDocumentNo: Code[35]; ShipToName: Text[100]; ShipToCity: Text[30]; ActualDeliveryDate: Date)
    begin
        OverrideZUGFeRDCustomerName := CustomerName;
        OverrideZUGFeRDExternalDocumentNo := ExternalDocumentNo;
        OverrideZUGFeRDShipToName := ShipToName;
        OverrideZUGFeRDShipToCity := ShipToCity;
        OverrideZUGFeRDActualDeliveryDate := ActualDeliveryDate;
    end;

    /// <summary>
    /// Sets the despatch advice reference (BT-16) that the subscriber adds to ram:ApplicableHeaderTradeDelivery of the ZUGFeRD export.
    /// </summary>
    /// <param name="DespatchAdviceID">The despatch advice reference to add as ram:DespatchAdviceReferencedDocument.</param>
    procedure SetZUGFeRDDespatchAdviceID(DespatchAdviceID: Text[35])
    begin
        AddedZUGFeRDDespatchAdviceID := DespatchAdviceID;
    end;

    /// <summary>
    /// Returns the record IDs of the headers carried by the last ZUGFeRD trade agreement and trade delivery events.
    /// </summary>
    /// <param name="TradeAgreementHeaderRecordId">The header carried by OnInsertApplicableHeaderTradeAgreementOnBeforeCreateElement.</param>
    /// <param name="TradeDeliveryValuesHeaderRecordId">The header carried by OnInsertApplicableHeaderTradeDeliveryOnBeforeCreateElement.</param>
    /// <param name="TradeDeliveryElementHeaderRecordId">The header carried by OnAfterInsertApplicableHeaderTradeDelivery.</param>
    procedure GetCapturedZUGFeRDTradeHeaderRecordIds(var TradeAgreementHeaderRecordId: RecordId; var TradeDeliveryValuesHeaderRecordId: RecordId; var TradeDeliveryElementHeaderRecordId: RecordId)
    begin
        TradeAgreementHeaderRecordId := CapturedTradeAgreementHeaderRecordId;
        TradeDeliveryValuesHeaderRecordId := CapturedTradeDeliveryValuesHeaderRecordId;
        TradeDeliveryElementHeaderRecordId := CapturedTradeDeliveryElementHeaderRecordId;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", OnInsertApplicableHeaderTradeAgreementOnBeforeCreateElement, '', false, false)]
    local procedure OverrideZUGFeRDOnInsertApplicableHeaderTradeAgreementOnBeforeCreateElement(HeaderRecordRef: RecordRef; var CustomerName: Text[100]; var ExternalDocumentNo: Code[35])
    begin
        CapturedTradeAgreementHeaderRecordId := HeaderRecordRef.RecordId();
        if OverrideZUGFeRDCustomerName <> '' then
            CustomerName := OverrideZUGFeRDCustomerName;
        if OverrideZUGFeRDExternalDocumentNo <> '' then
            ExternalDocumentNo := OverrideZUGFeRDExternalDocumentNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", OnInsertApplicableHeaderTradeDeliveryOnBeforeCreateElement, '', false, false)]
    local procedure OverrideZUGFeRDOnInsertApplicableHeaderTradeDeliveryOnBeforeCreateElement(HeaderRecordRef: RecordRef; var ShipToName: Text[100]; var ShipToAddress: Record "Standard Address"; var ActualDeliveryDate: Date)
    begin
        CapturedTradeDeliveryValuesHeaderRecordId := HeaderRecordRef.RecordId();
        if OverrideZUGFeRDShipToName <> '' then
            ShipToName := OverrideZUGFeRDShipToName;
        if OverrideZUGFeRDShipToCity <> '' then
            ShipToAddress.City := OverrideZUGFeRDShipToCity;
        if OverrideZUGFeRDActualDeliveryDate <> 0D then
            ActualDeliveryDate := OverrideZUGFeRDActualDeliveryDate;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", OnAfterInsertApplicableHeaderTradeDelivery, '', false, false)]
    local procedure AddZUGFeRDDespatchAdviceOnAfterInsertApplicableHeaderTradeDelivery(var DeliveryElement: XmlElement; HeaderRecordRef: RecordRef)
    var
        DespatchAdviceElement: XmlElement;
    begin
        CapturedTradeDeliveryElementHeaderRecordId := HeaderRecordRef.RecordId();
        if AddedZUGFeRDDespatchAdviceID = '' then
            exit;
        DespatchAdviceElement := XmlElement.Create('DespatchAdviceReferencedDocument', RAMNamespaceTxt);
        DespatchAdviceElement.Add(XmlElement.Create('IssuerAssignedID', RAMNamespaceTxt, AddedZUGFeRDDespatchAdviceID));
        DeliveryElement.Add(DespatchAdviceElement);
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
