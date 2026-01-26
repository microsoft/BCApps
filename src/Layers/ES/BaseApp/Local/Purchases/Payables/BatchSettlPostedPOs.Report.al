// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Sales.Receivables;

report 7000087 "Batch Settl. Posted POs"
{
    Caption = 'Batch Settl. Posted POs';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "G/L Register" = m,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Payment Order" = imd,
                  TableData "Closed Payment Order" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(PostedPmtOrd; "Posted Payment Order")
        {
            DataItemTableView = sorting("No.") order(ascending);
            dataitem(PostedDoc; "Posted Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date") where(Status = const(Open), Type = const(Payable));

                trigger OnAfterGetRecord()
                var
                    FromJnl: Boolean;
                begin
                    IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("No.");
                    if "Document Type" = "Document Type"::Invoice then
                        ExistInvoice := true;
                    BankAcc.Get(PostedPmtOrd."Bank Account No.");
                    Delay := BankAcc."Delay for Notices";

                    if DueOnly and (PostingDate < "Due Date" + Delay) then
                        CurrReport.Skip();

                    TotalDocCount := TotalDocCount + 1;
                    DocCount := DocCount + 1;

                    if not SupressWindows then begin
                        Window.Update(3, Round(DocCount / TotalDoc * 10000, 1));
                        Window.Update(4, StrSubstNo('%1 %2', "Document Type", "Document No."));
                    end;

                    case "Document Type" of
                        "Document Type"::Invoice, "Document Type"::"Credit Memo":
                            begin
                                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                                Clear(GenJnlLine);
                                GenJnlLine.Init();
                                GenJnlLine."Line No." := GenJnlLineNextNo;
                                GenJnlLine."Posting Date" := PostingDate;
                                GenJnlLine."Document Date" := GenJnlLine."Document Date";
                                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                                VendLedgEntry.Get(PostedDoc."Entry No.");
                                OnBeforeValidateInvoiceAccountNo(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, FromJnl, ExistsNoRealVAT);
                                GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                                GenJnlLine.Description := CopyStr(
                                    StrSubstNo(Text1100004, PostedDoc."Document No."),
                                    1, MaxStrLen(GenJnlLine.Description));
                                GenJnlLine."Document No." := PostedPmtOrd."No.";
                                GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                                GenJnlLine.Validate(Amount, PostedDoc."Remaining Amount");
                                GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                                GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                                GenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                                GenJnlLine."Source Code" := SourceCode;
                                GenJnlLine."System-Created Entry" := true;
                                GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                                GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                                GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry, PostedPmtOrd);
                                GenJnlLine.Insert();
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                OnAfterInvoiceGenJnlLineInsert(
                                  GenJnlLine, VendLedgEntry, PostedDoc, PostedPmtOrd,
                                  FromJnl, ExistsNoRealVAT, ExistVATEntry, FirstVATEntryNo, LastVATEntryNo, NoRealVATBuffer);
                                GroupAmount := GroupAmount + "Remaining Amount";
                                GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                            end;
                        "Document Type"::Bill:
                            begin
                                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                                Clear(GenJnlLine);
                                GenJnlLine.Init();
                                GenJnlLine."Line No." := GenJnlLineNextNo;
                                GenJnlLine."Posting Date" := PostingDate;
                                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                                GenJnlLine."Document No." := PostedPmtOrd."No.";
                                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                                VendLedgEntry.Get(PostedDoc."Entry No.");

                                if GLSetup."Unrealized VAT" then begin
                                    FromJnl := false;
                                    if PostedDoc."From Journal" then
                                        FromJnl := true;
                                    ExistsNoRealVAT := GenJnlPostLine.VendFindVATSetup(VATPostingSetup, VendLedgEntry, FromJnl);
                                end;

                                GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                                GenJnlLine.Description := CopyStr(
                                    StrSubstNo(Text1100005, PostedDoc."Document No.", PostedDoc."No."),
                                    1, MaxStrLen(GenJnlLine.Description));
                                GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                                GenJnlLine.Validate(Amount, PostedDoc."Remaining Amount");
                                GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                                GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                                GenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                                GenJnlLine."Source Code" := SourceCode;
                                GenJnlLine."System-Created Entry" := true;
                                GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                                GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                                GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                GenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
                                OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry, PostedPmtOrd);
                                GenJnlLine.Insert();
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                if GLSetup."Unrealized VAT" and
                                   ExistsNoRealVAT and
                                   (not IsRedrawn)
                                then begin
                                    VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                                    OnBeforeVendUnrealizedVAT2(PostedDoc, GenJnlLine, VendLedgEntry, PostedPmtOrd, NoRealVATBuffer);
                                    CarteraManagement.VendUnrealizedVAT2(
                                      VendLedgEntry,
                                      VendLedgEntry."Remaining Amt. (LCY)",
                                      GenJnlLine,
                                      ExistVATEntry,
                                      FirstVATEntryNo,
                                      LastVATEntryNo,
                                      NoRealVATBuffer,
                                      FromJnl,
                                      "Document No.");
                                    OnAfterVendUnrealizedVAT2(PostedDoc, GenJnlLine, VendLedgEntry, PostedPmtOrd, NoRealVATBuffer);

                                    if NoRealVATBuffer.Find('-') then begin
                                        repeat
                                            InsertGenJournalLine(
                                              GenJnlLine."Account Type"::"G/L Account",
                                              NoRealVATBuffer.Account,
                                              NoRealVATBuffer.Amount);
                                            InsertGenJournalLine(
                                              GenJnlLine."Account Type"::"G/L Account",
                                              NoRealVATBuffer."Balance Account",
                                              -NoRealVATBuffer.Amount);
                                        until NoRealVATBuffer.Next() = 0;
                                        NoRealVATBuffer.DeleteAll();
                                    end;
                                end;

                                GroupAmount := GroupAmount + "Remaining Amount";
                                GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                            end;
                    end;
                    if BGPOPostBuffer.Get('', '', VendLedgEntry."Entry No.") then begin
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        BGPOPostBuffer.Modify();
                    end else begin
                        BGPOPostBuffer.Init();
                        BGPOPostBuffer."Entry No." := VendLedgEntry."Entry No.";
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        BGPOPostBuffer.Insert();
                    end;
                end;

                trigger OnPostDataItem()
                var
                    VendLedgEntry2: Record "Vendor Ledger Entry";
                    DimensionManagement: Codeunit DimensionManagement;
                    DimesionSetIds: array[10] of Integer;
                begin
                    if (DocCount = 0) or (GroupAmount = 0) then
                        CurrReport.Skip();

                    VendLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(GenJnlLine);
                    GenJnlLine.Init();
                    GenJnlLine."Line No." := GenJnlLineNextNo;
                    GenJnlLine."Posting Date" := PostingDate;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                    GenJnlLine."Document No." := PostedPmtOrd."No.";
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                    GenJnlLine.Validate("Account No.", BankAcc."No.");
                    GenJnlLine.Description := CopyStr(StrSubstNo(Text1100009, PostedPmtOrd."No."), 1, MaxStrLen(GenJnlLine.Description));
                    GenJnlLine.Validate("Currency Code", PostedPmtOrd."Currency Code");
                    GenJnlLine.Validate(Amount, -GroupAmount);
                    GenJnlLine."Source Code" := SourceCode;
                    GenJnlLine."System-Created Entry" := true;
                    DimesionSetIds[1] := GenJnlLine."Dimension Set ID";
                    DimesionSetIds[2] := VendLedgEntry."Dimension Set ID";
                    GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                    GenJnlLine.Validate("Dimension Set ID", DimensionManagement.GetCombinedDimensionSetID(DimesionSetIds, VendLedgEntry."Global Dimension 1 Code", VendLedgEntry."Global Dimension 2 Code"));
                    OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry2, PostedPmtOrd);
                    GenJnlLine.Insert();
                    SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                    if PostedPmtOrd."Currency Code" <> '' then
                        if SumLCYAmt <> 0 then begin
                            Currency.SetFilter(Code, PostedPmtOrd."Currency Code");
                            Currency.FindFirst();
                            if SumLCYAmt > 0 then begin
                                Currency.TestField("Residual Gains Account");
                                Acct := Currency."Residual Gains Account";
                            end else begin
                                Currency.TestField("Residual Losses Account");
                                Acct := Currency."Residual Losses Account";
                            end;
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(GenJnlLine);
                            GenJnlLine.Init();
                            GenJnlLine."Line No." := GenJnlLineNextNo;
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                            GenJnlLine."Document No." := PostedPmtOrd."No.";
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                            GenJnlLine.Validate("Account No.", Acct);
                            GenJnlLine.Description := Text1100010;
                            GenJnlLine.Validate("Currency Code", '');
                            GenJnlLine.Validate(Amount, -SumLCYAmt);
                            DimesionSetIds[1] := GenJnlLine."Dimension Set ID";
                            DimesionSetIds[2] := VendLedgEntry."Dimension Set ID";
                            GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                            GenJnlLine.Validate("Dimension Set ID", DimensionManagement.GetCombinedDimensionSetID(DimesionSetIds, VendLedgEntry."Global Dimension 1 Code", VendLedgEntry."Global Dimension 2 Code"));
                            GenJnlLine."Source Code" := SourceCode;
                            GenJnlLine."System-Created Entry" := true;
                            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry2, PostedPmtOrd);
                            GenJnlLine.Insert();
                        end;

                    DocPost.PostSettlement(GenJnlLine);
                    GenJnlLine.DeleteAll();

                    DocPost.ClosePmtOrdIfEmpty(PostedPmtOrd, PostingDate);

                    if (Counter > 1) and GLSetup."Unrealized VAT" and
                       ExistVATEntry and ExistInvoice
                    then begin
                        if VATEntry.FindLast() then
                            ToVATEntryNo := VATEntry."Entry No.";
                        GLReg.FindLast();
                        GLReg."From VAT Entry No." := FromVATEntryNo;
                        GLReg."To VAT Entry No." := ToVATEntryNo;
                        GLReg.Modify();
                    end else
                        if ExistVATEntry then begin
                            GLReg.FindLast();
                            GLReg."From VAT Entry No." := FirstVATEntryNo;
                            GLReg."To VAT Entry No." := LastVATEntryNo;
                            GLReg.Modify();
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    SumLCYAmt := 0;
                    GenJnlLineNextNo := 0;
                    TotalDoc := Count;
                    DocCount := 0;
                    ExistInvoice := false;
                    Counter := Count;
                    if (Counter > 1) and GLSetup."Unrealized VAT" then begin
                        VATEntry.LockTable();
                        if VATEntry.FindLast() then
                            FromVATEntryNo := VATEntry."Entry No." + 1;
                    end;

                    FirstVATEntryNo := 0;
                    LastVATEntryNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PmtOrdCount := PmtOrdCount + 1;

                if not SupressWindows then begin
                    Window.Update(1, Round(PmtOrdCount / TotalPmtOrd * 10000, 1));
                    Window.Update(2, StrSubstNo('%1', "No."));
                    Window.Update(3, 0);
                end;

                GroupAmount := 0;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                Commit();

                if not SupressWindows then
                    Message(
                      Text1100003,
                      TotalDocCount, PmtOrdCount, GroupAmountLCY);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(PostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";

                GroupAmountLCY := 0;
                PmtOrdCount := 0;
                DocCount := 0;
                TotalDocCount := 0;
                TotalPmtOrd := Count;
                ExistVATEntry := false;

                if not SupressWindows then
                    Window.Open(
                      Text1100000 +
                      Text1100001 +
                      Text1100002);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the posting date.';
                    }
                    field(DueOnly; DueOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due bills only';
                        ToolTip = 'Specifies if you want to only include documents that have become overdue. If it does not matter if a document is overdue at the time of settlement, leave this field blank.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        PostingDate := WorkDate();
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        Text1100000: Label 'Settling           @1@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text1100001: Label 'Payment Order No.  #2######  @3@@@@@@@@@@@@@\';
        Text1100002: Label 'Payable document   #4######';
        Text1100003: Label '%1 Documents in %2 Payment Orders totaling %3 (LCY) have been settled.';
        Text1100004: Label 'Payable document settlement %1';
        Text1100005: Label 'Payable bill settlement %1/%2';
        Text1100009: Label 'Payment order settlement %1';
        Text1100010: Label 'Residual adjust generated by rounding Amount';
        Text1100011: Label 'Payable document settlement %1/%2';
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLReg: Record "G/L Register";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        DueOnly: Boolean;
        SupressWindows: Boolean;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        TotalDocCount: Integer;
        GroupAmount: Decimal;
        GroupAmountLCY: Decimal;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        PmtOrdCount: Integer;
        TotalPmtOrd: Integer;
        TotalDoc: Integer;
        ExistVATEntry: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        IsRedrawn: Boolean;
        ExistInvoice: Boolean;
        FromVATEntryNo: Integer;
        ToVATEntryNo: Integer;
        Counter: Integer;
        BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        ExistsNoRealVAT: Boolean;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := PostedPmtOrd."No.";
        GenJnlLine."Account Type" := AccType;
        GenJnlLine."Account No." := AccNo;
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            GenJnlLine.Description := CopyStr(
                StrSubstNo(Text1100011, PostedDoc."Document No.", PostedDoc."No."),
                1, MaxStrLen(GenJnlLine.Description))
        else
            GenJnlLine.Description := CopyStr(
                StrSubstNo(Text1100011, PostedDoc."Document No.", PostedDoc."No."),
                1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        GenJnlLine.Validate(Amount, -Amount2);
        GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := '';
        GenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry, PostedPmtOrd);
        GenJnlLine.Insert();
    end;

    procedure SetPostingDate(NewPostingDate: Date)
    begin
        PostingDate := NewPostingDate;
    end;

    procedure SetSupressWindows(NewSupressWindows: Boolean)
    begin
        SupressWindows := NewSupressWindows;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoiceGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean; var ExistVATEntry: Boolean; var FirstVATEntryNo: Integer; var LastVATEntryNo: Integer; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsert(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var VendorLedgerEntry2: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateInvoiceAccountNo(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;
}

