// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Reserved codeunit for implementing country-specific exchange rate adjustment logic.
/// Provides a placeholder for localization-specific event subscribers and customizations
/// related to exchange rate adjustment processing.
/// </summary>
/// <remarks>
/// Intended for use by localization partners to implement region-specific requirements
/// for exchange rate adjustments without modifying core adjustment procedures.
/// Event subscribers can be added to handle local compliance and calculation rules.
/// </remarks>
codeunit 597 "Exch. Rate Adjmt. Subscribers"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnBeforeGetLocalCustAccountNo', '', false, false)]
    local procedure GetLocalCustAccountNo(CustLedgerEntry: Record "Cust. Ledger Entry"; var AccountNo: Code[20]; var IsHandled: Boolean)
    var
        CustPostingGr: Record "Customer Posting Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        AccountNo := '';
        IsHandled := false;
        Clear(PostedCarteraDoc);
        CustLedgerEntry.TestField("Customer Posting Group");
        CustPostingGr.Get(CustLedgerEntry."Customer Posting Group");
        case true of
            (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::" ") and
            (CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::" "):
                AccountNo := CustPostingGr.GetReceivablesAccount();
            (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Rejected) and
            (CustLedgerEntry."Document Situation" in [CustLedgerEntry."Document Situation"::"Posted BG/PO",
                                                        CustLedgerEntry."Document Situation"::"Closed BG/PO"]):
                AccountNo := CustPostingGr.GetRejectedFactoringAcc();
            (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Open) and
            (CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::"Posted BG/PO"):
                begin
                    PostedCarteraDoc.Get("Cartera Document Type"::Receivable, CustLedgerEntry."Entry No.");
                    AccountNo := CustPostingGr.GetFactoringForCollectionAcc();
                    if PostedCarteraDoc."Dealing Type" = PostedCarteraDoc."Dealing Type"::Discount then
                        AccountNo := CustPostingGr.GetFactoringForDiscountAcc();
                end;
            (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Open) and
            (CustLedgerEntry."Document Situation" in [CustLedgerEntry."Document Situation"::Cartera,
                                                        CustLedgerEntry."Document Situation"::"BG/PO"]):
                AccountNo := CustPostingGr.GetBillsAccount(false);
            (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Rejected) and
            (CustLedgerEntry."Document Situation" in [CustLedgerEntry."Document Situation"::"Posted BG/PO",
                                                        CustLedgerEntry."Document Situation"::"Closed BG/PO",
                                                        CustLedgerEntry."Document Situation"::"Closed Documents"]):
                AccountNo := CustPostingGr.GetBillsAccount(true);
            (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Open) and
            (CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::"Posted BG/PO"):
                begin
                    AccountNo := CustPostingGr.GetBillsOnCollAccount();
                    PostedCarteraDoc.Get("Cartera Document Type"::Receivable, CustLedgerEntry."Entry No.");
                    if PostedCarteraDoc."Dealing Type" = PostedCarteraDoc."Dealing Type"::Discount then
                        AccountNo := CustPostingGr.GetDiscountedBillsAcc();
                end;
        end;
        IsHandled := AccountNo <> '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAdjustCustomerLedgerEntryOnAfterPrepareAdjust', '', false, false)]
    local procedure CreateLocalCustDocuments(var CustLedgerEntry: Record "Cust. Ledger Entry"; CurrAdjAmount: Decimal; OldAdjAmount: Decimal)
    begin
        CreateCustCarteraDocuments(CustLedgerEntry, CurrAdjAmount, OldAdjAmount);
    end;

    local procedure CreateCustCarteraDocuments(var CustLedgerEntry: Record "Cust. Ledger Entry"; CurrAdjAmount: Decimal; OldAdjAmount: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        if CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::" " then
            exit;

        CustLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        case CustLedgerEntry."Document Situation" of
            CustLedgerEntry."Document Situation"::Cartera:
                if CarteraDoc.Get(CarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then begin
                    CarteraDoc."Remaining Amt. (LCY)" := CustLedgerEntry."Remaining Amt. (LCY)" + CurrAdjAmount;
                    CarteraDoc."Original Amount (LCY)" := CustLedgerEntry."Original Amt. (LCY)" + CurrAdjAmount;
                    CarteraDoc."Adjusted Amount" := CurrAdjAmount;
                    CarteraDoc.Adjusted := true;
                    CarteraDoc.Modify();
                end;
            CustLedgerEntry."Document Situation"::"Posted BG/PO":
                if PostedCarteraDoc.Get(PostedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then begin
                    PostedCarteraDoc."Remaining Amt. (LCY)" := CustLedgerEntry."Remaining Amt. (LCY)";
                    PostedCarteraDoc."Adjusted Amount" := CurrAdjAmount + OldAdjAmount;
                    PostedCarteraDoc.ReAdjusted := true;
                    PostedCarteraDoc.Modify();
                end;
            CustLedgerEntry."Document Situation"::"Closed BG/PO",
            CustLedgerEntry."Document Situation"::"Closed Documents":
                if ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then begin
                    ClosedCarteraDoc."Remaining Amt. (LCY)" := CustLedgerEntry."Remaining Amt. (LCY)";
                    ClosedCarteraDoc.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnBeforeGetLocalVendAccountNo', '', false, false)]
    local procedure GetLocalVendAccountNo(VendLedgerEntry: Record "Vendor Ledger Entry"; var AccountNo: Code[20]; var IsHandled: Boolean)
    var
        VendPostingGr: Record "Vendor Posting Group";
    begin
        AccountNo := '';
        IsHandled := false;
        VendLedgerEntry.TestField("Vendor Posting Group");
        VendPostingGr.Get(VendLedgerEntry."Vendor Posting Group");
        case true of
            (VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Invoice) and
            (VendLedgerEntry."Document Status" = VendLedgerEntry."Document Status"::" ") and
            (VendLedgerEntry."Document Situation" = VendLedgerEntry."Document Situation"::" "):
                AccountNo := VendPostingGr.GetPayablesAccount();
            (VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Invoice) and
            (VendLedgerEntry."Document Status" = VendLedgerEntry."Document Status"::Open) and
            (VendLedgerEntry."Document Situation" = VendLedgerEntry."Document Situation"::"Posted BG/PO"):
                AccountNo := VendPostingGr.GetInvoicesInPmtOrderAccount();
            (VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Bill) and
            (VendLedgerEntry."Document Status" = VendLedgerEntry."Document Status"::Open) and
            (VendLedgerEntry."Document Situation" in [VendLedgerEntry."Document Situation"::Cartera,
                                                      VendLedgerEntry."Document Situation"::"BG/PO"]):
                AccountNo := VendPostingGr.GetBillsAccount();
            (VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Bill) and
            (VendLedgerEntry."Document Status" = VendLedgerEntry."Document Status"::Open) and
            (VendLedgerEntry."Document Situation" = VendLedgerEntry."Document Situation"::"Posted BG/PO"):
                AccountNo := VendPostingGr.GetBillsInPmtOrderAccount();
        end;
        IsHandled := AccountNo <> '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAdjustVendorLedgerEntryOnAfterPrepareAdjust', '', false, false)]
    local procedure CreateLocalVendDocuments(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrAdjAmount: Decimal; OldAdjAmount: Decimal)
    begin
        CreateVendCarteraDocuments(VendorLedgerEntry, CurrAdjAmount, OldAdjAmount);
    end;

    local procedure CreateVendCarteraDocuments(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrAdjAmount: Decimal; OldAdjAmount: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        VendorLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        if VendorLedgerEntry."Document Situation" <> VendorLedgerEntry."Document Situation"::" " then
            case VendorLedgerEntry."Document Situation" of
                VendorLedgerEntry."Document Situation"::Cartera:
                    if CarteraDoc.Get(CarteraDoc.Type::Payable, VendorLedgerEntry."Entry No.") then begin
                        CarteraDoc."Remaining Amt. (LCY)" := Abs(VendorLedgerEntry."Remaining Amt. (LCY)" + CurrAdjAmount);
                        CarteraDoc."Original Amount (LCY)" := Abs(VendorLedgerEntry."Original Amt. (LCY)" + CurrAdjAmount);
                        CarteraDoc."Adjusted Amount" := -CurrAdjAmount;
                        CarteraDoc.Adjusted := true;
                        CarteraDoc.Modify();
                    end;
                VendorLedgerEntry."Document Situation"::"Posted BG/PO":
                    if PostedCarteraDoc.Get(PostedCarteraDoc.Type::Payable, VendorLedgerEntry."Entry No.") then begin
                        PostedCarteraDoc."Remaining Amt. (LCY)" := VendorLedgerEntry."Remaining Amt. (LCY)";
                        PostedCarteraDoc."Adjusted Amount" := CurrAdjAmount + OldAdjAmount;
                        PostedCarteraDoc.ReAdjusted := true;
                        PostedCarteraDoc.Modify();
                    end;
                VendorLedgerEntry."Document Situation"::"Closed BG/PO",
                VendorLedgerEntry."Document Situation"::"Closed Documents":
                    if ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Payable, VendorLedgerEntry."Entry No.") then begin
                        ClosedCarteraDoc."Remaining Amt. (LCY)" := VendorLedgerEntry."Remaining Amt. (LCY)";
                        ClosedCarteraDoc.Modify();
                    end;
            end;
    end;
}
