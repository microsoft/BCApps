// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

report 7000080 "Post Payment Order"
{
    Caption = 'Post Payment Order';
    Permissions = TableData "Vendor Ledger Entry" = m,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Payment Order" = imd,
                  TableData "Posted Payment Order" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(PmtOrd; "Payment Order")
        {
            DataItemTableView = sorting("No.");
            dataitem("Cartera Doc."; "Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Payable));

                trigger OnAfterGetRecord()
                begin
                    DocCount := DocCount + 1;
                    Window.Update(2, DocCount);

                    TestField("Currency Code", PmtOrd."Currency Code");

                    TestField("Collection Agent", "Collection Agent"::Bank);
                    TestField("Due Date");
                    if "Remaining Amount" = 0 then
                        FieldError("Remaining Amount");
                    TestField(Type, Type::Payable);
                    if Accepted = Accepted::No then
                        FieldError(Accepted);

                    VendLedgEntry.Get("Entry No.");
                    VendPostingGr.Get(VendLedgEntry."Vendor Posting Group");
                    if VendLedgEntry."Applies-to ID" <> '' then
                        Error(Text1100006, "Document Type", "Document No.", "No.");

                    FeeRange.CalcPmtOrdCollExpensesAmt(
                      BankAcc."Operation Fees Code",
                      BankAcc."Currency Code",
                      "Remaining Amount",
                      VendLedgEntry."Entry No.");

                    if "Document Type" = "Document Type"::Bill then begin
                        VendPostingGr.TestField("Bills in Payment Order Acc.");
                        VendPostingGr.TestField("Bills Account");
                        AccountNo := VendPostingGr."Bills in Payment Order Acc.";
                        BalanceAccount := VendPostingGr."Bills Account";
                    end else begin
                        VendPostingGr.TestField("Invoices in  Pmt. Ord. Acc.");
                        VendPostingGr.TestField("Payables Account");
                        AccountNo := VendPostingGr."Invoices in  Pmt. Ord. Acc.";
                        BalanceAccount := VendPostingGr."Payables Account";
                    end;
                    OnAfterGetAccountNos("Cartera Doc.", AccountNo, BalanceAccount);

                    if BGPOPostBuffer.Get(AccountNo, BalanceAccount, VendLedgEntry."Entry No.") then begin
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        if "Currency Code" <> '' then
                            BGPOPostBuffer."Gain - Loss Amount (LCY)" := BGPOPostBuffer."Gain - Loss Amount (LCY)" +
                              GainLossManagement("Remaining Amount", "Posting Date", "Currency Code");
                        BGPOPostBuffer.Modify();
                    end else begin
                        BGPOPostBuffer.Account := AccountNo;
                        BGPOPostBuffer."Balance Account" := BalanceAccount;
                        BGPOPostBuffer."Entry No." := VendLedgEntry."Entry No.";
                        BGPOPostBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                        BGPOPostBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                        BGPOPostBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                        BGPOPostBuffer.Amount := "Remaining Amount";
                        if "Currency Code" <> '' then
                            BGPOPostBuffer."Gain - Loss Amount (LCY)" := GainLossManagement(
                                "Remaining Amount",
                                "Posting Date",
                                "Currency Code");
                        BGPOPostBuffer.Insert();
                    end;

                    PostedDocBuffer.Init();
                    PostedDocBuffer.TransferFields("Cartera Doc.");
                    PostedDocBuffer."Category Code" := '';
                    PostedDocBuffer."Bank Account No." := PmtOrd."Bank Account No.";
                    PostedDocBuffer."Remaining Amount" := "Remaining Amount";
                    PostedDocBuffer."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                    PostedDocBuffer."Original Document No." := "Original Document No.";
                    OnBeforePostedDocBufferInsert(PostedDocBuffer, "Cartera Doc.", PmtOrd);
                    PostedDocBuffer.Insert();
                end;

                trigger OnPostDataItem()
                var
                    IsHandled: Boolean;
                begin
                    GroupAmount := 0;
                    SumLCYAmt := 0;
                    if not BGPOPostBuffer.Find('-') then
                        exit;

                    GenJnlLine.LockTable();
                    GenJnlLine.SetRange("Journal Template Name", TemplName);
                    GenJnlLine.SetRange("Journal Batch Name", BatchName);
                    if GenJnlLine.FindLast() then begin
                        GenJnlLineNextNo := GenJnlLine."Line No.";
                        TransactionNo := GenJnlLine."Transaction No." + 1;
                    end;

                    repeat
                        InsertGenJournalLine(
                          GenJnlLine."Account Type"::"G/L Account",
                          BGPOPostBuffer.Account,
                          -BGPOPostBuffer.Amount,
                          BGPOPostBuffer."Global Dimension 1 Code",
                          BGPOPostBuffer."Global Dimension 2 Code",
                          BGPOPostBuffer."Dimension Set ID",
                          BGPOPostBuffer."Entry No.",
                          VendLedgEntry."Original Currency Factor");

                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                        InsertGenJournalLine(
                          GenJnlLine."Account Type"::"G/L Account",
                          BGPOPostBuffer."Balance Account",
                          BGPOPostBuffer.Amount,
                          BGPOPostBuffer."Global Dimension 1 Code",
                          BGPOPostBuffer."Global Dimension 2 Code",
                          BGPOPostBuffer."Dimension Set ID",
                          BGPOPostBuffer."Entry No.",
                          VendLedgEntry."Original Currency Factor");

                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                        if CheckCurrFact("Cartera Doc.", PmtOrd) then
                            if BGPOPostBuffer."Gain - Loss Amount (LCY)" <> 0 then begin
                                TempCurrencyCode := PmtOrd."Currency Code";
                                PmtOrd."Currency Code" := '';
                                if BGPOPostBuffer."Gain - Loss Amount (LCY)" < 0 then begin
                                    Currency.TestField("Realized Gains Acc.");
                                    InsertGenJournalLine(
                                      GenJnlLine."Account Type"::"G/L Account",
                                      Currency."Realized Gains Acc.",
                                      BGPOPostBuffer."Gain - Loss Amount (LCY)",
                                      BGPOPostBuffer."Global Dimension 1 Code",
                                      BGPOPostBuffer."Global Dimension 2 Code",
                                      BGPOPostBuffer."Dimension Set ID",
                                      BGPOPostBuffer."Entry No.", 0);
                                end else begin
                                    Currency.TestField("Realized Losses Acc.");
                                    InsertGenJournalLine(
                                      GenJnlLine."Account Type"::"G/L Account",
                                      Currency."Realized Losses Acc.",
                                      BGPOPostBuffer."Gain - Loss Amount (LCY)",
                                      BGPOPostBuffer."Global Dimension 1 Code",
                                      BGPOPostBuffer."Global Dimension 2 Code",
                                      BGPOPostBuffer."Dimension Set ID",
                                      BGPOPostBuffer."Entry No.", 0);
                                end;
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                InsertGenJournalLine(
                                  GenJnlLine."Account Type"::"G/L Account",
                                  BGPOPostBuffer."Balance Account",
                                  -BGPOPostBuffer."Gain - Loss Amount (LCY)",
                                  BGPOPostBuffer."Global Dimension 1 Code",
                                  BGPOPostBuffer."Global Dimension 2 Code",
                                  BGPOPostBuffer."Dimension Set ID",
                                  BGPOPostBuffer."Entry No.", 0);
                                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                                PmtOrd."Currency Code" := TempCurrencyCode;
                            end;

                        GroupAmount := GroupAmount + BGPOPostBuffer.Amount;
                    until BGPOPostBuffer.Next() = 0;

                    if PmtOrd."Currency Code" <> '' then begin
                        Currency.SetFilter(Code, PmtOrd."Currency Code");
                        Currency.FindFirst();
                        if SumLCYAmt <> 0 then begin
                            if SumLCYAmt > 0 then begin
                                Currency.TestField("Residual Gains Account");
                                Account := Currency."Residual Gains Account";
                            end else begin
                                Currency.TestField("Residual Losses Account");
                                Account := Currency."Residual Losses Account";
                            end;
                            TempCode := PmtOrd."Currency Code";
                            TempText := PmtOrd."Posting Description";
                            PmtOrd."Currency Code" := '';
                            PmtOrd."Posting Description" := Text1100004;
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              Account,
                              -SumLCYAmt,
                              "Global Dimension 1 Code", "Global Dimension 2 Code",
                              BGPOPostBuffer."Dimension Set ID",
                              BGPOPostBuffer."Entry No.", 0);
                            PmtOrd."Currency Code" := TempCode;
                            PmtOrd."Posting Description" := TempText;
                        end;
                    end;

                    FinishCode();

                    IsHandled := false;
                    OnPostDataItemCarteraDocOnBeforeCommit(PmtOrd, HidePrintDialog, IsHandled);
                    if IsHandled then
                        exit;

                    Commit();
                    if not HidePrintDialog then
                        Message(Text1100005, PmtOrd."No.");
                    exit;
                end;

                trigger OnPreDataItem()
                begin
                    if not Find('-') then
                        Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                    Window.Open(
                      '#1#################################\\' +
                      Text1100002);
                    Window.Update(1, StrSubstNo('%1 %2', Text1100003, PmtOrd."No."));

                    DocCount := 0;
                    FeeRange.InitPmtOrdCollExpenses(BankAcc."Operation Fees Code", BankAcc."Currency Code");
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

                if "Export Electronic Payment" then
                    TestField("Elect. Pmts Exported");
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
        Text1100002: Label 'Posting payable documents  #2######';
        Text1100003: Label 'Payment order';
        Text1100004: Label 'Residual adjust generated by rounding Amount';
        Text1100005: Label 'The Payment Order %1 was successfully posted.';
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        VendPostingGr: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        PostedDocBuffer: Record "Posted Cartera Doc." temporary;
        GenJnlLine: Record "Gen. Journal Line";
        BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        PostedDoc: Record "Posted Cartera Doc.";
        PostedPmtOrd: Record "Posted Payment Order";
        FeeRange: Record "Fee Range";
        Currency: Record Currency;
        CarteraJnlForm: Page "Cartera Journal";
        CarteraManagement: Codeunit CarteraManagement;
        DocPost: Codeunit "Document-Post";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlManagement: Codeunit GenJnlManagement;
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
        TempCurrencyCode: Code[10];
        Text1100006: Label 'You cannot post a payment order containing documents marked for application to ID. Please, remove %1 %2/%3. ';
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
            GenJnlManagement.SetName(BatchName, GenJnlLine);
            CarteraJnlForm.SetTableView(GenJnlLine);
            CarteraJnlForm.SetRecord(GenJnlLine);
            CarteraJnlForm.AllowClosing(true);
            CarteraJnlForm.RunModal();
        end;
    end;

    local procedure UpdateTables()
    begin
        PostedDocBuffer.Find('-');
        repeat
            PostedDoc.Copy(PostedDocBuffer);
            PostedDoc.Insert();
            VendLedgEntry.Get(PostedDoc."Entry No.");
            VendLedgEntry."Document Situation" := VendLedgEntry."Document Situation"::"Posted BG/PO";
            VendLedgEntry."Document Status" := "ES Document Status".FromInteger(PostedDoc.Status.AsInteger() + 1);
            OnUpdateTablesOnBeforeVendLedgEntryModify(VendLedgEntry, PostedDoc, PmtOrd);
            VendLedgEntry.Modify();
        until PostedDocBuffer.Next() = 0;

        PmtOrd.CalcFields(Amount);
        PostedPmtOrd.TransferFields(PmtOrd);
        PostedPmtOrd."Payment Order Expenses Amt." := FeeRange.GetTotalPmtOrdCollExpensesAmt();
        PostedPmtOrd.Insert();

        "Cartera Doc.".DeleteAll();
        PmtOrd.Delete();
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; Dep: Code[20]; Proj: Code[20]; DimSetID: Integer; EntryNo: Integer; CurrFactor: Decimal)
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Transaction No." := TransactionNo;
        GenJnlLine."Journal Template Name" := TemplName;
        GenJnlLine."Journal Batch Name" := BatchName;
        GenJnlLine."Posting Date" := PmtOrd."Posting Date";
        GenJnlLine."Document No." := PmtOrd."No.";
        GenJnlLine.Validate("Account Type", AccType);
        GenJnlLine.Validate("Account No.", AccNo);
        GenJnlLine.Description := PmtOrd."Posting Description";
        if PmtOrd."Currency Code" <> '' then begin
            GenJnlLine.Validate("Currency Code", PmtOrd."Currency Code");
            if CurrFactor <> 0 then
                GenJnlLine.Validate("Currency Factor", CurrFactor);
        end;
        GenJnlLine.Validate(Amount, Amount2);
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Reason Code" := ReasonCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := Dep;
        GenJnlLine."Shortcut Dimension 2 Code" := Proj;
        GenJnlLine."Dimension Set ID" := DimSetID;
        if EntryNo <> 0 then
            VendLedgEntry2.Get(EntryNo);

        GenJnlLine."Source No." := VendLedgEntry2."Vendor No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;

        OnBeforeGenJnlLineInsert(GenJnlLine, VendLedgEntry, VendLedgEntry2, EntryNo);
        if CurrReport.UseRequestPage then
            GenJnlLine.Insert()
        else
            GenJnlPostLine.Run(GenJnlLine);
    end;

    procedure InitReqForm(TemplName2: Code[10]; BatchName2: Code[10])
    begin
        TemplName := TemplName2;
        BatchName := BatchName2;
    end;

    procedure GainLossManagement(Amount: Decimal; PostingDate3: Date; CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
        VLECurrencyFactor: Decimal;
    begin
        Currency.Get(CurrencyCode);
        CurrencyFactor := CurrencyExchangeRate.ExchangeRate(PostingDate3, CurrencyCode);
        VLECurrencyFactor := VendLedgEntry."Original Currency Factor";
        if CurrencyFactor <> VLECurrencyFactor then
            exit(
              CarteraManagement.GetCurrFactorGainLoss(
                VLECurrencyFactor, CurrencyFactor, Amount, CurrencyCode));
        exit(CarteraManagement.GetGainLoss(PostingDate3, PmtOrd."Posting Date", Amount, CurrencyCode));
    end;

    procedure CheckCurrFact(Doc: Record "Cartera Doc."; PmtOrd: Record "Payment Order"): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrExchRate: Record "Currency Exchange Rate";
        CurrFact: Decimal;
    begin
        if PurchInvHeader.Get(Doc."Document No.") then begin
            CurrFact := CurrExchRate.ExchangeRate(PmtOrd."Posting Date", Doc."Currency Code");
            if CurrFact <> PurchInvHeader."Currency Factor" then
                exit(false);

            exit(true);
        end;
    end;

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
    local procedure OnAfterGetAccountNos(var CarteraDoc: Record "Cartera Doc."; var AccountNo: Code[20]; var BalanceAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var VendorLedgerEntry2: Record "Vendor Ledger Entry"; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDocBufferInsert(var PostedCarteraDoc: Record "Posted Cartera Doc."; CarteraDoc: Record "Cartera Doc."; PaymentOrder: Record "Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemCarteraDocOnBeforeCommit(var PaymentOrder: Record "Payment Order"; var HidePrintDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTablesOnBeforeVendLedgEntryModify(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PostedCarteraDoc: Record "Posted Cartera Doc."; PaymentOrder: Record "Payment Order")
    begin
    end;
}

