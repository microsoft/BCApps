// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Utilities;

report 7000099 "Post Bill Group"
{
    Caption = 'Post Bill Group';
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Bill Group" = imd,
                  TableData "Posted Bill Group" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(BillGr; "Bill Group")
        {
            DataItemTableView = sorting("No.");
            dataitem(Doc; "Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Receivable));

                trigger OnAfterGetRecord()
                var
                    IsHandled: Boolean;
                begin
                    DocCount := DocCount + 1;
                    Window.Update(2, DocCount);

                    TestField("Currency Code", BillGr."Currency Code");

                    TestField("Collection Agent", "Collection Agent"::Bank);
                    TestField("Due Date");
                    if "Remaining Amount" = 0 then
                        FieldError("Remaining Amount");
                    TestField(Type, Type::Receivable);
                    if Accepted = Accepted::No then
                        FieldError(Accepted);

                    if BillGr.Factoring <> BillGr.Factoring::" " then begin
                        PostDocToFactoring(Doc);
                        CurrReport.Skip();
                    end;
                    CustLedgEntry.Get("Entry No.");
                    CustPostingGr.Get(CustLedgEntry."Customer Posting Group");
                    if CustLedgEntry."Applies-to ID" <> '' then
                        Error(Text1100010, "Document No.", "No.");
                    if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                        CustPostingGr.TestField("Discted. Bills Acc.");
                        AccountNo := CustPostingGr."Discted. Bills Acc.";
                        if "Due Date" < BillGr."Posting Date" then
                            FieldError("Due Date",
                                StrSubstNo(Text1100004, BillGr.FieldCaption("Posting Date"), BillGr.TableCaption()));
                        FeeRange.CalcDiscExpensesAmt(
                            BankAcc."Operation Fees Code", BankAcc."Currency Code", "Remaining Amount", CustLedgEntry."Entry No.");
                        FeeRange.CalcDiscInterestsAmt(
                            BankAcc."Operation Fees Code", BankAcc."Currency Code", "Due Date" - BillGr."Posting Date",
                            "Remaining Amount", CustLedgEntry."Entry No.");
                    end else begin
                        CustPostingGr.TestField("Bills on Collection Acc.");
                        AccountNo := CustPostingGr."Bills on Collection Acc.";
                        FeeRange.CalcCollExpensesAmt(
                            BankAcc."Operation Fees Code", BankAcc."Currency Code", "Remaining Amount", CustLedgEntry."Entry No.");
                    end;

                    CustPostingGr.TestField("Bills Account");
                    BalanceAccount := CustPostingGr."Bills Account";
                    IsHandled := false;
                    OnAfterGetBillsAccounts(Doc, CustLedgEntry, AccountNo, BalanceAccount, BillGr, TempBGPOPostBuffer, IsHandled);
                    if not IsHandled then
                        if TempBGPOPostBuffer.Get(AccountNo, BalanceAccount, CustLedgEntry."Entry No.") then begin
                            TempBGPOPostBuffer.Amount := TempBGPOPostBuffer.Amount + "Remaining Amount";
                            if "Currency Code" <> '' then
                                TempBGPOPostBuffer."Gain - Loss Amount (LCY)" += GainLossManagement("Remaining Amount", "Posting Date", "Currency Code");
                            TempBGPOPostBuffer.Modify();
                        end else begin
                            TempBGPOPostBuffer.Account := AccountNo;
                            TempBGPOPostBuffer."Balance Account" := BalanceAccount;
                            TempBGPOPostBuffer."Entry No." := CustLedgEntry."Entry No.";
                            TempBGPOPostBuffer."Global Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                            TempBGPOPostBuffer."Global Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                            TempBGPOPostBuffer.Amount := "Remaining Amount";
                            if "Currency Code" <> '' then
                                TempBGPOPostBuffer."Gain - Loss Amount (LCY)" := GainLossManagement("Remaining Amount", "Posting Date", "Currency Code");
                            TempBGPOPostBuffer.Insert();
                        end;

                    TempPostedDocBuffer.Init();
                    TempPostedDocBuffer.TransferFields(Doc);
                    TempPostedDocBuffer."Original Document No." := "Original Document No.";
                    TempPostedDocBuffer."Category Code" := "Category Code";
                    TempPostedDocBuffer."Bank Account No." := BillGr."Bank Account No.";
                    TempPostedDocBuffer."Dealing Type" := BillGr."Dealing Type";
                    TempPostedDocBuffer."Remaining Amount" := "Remaining Amount";
                    TempPostedDocBuffer."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                    TempPostedDocBuffer.Insert();
                end;

                trigger OnPostDataItem()
                var
                    TempCurrencyCode: Code[10];
                    CustLedgEntry2: Record "Cust. Ledger Entry";
                begin
                    OnBeforeDocOnPostDataItem(Doc, TempBGPOPostBuffer);

                    GroupAmount := 0;
                    SumLCYAmt := 0;
                    if not TempBGPOPostBuffer.Find('-') then
                        exit;

                    GenJnlLine.LockTable();
                    GenJnlLine.SetRange("Journal Template Name", TemplName);
                    GenJnlLine.SetRange("Journal Batch Name", BatchName);
                    if GenJnlLine.FindLast() then begin
                        GenJnlLineNextNo := GenJnlLine."Line No.";
                        TransactionNo := GenJnlLine."Transaction No." + 1;
                    end;

                    repeat
                        CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                        InsertGenJournalLine(
                            GenJnlLine."Account Type"::"G/L Account", TempBGPOPostBuffer.Account, TempBGPOPostBuffer.Amount,
                            BillGr."Posting Description", CustLedgEntry2, CustLedgEntry."Original Currency Factor");
                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                        InsertGenJournalLine(
                            GenJnlLine."Account Type"::"G/L Account", TempBGPOPostBuffer."Balance Account", -TempBGPOPostBuffer.Amount,
                            BillGr."Posting Description", CustLedgEntry2, CustLedgEntry."Original Currency Factor");
                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                        if CheckCurrFact(Doc, BillGr) then
                            if TempBGPOPostBuffer."Gain - Loss Amount (LCY)" <> 0 then begin
                                TempCurrencyCode := BillGr."Currency Code";
                                BillGr."Currency Code" := '';
                                if TempBGPOPostBuffer."Gain - Loss Amount (LCY)" > 0 then begin
                                    Currency.TestField("Realized Gains Acc.");
                                    InsertGenJournalLine(
                                      GenJnlLine."Account Type"::"G/L Account", Currency."Realized Gains Acc.", -TempBGPOPostBuffer."Gain - Loss Amount (LCY)",
                                      BillGr."Posting Description", CustLedgEntry2, 0);
                                end else begin
                                    Currency.TestField("Realized Losses Acc.");
                                    InsertGenJournalLine(
                                        GenJnlLine."Account Type"::"G/L Account", Currency."Realized Losses Acc.", -TempBGPOPostBuffer."Gain - Loss Amount (LCY)",
                                      BillGr."Posting Description", CustLedgEntry2, 0);
                                end;
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                InsertGenJournalLine(
                                  GenJnlLine."Account Type"::"G/L Account", TempBGPOPostBuffer."Balance Account", TempBGPOPostBuffer."Gain - Loss Amount (LCY)",
                                  BillGr."Posting Description", CustLedgEntry2, 0);
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                BillGr."Currency Code" := TempCurrencyCode;
                            end;

                        if BillGr."Dealing Type" <> BillGr."Dealing Type"::Collection then begin
                            BankAcc.TestField("Bank Acc. Posting Group");
                            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");

                            if BillGr.Factoring = BillGr.Factoring::" " then begin
                                BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                                InsertGenJournalLine(
                                  GenJnlLine."Account Type"::"G/L Account", BankAccPostingGr."Liabs. for Disc. Bills Acc.", -TempBGPOPostBuffer.Amount,
                                  BillGr."Posting Description", CustLedgEntry2, 0);
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                CalcBankAccount(BillGr."Bank Account No.", TempBGPOPostBuffer.Amount, CustLedgEntry2."Entry No.");
                            end;
                        end;
                        GroupAmount := GroupAmount + TempBGPOPostBuffer.Amount;
                    until TempBGPOPostBuffer.Next() = 0;

                    if (BillGr.Factoring <> BillGr.Factoring::" ") and
                       (BillGr."Dealing Type" <> BillGr."Dealing Type"::Collection)
                    then
                        InsertFactoringLiabsAcc();

                    if BillGr."Dealing Type" = BillGr."Dealing Type"::Collection then begin
                        FinishCode();
                        Commit();
                        if BillGr.Factoring <> BillGr.Factoring::" " then
                            if not HidePrintDialog then
                                Message(Text1100005, BillGr."No.")
                            else
                                if not HidePrintDialog then
                                    Message(Text1100006, BillGr."No.");
                        exit;
                    end;

                    if BillGr.Factoring = BillGr.Factoring::" " then begin
                        if FeeRange.GetTotalDiscExpensesAmt() <> 0 then begin
                            BankAccPostingGr.TestField("Bank Services Acc.");
                            NoRegs := FeeRange.NoRegsDiscExpenses();
                            for i := 0 to NoRegs - 1 do begin
                                FeeRange.GetDiscExpensesAmt(TempBGPOPostBuffer, i);
                                CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                                InsertGenJournalLine(
                                    GenJnlLine."Account Type"::"G/L Account", BankAccPostingGr."Bank Services Acc.", TempBGPOPostBuffer.Amount,
                                    BillGr."Posting Description", CustLedgEntry2, 0);
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                CalcBankAccount(BillGr."Bank Account No.", -TempBGPOPostBuffer.Amount, CustLedgEntry2."Entry No.");
                            end;
                        end;
                    end else begin
                        BankAccPostingGr.TestField("Bank Services Acc.");
                        if (BillGr.Factoring = BillGr.Factoring::Unrisked)
                           and (FeeRange.GetTotalUnriskFactExpensesAmt() <> 0)
                        then begin
                            NoRegs := FeeRange.NoRegUnriskFactExpenses();
                            for i := 0 to NoRegs - 1 do begin
                                FeeRange.GetUnriskFactExpenses(TempBGPOPostBuffer, i);
                                CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                                InsertGenJournalLine(
                                    GenJnlLine."Account Type"::"G/L Account", BankAccPostingGr."Bank Services Acc.", TempBGPOPostBuffer.Amount,
                                    BillGr."Posting Description", CustLedgEntry2, 0);
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                CalcBankAccount(BillGr."Bank Account No.", -TempBGPOPostBuffer.Amount, CustLedgEntry2."Entry No.");
                            end;
                        end;
                        if (BillGr.Factoring = BillGr.Factoring::Risked)
                           and (FeeRange.GetTotalRiskFactExpensesAmt() <> 0)
                        then begin
                            NoRegs := FeeRange.NoRegRiskFactExpenses();
                            for i := 0 to NoRegs - 1 do begin
                                FeeRange.GetRiskFactExpenses(TempBGPOPostBuffer, i);
                                CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                                InsertGenJournalLine(
                                    GenJnlLine."Account Type"::"G/L Account", BankAccPostingGr."Bank Services Acc.", TempBGPOPostBuffer.Amount,
                                    BillGr."Posting Description", CustLedgEntry2, 0);
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                CalcBankAccount(BillGr."Bank Account No.", -TempBGPOPostBuffer.Amount, CustLedgEntry2."Entry No.");
                            end;
                        end;
                    end;

                    if FeeRange.GetTotalDiscInterestsAmt() <> 0 then begin
                        BankAccPostingGr.TestField("Discount Interest Acc.");
                        NoRegs := FeeRange.NoRegsDiscInterests();
                        for i := 0 to NoRegs - 1 do begin
                            FeeRange.GetDiscInterestsAmt(TempBGPOPostBuffer, i);
                            CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                            InsertGenJournalLine(
                                GenJnlLine."Account Type"::"G/L Account", BankAccPostingGr."Discount Interest Acc.", TempBGPOPostBuffer.Amount,
                                BillGr."Posting Description", CustLedgEntry2, 0);
                            SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                            CalcBankAccount(BillGr."Bank Account No.", -TempBGPOPostBuffer.Amount, CustLedgEntry2."Entry No.");
                        end;
                    end;

                    if TempBankAccPostBuffer.Find('-') then
                        repeat
                            CustLedgEntry2.Get(TempBankAccPostBuffer."Entry No.");
                            InsertGenJournalLine(
                                GenJnlLine."Account Type"::"Bank Account", BillGr."Bank Account No.", TempBankAccPostBuffer.Amount,
                                BillGr."Posting Description", CustLedgEntry2, 0);
                            SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                        until TempBankAccPostBuffer.Next() = 0;

                    if BillGr."Currency Code" <> '' then begin
                        Currency.SetFilter(Code, BillGr."Currency Code");
                        Currency.FindFirst();
                        if SumLCYAmt <> 0 then begin
                            if SumLCYAmt > 0 then begin
                                Currency.TestField("Residual Gains Account");
                                Account := Currency."Residual Gains Account";
                            end else begin
                                Currency.TestField("Residual Losses Account");
                                Account := Currency."Residual Losses Account";
                            end;
                            TempCode := BillGr."Currency Code";
                            TempText := BillGr."Posting Description";
                            BillGr."Currency Code" := '';
                            BillGr."Posting Description" := Text1100007;
                            CustLedgEntry2."Global Dimension 1 Code" := '';
                            CustLedgEntry2."Global Dimension 2 Code" := '';
                            CustLedgEntry2."Dimension Set ID" := 0;
                            InsertGenJournalLine(
                                GenJnlLine."Account Type"::"G/L Account", Account, -SumLCYAmt, BillGr."Posting Description", CustLedgEntry2, 0);
                            BillGr."Currency Code" := TempCode;
                            BillGr."Posting Description" := TempText;
                        end;
                    end;

                    FinishCode();

                    Commit();
                    Message(Text1100008, BillGr."No.");
                end;

                trigger OnPreDataItem()
                begin
                    if not Find('-') then
                        Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                    Window.Open(
                      '#1####################################\\' +
                      Text1100002);
                    Window.Update(1, StrSubstNo('%1 %2', Text1100003, BillGr."No."));

                    DocCount := 0;

                    if BillGr.Factoring = BillGr.Factoring::" " then
                        if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                            FeeRange.InitDiscExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                            FeeRange.InitDiscInterests(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                        end else
                            FeeRange.InitCollExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code")
                    else
                        case true of
                            BillGr.Factoring = BillGr.Factoring::Risked:
                                if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                                    FeeRange.InitRiskFactExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                                    FeeRange.InitDiscInterests(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                                end else
                                    FeeRange.InitRiskFactExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code")
                            else
                                if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                                    FeeRange.InitUnriskFactExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                                    FeeRange.InitDiscInterests(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                                end else
                                    FeeRange.InitUnriskFactExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code");
                        end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                DocPost.CheckPostingDate("Posting Date");

                TestField("Bank Account No.");
                TestField("Posting Date");

                BankAcc.Get("Bank Account No.");
                BankAcc.TestField("Currency Code", "Currency Code");
                BankAcc.TestField(Blocked, false);
                BankAcc.TestField("Operation Fees Code");
                if "Reason Code" <> '' then
                    ReasonCode := "Reason Code";

                if Factoring = Factoring::" " then
                    CarteraManagement.CheckDiscCreditLimit(BillGr)
                else
                    BankAcc.TestField("Customer Ratings Code");
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
                    field(TemplName; TemplName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aux. Jnl. Template Name';
                        TableRelation = "Gen. Journal Template".Name where(Type = const(Cartera),
                                                                            Recurring = const(false));
                        ToolTip = 'Specifies the name of general journal template where the payment order is posted.';

                        trigger OnValidate()
                        begin
                            if TemplName = '' then
                                BatchName := '';
                        end;
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aux. Jnl. Batch Name';
                        LookupPageID = "General Journal Batches";
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
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        SourceCodeSetup.Get();
        SourceCode := SourceCodeSetup."Cartera Journal";

        if CurrReport.UseRequestPage then begin
            if not GenJnlBatch.Get(TemplName, BatchName) then
                Error(Text1100000);
            ReasonCode := GenJnlBatch."Reason Code";
            GenJnlTemplate.Get(TemplName);
            SourceCode := GenJnlTemplate."Source Code";
        end;
    end;

    var
        Text1100000: Label 'Please fill in both the Template Name and the Batch Name of the Auxiliary Journal with correct values.';
        Text1100002: Label 'Posting receivable documents  #2######';
        Text1100003: Label 'Bill Group';
        Text1100004: Label 'cannot be previous to the %1 of the %2';
        Text1100005: Label 'Bank Bill Group %1 was successfully posted for factoring collection.';
        Text1100006: Label 'Bank Bill Group %1 was successfully posted for collection.';
        Text1100007: Label 'Residual adjust generated by rounding Amount';
        Text1100008: Label 'Bank Bill Group %1 was successfully posted for discount.';
        Text1100009: Label ' Customer No. %1';
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        CustPostingGr: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        TempPostedDocBuffer: Record "Posted Cartera Doc." temporary;
        GenJnlLine: Record "Gen. Journal Line";
        TempBGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        TempBankAccPostBuffer: Record "BG/PO Post. Buffer" temporary;
        PostedDoc: Record "Posted Cartera Doc.";
        PostedBillGr: Record "Posted Bill Group";
        BankAccPostingGr: Record "Bank Account Posting Group";
        FeeRange: Record "Fee Range";
        Currency: Record Currency;
        CarteraManagement: Codeunit CarteraManagement;
        DocPost: Codeunit "Document-Post";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CarteraJnlForm: Page "Cartera Journal";
        Window: Dialog;
        BatchName: Code[10];
        TemplName: Code[10];
        ReasonCode: Code[10];
        Account: Code[20];
        TransactionNo: Integer;
        DocCount: Integer;
        SourceCode: Code[10];
        AccountNo: Code[20];
        BalanceAccount: Code[20];
        GroupAmount: Decimal;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        TempCode: Code[10];
        TempText: Text[100];
        TotalDisctedAmt: Decimal;
        NoRegs: Integer;
        i: Integer;
        Text1100010: Label 'You cannot post a bill group containing documents marked for application to ID. Please, remove Bill %1/%2.';
        Text1100011: Label 'You cannot post a bill group containing documents marked for application to ID. Please, remove Invoice %1.';
        HidePrintDialog: Boolean;

    local procedure FinishCode()
    begin
        UpdateTables();
        Window.Close();
        if CurrReport.UseRequestPage then begin
            Commit();
            GenJnlLine.Reset();
            GenJnlTemplate.Get(TemplName);
            GenJnlLine.FilterGroup := 2;
            GenJnlLine.SetRange("Journal Template Name", TemplName);
            GenJnlLine.FilterGroup := 0;
            CarteraJnlForm.SetJnlBatchName(BatchName);
            CarteraJnlForm.SetTableView(GenJnlLine);
            CarteraJnlForm.SetRecord(GenJnlLine);
            CarteraJnlForm.AllowClosing(true);
            CarteraJnlForm.RunModal();
        end;
    end;

    local procedure UpdateTables()
    begin
        TempPostedDocBuffer.Find('-');
        repeat
            PostedDoc.Copy(TempPostedDocBuffer);
            PostedDoc.Insert();
            CustLedgEntry.Get(PostedDoc."Entry No.");
            CustLedgEntry."Document Situation" := CustLedgEntry."Document Situation"::"Posted BG/PO";
            CustLedgEntry."Document Status" := "ES Document Status".FromInteger(PostedDoc.Status.AsInteger() + 1);
            CustLedgEntry.Modify();
        until TempPostedDocBuffer.Next() = 0;

        BillGr.CalcFields(Amount);
        PostedBillGr.TransferFields(BillGr);
        PostedBillGr."Collection Expenses Amt." := FeeRange.GetTotalCollExpensesAmt();
        PostedBillGr."Discount Expenses Amt." := FeeRange.GetTotalDiscExpensesAmt();
        PostedBillGr."Discount Interests Amt." := FeeRange.GetTotalDiscInterestsAmt();
        PostedBillGr."Risked Factoring Exp. Amt." := FeeRange.GetTotalRiskFactExpensesAmt();
        PostedBillGr."Unrisked Factoring Exp. Amt." := FeeRange.GetTotalUnriskFactExpensesAmt();
        PostedBillGr.Insert();

        BankAcc."Last Bill Gr. No." := BillGr."No.";
        BankAcc."Date of Last Post. Bill Gr." := BillGr."Posting Date";
        BankAcc.Modify();

        Doc.DeleteAll();
        BillGr.Delete();
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; Text: Text[250]; CustLedgEntry: Record "Cust. Ledger Entry"; CurrFactor: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Transaction No." := TransactionNo;
        GenJnlLine."Journal Template Name" := TemplName;
        GenJnlLine."Journal Batch Name" := BatchName;
        GenJnlLine."Posting Date" := BillGr."Posting Date";
        GenJnlLine."Document No." := BillGr."No.";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine.Validate("Account Type", AccType);
        GenJnlLine.Validate("Account No.", AccNo);
        GenJnlLine.Description := Text;
        if BillGr."Currency Code" <> '' then begin
            GenJnlLine.Validate("Currency Code", BillGr."Currency Code");
            if CurrFactor <> 0 then
                GenJnlLine.Validate("Currency Factor", CurrFactor);
        end;
        GenJnlLine.Validate(Amount, Amount2);
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Reason Code" := ReasonCode;
        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" :=
            CarteraManagement.GetDimSetIDFromCustPostDocBuffer(GenJnlLine, CustLedgEntry, TempPostedDocBuffer);
        if AccType = GenJnlLine."Account Type"::"G/L Account" then begin
            GenJnlLine."Source No." := CustLedgEntry."Customer No.";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        end;

        OnBeforeGenJournalLineInsert(GenJnlLine, CustLedgEntry);
        if CurrReport.UseRequestPage then
            GenJnlLine.Insert()
        else
            GenJnlPostLine.Run(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure InitReqForm(TemplName2: Code[10]; BatchName2: Code[10])
    begin
        TemplName := TemplName2;
        BatchName := BatchName2;
    end;

    [Scope('OnPrem')]
    procedure PostDocToFactoring(Doc: Record "Cartera Doc.")
    begin
        CustLedgEntry.Get(Doc."Entry No.");
        CustPostingGr.Get(CustLedgEntry."Customer Posting Group");
        if CustLedgEntry."Applies-to ID" <> '' then
            Error(Text1100011, Doc."Document No.");
        if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
            CustPostingGr.TestField("Factoring for Discount Acc.");
            AccountNo := CustPostingGr."Factoring for Discount Acc.";
            if Doc."Due Date" < BillGr."Posting Date" then
                Doc.FieldError("Due Date",
                  StrSubstNo(
                    Text1100004,
                    BillGr.FieldCaption("Posting Date"),
                    BillGr.TableCaption()));
            if BillGr.Factoring = BillGr.Factoring::Risked then
                FeeRange.CalcRiskFactExpensesAmt(
                    BankAcc."Operation Fees Code", BankAcc."Currency Code", Doc."Remaining Amount", CustLedgEntry."Entry No.")
            else
                FeeRange.CalcUnriskFactExpensesAmt(
                   BankAcc."Operation Fees Code", BankAcc."Currency Code", Doc."Remaining Amount", CustLedgEntry."Entry No.");
            FeeRange.CalcDiscInterestsAmt(
                BankAcc."Operation Fees Code", BankAcc."Currency Code", Doc."Due Date" - BillGr."Posting Date",
                DocPost.FindDisctdAmt(Doc."Remaining Amount", Doc."Account No.", BillGr."Bank Account No."), CustLedgEntry."Entry No.");
        end else begin
            CustPostingGr.TestField("Factoring for Collection Acc.");
            if BillGr.Factoring = BillGr.Factoring::Risked then
                FeeRange.CalcRiskFactExpensesAmt(
                    BankAcc."Operation Fees Code", BankAcc."Currency Code", Doc."Remaining Amount", CustLedgEntry."Entry No.")
            else
                FeeRange.CalcUnriskFactExpensesAmt(
                    BankAcc."Operation Fees Code", BankAcc."Currency Code", Doc."Remaining Amount", CustLedgEntry."Entry No.");
            AccountNo := CustPostingGr."Factoring for Collection Acc.";
        end;
        CustPostingGr.TestField("Receivables Account");
        BalanceAccount := CustPostingGr."Receivables Account";
        if TempBGPOPostBuffer.Get(AccountNo, BalanceAccount, CustLedgEntry."Entry No.") then begin
            TempBGPOPostBuffer.Amount := TempBGPOPostBuffer.Amount + Doc."Remaining Amount";
            if Doc."Currency Code" <> '' then
                TempBGPOPostBuffer."Gain - Loss Amount (LCY)" += GainLossManagement(Doc."Remaining Amount", Doc."Posting Date", Doc."Currency Code");
            TempBGPOPostBuffer."Entry No." := CustLedgEntry."Entry No.";
            TempBGPOPostBuffer.Modify();
        end else begin
            TempBGPOPostBuffer.Account := AccountNo;
            TempBGPOPostBuffer."Balance Account" := BalanceAccount;
            TempBGPOPostBuffer.Amount := Doc."Remaining Amount";
            if Doc."Currency Code" <> '' then
                TempBGPOPostBuffer."Gain - Loss Amount (LCY)" := GainLossManagement(Doc."Remaining Amount", Doc."Posting Date", Doc."Currency Code");
            TempBGPOPostBuffer."Entry No." := CustLedgEntry."Entry No.";
            TempBGPOPostBuffer.Insert();
        end;

        TempPostedDocBuffer.Init();
        TempPostedDocBuffer.TransferFields(Doc);
        TempPostedDocBuffer."Original Document No." := Doc."Original Document No.";
        TempPostedDocBuffer."Category Code" := '';
        TempPostedDocBuffer."Bank Account No." := BillGr."Bank Account No.";
        TempPostedDocBuffer."Dealing Type" := BillGr."Dealing Type";
        TempPostedDocBuffer.Factoring := BillGr.Factoring;
        TempPostedDocBuffer."Remaining Amount" := Doc."Remaining Amount";
        TempPostedDocBuffer."Remaining Amt. (LCY)" := Doc."Remaining Amt. (LCY)";
        TempPostedDocBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertFactoringLiabsAcc()
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
        CustPostingGr2: Record "Customer Posting Group";
        Doc2: Record "Cartera Doc.";
        Currency2: Record Currency;
        GLSetup: Record "General Ledger Setup";
        AccNo: Code[20];
        DisctedAmt: Decimal;
        RoundingPrec: Decimal;
    begin
        Doc2.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.");
        Doc2.SetRange("Bill Gr./Pmt. Order No.", BillGr."No.");
        Doc2.Find('-');
        if Doc2."Currency Code" <> '' then begin
            Currency2.Get(Doc2."Currency Code");
            RoundingPrec := Currency2."Amount Rounding Precision";
        end else begin
            GLSetup.Get();
            RoundingPrec := GLSetup."Amount Rounding Precision";
        end;

        repeat
            DisctedAmt :=
                Round(DocPost.FindDisctdAmt(Doc2."Remaining Amount", Doc2."Account No.", BillGr."Bank Account No."), RoundingPrec);
            CustLedgEntry2.Get(Doc2."Entry No.");
            if BillGr.Factoring = BillGr.Factoring::Risked then begin
                BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
                AccNo := BankAccPostingGr."Liabs. for Factoring Acc.";
            end else begin
                CustPostingGr2.Get(CustLedgEntry."Customer Posting Group");
                CustPostingGr2.TestField("Factoring for Discount Acc.");
                AccNo := BankAccPostingGr."Liabs. for Factoring Acc.";
            end;
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account", AccNo, -DisctedAmt,
              BillGr."Posting Description" + StrSubstNo(Text1100009, Doc2."Account No."), CustLedgEntry2, 0);
            CalcBankAccount(BillGr."Bank Account No.", DisctedAmt, CustLedgEntry2."Entry No.");
            TotalDisctedAmt := TotalDisctedAmt + DisctedAmt;
            SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
        until Doc2.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GainLossManagement(Amount: Decimal; PostingDate3: Date; CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
        CLECurrencyFactor: Decimal;
    begin
        Currency.Get(CurrencyCode);
        CurrencyFactor := CurrencyExchangeRate.ExchangeRate(PostingDate3, CurrencyCode);
        CLECurrencyFactor := CustLedgEntry."Original Currency Factor";
        if CurrencyFactor <> CLECurrencyFactor then
            exit(
              CarteraManagement.GetCurrFactorGainLoss(
                CLECurrencyFactor, CurrencyFactor, Amount, CurrencyCode));
        exit(CarteraManagement.GetGainLoss(PostingDate3, BillGr."Posting Date", Amount, CurrencyCode));
    end;

    [Scope('OnPrem')]
    procedure CalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBankAccount(BankAcc2, Amount2, EntryNo, TempBankAccPostBuffer, IsHandled);
        if IsHandled then
            exit;

        if TempBankAccPostBuffer.Get(BankAcc2, '', EntryNo) then begin
            TempBankAccPostBuffer.Amount := TempBankAccPostBuffer.Amount + Amount2;
            TempBankAccPostBuffer.Modify();
        end else begin
            TempBankAccPostBuffer.Init();
            TempBankAccPostBuffer.Account := BankAcc2;
            TempBankAccPostBuffer."Entry No." := EntryNo;
            TempBankAccPostBuffer.Amount := Amount2;
            TempBankAccPostBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCurrFact(Doc: Record "Cartera Doc."; BillGr: Record "Bill Group"): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CurrExchRate: Record "Currency Exchange Rate";
        CurrFact: Decimal;
    begin
        if SalesInvHeader.Get(Doc."Document No.") then begin
            CurrFact := CurrExchRate.ExchangeRate(BillGr."Posting Date", Doc."Currency Code");
            if CurrFact <> SalesInvHeader."Currency Factor" then
                exit(false);

            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        HidePrintDialog := NewHidePrintDialog;
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
    local procedure OnBeforeDocOnPostDataItem(var CarteraDoc: Record "Cartera Doc."; var BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBillsAccounts(CarteraDoc: Record "Cartera Doc."; CustLedgerEntry: Record "Cust. Ledger Entry"; var AccountNo: Code[20]; var BalanceAccount: Code[20]; BillGr: Record "Bill Group"; var BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsert(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer; var TempBankAccPostBuffer: Record "BG/PO Post. Buffer"; var IsHandled: Boolean)
    begin
    end;
}

