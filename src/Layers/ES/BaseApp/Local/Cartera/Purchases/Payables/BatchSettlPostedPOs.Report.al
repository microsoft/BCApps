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

                    if OnlyDueDocuments and (DocumentPostingDate < "Due Date" + Delay) then
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
                                Clear(TempGenJnlLine);
                                TempGenJnlLine.Init();
                                TempGenJnlLine."Line No." := GenJnlLineNextNo;
                                TempGenJnlLine."Posting Date" := DocumentPostingDate;
                                TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                                TempGenJnlLine."Document Date" := TempGenJnlLine."Document Date";
                                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Vendor);
                                VendLedgEntry.Get(PostedDoc."Entry No.");
                                OnBeforeValidateInvoiceAccountNo(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, FromJnl, ExistsNoRealVAT);
                                TempGenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                                TempGenJnlLine.Description := CopyStr(
                                    StrSubstNo(Text1100004Lbl, PostedDoc."Document No."),
                                    1, MaxStrLen(TempGenJnlLine.Description));
                                TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                                TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                                TempGenJnlLine.Validate(Amount, PostedDoc."Remaining Amount");
                                TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                                TempGenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                                TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                                TempGenJnlLine."Source Code" := SourceCode;
                                TempGenJnlLine."System-Created Entry" := true;
                                TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                                TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                                TempGenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry, PostedPmtOrd);
                                TempGenJnlLine.Insert();
                                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                                OnAfterInvoiceGenJnlLineInsert(
                                  TempGenJnlLine, VendLedgEntry, PostedDoc, PostedPmtOrd,
                                  FromJnl, ExistsNoRealVAT, ExistVATEntry, FirstVATEntryNo, LastVATEntryNo, TempNoRealVATBuffer);
                                GroupAmount := GroupAmount + "Remaining Amount";
                                GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                            end;
                        "Document Type"::Bill:
                            begin
                                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                                Clear(TempGenJnlLine);
                                TempGenJnlLine.Init();
                                TempGenJnlLine."Line No." := GenJnlLineNextNo;
                                TempGenJnlLine."Posting Date" := DocumentPostingDate;
                                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                                TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                                TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Vendor);
                                VendLedgEntry.Get(PostedDoc."Entry No.");

                                if GLSetup."Unrealized VAT" then begin
                                    FromJnl := false;
                                    if PostedDoc."From Journal" then
                                        FromJnl := true;
                                    ExistsNoRealVAT := GenJnlPostLine.VendFindVATSetup(VATPostingSetup, VendLedgEntry, FromJnl);
                                end;

                                TempGenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                                TempGenJnlLine.Description := CopyStr(
                                    StrSubstNo(Text1100005Lbl, PostedDoc."Document No.", PostedDoc."No."),
                                    1, MaxStrLen(TempGenJnlLine.Description));
                                TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                                TempGenJnlLine.Validate(Amount, PostedDoc."Remaining Amount");
                                TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                                TempGenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                                TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                                TempGenJnlLine."Source Code" := SourceCode;
                                TempGenJnlLine."System-Created Entry" := true;
                                TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                                TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                                TempGenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                TempGenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
                                OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry, PostedPmtOrd);
                                TempGenJnlLine.Insert();
                                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                                if GLSetup."Unrealized VAT" and
                                   ExistsNoRealVAT and
                                   (not IsRedrawn)
                                then begin
                                    VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                                    OnBeforeVendUnrealizedVAT2(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd, TempNoRealVATBuffer);
                                    CarteraManagement.VendUnrealizedVAT2(
                                      VendLedgEntry,
                                      VendLedgEntry."Remaining Amt. (LCY)",
                                      TempGenJnlLine,
                                      ExistVATEntry,
                                      FirstVATEntryNo,
                                      LastVATEntryNo,
                                      TempNoRealVATBuffer,
                                      FromJnl,
                                      "Document No.");
                                    OnAfterVendUnrealizedVAT2(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd, TempNoRealVATBuffer);

                                    if TempNoRealVATBuffer.Find('-') then begin
                                        repeat
                                            InsertGenJournalLine(
                                              TempGenJnlLine."Account Type"::"G/L Account",
                                              TempNoRealVATBuffer.Account,
                                              TempNoRealVATBuffer.Amount);
                                            InsertGenJournalLine(
                                              TempGenJnlLine."Account Type"::"G/L Account",
                                              TempNoRealVATBuffer."Balance Account",
                                              -TempNoRealVATBuffer.Amount);
                                        until TempNoRealVATBuffer.Next() = 0;
                                        TempNoRealVATBuffer.DeleteAll();
                                    end;
                                end;

                                GroupAmount := GroupAmount + "Remaining Amount";
                                GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                            end;
                    end;
                    if TempBGPOPostBuffer.Get('', '', VendLedgEntry."Entry No.") then begin
                        TempBGPOPostBuffer.Amount := TempBGPOPostBuffer.Amount + "Remaining Amount";
                        TempBGPOPostBuffer.Modify();
                    end else begin
                        TempBGPOPostBuffer.Init();
                        TempBGPOPostBuffer."Entry No." := VendLedgEntry."Entry No.";
                        TempBGPOPostBuffer.Amount := TempBGPOPostBuffer.Amount + "Remaining Amount";
                        TempBGPOPostBuffer.Insert();
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

                    VendLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(TempGenJnlLine);
                    TempGenJnlLine.Init();
                    TempGenJnlLine."Line No." := GenJnlLineNextNo;
                    TempGenJnlLine."Posting Date" := DocumentPostingDate;
                    TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                    TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                    TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                    TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                    TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedPmtOrd."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                    TempGenJnlLine.Validate("Currency Code", PostedPmtOrd."Currency Code");
                    TempGenJnlLine.Validate(Amount, -GroupAmount);
                    TempGenJnlLine."Source Code" := SourceCode;
                    TempGenJnlLine."System-Created Entry" := true;
                    DimesionSetIds[1] := TempGenJnlLine."Dimension Set ID";
                    DimesionSetIds[2] := VendLedgEntry."Dimension Set ID";
                    TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                    TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                    TempGenJnlLine.Validate("Dimension Set ID", DimensionManagement.GetCombinedDimensionSetID(DimesionSetIds, VendLedgEntry."Global Dimension 1 Code", VendLedgEntry."Global Dimension 2 Code"));
                    OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry2, PostedPmtOrd);
                    TempGenJnlLine.Insert();
                    SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

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
                            Clear(TempGenJnlLine);
                            TempGenJnlLine.Init();
                            TempGenJnlLine."Line No." := GenJnlLineNextNo;
                            TempGenJnlLine."Posting Date" := DocumentPostingDate;
                            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                            TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                            TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                            TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                            TempGenJnlLine.Validate("Account No.", Acct);
                            TempGenJnlLine.Description := Text1100010Lbl;
                            TempGenJnlLine.Validate("Currency Code", '');
                            TempGenJnlLine.Validate(Amount, -SumLCYAmt);
                            DimesionSetIds[1] := TempGenJnlLine."Dimension Set ID";
                            DimesionSetIds[2] := VendLedgEntry."Dimension Set ID";
                            TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                            TempGenJnlLine.Validate("Dimension Set ID", DimensionManagement.GetCombinedDimensionSetID(DimesionSetIds, VendLedgEntry."Global Dimension 1 Code", VendLedgEntry."Global Dimension 2 Code"));
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine."System-Created Entry" := true;
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry2, PostedPmtOrd);
                            TempGenJnlLine.Insert();
                        end;

                    DocPost.PostSettlement(TempGenJnlLine);
                    TempGenJnlLine.DeleteAll();

                    DocPost.ClosePmtOrdIfEmpty(PostedPmtOrd, DocumentPostingDate);

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
                      Text1100003Lbl,
                      TotalDocCount, PmtOrdCount, GroupAmountLCY);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(DocumentPostingDate);

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
                      Text1100000Lbl +
                      Text1100001Lbl +
                      Text1100002Lbl);
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
                    field(PostingDate; DocumentPostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the posting date.';
                    }
                    field(DueOnly; OnlyDueDocuments)
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
        DocumentPostingDate := WorkDate();
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLReg: Record "G/L Register";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        TempBGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        TempNoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text1100000Lbl: Label 'Settling           @1@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text1100001Lbl: Label 'Payment Order No.  #2######  @3@@@@@@@@@@@@@\', Comment = '#2 = Payment order number, @3 = Document settlement progress';
        Text1100002Lbl: Label 'Payable document   #4######', Comment = '#4 = Document type and number';
        Text1100003Lbl: Label '%1 Documents in %2 Payment Orders totaling %3 (LCY) have been settled.', Comment = '%1 = Number of documents settled, %2 = Number of payment orders, %3 = Total amount settled in local currency';
        Text1100004Lbl: Label 'Payable document settlement %1', Comment = '%1 = Document number';
        Text1100005Lbl: Label 'Payable bill settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100009Lbl: Label 'Payment order settlement %1', Comment = '%1 = Payment order number';
        Text1100010Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100011Lbl: Label 'Payable document settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Window: Dialog;
        DocumentPostingDate: Date;
        OnlyDueDocuments: Boolean;
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
        ExistsNoRealVAT: Boolean;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedPmtOrd."No.";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine."Account No." := AccNo;
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            TempGenJnlLine.Description := CopyStr(
                StrSubstNo(Text1100011Lbl, PostedDoc."Document No.", PostedDoc."No."),
                1, MaxStrLen(TempGenJnlLine.Description))
        else
            TempGenJnlLine.Description := CopyStr(
                StrSubstNo(Text1100011Lbl, PostedDoc."Document No.", PostedDoc."No."),
                1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        TempGenJnlLine.Validate(Amount, -Amount2);
        TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := '';
        TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        TempGenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, VendLedgEntry, PostedPmtOrd);
        TempGenJnlLine.Insert();
    end;

    procedure SetPostingDate(NewPostingDate: Date)
    begin
        DocumentPostingDate := NewPostingDate;
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

