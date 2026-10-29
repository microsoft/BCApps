// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;

report 7000083 "Redraw Payable Bills"
{
    Caption = 'Redraw Payable Bills';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(VendLedgEntry; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                CheckUnrealizedVAT(VendLedgEntry);

                IsHandled := false;
                OnAfterGetVendorLedgerEntryOnBeforeCheckNewDueDate(VendLedgEntry, RedrawDueDate, IsHandled);
                if not IsHandled then
                    if RedrawDueDate < "Due Date" then begin
                        Window.Close();
                        Error(
                        Text1100002Lbl,
                        FieldCaption("Due Date"),
                        FieldCaption("Entry No."),
                        "Entry No.");
                    end;

                SumLCYAmt := 0;
                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                GenJnlLineInit();
                CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if "Remaining Amount" <> 0 then begin // open bill
                    CarteraManagement.CreatePayableDocPayment(TempGenJnlLine, VendLedgEntry);
                    IsOpenBill := true;
                end else begin // settled bill
                    CarteraManagement.ReversePayableDocPayment(TempGenJnlLine, VendLedgEntry);
                    IsOpenBill := false;
                end;

                TempGenJnlLine.Insert();

                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                NewDocAmount := -TempGenJnlLine.Amount;
                NewDocAmountLCY := -TempGenJnlLine."Amount (LCY)";

                Vendor.Get("Vendor No.");
                Vendor.TestField("Vendor Posting Group");
                VendPostingGr.Get(Vendor."Vendor Posting Group");

                if ((not IsOpenBill) and ("Currency Code" <> '') and
                    ("Document Status" = "Document Status"::Honored))
                then
                    InsertGainLoss();

                case "Document Situation" of
                    "Document Situation"::"Posted BG/PO":
                        PostedDoc.Get(PostedDoc.Type::Payable, "Entry No.");
                    "Document Situation"::"Closed BG/PO":
                        ClosedDoc.Get(ClosedDoc.Type::Payable, "Entry No.");
                end;

                "Document Status" := "Document Status"::Redrawn;
                Modify();

                if StrPos(TempGenJnlLine."Bill No.", '-') = 0 then
#pragma warning disable AA0139
                    DocNo := VendLedgEntry."Bill No." + '-1'
#pragma warning restore AA0139
                else
                    DocNo := IncStr(TempGenJnlLine."Bill No.");
                GenJnlLineInit();

                if ArePostedDocs then begin
                    PostedDoc.Get(
                      PostedDoc.Type::Payable, VendLedgEntry."Entry No.");
                    if RedrawPaymentMethodCode = '' then
                        TempGenJnlLine."Payment Method Code" := PostedDoc."Payment Method Code"
                    else
                        TempGenJnlLine."Payment Method Code" := RedrawPaymentMethodCode;
                    TempGenJnlLine."Recipient Bank Account" := PostedDoc."Cust./Vendor Bank Acc. Code";
                end else begin
                    ClosedDoc.Get(
                      ClosedDoc.Type::Payable, VendLedgEntry."Entry No.");
                    if RedrawPaymentMethodCode = '' then
                        TempGenJnlLine."Payment Method Code" := ClosedDoc."Payment Method Code"
                    else
                        TempGenJnlLine."Payment Method Code" := RedrawPaymentMethodCode;
                    TempGenJnlLine."Recipient Bank Account" := ClosedDoc."Cust./Vendor Bank Acc. Code";
                end;
                TempGenJnlLine."Due Date" := RedrawDueDate;
                TempGenJnlLine."External Document No." := VendLedgEntry."External Document No.";
                InsertGenJnlLine(
                  TempGenJnlLine."Account Type"::Vendor,
                  VendLedgEntry."Vendor No.",
                  TempGenJnlLine."Document Type"::Bill,
                  NewDocAmount,
                  StrSubstNo(Text1100003Lbl, VendLedgEntry."Document No.", DocNo), DocNo);

                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

                if "Currency Code" <> '' then begin
                    Currency.SetFilter(Code, "Currency Code");
                    Currency.FindFirst();
                    if SumLCYAmt <> 0 then begin
                        if SumLCYAmt > 0 then begin
                            Currency.TestField("Residual Gains Account");
                            Account := Currency."Residual Gains Account";
                        end else begin
                            Currency.TestField("Residual Losses Account");
                            Account := Currency."Residual Losses Account";
                        end;
                        VendLedgEntry."Currency Code" := '';
                        GenJnlLineInit();
                        InsertGenJnlLine(
                          TempGenJnlLine."Account Type"::"G/L Account",
                          Account,
                          "Gen. Journal Document Type"::" ",
                          -SumLCYAmt,
                          Text1100004Lbl,
                          '');
                    end;
                end;

                if not IsOpenBill then
                    DocPost.InsertDtldVendLedgEntry(
                      VendLedgEntry,
                      NewDocAmount,
                      NewDocAmountLCY,
                      EntryType::Redrawal,
                      DocumentPostingDate);
            end;

            trigger OnPostDataItem()
            var
                TempGenJnlLine2: Record "Gen. Journal Line" temporary;
                GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
            begin
                Window.Close();

                if ArePostedDocs then
                    PostedPmtOrd.Modify()
                else
                    ClosedPmtOrd.Modify();
                if TempGenJnlLine.Find('-') then
                    repeat
                        TempGenJnlLine2 := TempGenJnlLine;
                        GenJnlPostLine.Run(TempGenJnlLine2);
                    until TempGenJnlLine.Next() = 0;

                Commit();

                Message(Text1100005Lbl, DocCount);
            end;

            trigger OnPreDataItem()
            begin
                ReasonCode := '';
                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";

                DocPost.CheckPostingDate(DocumentPostingDate);

                Window.Open(
                  Text1100001Lbl);

                DocCount := 0;

                if TempGenJnlLine.Find('+') then
                    GenJnlLineNextNo := TempGenJnlLine."Line No." + 10000
                else
                    GenJnlLineNextNo := 10000;
                TransactionNo := TempGenJnlLine."Transaction No." + 1;

                Clear(PmtOrdPostingDate);
                Find('-');
                case true of
                    PostedDoc.Get(PostedDoc.Type::Payable, "Entry No."):
                        begin
                            ArePostedDocs := true;
                            PostedPmtOrd.Get(PostedDoc."Bill Gr./Pmt. Order No.");
                            PmtOrdPostingDate := PostedPmtOrd."Posting Date";
                            BankAcc.Get(PostedPmtOrd."Bank Account No.");
                        end;
                    ClosedDoc.Get(ClosedDoc.Type::Payable, "Entry No."):
                        begin
                            ArePostedDocs := false;
                            if ClosedDoc."Bill Gr./Pmt. Order No." <> '' then begin
                                ClosedPmtOrd.Get(ClosedDoc."Bill Gr./Pmt. Order No.");
                                PmtOrdPostingDate := ClosedPmtOrd."Posting Date";
                                BankAcc.Get(ClosedPmtOrd."Bank Account No.");
                            end;
                        end;
                    else
                        CurrReport.Quit();
                end;
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
                        ToolTip = 'Specifies the posting date.';
                    }
                    field(NewDueDate; RedrawDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Due Date';
                        ToolTip = 'Specifies the new due date we want to define for the new bill that will be created by redrawing.';
                    }
                    field(NewPmtMethod; RedrawPaymentMethodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Payment Method';
                        TableRelation = "Payment Method" where("Create Bills" = const(true));
                        ToolTip = 'Specifies a new method if you want it to be different from the one in the old bill that we are redrawing.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            DocumentPostingDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if RedrawDueDate = 0D then
            Error(Text1100000Lbl);
    end;

    var
        Vendor: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        PostedDoc: Record "Posted Cartera Doc.";
        ClosedDoc: Record "Closed Cartera Doc.";
        PostedPmtOrd: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
        BankAcc: Record "Bank Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        Currency: Record Currency;
        SourceCodeSetup: Record "Source Code Setup";
        CarteraManagement: Codeunit CarteraManagement;
        DocPost: Codeunit "Document-Post";
        Text1100000Lbl: Label 'Please, specify a New Due Date for the redrawn bill.';
        Text1100001Lbl: Label 'Redrawing              #1######', Comment = '#1 = Number of bills redrawn';
        Text1100002Lbl: Label 'The New Due Date cannot be earlier than the current %1 in Bill %2 %3.', Comment = '%1 = Due Date field caption, %2 = Entry No. field caption, %3 = Entry number';
        Text1100003Lbl: Label 'Bill %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100004Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100005Lbl: Label '%1 bills have been redrawn.', Comment = '%1 = Number of bills redrawn';
        Window: Dialog;
        TransactionNo: Integer;
        ArePostedDocs: Boolean;
        DocumentPostingDate: Date;
        PmtOrdPostingDate: Date;
        SourceCode: Code[10];
        ReasonCode: Code[10];
        NewDocAmount: Decimal;
        NewDocAmountLCY: Decimal;
        GenJnlLineNextNo: Integer;
        DocCount: Integer;
        Account: Code[20];
        DocNo: Code[20];
        RedrawDueDate: Date;
        RedrawPaymentMethodCode: Code[10];
        SumLCYAmt: Decimal;
        IsOpenBill: Boolean;
        EntryType: Option " ","Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount",,,,,,,,,Settlement,Rejection,Redrawal,Expenses;

    local procedure GenJnlLineInit()
    begin
        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
        TempGenJnlLine."Transaction No." := TransactionNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."Reason Code" := ReasonCode;
        TempGenJnlLine."System-Created Entry" := true;
    end;

    local procedure InsertGenJnlLine(AccountType2: Enum "Gen. Journal Account Type"; AccountNo2: Code[20]; DocumentType2: Enum "Gen. Journal Document Type"; Amount2: Decimal; Description2: Text[250]; DocNo2: Code[20])
    var
        PreservedDueDate: Date;
        PreservedPaymentMethodCode: Code[10];
    begin
        TempGenJnlLine."Account Type" := AccountType2;
        PreservedDueDate := TempGenJnlLine."Due Date";
        PreservedPaymentMethodCode := TempGenJnlLine."Payment Method Code";
        TempGenJnlLine.Validate("Account No.", AccountNo2);
        TempGenJnlLine."Due Date" := PreservedDueDate;
        TempGenJnlLine."Payment Method Code" := PreservedPaymentMethodCode;
        TempGenJnlLine."Document Type" := DocumentType2;
        TempGenJnlLine."Document No." := VendLedgEntry."Document No.";
        TempGenJnlLine."Bill No." := DocNo2;
        TempGenJnlLine.Description := CopyStr(Description2, 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
        TempGenJnlLine.Validate(Amount, Amount2);
        TempGenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, VendLedgEntry."Dimension Set ID");

        OnBeforeInsertGenJnlLine(TempGenJnlLine, VendLedgEntry, RedrawPaymentMethodCode);
        TempGenJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertGainLoss()
    var
        GLEntry: Record "G/L Entry";
        DocMisc: Codeunit "Document-Misc";
        GainLossAmt: Decimal;
        PostingDate2: Date;
        TempCurrencyCode: Code[10];
        AccNo: Code[20];
        Type: Option Receivable,Payable;
        TypeDoc: Option Bill,Invoice;
    begin
        Currency.Get(VendLedgEntry."Currency Code");
        AccNo := GetAccount();
        if ArePostedDocs then
            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Bill then
                DocMisc.FilterGLEntry(GLEntry, AccNo, PostedDoc."Document No.", PostedDoc."No.", TypeDoc::Bill, '')
            else
                DocMisc.FilterGLEntry(GLEntry, AccNo, PostedDoc."Document No.", PostedDoc."No.", TypeDoc::Invoice, '')
        else
            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Bill then
                DocMisc.FilterGLEntry(GLEntry, AccNo, ClosedDoc."Document No.", ClosedDoc."No.", TypeDoc::Bill, '')
            else
                DocMisc.FilterGLEntry(GLEntry, AccNo, ClosedDoc."Document No.", ClosedDoc."No.", TypeDoc::Invoice, '');

        if GLEntry.Find('-') then begin
            GainLossAmt := 0;
            GLEntry.CalcSums(Amount);
            GainLossAmt := (TempGenJnlLine."Amount (LCY)" + GLEntry.Amount);
        end else begin
            PostingDate2 := 0D;
            GainLossAmt := 0;
            if ArePostedDocs then begin
                PostingDate2 :=
                  CarteraManagement.GetLastDate(VendLedgEntry."Currency Code", PostedDoc."Honored/Rejtd. at Date", Type::Payable);
                GainLossAmt := CarteraManagement.GetGainLoss(PostingDate2, DocumentPostingDate, PostedDoc."Original Amount", VendLedgEntry.
                    "Currency Code");
            end else begin
                PostingDate2 :=
                  CarteraManagement.GetLastDate(VendLedgEntry."Currency Code", ClosedDoc."Honored/Rejtd. at Date", Type::Payable);
                GainLossAmt := CarteraManagement.GetGainLoss(PostingDate2, DocumentPostingDate, ClosedDoc."Original Amount", VendLedgEntry.
                    "Currency Code");
            end;
        end;

        if GainLossAmt <> 0 then begin
            TempCurrencyCode := VendLedgEntry."Currency Code";
            VendLedgEntry."Currency Code" := '';
            if GainLossAmt < 0 then begin
                Currency.TestField("Realized Gains Acc.");
                GenJnlLineInit();
                InsertGenJnlLine(
                  TempGenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Gains Acc.",
                  "Gen. Journal Document Type"::" ",
                  GainLossAmt,
                  StrSubstNo(
                    Text1100003Lbl,
                    VendLedgEntry."Document No.",
                    VendLedgEntry."Bill No."),
                  '');
            end else begin
                Currency.TestField("Realized Losses Acc.");
                GenJnlLineInit();
                InsertGenJnlLine(
                  TempGenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Losses Acc.",
                  "Gen. Journal Document Type"::" ",
                  GainLossAmt,
                  StrSubstNo(
                    Text1100003Lbl,
                    VendLedgEntry."Document No.",
                    VendLedgEntry."Bill No."),
                  '');
            end;
            GenJnlLineInit();

            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
            InsertGenJnlLine(
              TempGenJnlLine."Account Type"::"G/L Account",
              BankAccPostingGr."G/L Account No.",
              "Gen. Journal Document Type"::" ",
              -GainLossAmt,
              StrSubstNo(
                Text1100003Lbl,
                VendLedgEntry."Document No.",
                VendLedgEntry."Bill No."),
              '');
            VendLedgEntry."Currency Code" := TempCurrencyCode;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccount(): Code[20]
    begin
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        exit(BankAccPostingGr."G/L Account No.");
    end;

    [Scope('OnPrem')]
    procedure CheckUnrealizedVAT(VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ExistVATNOReal: Boolean;
        UnrealizedVATErr: Label 'You can not redraw a bill when this contains Unrealized VAT.';
    begin
        VendLedgEntry2.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
        VendLedgEntry2.SetRange("Document No.", VendLedgEntry."Document No.");
        VendLedgEntry2.SetRange("Document Type", VendLedgEntry."Document Type");
        VendLedgEntry2.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        if VendLedgEntry2.FindFirst() then begin
            OnBeforeVendFindVATSetup(VendLedgEntry2);
            ExistVATNOReal := GenJnlPostLine.VendFindVATSetup(VATPostingSetup, VendLedgEntry2, false);
        end;
        if ExistVATNOReal then
            Error(UnrealizedVATErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; NewPaymentMethod: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendFindVATSetup(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorLedgerEntryOnBeforeCheckNewDueDate(var VendorLedgerEntry: Record "Vendor Ledger Entry"; NewDueDate: Date; var IsHandled: Boolean)
    begin
    end;
}

