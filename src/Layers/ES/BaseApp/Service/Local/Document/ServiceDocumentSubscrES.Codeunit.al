// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;

codeunit 10763 "Service Document Subscr. ES"
{
    SingleInstance = true;

    var
        SIIManagement: Codeunit "SII Management";
        ServSIIManagement: Codeunit "Serv. SII Management";
        ECDifference: Decimal;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidateBillToCustomerNoOnAfterSetFilters', '', true, true)]
    local procedure OnValidateBillToCustomerNoOnAfterSetFilters(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
        if xServiceHeader."Bill-to Customer No." <> ServiceHeader."Bill-to Customer No." then
            ServiceHeader."Corrected Invoice No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateBillToCustomerNo', '', true, true)]
    local procedure OnAfterValidateBillToCustomerNo(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var Customer: Record Customer)
    begin
        ServiceHeader.Validate(
            "ID Type",
            SIIManagement.GetSalesIDType(ServiceHeader."Bill-to Customer No.", ServiceHeader."Correction Type", ServiceHeader."Corrected Invoice No."));
        ServSIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateAppliesToDocNo', '', true, true)]
    local procedure OnAfterValidateAppliesToDocNo(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        ServiceHeader."Applies-to Bill No." := CustLedgEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidateAppliestoDocNoOnAfterSetFilters', '', true, true)]
    local procedure OnValidateAppliestoDocNoOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ServiceHeader: Record "Service Header")
    begin
        if (ServiceHeader."Applies-to Doc. No." <> '') and (ServiceHeader."Applies-to Bill No." <> '') then begin
            CustLedgerEntry.SetRange("Bill No.", ServiceHeader."Applies-to Bill No.");
            if CustLedgerEntry.FindFirst() then;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyAppliestoFieldsFromCustLedgerEntry', '', true, true)]
    local procedure OnAfterCopyAppliestoFieldsFromCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        ServiceHeader."Applies-to Bill No." := CustLedgerEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', true, true)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer; SkipBillToContact: Boolean)
    begin
        ServiceHeader."Cust. Bank Acc. Code" := Customer."Preferred Bank Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLine', '', true, true)]
    local procedure OnAfterCopyToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Payment Terms Code" := ServiceHeader."Payment Terms Code";
        GenJournalLine."Payment Method Code" := ServiceHeader."Payment Method Code";
        GenJournalLine."Correction Type" := ServiceHeader."Correction Type";
        GenJournalLine."Corrected Invoice No." := ServiceHeader."Corrected Invoice No.";
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

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLineApplyTo', '', true, true)]
    local procedure OnAfterCopyToGenJnlLineApplyTo(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Applies-to Bill No." := ServiceHeader."Applies-to Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInitRecord', '', true, true)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
        ServSIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;

    // Service Line

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'VAT Prod. Posting Group', true, true)]
    local procedure OnAfterValidateVATProdPostingGroup(var Rec: Record "Service Line")
    begin
        ServSIIManagement.UpdatePurchSpecialSchemeCodeInServiceine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterClearVATPct', '', true, true)]
    local procedure OnAfterClearVATPct(var ServiceLine: Record "Service Line")
    begin
        ServiceLine."EC %" := 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterClearVATDifference', '', true, true)]
    local procedure OnAfterClearVATDifference(var ServiceLine: Record "Service Line")
    begin
        ServiceLine."EC Difference" := 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterGetVATPct', '', true, true)]
    local procedure OnAfterGetVATPct(var ServiceLine: Record "Service Line"; var VATPct: Decimal)
    begin
        VATPct += ServiceLine."EC %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterCopyFromVATPostingSetup', '', true, true)]
    local procedure OnAfterCopyFromVATPostingSetup(var ServiceLine: Record "Service Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
        ServiceLine."EC %" := VATPostingSetupFrom."EC %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnCalcVATAmountLinesOnBeforeVATAmountLineModifyInvoicing', '', true, true)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyInvoicing(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."Line Discount Amount" += ServiceLine."Line Discount Amount";
        VATAmountLine."EC Difference" += ServiceLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnCalcVATAmountLinesOnBeforeVATAmountLineModifyShipping', '', true, true)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyShipping(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."Line Discount Amount" += ServiceLine."Line Discount Amount";
        VATAmountLine."EC Difference" += ServiceLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnCalcVATAmountLinesOnBeforeVATAmountLineModifyElseCase', '', true, true)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyElseCase(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."Line Discount Amount" += ServiceLine."Line Discount Amount";
        VATAmountLine."EC Difference" += ServiceLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify', '', true, true)]
    local procedure OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var ServiceLine: Record "Service Line"; NewVATBaseAmount: Decimal)
    begin
        TempVATAmountLineRemainder."EC Difference" := ECDifference - ServiceLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterRoundVATDifference', '', true, true)]
    local procedure OnAfterRoundVATDifference(var ServiceLine: Record "Service Line"; Currency: Record Currency)
    begin
        ServiceLine."EC Difference" := Round(ECDifference, Currency."Amount Rounding Precision");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterCalcVATDifference', '', true, true)]
    local procedure OnAfterCalcVATDifference(var TempVATAmountLineRemainder: record "VAT Amount Line" temporary; var VATAmountLine: Record "VAT Amount Line"; LineAmount: Decimal)
    begin
        ECDifference :=
            TempVATAmountLineRemainder."EC Difference" +
            VATAmountLine."EC Difference" * LineAmount / VATAmountLine.CalcLineAmount();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterCalcVATAmount', '', true, true)]
    local procedure OnAfterCalcVATAmount(VATAmountLine: Record "VAT Amount Line"; NewAmount: Decimal; NewBase: Decimal; var VATAmount: Decimal)
    begin
        VATAmount += VATAmountLine."EC Amount" * NewAmount / NewBase;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnInsertVATAmountOnBeforeInsert', '', true, true)]
    local procedure OnInsertVATAmountOnBeforeInsert(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group");
        VATAmountLine."EC %" := VATPostingSetup."EC %";
    end;

    // Service Calc Discount

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Calc. Discount", 'OnCalculateInvoiceDiscountOnAfterApplyServiceCharge', '', true, true)]
    local procedure OnCalculateInvoiceDiscountOnAfterApplyServiceCharge(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CurrencyDate: Date; TemporaryHeader: Boolean)
    var
        GLAcc: Record "G/L Account";
        GLSetup: Record "General Ledger Setup";
        TempServiceLine: Record "Service Line" temporary;
        InvAllow: Boolean;
    begin
        GLSetup.Get();
        if GLSetup."Payment Discount Type" <> GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines" then
            ServiceLine.SetRange("Allow Invoice Disc.", true);
        if ServiceLine.Find('-') then begin
            if TemporaryHeader then
                ServiceLine.SetServHeader(ServiceHeader);
            repeat
                InvAllow := false;
                if ServiceLine.Type = ServiceLine.Type::"G/L Account" then
                    InvAllow := GLAcc.InvoiceDiscountAllowed(ServiceLine."No.");
                if (ServiceLine.Quantity <> 0) and not InvAllow then begin
                    ServiceLine."Pmt. Discount Amount" := 0;
                    ServiceLine.Validate("Inv. Discount Amount");
                    if ServiceLine."Allow Invoice Disc." then begin
                        case GLSetup."Discount Calculation" of
                            GLSetup."Discount Calculation"::" ",
                            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.",
                            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.":
                                begin
                                    TempServiceLine."Inv. Discount Amount" :=
                                        TempServiceLine."Inv. Discount Amount" +
                                        ServiceLine."Line Amount" * CustInvoiceDisc."Discount %" / 100;
                                    ServiceLine."Inv. Discount Amount" :=
                                            Round(TempServiceLine."Inv. Discount Amount", 0.00001);
                                end;
                            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. + Payment Disc.",
                            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. * Payment Disc.":
                                begin
                                    TempServiceLine."Inv. Discount Amount" :=
                                        TempServiceLine."Inv. Discount Amount" +
                                        (ServiceLine."Line Amount" + ServiceLine."Line Discount Amount") *
                                        CustInvoiceDisc."Discount %" / 100;
                                    ServiceLine."Inv. Discount Amount" := Round(TempServiceLine."Inv. Discount Amount", 0.00001);
                                end;
                        end;
                        TempServiceLine."Inv. Discount Amount" :=
                            TempServiceLine."Inv. Discount Amount" - ServiceLine."Inv. Discount Amount";
                    end;
                    if GLSetup."Payment Discount Type" =
                        GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines"
                    then begin
                        GLSetup.TestField("Discount Calculation");
                        case GLSetup."Discount Calculation" of
                            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. + Payment Disc.",
                            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.":
                                if ServiceLine."Line Amount" <> 0 then begin
                                    TempServiceLine."Pmt. Discount Amount" :=
                                        TempServiceLine."Pmt. Discount Amount" +
                                        (ServiceLine."Line Amount" + ServiceLine."Line Discount Amount") *
                                        ServiceHeader."Payment Discount %" / 100;
                                    ServiceLine."Pmt. Discount Amount" := Round(TempServiceLine."Pmt. Discount Amount", 0.01);
                                end;
                            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. * Payment Disc.",
                            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.":
                                if ServiceLine."Line Amount" <> 0 then begin
                                    TempServiceLine."Pmt. Discount Amount" :=
                                        TempServiceLine."Pmt. Discount Amount" +
                                        (ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount") *
                                        ServiceHeader."Payment Discount %" / 100;
                                    ServiceLine."Pmt. Discount Amount" := Round(TempServiceLine."Pmt. Discount Amount", 0.01);
                                end;
                        end;
                        TempServiceLine."Pmt. Discount Amount" :=
                            TempServiceLine."Pmt. Discount Amount" - ServiceLine."Pmt. Discount Amount";
                    end;

                    ServiceLine.Validate("Inv. Discount Amount");
                    ServiceLine.Modify();
                end;
            until ServiceLine.Next() = 0;
        end;
    end;
}