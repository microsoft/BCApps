// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

codeunit 1312 "Vendor Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure CalcAmountsOnPostedInvoices(VendNo: Code[20]; var RecCount: Integer): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(VendNo, RecCount, VendorLedgerEntry."Document Type"::Invoice));
    end;

    procedure CalcAmountsOnPostedCrMemos(VendNo: Code[20]; var RecCount: Integer): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(VendNo, RecCount, VendorLedgerEntry."Document Type"::"Credit Memo"));
    end;

    procedure CalcAmountsOnPostedOrders(VendNo: Code[20]; var RecCount: Integer): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(VendNo, RecCount, VendorLedgerEntry."Document Type"::" "));
    end;

    procedure CalcAmountsOnUnpostedInvoices(VendNo: Code[20]; var RecCount: Integer): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(CalcAmountsOnUnpostedDocs(VendNo, RecCount, VendorLedgerEntry."Document Type"::Invoice));
    end;

    procedure CalcAmountsOnUnpostedCrMemos(VendNo: Code[20]; var RecCount: Integer): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(CalcAmountsOnUnpostedDocs(VendNo, RecCount, VendorLedgerEntry."Document Type"::"Credit Memo"));
    end;

    procedure DrillDownOnPostedInvoices(VendNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendNo);
        PurchInvHeader.SetFilter("Posting Date", GetCurrentYearFilter());

        PAGE.Run(PAGE::"Posted Purchase Invoices", PurchInvHeader);
    end;

    procedure DrillDownOnPostedCrMemo(VendNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", VendNo);
        PurchCrMemoHdr.SetFilter("Posting Date", GetCurrentYearFilter());

        PAGE.Run(PAGE::"Posted Purchase Credit Memos", PurchCrMemoHdr);
    end;

    procedure DrillDownOnPostedOrders(VendNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Buy-from Vendor No.", VendNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetFilter("Order Date", GetCurrentYearFilter());

        PAGE.Run(PAGE::"Purchase Orders", PurchaseLine);
    end;

    procedure DrillDownOnOutstandingInvoices(VendNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SetFilterForUnpostedLines(PurchaseLine, VendNo, PurchaseHeader."Document Type"::Invoice);
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeader);
    end;

    procedure DrillDownOnOutstandingCrMemos(VendNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SetFilterForUnpostedLines(PurchaseLine, VendNo, PurchaseHeader."Document Type"::"Credit Memo");
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeader);
    end;

    local procedure CalcAmountsOnPostedDocs(VendNo: Code[20]; var RecCount: Integer; DocType: Enum "Gen. Journal Document Type"): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        SetFilterForPostedDocs(VendLedgEntry, VendNo, DocType);
        RecCount := VendLedgEntry.Count;
        VendLedgEntry.CalcSums("Purchase (LCY)");
        exit(VendLedgEntry."Purchase (LCY)");
    end;

    local procedure CalcAmountsOnUnpostedDocs(VendNo: Code[20]; var RecCount: Integer; DocType: Enum "Purchase Document Type") Result: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchOutstdAmountOnVAT: Query "Purch. Outstd. Amount On VAT";
        Factor: Integer;
    begin
        RecCount := 0;
        Result := 0;
        if VendNo = '' then
            exit;

        PurchaseHeader.SetRange("Document Type", DocType);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendNo);
        RecCount := PurchaseHeader.Count();

        case DocType of
            "Purchase Document Type"::Invoice:
                Factor := 1;
            "Purchase Document Type"::"Credit Memo":
                Factor := -1;
        end;
        PurchOutstdAmountOnVAT.SetRange(Document_Type, DocType);
        PurchOutstdAmountOnVAT.SetRange(Buy_from_Vendor_No_, VendNo);
        PurchOutstdAmountOnVAT.Open();
        while PurchOutstdAmountOnVAT.Read() do
            Result += Factor * PurchOutstdAmountOnVAT.Sum_Outstanding_Amount__LCY_ * 100 / (100 + PurchOutstdAmountOnVAT.VAT__);
        PurchOutstdAmountOnVAT.Close();

        exit(Round(Result));
    end;

    local procedure SetFilterForUnpostedLines(var PurchaseLine: Record "Purchase Line"; VendNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        PurchaseLine.SetRange("Buy-from Vendor No.", VendNo);

        PurchaseLine.SetRange("Document Type", DocumentType);
    end;

    local procedure SetFilterForPostedDocs(var VendLedgEntry: Record "Vendor Ledger Entry"; VendNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendLedgEntry.SetRange("Buy-from Vendor No.", VendNo);
        VendLedgEntry.SetFilter("Posting Date", GetCurrentYearFilter());
        VendLedgEntry.SetRange("Document Type", DocumentType);
    end;

    procedure SetFilterForExternalDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; ExternalDocNo: Text[35]; VendorNo: Code[20]; DocumentDate: Date)
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("External Document No.", ExternalDocNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange(Reversed, false);
        OnAfterSetFilterForExternalDocNo(VendorLedgerEntry, DocumentDate);
    end;

    procedure GetCurrentYearFilter(): Text[30]
    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CustDateFilter: Text[30];
        CustDateName: Text[30];
    begin
        DateFilterCalc.CreateFiscalYearFilter(CustDateFilter, CustDateName, WorkDate(), 0);
        exit(CustDateFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterForExternalDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentDate: Date)
    begin
    end;
}

