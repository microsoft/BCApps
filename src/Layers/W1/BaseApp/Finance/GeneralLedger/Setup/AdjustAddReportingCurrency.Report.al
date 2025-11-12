// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;

report 86 "Adjust Add. Reporting Currency"
{
    Caption = 'Adjust Add. Reporting Currency';
    Permissions = TableData "G/L Entry" = rim,
                  TableData "Item Ledger Entry" = rm,
                  TableData "G/L Register" = rim,
                  TableData "Job Ledger Entry" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "Value Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; System.Utilities.Integer)
        {
            DataItemTableView = where(Number = const(1));

            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = sorting(Type, Closed) where(Type = filter(Purchase .. Sale));

                trigger OnAfterGetRecord()
                begin
                    VATEntryCount := VATEntryCount + VATEntryStep;
                    if VATEntryOldCount div 100000 <> VATEntryCount div 100000 then begin
                        Window.Update(1, VATEntryCount div 100000);
                        VATEntryOldCount := VATEntryCount;
                    end;

                    "Additional-Currency Amount" := ExchangeAmtLCYToFCY("Posting Date", Amount, false);
                    "Additional-Currency Base" := ExchangeAmtLCYToFCY("Posting Date", Base, false);
                    "Add.-Currency Unrealized Amt." := ExchangeAmtLCYToFCY("Posting Date", "Unrealized Amount", false);
                    "Add.-Currency Unrealized Base" := ExchangeAmtLCYToFCY("Posting Date", "Unrealized Base", false);
                    "Add.-Curr. Rem. Unreal. Amount" := ExchangeAmtLCYToFCY("Posting Date", "Remaining Unrealized Amount", false);
                    "Add.-Curr. Rem. Unreal. Base" := ExchangeAmtLCYToFCY("Posting Date", "Remaining Unrealized Base", false);
                    Modify();
                end;

                trigger OnPostDataItem()
                begin
                    Window.Close();
                end;

                trigger OnPreDataItem()
                var
                    GLSetup: Record "General Ledger Setup";
                    IsHandled: Boolean;
                begin
                    Window.Open(Text002Txt);
                    if Count > 0 then
                        VATEntryStep := 10000 * 100000 div Count;

                    IsHandled := false;
                    OnPreDataItemVatEntryOnBeforeSetFilterOnClosedVATEntries("VAT Entry", IsHandled);
                    if not IsHandled then begin
                        GLSetup.Get();
                        if not GLSetup."Unrealized VAT" then
                            SetRange(Closed, false);
                    end;
                end;
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Entry No.");

                trigger OnAfterGetRecord()
                var
                    GLAccNo: Code[20];
                begin
                    if OldGLEntry."Posting Date" < "Posting Date" then begin
                        Window.Update(1, "Posting Date");
                        OldGLEntry := "G/L Entry";
                    end;
                    "Additional-Currency Amount" := ExchangeAmtLCYToFCY("Posting Date", Amount, false);
                    if "Debit Amount" <> 0 then begin
                        "Add.-Currency Debit Amount" := "Additional-Currency Amount";
                        "Add.-Currency Credit Amount" := 0;
                    end else begin
                        "Add.-Currency Debit Amount" := 0;
                        "Add.-Currency Credit Amount" := -"Additional-Currency Amount";
                    end;
                    Modify();

                    TotalAddCurrAmount := TotalAddCurrAmount + "Additional-Currency Amount";
                    TotalAmount := TotalAmount + Amount;
                    if TotalAmount = 0 then
                        if TotalAddCurrAmount <> 0 then begin
                            if TotalAddCurrAmount < 0 then
                                GLAccNo := Currency."Residual Losses Account"
                            else
                                GLAccNo := Currency."Residual Gains Account";
                            InsertGLEntry(
                            "Posting Date", "Document Date", "Document Type".AsInteger(), DocumentNo, GLAccNo,
                            "Reason Code", -TotalAddCurrAmount);
                            TotalAddCurrAmount := 0;
                        end;

                    if "Entry No." = LastEntryNo then
                        CurrReport.Break();

                    if "Posting Date" = ClosingDate("Posting Date") then begin
                        TempCloseIncomeStatementBuffer."Closing Date" := "Posting Date";
                        TempCloseIncomeStatementBuffer."G/L Account No." := "G/L Account No.";
                        if TempCloseIncomeStatementBuffer.Insert() then;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if TempCloseIncomeStatementBuffer.Find('-') then
                        repeat
                            if IsAccountingPeriodClosingDate(
                                TempCloseIncomeStatementBuffer."Closing Date")
                            then begin
                                CheckCombination(TempCloseIncomeStatementBuffer);

                                Clear(TempCloseIncomeStatementBuffer3);
                                TempCloseIncomeStatementBuffer3."Closing Date" := "Posting Date";
                                TempCloseIncomeStatementBuffer3."G/L Account No." := Currency."Residual Gains Account";
                                if TempCloseIncomeStatementBuffer3.Insert() then;
                                TempCloseIncomeStatementBuffer3."Closing Date" := "Posting Date";
                                TempCloseIncomeStatementBuffer3."G/L Account No." := Currency."Residual Losses Account";
                                if TempCloseIncomeStatementBuffer3.Insert() then;
                            end;
                        until TempCloseIncomeStatementBuffer.Next() = 0;

                    if TempCloseIncomeStatementBuffer3.Find('-') then
                        repeat
                            CheckCombination(TempCloseIncomeStatementBuffer3);
                        until TempCloseIncomeStatementBuffer3.Next() = 0;

                    if GLReg."To Entry No." <> 0 then
                        GLReg.Insert();
                    Window.Close();
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(Text003Txt + Text004Txt);
                end;
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemTableView = sorting("Item No.");

                trigger OnAfterGetRecord()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                    PostingDate: Date;
                begin
                    if OldValueEntry."Item No." <> "Item No." then begin
                        Window.Update(1, "Item No.");
                        OldValueEntry := "Value Entry";
                    end;

                    if "Entry Type" = "Entry Type"::Revaluation then begin
                        ItemLedgerEntry.Get("Item Ledger Entry No.");
                        PostingDate := ItemLedgerEntry."Posting Date";
                    end else
                        PostingDate := "Posting Date";

                    "Cost per Unit (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost per Unit", true);
                    "Cost Amount (Actual) (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Amount (Actual)", false);
                    "Cost Amount (Expected) (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Amount (Expected)", false);
                    "Cost Amount (Non-Invtbl.)(ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Amount (Non-Invtbl.)", false);
                    "Cost Posted to G/L (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Posted to G/L", false);

                    Modify();
                end;

                trigger OnPostDataItem()
                begin
                    Window.Close();
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(Text011Txt + Text006Txt);
                end;
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemTableView = sorting("Job No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if OldJobLedgEntry."Job No." <> "Job No." then begin
                        Window.Update(1, "Job No.");
                        OldJobLedgEntry := "Job Ledger Entry";
                    end;

                    "Additional-Currency Total Cost" := ExchangeAmtLCYToFCY("Posting Date", "Total Cost (LCY)", false);
                    "Add.-Currency Total Price" := ExchangeAmtLCYToFCY("Posting Date", "Total Price (LCY)", false);
                    Modify();
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(Text007Txt + Text008Txt);
                end;
            }
            dataitem("Cost Entry"; "Cost Entry")
            {
                DataItemTableView = sorting("Entry No.");

                trigger OnAfterGetRecord()
                begin
                    if OldCostEntry."Posting Date" < "Posting Date" then begin
                        Window.Update(1, "Posting Date");
                        OldCostEntry := "Cost Entry";
                    end;
                    "Additional-Currency Amount" := ExchangeAmtLCYToFCY("Posting Date", Amount, false);
                    if "Debit Amount" <> 0 then begin
                        "Add.-Currency Debit Amount" := "Additional-Currency Amount";
                        "Add.-Currency Credit Amount" := 0;
                    end else begin
                        "Add.-Currency Debit Amount" := 0;
                        "Add.-Currency Credit Amount" := -"Additional-Currency Amount";
                    end;
                    Modify();
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(Text012Txt + Text004Txt);
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Adjust Additional Reporting Currency (batch job)';
        AboutText = 'The Adjust Additional Reporting Currency batch job converts LCY amounts on existing G/L entries to the ACY. The batch job uses a default exchange rate copied from the exchange rate that is valid on the work date on the Currency Exchange Rates page. Residual amounts that occur on conversion of LCY to ACY are posted to the residual gains and losses accounts specified on the Currencies page. Please see the documentation on how to set up an additional reporting currency for more information';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#pragma warning disable AA0100
                    field("GLSetup.""Additional Reporting Currency"""; GLSetup."Additional Reporting Currency")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = 'Additional Reporting Currency';
                        Editable = true;
                        ToolTip = 'Specifies the currency code from the Additional Reporting Currency field in the General Ledger Setup window.';

                        trigger OnAssistEdit()
                        begin
                            ChangeExchangeRate.SetParameter(GLSetup."Additional Reporting Currency", CurrencyFactor, WorkDate());
                            if ChangeExchangeRate.RunModal() = ACTION::OK then
                                CurrencyFactor := ChangeExchangeRate.GetParameter();
                            Clear(ChangeExchangeRate);
                        end;

                        trigger OnValidate()
                        begin
                            GLSetup := GLSetup2;
                        end;
                    }
                    field(PostingDocNo; DocumentNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies a document number that will be copied to rounding entries if another document number does not apply. The batch job creates these rounding entries.';
                        Visible = not IsJournalTemplNameVisible;
                    }
                    field(JnlTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                    field(RetainedEarningsAcc; RetainedEarningsGLAcc."No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Retained Earnings Acc.';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the retained earnings account that the batch job posts to. This account should be the same as the account that is used by the Close Income Statement batch job.';

                        trigger OnValidate()
                        begin
                            if RetainedEarningsGLAcc."No." <> '' then begin
                                RetainedEarningsGLAcc.Find();
                                RetainedEarningsGLAcc.CheckGLAcc();
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.TestField("Additional Reporting Currency");
            GLSetup2 := GLSetup;
            CurrencyFactor := CurrExchRate.ExchangeRate(WorkDate(), GLSetup."Additional Reporting Currency");
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if GLSetup."Additional Reporting Currency" = '' then
            GLSetup.Get();
    end;

    trigger OnPostReport()
    begin
        ReportIsExecuted := true;
    end;

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
    begin
        Currency.Get(GLSetup."Additional Reporting Currency");
        Currency.TestField("Amount Rounding Precision");
        Currency.TestField("Unit-Amount Rounding Precision");
        Currency.TestField("Residual Gains Account");
        ResidualGLAcc.Get(Currency."Residual Gains Account");
        ResidualGLAcc.TestField(Blocked, false);
        ResidualGLAcc.TestField("Account Type", ResidualGLAcc."Account Type"::Posting);
        Currency.TestField("Residual Losses Account");
        ResidualGLAcc.Get(Currency."Residual Losses Account");
        ResidualGLAcc.TestField(Blocked, false);
        ResidualGLAcc.TestField("Account Type", ResidualGLAcc."Account Type"::Posting);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Adjust Add. Reporting Currency");

        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlLineReq."Journal Template Name" = '' then
                Error(PleaseEnterErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(PleaseEnterErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));

            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            DocumentNo := NoSeries.GetNextNo(GenJnlBatch."No. Series", FiscalYearEndDate2);
        end else
            if DocumentNo = '' then
                Error(
                    Text000Err, GenJnlLineReq.FieldCaption("Document No."));

        if RetainedEarningsGLAcc."No." = '' then
            Error(Text001Err);
    end;

    var
        GenJnlLineReq: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLSetup2: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        OldGLEntry: Record "G/L Entry";
        OldValueEntry: Record "Value Entry";
        OldJobLedgEntry: Record "Job Ledger Entry";
        OldCostEntry: Record "Cost Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        GLEntry2: Record "G/L Entry";
        GLReg: Record "G/L Register";
        TempCloseIncomeStatementBuffer: Record "Close Income Statement Buffer" temporary;
        TempCloseIncomeStatementBuffer3: Record "Close Income Statement Buffer" temporary;
        GLEntry3: Record "G/L Entry";
        RetainedEarningsGLAcc: Record "G/L Account";
        ResidualGLAcc: Record "G/L Account";
        ChangeExchangeRate: Page "Change Exchange Rate";
        CurrencyFactor: Decimal;
        TotalAddCurrAmount: Decimal;
        TotalAmount: Decimal;
        NextEntryNo: Integer;
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        FiscalYearStartDate: Date;
        ReportIsExecuted: Boolean;
        VATEntryCount: Integer;
        VATEntryOldCount: Integer;
        VATEntryStep: Integer;
        FiscalYearStartDate2: Date;
        FiscalYearEndDate2: Date;
        LastDateChecked: Date;
        LastFiscalYearStartDate: Date;
        LastFiscalYearEndDate: Date;
        LastIsAccPeriodClosingDate: Boolean;
        IsJournalTemplNameVisible: Boolean;
        DocumentNo: Code[20];

        Text000Err: Label 'Enter a %1.', Comment = '%1 - Document No.';
        Text001Err: Label 'Enter Retained Earnings Account No.';
        Text002Txt: Label 'Processing VAT Entries @1@@@@@@@@@@\';
        Text003Txt: Label 'Processing G/L Entries...\\';
#pragma warning disable AA0470
        Text004Txt: Label 'Posting Date #1##########\';
        Text006Txt: Label 'Item No. #1##########\';
#pragma warning restore AA0470
        Text007Txt: Label 'Processing Project Ledger Entries...\\';
#pragma warning disable AA0470
        Text008Txt: Label 'Project No. #1##########\';
#pragma warning restore AA0470
        Text010Txt: Label 'Residual caused by rounding of %1', Comment = '%1 - additional currency amount';
        Text011Txt: Label 'Processing Value Entries...\\';
        Text012Txt: Label 'Processing Cost Entries...\\';
        PleaseEnterErr: Label 'Please enter a %1.', Comment = '%1 - field caption';

    protected var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Window: Dialog;

    procedure SetAddCurr(AddCurr: Code[10])
    begin
        GLSetup."Additional Reporting Currency" := AddCurr;
    end;

    procedure IsExecuted(): Boolean
    begin
        exit(ReportIsExecuted);
    end;

    protected procedure ExchangeAmtLCYToFCY(PostingDate: Date; Amount: Decimal; IsUnitAmount: Boolean): Decimal
    var
        AmtRndgPrec: Decimal;
    begin
        if IsUnitAmount then
            AmtRndgPrec := Currency."Unit-Amount Rounding Precision"
        else
            AmtRndgPrec := Currency."Amount Rounding Precision";
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              PostingDate, GLSetup."Additional Reporting Currency", Amount,
              CurrExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency")),
            AmtRndgPrec));
    end;

    procedure IsAccountingPeriodClosingDate(Date: Date): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        OK: Boolean;
    begin
        if AccountingPeriod.IsEmpty() then
            exit(false);

        if Date <> LastDateChecked then begin
            OK := AccountingPeriod.Get(NormalDate(Date) + 1);
            if OK then
                OK := AccountingPeriod."New Fiscal Year";
            if OK then begin
                LastFiscalYearEndDate := ClosingDate(Date);
                AccountingPeriod.SetRange("New Fiscal Year", true);
                OK := AccountingPeriod.Find('<');
                LastFiscalYearStartDate := AccountingPeriod."Starting Date";
                LastIsAccPeriodClosingDate := true;
            end else begin
                LastIsAccPeriodClosingDate := false;
                LastFiscalYearStartDate := 0D;
                LastFiscalYearEndDate := 0D;
            end;
        end;
        FiscalYearStartDate2 := LastFiscalYearStartDate;
        FiscalYearEndDate2 := LastFiscalYearEndDate;
        exit(LastIsAccPeriodClosingDate);
    end;

    procedure CheckCombination(CloseIncomeStmtBuffer2: Record "Close Income Statement Buffer")
    begin
        Clear(GLEntry3);
        GLEntry3.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry3.SetRange("G/L Account No.", CloseIncomeStmtBuffer2."G/L Account No.");
        GLEntry3.SetRange("Posting Date", FiscalYearStartDate2, FiscalYearEndDate2);

        GLEntry3.CalcSums(Amount);
        if GLEntry3.Amount = 0 then begin
            GLEntry3.CalcSums("Additional-Currency Amount");
            if GLEntry3."Additional-Currency Amount" <> 0 then begin
                InsertGLEntry(
                  FiscalYearEndDate2, FiscalYearEndDate2, GLEntry3."Document Type"::" ".AsInteger(), DocumentNo,
                  CloseIncomeStmtBuffer2."G/L Account No.", '', -GLEntry3."Additional-Currency Amount");
                InsertGLEntry(
                  FiscalYearEndDate2, FiscalYearEndDate2, GLEntry3."Document Type"::" ".AsInteger(), DocumentNo,
                  RetainedEarningsGLAcc."No.", '', GLEntry3."Additional-Currency Amount");
            end;
        end;
    end;

    procedure InsertGLEntry(PostingDate: Date; DocumentDate: Date; DocumentType: Integer; DocumentNo: Code[20]; GLAccountNo: Code[20]; ReasonCode: Code[10]; AddCurrAmount: Decimal)
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        if NextEntryNo = 0 then begin
            GLEntry2.GetLastEntry(LastEntryNo, NextTransactionNo);
            NextEntryNo := LastEntryNo + 1;
            NextTransactionNo += 1;

            FiscalYearStartDate := AccountingPeriodMgt.GetPeriodStartingDate();

            GLReg.LockTable();
            if GLReg.FindLast() then;
            GLReg.Initialize(
                GLReg."No." + 1, 0, 0, SourceCodeSetup."Adjust Add. Reporting Currency",
                GenJnlBatch.Name, GenJnlBatch."Journal Template Name");
        end else
            NextEntryNo := NextEntryNo + 1;

        GLEntry2.Init();
        GLEntry2."Posting Date" := PostingDate;
        GLEntry2."Document Date" := DocumentDate;
        GLEntry2."Document Type" := "Gen. Journal Document Type".FromInteger(DocumentType);
        GLEntry2."Document No." := DocumentNo;
        GLEntry2."External Document No." := '';
        GLEntry2.Description :=
          CopyStr(
            StrSubstNo(
              Text010Txt,
              GLEntry2.FieldCaption("Additional-Currency Amount")),
            1, MaxStrLen(GLEntry2.Description));
        GLEntry2."Source Code" := SourceCodeSetup."Adjust Add. Reporting Currency";
        GLEntry2."Source Type" := "Gen. Journal Source Type"::" ";
        GLEntry2."Source No." := '';
        GLEntry2."Job No." := '';
        GLEntry2.Quantity := 0;
        GLEntry2."Journal Templ. Name" := GenJnlBatch."Journal Template Name";
        GLEntry2."Journal Batch Name" := GenJnlBatch.Name;
        GLEntry2."Reason Code" := ReasonCode;
        GLEntry2."Entry No." := NextEntryNo;
        GLEntry2."Transaction No." := NextTransactionNo;
        GLEntry2."G/L Account No." := GLAccountNo;
        GLEntry2.Amount := 0;
        GLEntry2."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLEntry2."User ID"));
        GLEntry2."No. Series" := '';
        GLEntry2."System-Created Entry" := true;
        GLEntry2."Prior-Year Entry" := GLEntry2."Posting Date" < FiscalYearStartDate;
        GLEntry2."Additional-Currency Amount" := AddCurrAmount;
        if GLEntry2."Additional-Currency Amount" > 0 then begin
            GLEntry2."Add.-Currency Debit Amount" := GLEntry2."Additional-Currency Amount";
            GLEntry2."Add.-Currency Credit Amount" := 0;
        end else begin
            GLEntry2."Add.-Currency Debit Amount" := 0;
            GLEntry2."Add.-Currency Credit Amount" := -GLEntry2."Additional-Currency Amount";
        end;
        OnInsertGLEntryOnBeforeGLEntryInsert(GLEntry2);
        GLEntry2.Insert();

        GLReg."To Entry No." := GLEntry2."Entry No.";
    end;

    procedure InitializeRequest(NewDocumentNo: Code[20]; NewRetainedEarningsGLAccNo: Code[20])
    begin
        DocumentNo := NewDocumentNo;
        RetainedEarningsGLAcc."No." := NewRetainedEarningsGLAccNo;
        GLSetup2 := GLSetup;
        CurrencyFactor := CurrExchRate.ExchangeRate(WorkDate(), GLSetup."Additional Reporting Currency");
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
        GenJnlLineReq."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLineReq."Journal Batch Name" := GenJnlBatch.Name;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLEntryOnBeforeGLEntryInsert(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemVatEntryOnBeforeSetFilterOnClosedVATEntries(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean)
    begin
    end;
}

