// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;

report 597 "G/L Currency Revaluation"
{
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Currency Revaluation';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Source Currency Code";
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
                    field(JournalBatchName; GenJnlBatch.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        TableRelation = "Gen. Journal Batch".Name;
                        ToolTip = 'Specifies the name of the general journal that the entries are posted from.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlBatch.FilterGroup(2);
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
                            GenJnlBatch.FilterGroup(0);
                            if GenJnlBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                                GenJnlBatch.Get(GenJnlTemplate.Name, GenJnlBatch.Name);
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlBatch.Get(GenJnlTemplate.Name, GenJnlBatch.Name);
                        end;
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the correction.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GenJnlBatch.Name := '';
            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
            GenJnlTemplate.SetRange(Recurring, false);
            GenJnlTemplate.FindFirst();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SourceCodeSetup.Get();
        PostingDateReq := WorkDate();
    end;

    trigger OnPreReport()
    begin
        if PostingDateReq = 0D then
            Error(PostingDateErr);

        if GenJnlBatch.Name = '' then
            Error(GenJournalErr);

        GenJnlTemplate.FindFirst();
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetFilter("Account No.", '<>%1', '');
        if GenJnlLine.FindFirst() then
            Error(JournalIsNotEmptyErr, GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.");
        GenJnlLine.DeleteAll();

        RunRevaluationProcess();

        Message(LinesCreatedMsg, LinesCreated, GenJnlBatch.Name);

        if not SkipShowBatch and (LinesCreated > 0) then
            OpenGeneralJournalBatch();
    end;

    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        PostingDateReq: Date;
        LastLineNo: Integer;
        LinesCreated: Integer;
        SkipShowBatch: Boolean;
        CorrTxt: Label 'Corr';
        PostingDateErr: Label 'Please enter posting date.';
        GenJournalErr: Label 'Please enter general journal name.';
        JournalIsNotEmptyErr: Label 'There are already entries in the G/L journal %1. Please post or delete them before you proceed.', Comment = '%1 - journal batch name';
        RevaluationTxt: Label 'Gain/Loss %1 Acc. %2 of %3', Comment = '%1 - currency code, %2 - account number, %3 - posting date';
        LinesCreatedMsg: Label '%1 currency revaluation lines have been created in the general journal %2.', Comment = '%1 - line count, %2 - journal batch name';

    local procedure RunRevaluationProcess()
    var
        GLAccount: Record "G/L Account";
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
        RevaluationAmount: Decimal;
        CurrencyFactor: Decimal;
    begin
        GLAccount.SetFilter("No.", "G/L Account".GetFilter("No."));
        GLAccount.SetRange("Source Currency Revaluation", true);
        if GLAccount.FindSet() then
            repeat
                GLAccountSourceCurrency.Reset();
                GLAccountSourceCurrency.SetRange("G/L Account No.", GLAccount."No.");
                if "G/L Account".GetFilter("Source Currency Code") <> '' then
                    GLAccountSourceCurrency.SetFilter("Currency Code", "G/L Account".GetFilter("Source Currency Code"));
                GLAccountSourceCurrency.SetRange("Date Filter", 0D, PostingDateReq);
                GLAccountSourceCurrency.SetAutoCalcFields("Balance at Date", "Source Curr. Balance at Date");
                if GLAccountSourceCurrency.FindSet() then
                    repeat
                        if GLAccountSourceCurrency."Currency Code" <> '' then begin
                            CurrencyFactor := CurrencyExchangeRate.ExchangeRateAdjmt(PostingDateReq, GLAccountSourceCurrency."Currency Code");
                            RevaluationAmount := 0;
                            if CurrencyFactor <> 0 then
                                RevaluationAmount :=
                                    Round(
                                        CurrencyExchangeRate.ExchangeAmtFCYToLCYAdjmt(
                                            PostingDateReq, GLAccountSourceCurrency."Currency Code", GLAccountSourceCurrency."Source Curr. Balance at Date", CurrencyFactor)) -
                                    GLAccountSourceCurrency."Balance at Date";
                            if RevaluationAmount <> 0 then begin
                                CreateGenJnlLine(GLAccount, GLAccountSourceCurrency, RevaluationAmount);
                                LinesCreated := LinesCreated + 1;
                            end;
                        end;
                    until GLAccountSourceCurrency.Next() = 0;
            until GLAccount.Next() = 0;
    end;

    local procedure CreateGenJnlLine(GLAccount: Record "G/L Account"; GLAccountSourceCurrency: Record "G/L Account Source Currency"; RevaluationAmount: Decimal)
    var
        Currency: Record Currency;
    begin
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        LastLineNo := LastLineNo + 10000;
        GenJnlLine."Line No." := LastLineNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Document No." := CorrTxt + "G/L Account"."Source Currency Code";
        GenJnlLine.Description :=
            StrSubstNo(
                RevaluationTxt,
                GLAccountSourceCurrency."Currency Code", GLAccountSourceCurrency."G/L Account No.", PostingDateReq);
        GenJnlLine."Account No." := GLAccountSourceCurrency."G/L Account No.";
        GenJnlLine.Validate("Posting Date", PostingDateReq);
        GenJnlLine."Source Code" := SourceCodeSetup."G/L Currency Revaluation";
        GenJnlLine."System-Created Entry" := true;
        Currency.Get(GLAccountSourceCurrency."Currency Code");
        if RevaluationAmount > 0 then
            GenJnlLine.Validate("Bal. Account No.", GetGainsAccount(Currency, GLAccount."Unrealized Revaluation"))
        else
            GenJnlLine.Validate("Bal. Account No.", GetLossesAccount(Currency, GLAccount."Unrealized Revaluation"));
        GenJnlLine."Source Currency Code" := Currency.Code;
        GenJnlLine."Amount (LCY)" := RevaluationAmount;
        GenJnlLine.Validate(Amount, RevaluationAmount);
        GenJnlLine."Zero Src. Curr. Amount" := true;
        GenJnlLine.Insert();
    end;

    local procedure GetGainsAccount(Currency: Record Currency; Unrealized: Boolean): Code[20]
    begin
        if Unrealized then
            exit(Currency.GetUnrealizedGainsAccount());

        exit(Currency.GetRealizedGainsAccount());
    end;

    local procedure GetLossesAccount(Currency: Record Currency; Unrealized: Boolean): Code[20]
    begin
        if Unrealized then
            exit(Currency.GetUnrealizedLossesAccount());

        exit(Currency.GetRealizedLossesAccount());
    end;

    procedure SetSkipShowBatch(NewSkipShowBatch: Boolean)
    begin
        SkipShowBatch := NewSkipShowBatch;
    end;

    local procedure OpenGeneralJournalBatch()
    var
        GenJnlManagement: Codeunit GenJnlManagement;
    begin
        GenJnlManagement.TemplateSelectionFromBatch(GenJnlBatch);
    end;
}

