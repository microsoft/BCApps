// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;

codeunit 28013 "WHT Sales Post"
{
    var
        WHTManagement: Codeunit WHTManagement;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnPostInvoiceOnAfterPostLines', '', true, false)]
    local procedure OnPostInvoiceOnAfterPostLines(var SalesHeader: Record "Sales Header"; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; TotalAmount: Decimal; var TempSalesLineGlobal: Record "Sales Line" temporary; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TotalSalesLineLCY: Record "Sales Line" temporary)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."Enable WHT" and (not GLSetup."Enable GST (Australia)") then
            PostWHT(
                SalesHeader, TotalAmount, GenJnlPostLine, TempSalesLineGlobal, SalesInvoiceHeader, SalesCrMemoHeader,
                SrcCode, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, TotalSalesLineLCY);
    end;

    local procedure PostWHT(var SalesHeader: Record "Sales Header"; TotalInvAmount: Decimal; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TempSalesLineGlobal: Record "Sales Line" temporary; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; var TotalSalesLineLCY: Record "Sales Line" temporary)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLReg: Record "G/L Register";
        WHTPostingSetup: Record "WHT Posting Setup";
        WHTEntry: Record "WHT Entry";
    begin
        WHTPostingSetup.Get(TempSalesLineGlobal."WHT Business Posting Group", TempSalesLineGlobal."WHT Product Posting Group");
        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice] then begin
            if TotalInvAmount >= WHTPostingSetup."WHT Minimum Invoice Amount" then
                WHTManagement.InsertCustInvoiceWHT(SalesInvHeader);
            WHTEntry.Reset();
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
            WHTEntry.SetRange("Document No.", SalesInvHeader."No.");
            if WHTEntry.Find('-') then
                repeat
                    WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                    if (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::Payment) and
                       (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::" ")
                    then
                        if WHTEntry.Amount <> 0 then begin
                            SalesHeader."WHT Amount" := SalesHeader."WHT Amount" + WHTEntry.Amount;
                            InsertGenJournalWHT(
                                SalesHeader, GenJnlLine, WHTPostingSetup.GetPrepaidWHTAccount(), -WHTEntry.Amount,
                                SrcCode, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, TotalSalesLineLCY);
                            GenJnlPostLine.IncreaseWHTEntryNo();
                            GenJnlPostLine.Run(GenJnlLine);
                        end;
                until WHTEntry.Next() = 0;

            if WHTEntry.Find('+') then
                if GLReg.FindLast() then begin
                    GLReg."To WHT Entry No." := WHTEntry."Entry No.";
                    GLReg.Modify();
                end;
        end else begin
            WHTManagement.InsertCustCreditWHT(SalesCrMemoHeader, SalesHeader."Applies-to ID");
            WHTEntry.Reset();
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
            WHTEntry.SetRange("Document No.", SalesCrMemoHeader."No.");
            if WHTEntry.Find('-') then
                repeat
                    WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                    if (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::Payment) and
                       (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::" ")
                    then
                        if WHTEntry.Amount <> 0 then begin
                            SalesHeader."WHT Amount" := SalesHeader."WHT Amount" + WHTEntry.Amount;
                            InsertGenJournalWHT(
                                SalesHeader, GenJnlLine, WHTPostingSetup.GetPrepaidWHTAccount(), -WHTEntry.Amount,
                                SrcCode, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, TotalSalesLineLCY);
                            GenJnlPostLine.IncreaseWHTEntryNo();
                            GenJnlPostLine.Run(GenJnlLine);
                        end;
                until WHTEntry.Next() = 0;

            if WHTEntry.FindLast() then
                if GLReg.FindLast() then begin
                    GLReg."To WHT Entry No." := WHTEntry."Entry No.";
                    GLReg.Modify();
                end;
        end;

        if (SalesHeader."WHT Amount" <> 0) then
            WHTManagement.PrintWHTSlips(GLReg, false);
    end;

    [Scope('OnPrem')]
    procedure InsertGenJournalWHT(var SalesHeader: Record "Sales Header"; var GenJnlLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AmountWHT: Decimal; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; var TotalSalesLineLCY: Record "Sales Line" temporary)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := SalesHeader."Posting Date";
        GenJnlLine."Document Date" := SalesHeader."Document Date";
        GenJnlLine.Description := SalesHeader."Posting Description";
        GenJnlLine."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := SalesHeader."Dimension Set ID";
        GenJnlLine."Reason Code" := SalesHeader."Reason Code";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := AccountNo;
        GenJnlLine."Document Type" := GenJnlLineDocType;
        GenJnlLine."Document No." := GenJnlLineDocNo;
        GenJnlLine."External Document No." := GenJnlLineExtDocNo;
        GenJnlLine."Currency Code" := SalesHeader."Currency Code";
        GenJnlLine.Amount := AmountWHT;
        GenJnlLine."Source Currency Code" := SalesHeader."Currency Code";
        GenJnlLine."Source Currency Amount" := AmountWHT;
        if SalesHeader."Currency Code" <> '' then
            GenJnlLine."Amount (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  SalesHeader."Posting Date", SalesHeader."Currency Code", AmountWHT, SalesHeader."Currency Factor"));
        if SalesHeader."Currency Code" = '' then
            GenJnlLine."Currency Factor" := 1
        else
            GenJnlLine."Currency Factor" := SalesHeader."Currency Factor";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalSalesLineLCY.Amount;
        GenJnlLine.Correction := SalesHeader.Correction;
        GenJnlLine."Inv. Discount (LCY)" := -TotalSalesLineLCY."Inv. Discount Amount";
        GenJnlLine."Sell-to/Buy-from No." := SalesHeader."Sell-to Customer No.";
        GenJnlLine."Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."On Hold" := SalesHeader."On Hold";
        GenJnlLine."Allow Application" := SalesHeader."Bal. Account No." = '';
        GenJnlLine."Due Date" := SalesHeader."Due Date";
        GenJnlLine."Payment Terms Code" := SalesHeader."Payment Terms Code";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        GenJnlLine."Source No." := SalesHeader."Bill-to Customer No.";
        GenJnlLine."Source Code" := SrcCode;
        GenJnlLine."Posting No. Series" := SalesHeader."Posting No. Series";
        GenJnlLine."IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
        GenJnlLine.Adjustment := SalesHeader.Adjustment;
        GenJnlLine."BAS Adjustment" := SalesHeader."BAS Adjustment";
        GenJnlLine."Adjustment Applies-to" := SalesHeader."Adjustment Applies-to";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnCheckAndUpdateOnBeforeSetPostingFlags', '', true, false)]
    local procedure OnCheckAndUpdateOnBeforeSetPostingFlags(var SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line" temporary; var ModifyHeader: Boolean; var HideProgressWindow: Boolean);
    begin
        CheckWHTApplication(SalesHeader);
    end;

    local procedure CheckWHTApplication(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.IsCreditDocType() then begin
            if (SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Invoice) and (SalesHeader."Applies-to Doc. No." <> '') then
                WHTManagement.CheckApplicationSalesWHT(SalesHeader);
            if ((SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Refund) and (SalesHeader."Applies-to Doc. No." <> '')) or
               (SalesHeader."Applies-to ID" <> '')
            then
                WHTManagement.CheckApplicationSalesWHT(SalesHeader);
        end;

        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice] then begin
            if (SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::"Credit Memo") and (SalesHeader."Applies-to Doc. No." <> '') then
                WHTManagement.CheckApplicationSalesWHT(SalesHeader);

            if ((SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Payment) and (SalesHeader."Applies-to Doc. No." <> '')) or
               (SalesHeader."Applies-to ID" <> '')
            then
                WHTManagement.CheckApplicationSalesWHT(SalesHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterFinalizePosting', '', true, false)]
    local procedure OnAfterFinalizePosting(var SalesHeader: Record "Sales Header")
    begin
        UpdateTaxForPostedDoc(SalesHeader);
    end;

    local procedure UpdateTaxForPostedDoc(var SalesHeader: Record "Sales Header")
    var
        GLSetup: Record "General Ledger Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TaxPostBuffer: Record "Tax Posting Buffer";
        TaxManagement: Codeunit TaxInvoiceManagement;
        TaxInvoiceNo: Code[20];
    begin
        if SalesHeader.Invoice or (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"]) then begin
            GLSetup.Get();
            if GLSetup."Enable Tax Invoices" then
                if SalesHeader."Tax Document Marked" then
                    if SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"] then begin
                        if SalesHeader."Last Posting No." = '' then
                            SalesCrMemoHeader."No." := SalesHeader."No."
                        else
                            SalesCrMemoHeader."No." := SalesHeader."Last Posting No.";
                        SalesCrMemoHeader.SetRecFilter();
                        TaxInvoiceNo := TaxManagement.SalesTaxCrMemoPost(SalesCrMemoHeader);
                    end else begin
                        if SalesHeader."Last Posting No." = '' then
                            SalesInvHeader."No." := SalesHeader."No."
                        else
                            SalesInvHeader."No." := SalesHeader."Last Posting No.";
                        SalesInvHeader.SetRecFilter();
                        TaxInvoiceNo := TaxManagement.SalesTaxInvPost(SalesInvHeader);
                    end;
            if GLSetup."Enable Tax Invoices" then begin
                TaxManagement.PrintTaxInvoices(false);
                if TaxPostBuffer.FindFirst() then
                    TaxPostBuffer.DeleteAll();
            end;
        end;
    end;


}
