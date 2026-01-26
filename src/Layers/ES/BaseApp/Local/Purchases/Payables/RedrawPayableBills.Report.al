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
                OnAfterGetVendorLedgerEntryOnBeforeCheckNewDueDate(VendLedgEntry, NewDueDate, IsHandled);
                if not IsHandled then
                    if NewDueDate < "Due Date" then begin
                        Window.Close();
                        Error(
                        Text1100002,
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
                    CarteraManagement.CreatePayableDocPayment(GenJnlLine, VendLedgEntry);
                    IsOpenBill := true;
                end else begin // settled bill
                    CarteraManagement.ReversePayableDocPayment(GenJnlLine, VendLedgEntry);
                    IsOpenBill := false;
                end;

                GenJnlLine.Insert();

                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                NewDocAmount := -GenJnlLine.Amount;
                NewDocAmountLCY := -GenJnlLine."Amount (LCY)";

                Vendor.Get("Vendor No.");
                Vendor.TestField("Vendor Posting Group");
                VendPostingGr.Get(Vendor."Vendor Posting Group");

                if ((not IsOpenBill) and ("Currency Code" <> '') and
                    ("Document Status" = "Document Status"::Honored))
                then
                    InsertGainLoss();

                case "Document Situation" of
                    "Document Situation"::"Posted BG/PO":
                        begin
                            PostedDoc.Get(PostedDoc.Type::Payable, "Entry No.");
                            AmtForCollection := PostedDoc."Amount for Collection";
                        end;
                    "Document Situation"::"Closed BG/PO":
                        begin
                            ClosedDoc.Get(ClosedDoc.Type::Payable, "Entry No.");
                            AmtForCollection := ClosedDoc."Amount for Collection";
                        end;
                end;

                "Document Status" := "Document Status"::Redrawn;
                Modify();

                if StrPos(GenJnlLine."Bill No.", '-') = 0 then
                    DocNo := VendLedgEntry."Bill No." + '-1'
                else
                    DocNo := IncStr(GenJnlLine."Bill No.");
                GenJnlLineInit();

                if ArePostedDocs then begin
                    PostedDoc.Get(
                      PostedDoc.Type::Payable, VendLedgEntry."Entry No.");
                    if NewPmtMethod = '' then
                        GenJnlLine."Payment Method Code" := PostedDoc."Payment Method Code"
                    else
                        GenJnlLine."Payment Method Code" := NewPmtMethod;
                    GenJnlLine."Recipient Bank Account" := PostedDoc."Cust./Vendor Bank Acc. Code";
                end else begin
                    ClosedDoc.Get(
                      ClosedDoc.Type::Payable, VendLedgEntry."Entry No.");
                    if NewPmtMethod = '' then
                        GenJnlLine."Payment Method Code" := ClosedDoc."Payment Method Code"
                    else
                        GenJnlLine."Payment Method Code" := NewPmtMethod;
                    GenJnlLine."Recipient Bank Account" := ClosedDoc."Cust./Vendor Bank Acc. Code";
                end;
                GenJnlLine."Due Date" := NewDueDate;
                GenJnlLine."External Document No." := VendLedgEntry."External Document No.";
                InsertGenJnlLine(
                  GenJnlLine."Account Type"::Vendor,
                  VendLedgEntry."Vendor No.",
                  GenJnlLine."Document Type"::Bill,
                  NewDocAmount,
                  StrSubstNo(Text1100003, VendLedgEntry."Document No.", DocNo), DocNo);

                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

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
                          GenJnlLine."Account Type"::"G/L Account",
                          Account,
                          "Gen. Journal Document Type"::" ",
                          -SumLCYAmt,
                          Text1100004,
                          '');
                    end;
                end;

                if not IsOpenBill then
                    DocPost.InsertDtldVendLedgEntry(
                      VendLedgEntry,
                      NewDocAmount,
                      NewDocAmountLCY,
                      EntryType::Redrawal,
                      PostingDate);
            end;

            trigger OnPostDataItem()
            var
                GenJnlLine2: Record "Gen. Journal Line" temporary;
                GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
            begin
                Window.Close();

                if ArePostedDocs then
                    PostedPmtOrd.Modify()
                else
                    ClosedPmtOrd.Modify();
                if GenJnlLine.Find('-') then
                    repeat
                        GenJnlLine2 := GenJnlLine;
                        GenJnlPostLine.Run(GenJnlLine2);
                    until GenJnlLine.Next() = 0;

                Commit();

                Message(Text1100005, DocCount);
            end;

            trigger OnPreDataItem()
            begin
                ReasonCode := '';
                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";

                DocPost.CheckPostingDate(PostingDate);

                Window.Open(
                  Text1100001);

                DocCount := 0;

                if GenJnlLine.Find('+') then
                    GenJnlLineNextNo := GenJnlLine."Line No." + 10000
                else
                    GenJnlLineNextNo := 10000;
                TransactionNo := GenJnlLine."Transaction No." + 1;

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
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date.';
                    }
                    field(NewDueDate; NewDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Due Date';
                        ToolTip = 'Specifies the new due date we want to define for the new bill that will be created by redrawing.';
                    }
                    field(NewPmtMethod; NewPmtMethod)
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
            PostingDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if NewDueDate = 0D then
            Error(Text1100000);
    end;

    var
        Text1100000: Label 'Please, specify a New Due Date for the redrawn bill.';
        Text1100001: Label 'Redrawing              #1######';
        Text1100002: Label 'The New Due Date cannot be earlier than the current %1 in Bill %2 %3.';
        Text1100003: Label 'Bill %1/%2';
        Text1100004: Label 'Residual adjust generated by rounding Amount';
        Text1100005: Label '%1 bills have been redrawn.';
        Vendor: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        GenJnlLine: Record "Gen. Journal Line" temporary;
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
        Window: Dialog;
        TransactionNo: Integer;
        ArePostedDocs: Boolean;
        PostingDate: Date;
        PmtOrdPostingDate: Date;
        SourceCode: Code[10];
        ReasonCode: Code[10];
        NewDocAmount: Decimal;
        NewDocAmountLCY: Decimal;
        GenJnlLineNextNo: Integer;
        DocCount: Integer;
        Account: Code[20];
        DocNo: Code[20];
        NewDueDate: Date;
        NewPmtMethod: Code[10];
        AmtForCollection: Decimal;
        SumLCYAmt: Decimal;
        IsOpenBill: Boolean;
        EntryType: Option " ","Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount",,,,,,,,,Settlement,Rejection,Redrawal,Expenses;

    local procedure GenJnlLineInit()
    begin
        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
        GenJnlLine."Transaction No." := TransactionNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Reason Code" := ReasonCode;
        GenJnlLine."System-Created Entry" := true;
    end;

    local procedure InsertGenJnlLine(AccountType2: Enum "Gen. Journal Account Type"; AccountNo2: Code[20]; DocumentType2: Enum "Gen. Journal Document Type"; Amount2: Decimal; Description2: Text[250]; DocNo2: Code[20])
    var
        PreservedDueDate: Date;
        PreservedPaymentMethodCode: Code[10];
    begin
        GenJnlLine."Account Type" := AccountType2;
        PreservedDueDate := GenJnlLine."Due Date";
        PreservedPaymentMethodCode := GenJnlLine."Payment Method Code";
        GenJnlLine.Validate("Account No.", AccountNo2);
        GenJnlLine."Due Date" := PreservedDueDate;
        GenJnlLine."Payment Method Code" := PreservedPaymentMethodCode;
        GenJnlLine."Document Type" := DocumentType2;
        GenJnlLine."Document No." := VendLedgEntry."Document No.";
        GenJnlLine."Bill No." := DocNo2;
        GenJnlLine.Description := CopyStr(Description2, 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
        GenJnlLine.Validate(Amount, Amount2);
        GenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(GenJnlLine, VendLedgEntry."Dimension Set ID");

        OnBeforeInsertGenJnlLine(GenJnlLine, VendLedgEntry, NewPmtMethod);
        GenJnlLine.Insert();
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
            GainLossAmt := (GenJnlLine."Amount (LCY)" + GLEntry.Amount);
        end else begin
            PostingDate2 := 0D;
            GainLossAmt := 0;
            if ArePostedDocs then begin
                PostingDate2 :=
                  CarteraManagement.GetLastDate(VendLedgEntry."Currency Code", PostedDoc."Honored/Rejtd. at Date", Type::Payable);
                GainLossAmt := CarteraManagement.GetGainLoss(PostingDate2, PostingDate, PostedDoc."Original Amount", VendLedgEntry.
                    "Currency Code");
            end else begin
                PostingDate2 :=
                  CarteraManagement.GetLastDate(VendLedgEntry."Currency Code", ClosedDoc."Honored/Rejtd. at Date", Type::Payable);
                GainLossAmt := CarteraManagement.GetGainLoss(PostingDate2, PostingDate, ClosedDoc."Original Amount", VendLedgEntry.
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
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Gains Acc.",
                  "Gen. Journal Document Type"::" ",
                  GainLossAmt,
                  StrSubstNo(
                    Text1100003,
                    VendLedgEntry."Document No.",
                    VendLedgEntry."Bill No."),
                  '');
            end else begin
                Currency.TestField("Realized Losses Acc.");
                GenJnlLineInit();
                InsertGenJnlLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Losses Acc.",
                  "Gen. Journal Document Type"::" ",
                  GainLossAmt,
                  StrSubstNo(
                    Text1100003,
                    VendLedgEntry."Document No.",
                    VendLedgEntry."Bill No."),
                  '');
            end;
            GenJnlLineInit();

            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
            InsertGenJnlLine(
              GenJnlLine."Account Type"::"G/L Account",
              BankAccPostingGr."G/L Account No.",
              "Gen. Journal Document Type"::" ",
              -GainLossAmt,
              StrSubstNo(
                Text1100003,
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
        ExistVATNOReal: Boolean;
        Text1100001: Label 'You can not redraw a bill when this contains Unrealized VAT.';
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
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
            Error(Text1100001);
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

