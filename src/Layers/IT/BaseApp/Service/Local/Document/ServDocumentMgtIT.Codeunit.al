// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Utilities;

codeunit 12140 "Serv. Document Mgt. IT"
{
    var
        ShipmentMethod: Record "Shipment Method";
        Text1130013: Label 'You cannot change %1 because %2 is not blank';
        Text1130016: Label '%1 will be modified according to %2';
        Text1130017: Label '%1 cannot be less than %2';
        Text1130018: Label '%1 cannot be greater than %2';
        Text1130019: Label 'A Posting No. has been assigned to this record. You cannot delete this document.';

    // Service Header

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Document Date', false, false)]
    local procedure DocumentDateOnBeforeValidateEvent(var Rec: Record "Service Header"; var xRec: Record "Service Header")
    begin
        if Rec."Document Type" <> Rec."Document Type"::Quote then
            if Rec."Document Date" > Rec."Posting Date" then
                Error(Text1130018, Rec.FieldCaption("Document Date"), Rec.FieldCaption("Posting Date"));
        if not Rec.CheckVATExemption() then
            Rec."Document Date" := xRec."Document Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidateDocumentDateOnAfterValidateVATReportingDate', '', false, false)]
    local procedure OnValidateDocumentDateOnAfterValidateVATReportingDate(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Currency Code" <> '' then begin
            ServiceHeader.UpdateCurrencyFactor();
            if ServiceHeader."Currency Factor" <> xServiceHeader."Currency Factor" then
                ServiceHeader.ConfirmCurrencyFactorUpdate();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'VAT Bus. Posting Group', false, false)]
    local procedure VATBusPostingGroupOnBeforeValidateEvent(var Rec: Record "Service Header"; var xRec: Record "Service Header")
    begin
        if not Rec.CheckVATExemption() then
            Rec."VAT Bus. Posting Group" := xRec."VAT Bus. Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateEvent', 'VAT Bus. Posting Group', false, false)]
    local procedure VATBusPostingGroupOnAfterValidateEvent(var Rec: Record "Service Header"; var xRec: Record "Service Header")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusinessPostingGroup.Get(Rec."VAT Bus. Posting Group");
        Rec.Validate("Operation Type", VATBusinessPostingGroup."Default Sales Operation Type");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Operation Occurred Date', false, false)]
    local procedure OperationOccurredDateOnBeforeValidateEvent(var Rec: Record "Service Header"; var xRec: Record "Service Header")
    begin
        if Rec."Document Type" <> Rec."Document Type"::Quote then
            if Rec."Operation Occurred Date" > Rec."Posting Date" then
                Error(Text1130018, Rec.FieldCaption("Operation Occurred Date"), Rec.FieldCaption("Posting Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateEvent', 'Shipment Method Code', false, false)]
    local procedure ShipmentMethodCodeOnAfterValidateEvent(var Rec: Record "Service Header")
    begin
        if Rec."Document Type" in [Rec."Document Type"::Order, Rec."Document Type"::Invoice] then begin
            if Rec."Shipping Agent Code" <> '' then
                Rec.CheckShipAgentMethodComb();
            if not ShipmentMethod.ThirdPartyLoader(Rec."Shipment Method Code") and
                (Rec."3rd Party Loader Type" <> Rec."3rd Party Loader Type"::" ")
            then begin
                Rec."3rd Party Loader Type" := Rec."3rd Party Loader Type"::" ";
                Rec."3rd Party Loader No." := '';
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateEvent', 'Shipping Agent Code', false, false)]
    local procedure ShipmentAgentCodeOnAfterValidateEvent(var Rec: Record "Service Header")
    begin
        if Rec."Document Type" in [Rec."Document Type"::Order, Rec."Document Type"::Invoice] then begin
            if Rec."Shipment Method Code" <> '' then
                Rec.CheckShipAgentMethodComb();
            Rec.UpdateTDDPreparedBy();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Ship-to Code', false, false)]
    local procedure ShiptoCodeOnBeforeValidateEvent(var Rec: Record "Service Header")
    begin
        Rec.SetOperationType();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateBillToCustomerNo', '', false, false)]
    local procedure OnAfterValidateBillToCustomerNo(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    var
        CustBankAccount: Record "Customer Bank Account";
        ServFatturaSubscribers: Codeunit "Serv. Fattura Subscribers";
    begin
        CustBankAccount.Reset();
        CustBankAccount.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
        if Customer."Preferred Bank Account Code" <> '' then
            CustBankAccount.SetRange(Code, Customer."Preferred Bank Account Code");
        if CustBankAccount.FindFirst() then
            ServiceHeader."Bank Account" := CustBankAccount.Code
        else
            ServiceHeader."Bank Account" := '';

        ServFatturaSubscribers.UpdateFatturaDocTypeInServDoc(ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInitPostingDate', '', false, false)]
    local procedure OnAfterInitPostingDate(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader."Operation Occurred Date" := WorkDate();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnUpdateCurrencyFactorOnAfterSetCurrencyDate', '', false, false)]
    local procedure OnUpdateCurrencyFactorOnAfterSetCurrencyDate(var ServiceHeader: Record "Service Header"; var CurrencyDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Use Document Date in Currency" then
            CurrencyDate := ServiceHeader."Document Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnDeleteOnBeforeShowPostedDocsToPrint', '', false, false)]
    local procedure OnDeleteOnBeforeShowPostedDocsToPrint(var ServiceHeader: Record "Service Header")
    var
        PaymentSales: Record "Payment Lines";
    begin
        PaymentSales.Reset();
        PaymentSales.SetRange(Type, ServiceHeader."Document Type");
        PaymentSales.SetRange(Code, ServiceHeader."No.");
        PaymentSales.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', false, false)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header")
    begin
        if not ServiceHeader.CheckVATExemption() then
            ServiceHeader.FieldError("Bill-to Customer No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeOnDelete', '', false, false)]
    local procedure OnBeforeOnDelete(var ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Posting No." <> '' then
            Error(Text1130019);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterOnInsert', '', false, false)]
    local procedure OnAfterOnInsert(var ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
            ServiceHeader."Refers to Period" := ServiceHeader."Refers to Period"::" ";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeConfirmRecreateServLines', '', false, false)]
    local procedure OnBeforeConfirmRecreateServLines(var ServiceHeader: Record "Service Header"; var HideValidationDialog: Boolean; var Result: Boolean; var IsHandled: Boolean; ChangedFieldName: Text[100])
    var
        SplitVATServiceLine: Record "Service Line";
        SplitVATLinesExist: Boolean;
    begin
        SplitVATLinesExist := ServiceHeader.GetSplitVATLines(SplitVATServiceLine);
        if HideValidationDialog or not GuiAllowed() then
            Result := true
        else
            Result := ServiceHeader.AskUser(SplitVATLinesExist, ChangedFieldName);
        ServiceHeader.RemoveSplitVATLinesIfExist(SplitVATServiceLine, SplitVATLinesExist);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyAppliestoFieldsFromCustLedgerEntry', '', false, false)]
    local procedure OnAfterCopyAppliestoFieldsFromCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        ServiceHeader."Applies-to Occurrence No." := CustLedgerEntry."Document Occurrence";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidatePostingDateOnAfterCheckPostingDate', '', false, false)]
    local procedure OnValidatePostingDateOnAfterCheckPostingDate(var ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Posting No." <> '' then
            if ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo"] then
                Error(Text1130013, ServiceHeader.FieldCaption("Posting Date"), ServiceHeader.FieldCaption("Posting No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidatePostingDateOnAfterValidateVATReportingDate', '', false, false)]
    local procedure OnValidatePostingDateOnAfterValidateVATReportingDate(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidatePostingDateOnAfterUpdatePostingDateOnLines', '', false, false)]
    local procedure OnValidatePostingDateOnAfterUpdatePostingDateOnLines(var ServiceHeader: Record "Service Header"; HideValidationDialog: Boolean)
    var
        LocalApplicationManagement: Codeunit LocalApplicationManagement;
        RecRef: RecordRef;
        Confirmed: Boolean;
    begin
        if ServiceHeader."Document Type" <> ServiceHeader."Document Type"::Quote then begin
            if ServiceHeader."Document Date" > ServiceHeader."Posting Date" then begin
                if HideValidationDialog then
                    Confirmed := true
                else
                    Confirmed := Confirm(Text1130016, false, ServiceHeader.FieldCaption("Document Date"), ServiceHeader.FieldCaption("Posting Date"));
                if Confirmed then
                    ServiceHeader.Validate("Document Date", ServiceHeader."Posting Date")
                else
                    Error(Text1130017, ServiceHeader.FieldCaption("Posting Date"), ServiceHeader.FieldCaption("Document Date"));
            end;
            RecRef.GetTable(ServiceHeader);
            LocalApplicationManagement.ValidateOperationOccurredDate(RecRef, HideValidationDialog);
            RecRef.SetTable(ServiceHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidatePaymentTerms', '', false, false)]
    local procedure OnBeforeValidatePaymentTerms(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    var
        ServPaymentLinesMgt: Codeunit "Serv. Payment Lines Mgt.";
    begin
        ServPaymentLinesMgt.CreatePaymentLinesServices(ServiceHeader);
        ServiceHeader.CalcFields("Payment %");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInitRecord', '', false, false)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.Validate("Payment Terms Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyCustomerFields', '', false, false)]
    local procedure OnAfterCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Fiscal Code" := Customer."Fiscal Code";
        ServiceHeader."Individual Person" := Customer."Individual Person";
        ServiceHeader.Resident := Customer.Resident;
        ServiceHeader."First Name" := Customer."First Name";
        ServiceHeader."Last Name" := Customer."Last Name";
        ServiceHeader."Date of Birth" := Customer."Date of Birth";
        ServiceHeader."Tax Representative Type" := Customer."Tax Representative Type";
        ServiceHeader."Tax Representative No." := Customer."Tax Representative No.";
        ServiceHeader."Place of Birth" := Customer."Place of Birth";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterUpdateServLinesByFieldNo', '', false, false)]
    local procedure OnAfterUpdateServLinesByFieldNo()
    begin
        Commit(); // test if all works without this commit
    end;

    // Service Line

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Customer No.', false, false)]
    local procedure OnAfterValidateEventCustomerNo(var Rec: Record "Service Line")
    begin
        Rec.ValidateIncludeInDT();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Unit Price', false, false)]
    local procedure OnAfterValidateEventUnitPrice(var Rec: Record "Service Line")
    begin
        Rec.ValidateIncludeInDT();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Inv. Discount Amount', false, false)]
    local procedure OnAfterValidateEventInvDiscountAmount(var Rec: Record "Service Line")
    begin
        Rec.ValidateIncludeInDT();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Contract No.', false, false)]
    local procedure OnAfterValidateEventContractNo(var Rec: Record "Service Line")
    begin
        Rec.ValidateIncludeInDT();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnValidateQuantityOnBeforeResetAmounts', '', false, false)]
    local procedure OnValidateQuantityOnBeforeResetAmounts(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.ValidateIncludeInDT();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnValidateNoOnAfterCopyFields', '', false, false)]
    local procedure OnValidateNoOnAfterCopyFields(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        SetServiceTariffNo(ServiceLine, ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnValidateVATProdPostingGroupOnAfterCopyFields', '', false, false)]
    local procedure OnAfterValidateEventVATProdPostingGroup(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        SetServiceTariffNo(ServiceLine, ServiceHeader);
    end;

    local procedure SetServiceTariffNo(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.IsEUService(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
            ServiceLine."Service Tariff No." := ServiceHeader."Service Tariff No."
        else
            if ServiceLine."Service Tariff No." <> '' then
                ServiceLine."Service Tariff No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterOnDelete', '', false, false)]
    local procedure OnAfterOnDelete(var ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        if ServiceLine.RemoveSplitVATLinesWithCheck(ServiceLine.TableCaption()) then begin
            ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            ServiceHeader.AddSplitVATLinesIgnoringALine(ServiceLine);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnInitHeaderDefaultsOnAfterAssignLocationCode', '', false, false)]
    local procedure OnInitHeaderDefaultsOnAfterAssignLocationCode(var ServiceLine: Record "Service Line"; ServHeader: Record "Service Header")
    begin
        ServiceLine."Refers to Period" := ServHeader."Refers to Period";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterClearFields', '', false, false)]
    local procedure OnAfterClearFields(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; TempServiceLine: Record "Service Line" temporary; CallingFieldNo: Integer)
    begin
        ServiceLine."Automatically Generated" := TempServiceLine."Automatically Generated";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnInsertVATAmountOnBeforeInsert', '', false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        if NonDeductibleVAT.IsNonDeductibleVATEnabled() then
            VATAmountLine."Non-Deductible VAT %" := 100 - ServiceLine."Deductible %"
        else
            VATAmountLine."Deductible %" := ServiceLine."Deductible %";
    end;

    // Service Contract

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServContractManagement", 'OnCreateServHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure ServiceContract_OnCreateServHeaderOnAfterCopyFromCustomer(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Fiscal Code" := Customer."Fiscal Code";
        ServiceHeader."Individual Person" := Customer."Individual Person";
        ServiceHeader.Resident := Customer.Resident;
        ServiceHeader."First Name" := Customer."First Name";
        ServiceHeader."Last Name" := Customer."Last Name";
        ServiceHeader."Date of Birth" := Customer."Date of Birth";
        ServiceHeader."Tax Representative Type" := Customer."Tax Representative Type";
        ServiceHeader."Tax Representative No." := Customer."Tax Representative No.";
        ServiceHeader."VAT Registration No." := Customer."VAT Registration No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServContractManagement", 'OnCreateOrGetCreditHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure ServiceContract_OnCreateOrGetCreditHeaderOnAfterCopyFromCustomer(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Fiscal Code" := Customer."Fiscal Code";
        ServiceHeader."Individual Person" := Customer."Individual Person";
        ServiceHeader.Resident := Customer.Resident;
        ServiceHeader."First Name" := Customer."First Name";
        ServiceHeader."Last Name" := Customer."Last Name";
        ServiceHeader."Date of Birth" := Customer."Date of Birth";
        ServiceHeader."Tax Representative Type" := Customer."Tax Representative Type";
        ServiceHeader."Tax Representative No." := Customer."Tax Representative No.";
        ServiceHeader."VAT Registration No." := Customer."VAT Registration No.";
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServContractManagement", 'OnBeforeServHeaderModify', '', false, false)]
    local procedure ServiceContract_OnBeforeServHeaderModify(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Use Activity Code" then
            ServiceHeader."Activity Code" := ServiceContractHeader."Activity Code";
    end;

    // History

    var
        DeletePostedInvoiceErr: Label 'You are not allowed to delete posted invoices.';

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnBeforeOnDelete', '', false, false)]
    local procedure ServiceInvoiceHeaderOnBeforeOnDelete(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        Error(DeletePostedInvoiceErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Calc. Discount", 'OnCalculateInvoiceDiscountOnAfterSetServiceLineFilters', '', false, false)]
    local procedure OnCalculateInvoiceDiscountOnAfterSetServiceLineFilters(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Automatically Generated", false);
    end;

    // Reports

    var
        FieldChangeWarningMsg: Label 'The %1 and %2 may be modified automatically if they are greater than the %3.';

    [EventSubscriber(ObjectType::Report, Report::"Batch Post Service Cr. Memos", 'OnAfterValidateReplacePostingDate', '', false, false)]
    local procedure ServiceCreditMemosOnAfterValidateReplacePostingDate(var ServiceHeader: Record "Service Header"; ReplacePostingDate: Boolean)
    begin
        if ReplacePostingDate then
            Message(
                FieldChangeWarningMsg,
                ServiceHeader.FieldCaption("Document Date"), ServiceHeader.FieldCaption("Operation Occurred Date"),
                ServiceHeader.FieldCaption("Posting Date"));
    end;

    [EventSubscriber(ObjectType::Report, Report::"Batch Post Service Invoices", 'OnAfterValidateReplacePostingDate', '', false, false)]
    local procedure ServiceInvoicesOnAfterValidateReplacePostingDate(var ServiceHeader: Record "Service Header"; ReplacePostingDate: Boolean)
    begin
        if ReplacePostingDate then
            Message(
                FieldChangeWarningMsg,
                ServiceHeader.FieldCaption("Document Date"), ServiceHeader.FieldCaption("Operation Occurred Date"),
                ServiceHeader.FieldCaption("Posting Date"));
    end;

    [EventSubscriber(ObjectType::Report, Report::"Batch Post Service Orders", 'OnAfterValidateReplacePostingDate', '', false, false)]
    local procedure ServiceOrdersOnAfterValidateReplacePostingDate(var ServiceHeader: Record "Service Header"; ReplacePostingDate: Boolean)
    begin
        if ReplacePostingDate then
            Message(
                FieldChangeWarningMsg,
                ServiceHeader.FieldCaption("Document Date"), ServiceHeader.FieldCaption("Operation Occurred Date"),
                ServiceHeader.FieldCaption("Posting Date"));
    end;

}
