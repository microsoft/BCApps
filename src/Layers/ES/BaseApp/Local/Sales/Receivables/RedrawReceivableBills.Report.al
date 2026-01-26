// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;

report 7000096 "Redraw Receivable Bills"
{
    Caption = 'Redraw Receivable Bills';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(CustLedgEntry; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");

            trigger OnAfterGetRecord()
            begin
                CheckUnrealizedVAT(CustLedgEntry);

                Clear(FeeRange);
                Clear(FinanceChargeTerms);

                if NewDueDate < "Due Date" then
                    Error(
                      Text1100003,
                      FieldCaption("Due Date"),
                      FieldCaption("Entry No."),
                      "Entry No.");
                SumLCYAmt := 0;
                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                GenJnlLineInit();
                CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if "Remaining Amount" <> 0 then begin // open bill
                    CarteraManagement.CreateReceivableDocPayment(GenJnlLine, CustLedgEntry);
                    IsOpenBill := true;
                end else begin // settled bill
                    CarteraManagement.ReverseReceivableDocPayment(GenJnlLine, CustLedgEntry);
                    IsOpenBill := false;
                end;
                GenJnlLine.Insert();

                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                NewDocAmount := -GenJnlLine.Amount;
                NewDocAmountLCY := -GenJnlLine."Amount (LCY)";

                Customer.Get("Customer No.");
                Customer.TestField("Customer Posting Group");
                CustPostingGr.Get(Customer."Customer Posting Group");

                if ((not IsOpenBill) and
                    ("Currency Code" <> '') and
                    ("Document Status" = "Document Status"::Honored))
                then
                    InsertGainLoss();

                case "Document Situation" of
                    "Document Situation"::"Posted BG/PO":
                        begin
                            PostedDoc.Get(PostedDoc.Type::Receivable, "Entry No.");
                            AmtForCollection := PostedDoc."Remaining Amount";
                        end;
                    "Document Situation"::"Closed BG/PO":
                        begin
                            ClosedDoc.Get(ClosedDoc.Type::Receivable, "Entry No.");
                            AmtForCollection := ClosedDoc."Remaining Amount";
                        end;
                end;

                if BillGrPostingDate <> 0D then begin
                    if IncludeDiscCollExpenses then
                        if Discount then begin
                            FeeRange.CalcDiscExpensesAmt(
                              BankAcc."Operation Fees Code",
                              BankAcc."Currency Code",
                              AmtForCollection,
                              "Entry No.");
                            FeeRange.CalcDiscInterestsAmt(
                              BankAcc."Operation Fees Code",
                              BankAcc."Currency Code",
                              NewDueDate - "Due Date",
                              AmtForCollection,
                              "Entry No.");
                        end else
                            FeeRange.CalcCollExpensesAmt(
                              BankAcc."Operation Fees Code",
                              BankAcc."Currency Code",
                              AmtForCollection,
                              "Entry No.");
                    if IncludeRejExpenses then
                        FeeRange.CalcRejExpensesAmt(
                          BankAcc."Operation Fees Code",
                          BankAcc."Currency Code",
                          AmtForCollection,
                          "Entry No.");
                    if IncludeFinanceCharges then begin
                        Customer.TestField("Fin. Charge Terms Code");
                        FinanceChargeTerms.CalcFinChargesAmt(
                          "Due Date",
                          Customer."Fin. Charge Terms Code",
                          "Currency Code",
                          AmtForCollection,
                          NewDueDate - "Due Date");
                    end;
                end;

                if StrPos(GenJnlLine."Bill No.", '-') = 0 then
                    DocNo := CustLedgEntry."Bill No." + '-1'
                else
                    DocNo := IncStr(GenJnlLine."Bill No.");
                TempCustLedgEntryInit(CustLedgEntry, DocNo, NewDocAmount, NewDocAmountLCY);
                GenJnlLineInit();
                if ArePostedDocs then begin
                    PostedDoc.Get(
                      PostedDoc.Type::Receivable, CustLedgEntry."Entry No.");
                    if NewPmtMethod = '' then
                        GenJnlLine."Payment Method Code" := PostedDoc."Payment Method Code"
                    else
                        GenJnlLine."Payment Method Code" := NewPmtMethod;
                    GenJnlLine."Recipient Bank Account" := PostedDoc."Cust./Vendor Bank Acc. Code";
                end else begin
                    ClosedDoc.Get(
                      ClosedDoc.Type::Receivable, CustLedgEntry."Entry No.");
                    if NewPmtMethod = '' then
                        GenJnlLine."Payment Method Code" := ClosedDoc."Payment Method Code"
                    else
                        GenJnlLine."Payment Method Code" := NewPmtMethod;
                    GenJnlLine."Recipient Bank Account" := ClosedDoc."Cust./Vendor Bank Acc. Code";
                end;
                GenJnlLine."Due Date" := NewDueDate;
                InsertGenJnlLine(
                  GenJnlLine."Account Type"::Customer,
                  CustLedgEntry."Customer No.",
                  GenJnlLine."Document Type"::Bill,
                  NewDocAmount +
                  FeeRange.GetTotalCollExpensesAmt() +
                  FeeRange.GetTotalDiscExpensesAmt() +
                  FeeRange.GetTotalDiscInterestsAmt() +
                  FeeRange.GetTotalRejExpensesAmt() +
                  FinanceChargeTerms.GetTotalFinChargesAmt(),
                  StrSubstNo(
                    Text1100004,
                    CustLedgEntry."Document No.",
                    DocNo),
                  DocNo);

                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                if IncludeDiscCollExpenses then begin
                    CustPostingGr.TestField("Finance Income Acc.");
                    GenJnlLineInit();
                    InsertGenJnlLine(
                      GenJnlLine."Account Type"::"G/L Account",
                      CustPostingGr."Finance Income Acc.",
                      "Gen. Journal Document Type"::" ",
                      -(FeeRange.GetTotalDiscExpensesAmt() + FeeRange.GetTotalCollExpensesAmt()),
                      StrSubstNo(
                        Text1100005,
                        CustLedgEntry."Document No.",
                        CustLedgEntry."Bill No."),
                      '');

                    SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                    if Discount then begin
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        BankAccPostingGr.TestField("Discount Interest Acc.");
                        GenJnlLineInit();
                        InsertGenJnlLine(
                          GenJnlLine."Account Type"::"G/L Account",
                          BankAccPostingGr."Discount Interest Acc.",
                          "Gen. Journal Document Type"::" ",
                          -FeeRange.GetTotalDiscInterestsAmt(),
                          StrSubstNo(
                            Text1100006,
                            CustLedgEntry."Document No.",
                            CustLedgEntry."Bill No."),
                          '');

                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                    end;
                end;

                if IncludeRejExpenses then begin
                    CustPostingGr.TestField("Finance Income Acc.");
                    GenJnlLineInit();
                    InsertGenJnlLine(
                      GenJnlLine."Account Type"::"G/L Account",
                      CustPostingGr."Finance Income Acc.",
                      "Gen. Journal Document Type"::" ",
                      -FeeRange.GetTotalRejExpensesAmt(),
                      StrSubstNo(
                        Text1100007,
                        CustLedgEntry."Document No.",
                        CustLedgEntry."Bill No."),
                      '');

                    SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                end;

                if IncludeFinanceCharges then begin
                    CustPostingGr.TestField("Finance Income Acc.");
                    GenJnlLineInit();
                    InsertGenJnlLine(
                      GenJnlLine."Account Type"::"G/L Account",
                      CustPostingGr."Finance Income Acc.",
                      "Gen. Journal Document Type"::" ",
                      -FinanceChargeTerms.GetTotalFinChargesAmt(),
                      StrSubstNo(
                        Text1100008,
                        CustLedgEntry."Document No.",
                        CustLedgEntry."Bill No."),
                      '');

                    SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                end;
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
                        CustLedgEntry."Currency Code" := '';
                        GenJnlLineInit();
                        InsertGenJnlLine(
                          GenJnlLine."Account Type"::"G/L Account",
                          Account,
                          "Gen. Journal Document Type"::" ",
                          -SumLCYAmt,
                          Text1100009,
                          '');
                    end;
                end;

                "Document Status" := "Document Status"::Redrawn;

                Modify();

                if not IsOpenBill then
                    DocPost.InsertDtldCustLedgEntry(
                      CustLedgEntry,
                      NewDocAmount,
                      NewDocAmountLCY,
                      EntryType::Redrawal,
                      PostingDate);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
                // CarteraDimMgt.CopyJnlLinDim(GenJnlLine,GenJnlLine,TempJnlLineDim,JnlLineDim2);
                Commit();
                GenJnlLine.Reset();
                GenJnlTemplate.Get(TemplName);
                GenJnlLine.FilterGroup := 2;
                GenJnlLine.SetRange("Journal Template Name", TemplName);
                GenJnlLine.FilterGroup := 0;
                GenJnlManagement.SetName(BatchName, GenJnlLine);
                CarteraJnlForm.SetTableView(GenJnlLine);
                CarteraJnlForm.SetRecord(GenJnlLine);
                CarteraJnlForm.SetJnlBatchName(BatchName);
                CarteraJnlForm.AllowClosing(true);
                CarteraJnlForm.RunModal();

                SplitDetailedCVEntry();

                Message(Text1100010, DocCount);
            end;

            trigger OnPreDataItem()
            begin
                IncludeExpenses := IncludeDiscCollExpenses or IncludeRejExpenses or IncludeFinanceCharges;

                ReasonCode := GenJnlBatch."Reason Code";
                GenJnlTemplate.Get(TemplName);
                SourceCode := GenJnlTemplate."Source Code";

                DocPost.CheckPostingDate(PostingDate);

                Window.Open(
                  Text1100002);

                DocCount := 0;

                GenJnlLine.SetFilter("Journal Template Name", TemplName);
                GenJnlLine.SetFilter("Journal Batch Name", BatchName);
                if GenJnlLine.FindLast() then
                    GenJnlLineNextNo := GenJnlLine."Line No." + 10000
                else
                    GenJnlLineNextNo := 10000;
                TransactionNo := GenJnlLine."Transaction No." + 1;

                Clear(BillGrPostingDate);
                Find('-');
                case true of
                    PostedDoc.Get(PostedDoc.Type::Receivable, "Entry No."):
                        begin
                            ArePostedDocs := true;
                            PostedBillGr.Get(PostedDoc."Bill Gr./Pmt. Order No.");
                            BillGrPostingDate := PostedBillGr."Posting Date";
                            if PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount then
                                Discount := true
                            else
                                Discount := false;
                            BankAcc.Get(PostedBillGr."Bank Account No.");
                        end;
                    ClosedDoc.Get(ClosedDoc.Type::Receivable, "Entry No."):
                        begin
                            ArePostedDocs := false;
                            if ClosedDoc."Bill Gr./Pmt. Order No." <> '' then begin
                                ClosedBillGr.Get(ClosedDoc."Bill Gr./Pmt. Order No.");
                                BillGrPostingDate := ClosedBillGr."Posting Date";
                                if ClosedBillGr."Dealing Type" = ClosedBillGr."Dealing Type"::Discount then
                                    Discount := true
                                else
                                    Discount := false;
                                BankAcc.Get(ClosedBillGr."Bank Account No.");
                            end;
                        end;
                    else
                        CurrReport.Quit();
                end;

                if IncludeDiscCollExpenses then
                    if Discount then begin
                        FeeRange.InitDiscExpenses(
                          BankAcc."Operation Fees Code",
                          BankAcc."Currency Code");
                        FeeRange.InitDiscInterests(
                          BankAcc."Operation Fees Code",
                          BankAcc."Currency Code");
                    end else
                        FeeRange.InitCollExpenses(
                          BankAcc."Operation Fees Code",
                          BankAcc."Currency Code");
                if IncludeRejExpenses then
                    FeeRange.InitRejExpenses(
                      BankAcc."Operation Fees Code",
                      BankAcc."Currency Code");

                if BankAcc.Find() and (IncludeDiscCollExpenses or IncludeRejExpenses) then
                    BankAcc.TestField("Operation Fees Code");
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
                        ToolTip = 'Specifies the date the batch job of redrawn bills is posted. By default, today''s date is used.';
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
                    group(Include)
                    {
                        Caption = 'Include';
                        field(DiscCollExpenses; IncludeDiscCollExpenses)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Disc./Coll. Expenses';
                            ToolTip = 'Specifies if the expense amounts you have chosen for the redrawn bill will be included. If you leave the check box blank, the redrawn bill will be for the same amount as the old bill.';
                        }
                        field(RejectionExpenses; IncludeRejExpenses)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Rejection Expenses';
                            ToolTip = 'Specifies if the expense amounts you have chosen for the redrawn bill will be included. If you leave the check box blank, the redrawn bill will be for the same amount as the old bill.';
                        }
                        field(FinanceCharges; IncludeFinanceCharges)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Finance Charges';
                            ToolTip = 'Specifies if the expense amounts you have chosen for the redrawn bill will be included. If you leave the check box blank, the redrawn bill will be for the same amount as the old bill.';
                        }
                    }
                    field(AuxJnlTemplateName; TemplName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aux. Jnl. Template Name';
                        TableRelation = "Gen. Journal Template".Name where(Type = const(Cartera),
                                                                            Recurring = const(false));
                        ToolTip = 'Specifies the name of general journal template where the payment order is posted.';

                        trigger OnValidate()
                        var
                            GenJournalTemplate: Record "Gen. Journal Template";
                        begin
                            if TemplName = '' then
                                BatchName := ''
                            else begin
                                GenJournalTemplate.Get(TemplName);
                                GenJournalTemplate.TestField(Type, GenJournalTemplate.Type::Cartera);
                            end;
                        end;
                    }
                    field(AuxJnlBatchName; BatchName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aux. Jnl. Batch Name';
                        TableRelation = "Gen. Journal Batch".Name;
                        ToolTip = 'Specifies the name of general journal batch where the payment order is posted.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if TemplName = '' then
                                exit;

                            if GenJnlBatch.Get(TemplName, Text) then;
                            GenJnlBatch.SetRange("Journal Template Name", TemplName);
                            if PAGE.RunModal(PAGE::"General Journal Batches", GenJnlBatch) = ACTION::LookupOK then
                                BatchName := GenJnlBatch.Name;
                        end;

                        trigger OnValidate()
                        begin
                            BatchNameOnValidate();
                            BatchNameOnAfterValidate();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            IncludeExpenses := IncludeDiscCollExpenses or IncludeRejExpenses;
        end;

        trigger OnOpenPage()
        begin
            PostingDate := WorkDate();
            TemplName := '';
            BatchName := '';
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if NewDueDate = 0D then
            Error(Text1100000);

        if not GenJnlBatch.Get(TemplName, BatchName) then
            Error(Text1100001);
    end;

    var
        Text1100000: Label 'Please, specify a New Due Date for the redrawn bill.';
        Text1100001: Label 'Please fill in both the Template Name and the Batch Name of the Auxiliary Journal with correct values.';
        Text1100002: Label 'Redrawing              #1######';
        Text1100003: Label 'The New Due Date cannot be earlier than the current %1 in Bill %2 %3.';
        Text1100004: Label 'Bill %1/%2';
        Text1100005: Label 'Bill %1/%2 Discount/Collection Expenses';
        Text1100006: Label 'Bill %1/%2 Discount Interests';
        Text1100007: Label 'Bill %1/%2 Rejection Expenses';
        Text1100008: Label 'Bill %1/%2 Finance Charges';
        Text1100009: Label 'Residual adjust generated by rounding Amount';
        Text1100010: Label '%1 bills have been prepared for redrawal.';
        Customer: Record Customer;
        CustPostingGr: Record "Customer Posting Group";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PostedDoc: Record "Posted Cartera Doc.";
        ClosedDoc: Record "Closed Cartera Doc.";
        FeeRange: Record "Fee Range";
        FinanceChargeTerms: Record "Finance Charge Terms";
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        BankAcc: Record "Bank Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        Currency: Record Currency;
        TempCVLedgEntryBuf: Record "CV Ledger Entry Buffer" temporary;
        CarteraManagement: Codeunit CarteraManagement;
        DocPost: Codeunit "Document-Post";
        GenJnlManagement: Codeunit GenJnlManagement;
        CarteraJnlForm: Page "Cartera Journal";
        Window: Dialog;
        TransactionNo: Integer;
        IncludeDiscCollExpenses: Boolean;
        IncludeRejExpenses: Boolean;
        IncludeFinanceCharges: Boolean;
        IncludeExpenses: Boolean;
        ArePostedDocs: Boolean;
        Discount: Boolean;
        IsOpenBill: Boolean;
        PostingDate: Date;
        BillGrPostingDate: Date;
        BatchName: Code[10];
        TemplName: Code[10];
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
        EntryType: Option " ","Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount",,,,,,,,,Settlement,Rejection,Redrawal,Expenses;

    local procedure GenJnlLineInit()
    begin
        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
        GenJnlLine."Transaction No." := TransactionNo;
        GenJnlLine."Journal Template Name" := TemplName;
        GenJnlLine."Journal Batch Name" := BatchName;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Reason Code" := ReasonCode;
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
        GenJnlLine."Document No." := CustLedgEntry."Document No.";
        GenJnlLine."Bill No." := DocNo2;
        GenJnlLine.Description := CopyStr(Description2, 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
        GenJnlLine.Validate(Amount, Amount2);
        GenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(GenJnlLine, CustLedgEntry."Dimension Set ID");
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
            GenJnlLine.Validate("Direct Debit Mandate ID", CustLedgEntry."Direct Debit Mandate ID");
        OnBeforeGenJnlLineInsert(GenJnlLine, CustLedgEntry, NewPmtMethod);
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
        Currency.Get(CustLedgEntry."Currency Code");
        AccNo := GetAccount();
        if ArePostedDocs then
            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Bill then
                DocMisc.FilterGLEntry(GLEntry, AccNo, PostedDoc."Document No.", PostedDoc."No.", TypeDoc::Bill, '')
            else
                if PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount then
                    DocMisc.FilterGLEntry(GLEntry, AccNo, PostedDoc."Document No.", PostedDoc."No.", TypeDoc::Invoice, PostedDoc."Account No.")
                else
                    DocMisc.FilterGLEntry(GLEntry, AccNo, PostedDoc."Document No.", PostedDoc."No.", TypeDoc::Invoice, '')
        else
            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Bill then
                DocMisc.FilterGLEntry(GLEntry, AccNo, ClosedDoc."Document No.", ClosedDoc."No.", TypeDoc::Bill, '')
            else
                if ClosedDoc."Dealing Type" = ClosedDoc."Dealing Type"::Discount then
                    DocMisc.FilterGLEntry(GLEntry, AccNo, ClosedDoc."Document No.", ClosedDoc."No.", TypeDoc::Invoice, ClosedDoc."Account No.")
                else
                    DocMisc.FilterGLEntry(GLEntry, AccNo, ClosedDoc."Document No.", ClosedDoc."No.", TypeDoc::Invoice, '');

        if GLEntry.Find('-') then begin
            GainLossAmt := 0;
            GLEntry.CalcSums(Amount);
            GainLossAmt := -(GenJnlLine."Amount (LCY)" + GLEntry.Amount);
        end else begin
            PostingDate2 := 0D;
            GainLossAmt := 0;
            if ArePostedDocs then begin
                PostingDate2 := CarteraManagement.GetLastDate(
                    CustLedgEntry."Currency Code",
                    PostedDoc."Honored/Rejtd. at Date",
                    Type::Receivable);
                GainLossAmt := CarteraManagement.GetGainLoss(
                    PostingDate2,
                    PostingDate,
                    PostedDoc."Original Amount",
                    CustLedgEntry."Currency Code");
            end else begin
                PostingDate2 :=
                  CarteraManagement.GetLastDate(CustLedgEntry."Currency Code", ClosedDoc."Honored/Rejtd. at Date", Type::Receivable
                    );
                GainLossAmt := CarteraManagement.GetGainLoss(
                    PostingDate2,
                    PostingDate,
                    ClosedDoc."Original Amount",
                    CustLedgEntry."Currency Code");
            end;
        end;
        if GainLossAmt <> 0 then begin
            TempCurrencyCode := CustLedgEntry."Currency Code";
            CustLedgEntry."Currency Code" := '';
            if GainLossAmt > 0 then begin
                Currency.TestField("Realized Gains Acc.");
                GenJnlLineInit();
                InsertGenJnlLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Gains Acc.",
                  "Gen. Journal Document Type"::" ",
                  -GainLossAmt,
                  StrSubstNo(
                    Text1100004,
                    CustLedgEntry."Document No.",
                    CustLedgEntry."Bill No."),
                  '');
            end else begin
                Currency.TestField("Realized Losses Acc.");
                GenJnlLineInit();
                InsertGenJnlLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Losses Acc.",
                  "Gen. Journal Document Type"::" ",
                  -GainLossAmt,
                  StrSubstNo(
                    Text1100004,
                    CustLedgEntry."Document No.",
                    CustLedgEntry."Bill No."),
                  '');
            end;
            GenJnlLineInit();

            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
            InsertGenJnlLine(
              GenJnlLine."Account Type"::"G/L Account",
              BankAccPostingGr."G/L Account No.",
              "Gen. Journal Document Type"::" ",
              GainLossAmt,
              StrSubstNo(
                Text1100004,
                CustLedgEntry."Document No.",
                CustLedgEntry."Bill No."),
              '');
            CustLedgEntry."Currency Code" := TempCurrencyCode;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccount(): Code[20]
    begin
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        if PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount then
            if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then
                exit(BankAccPostingGr."Liabs. for Disc. Bills Acc.")
            else
                exit(BankAccPostingGr."Liabs. for Factoring Acc.")
        else
            exit(BankAccPostingGr."G/L Account No.");
    end;

    [Scope('OnPrem')]
    procedure SplitDetailedCVEntry()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        ExpAmount: Decimal;
        ExpAmountLCY: Decimal;
    begin
        if TempCVLedgEntryBuf.Find('-') then
            repeat
                DtldCustLedgEntry.Reset();
                DtldCustLedgEntry.SetRange("Entry Type", EntryType::"Initial Entry");
                DtldCustLedgEntry.SetRange("Posting Date", PostingDate);
                DtldCustLedgEntry.SetRange("Document Type", TempCVLedgEntryBuf."Document Type"::Bill);
                DtldCustLedgEntry.SetRange("Document No.", TempCVLedgEntryBuf."Document No.");
                DtldCustLedgEntry.SetRange("Customer No.", TempCVLedgEntryBuf."CV No.");
                DtldCustLedgEntry.SetRange("Bill No.", TempCVLedgEntryBuf."Bill No.");

                if DtldCustLedgEntry.FindFirst() then begin
                    ExpAmount := DtldCustLedgEntry.Amount - TempCVLedgEntryBuf.Amount;
                    ExpAmountLCY := DtldCustLedgEntry."Amount (LCY)" - TempCVLedgEntryBuf."Amount (LCY)";
                    if ExpAmount <> 0 then begin
                        DtldCustLedgEntry.Amount := TempCVLedgEntryBuf.Amount;
                        DtldCustLedgEntry."Amount (LCY)" := TempCVLedgEntryBuf."Amount (LCY)";
                        CustLedgEntry2.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
                        DocPost.InsertDtldCustLedgEntry(
                          CustLedgEntry2,
                          ExpAmount,
                          ExpAmountLCY,
                          EntryType::Expenses,
                          PostingDate);
                        DtldCustLedgEntry.Modify();
                    end;
                end;
            until TempCVLedgEntryBuf.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure TempCustLedgEntryInit(CustLedgEntry3: Record "Cust. Ledger Entry"; DocNo2: Code[20]; InitialDocAmount: Decimal; InitialDocAmountLCY: Decimal)
    begin
        TempCVLedgEntryBuf.Init();
        TempCVLedgEntryBuf.TransferFields(CustLedgEntry3);
        TempCVLedgEntryBuf."CV No." := CustLedgEntry."Customer No.";
        TempCVLedgEntryBuf.Insert();
        TempCVLedgEntryBuf."Bill No." := DocNo2;
        TempCVLedgEntryBuf.Amount := InitialDocAmount;
        TempCVLedgEntryBuf."Amount (LCY)" := InitialDocAmountLCY;
        TempCVLedgEntryBuf.Modify();
    end;

    [Scope('OnPrem')]
    procedure CheckUnrealizedVAT(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        ExistVATNOReal: Boolean;
        VATPostingSetup: Record "VAT Posting Setup";
        Text1100101: Label 'You can not redraw a bill when this contains Unrealized VAT.';
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUnrealizedVAT(CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry2.SetCurrentKey("Document No.", "Document Type", "Customer No.");
        CustLedgEntry2.SetRange("Document No.", CustLedgEntry."Document No.");
        CustLedgEntry2.SetRange("Document Type", CustLedgEntry."Document Type");
        CustLedgEntry2.SetRange("Customer No.", CustLedgEntry."Customer No.");
        if CustLedgEntry2.FindFirst() then
            ExistVATNOReal := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry2, true);
        if ExistVATNOReal then
            Error(Text1100101);
    end;

    local procedure BatchNameOnAfterValidate()
    begin
        if TemplName = '' then
            BatchName := '';
    end;

    local procedure BatchNameOnValidate()
    begin
        if BatchName = '' then
            exit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUnrealizedVAT(var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var NewPaymentMethod: Code[10])
    begin
    end;
}

