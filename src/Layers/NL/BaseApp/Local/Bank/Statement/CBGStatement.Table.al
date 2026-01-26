// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.NoSeries;
using Microsoft.Utilities;

table 11400 "CBG Statement"
{
    Caption = 'CBG Statement';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Gen. Journal Template".Name;
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank/Giro,Cash';
            OptionMembers = "Bank/Giro",Cash;
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            NotBlank = true;
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"."No."
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"."No.";
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            NotBlank = true;

            trigger OnValidate()
            var
                JournalTemplate: Record "Gen. Journal Template";
                NoSeries: Codeunit "No. Series";
            begin
                if "Document No." <> xRec."Document No." then begin
                    JournalTemplate.Get("Journal Template Name");
                    JournalTemplate.TestField("No. Series");
                    NoSeries.TestManual(JournalTemplate."No. Series");
                    "No. Series" := '';
                end;
            end;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                if Date <> xRec.Date then
                    UpdateCBGStatementLine(FieldCaption(Date), CurrFieldNo <> 0);
            end;
        }
        field(11; Currency; Code[10])
        {
            Caption = 'Currency';
            TableRelation = Currency;
        }
        field(12; "Opening Balance"; Decimal)
        {
            Caption = 'Opening Balance';
        }
        field(13; "Closing Balance"; Decimal)
        {
            Caption = 'Closing Balance';
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(15; "Net Change Debit"; Decimal)
        {
            CalcFormula = sum("CBG Statement Line"."Debit Incl. VAT" where("Journal Template Name" = field("Journal Template Name"),
                                                                            "No." = field("No.")));
            Caption = 'Net Change Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Net Change Credit"; Decimal)
        {
            CalcFormula = sum("CBG Statement Line"."Credit Incl. VAT" where("Journal Template Name" = field("Journal Template Name"),
                                                                             "No." = field("No.")));
            Caption = 'Net Change Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(18; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        LineFilter(CBGStatementLine);
        CBGStatementLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        InitRecord("Journal Template Name");
        InitNoSeries(true);
        "No." := GetNewRecNo();
    end;

    var
        Text1000000: Label '%1 is not allowed as default %2 in a Cash, Bank or Giro Journal.';
        Text1000001: Label 'Bank?';
        Text1000002: Label 'Bank posting grp?';
        Text1000003: Label 'Bank posting grp GL Acc.?';
        Text1000004: Label 'Account No.?';
        Text1000005: Label 'The opening balance (%1) and the net change (%2) are not equal with the closing balance (%3)\';
        Text1000006: Label 'The difference is: %4\\';
        Text1000007: Label 'Do you want to change the closing balance?';
        Text1000008: Label 'Process canceled, check the statement lines or correct the opening and the closing balance.';
        Text1000010: Label 'Process      @1@@@@@@@@@';
        Text1000011: Label 'Bal. Account Type must be "Bank" in/';
        Text1000012: Label 'General Journal Template %1 when/';
        Text1000013: Label 'the identification must be applied.';
        DimManagement: Codeunit DimensionManagement;
        CBGStatementLine: Record "CBG Statement Line";
        Text1000014: Label 'You have modified %1.\\';
        Text1000015: Label 'Do you want to update the lines?';
        DefaultJnlBatchNameTxt: Label 'DEFAULT', Locked = true;

    procedure InitRecord(UseTemplate: Code[10])
    var
        CBGStatement: Record "CBG Statement";
        JournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        "Journal Template Name" := DelChr(UseTemplate, '<>', '''');
        JournalTemplate.Get("Journal Template Name");

        case JournalTemplate.Type of
            JournalTemplate.Type::Cash:
                Type := Type::Cash;
            JournalTemplate.Type::Bank:
                begin
                    Type := Type::"Bank/Giro";
                    if Date = 0D then
                        Date := WorkDate();
                end;
        end;

        case JournalTemplate."Bal. Account Type" of
            JournalTemplate."Bal. Account Type"::"G/L Account":
                "Account Type" := "Account Type"::"G/L Account";
            JournalTemplate."Bal. Account Type"::"Bank Account":
                "Account Type" := "Account Type"::"Bank Account"
            else
                Error(Text1000000,
                  JournalTemplate."Bal. Account Type",
                  JournalTemplate.FieldCaption("Bal. Account Type"));
        end;

        JournalTemplate.TestField("Bal. Account No.");
        "Account No." := JournalTemplate."Bal. Account No.";
        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLAccount.Get("Account No.");
                    Currency := '';
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccount.Get("Account No.");
                    Currency := BankAccount."Currency Code";
                end;
        end;

        if "Opening Balance" = 0 then begin
            CBGStatement.SetRange("Journal Template Name", "Journal Template Name");
            CBGStatement.SetFilter("No.", '<>%1', "No.");
            if CBGStatement.FindLast() then
                "Opening Balance" := CBGStatement."Closing Balance"
            else
                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLAccount.Get("Account No.");
                            GLAccount.CalcFields(Balance);
                            "Opening Balance" := GLAccount.Balance;
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAccount.Get("Account No.");
                            BankAccount.CalcFields(Balance);
                            "Opening Balance" := BankAccount.Balance;
                        end;
                end;

            "Closing Balance" := 0;
        end;

        InitNoSeries(false);

        if JournalTemplate.Type = JournalTemplate.Type::Bank then
            DimManagement.AddDimSource(DefaultDimSource, Database::"Bank Account", "Account No.")// Use the Bank Account
        else
            DimManagement.AddDimSource(DefaultDimSource, Database::"G/L Account", "Account No.");// Use the G/L Account
        CreateDim(DefaultDimSource);

        OnAfterInitRecord(CBGStatement, Rec);
    end;

    local procedure InitNoSeries(IncreaseNoSeries: Boolean)
    var
        JournalTemplate: Record "Gen. Journal Template";
        NoSeries: Codeunit "No. Series";
    begin
        JournalTemplate.SetLoadFields(Type, "No. Series");
        JournalTemplate.Get("Journal Template Name");
        if (JournalTemplate.Type = JournalTemplate.Type::Bank) and (("Document No." = '') or (IncreaseNoSeries)) then begin
            JournalTemplate.TestField("No. Series");
                "No. Series" := JournalTemplate."No. Series";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";

                if IncreaseNoSeries then
                    "Document No." := NoSeries.GetNextNo("No. Series", Date)
                else
                    "Document No." := NoSeries.PeekNextNo("No. Series", Date);
        end;
    end;

    procedure CLAccountNo() CLAccNo: Text[80]
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        BankAccPostingGrp: Record "Bank Account Posting Group";
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                CLAccNo := "Account No.";
            "Account Type"::"Bank Account":
                case false of
                    BankAccount.Get("Account No."):
                        CLAccNo := Text1000001;
                    BankAccPostingGrp.Get(BankAccount."Bank Acc. Posting Group"):
                        CLAccNo := Text1000002;
                    GLAccount.Get(BankAccPostingGrp."G/L Account No."):
                        CLAccNo := Text1000003
                    else
                        CLAccNo := GLAccount."No.";
                end;
        end;
    end;

    procedure GetName() Name: Text[100]
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                case false of
                    GLAccount.Get("Account No."):
                        Name := Text1000004;
                    else
                        Name := GLAccount.Name;
                end;
            "Account Type"::"Bank Account":
                case false of
                    BankAccount.Get("Account No."):
                        Name := Text1000004;
                    else
                        Name := BankAccount.Name;
                end;
        end;
    end;

    procedure AssistEdit(OldCBGStatement: Record "CBG Statement"): Boolean
    var
        CBGStatement: Record "CBG Statement";
        JournalTemplate: Record "Gen. Journal Template";
        NoSeries: Codeunit "No. Series";
    begin
        CBGStatement := Rec;
        JournalTemplate.Get(CBGStatement."Journal Template Name");
        JournalTemplate.TestField("No. Series");
        if NoSeries.LookupRelatedNoSeries(JournalTemplate."No. Series", OldCBGStatement."No. Series", CBGStatement."No. Series") then begin
            CBGStatement."Document No." := NoSeries.GetNextNo(CBGStatement."No. Series");
            Rec := CBGStatement;
            exit(true);
        end;
    end;

    procedure LineFilter(var CBGStatementLine: Record "CBG Statement Line")
    begin
        CBGStatementLine.Reset();
        CBGStatementLine.SetRange("Journal Template Name", "Journal Template Name");
        CBGStatementLine.SetRange("No.", "No.");
    end;

    procedure MakeGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; ForEachDocumentNo: Code[20]; ForEachDate: Date; TotAmountVV: Decimal; TotAmountLV: Decimal)
    var
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        OnBeforeMakeGenJournalLine(GenJnlLine, ForEachDocumentNo, ForEachDate, TotAmountVV, TotAmountLV);
        DocumentType := GenJnlLine."Document Type";
        GenJnlLine.Init();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Journal Template Name" := "Journal Template Name";
        GenJnlLine."Journal Batch Name" := DefaultJnlBatchNameTxt;

        case "Account Type" of
            "Account Type"::"Bank Account":
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Bank Account";
            "Account Type"::"G/L Account":
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        end;
        GenJnlLine.Validate("Posting Date", ForEachDate);
        GenJnlLine."Document Type" := DocumentType;
        GenJnlLine.Validate("Account No.", "Account No.");
        case Type of
            Type::"Bank/Giro":
                begin
                    GenJnlLine."Document No." := "Document No.";
                    GenJnlLine.Validate("Document Date", Date);
                end;
            Type::Cash:
                begin
                    GenJnlLine."Document No." := ForEachDocumentNo;
                    GenJnlLine.Validate("Document Date", ForEachDate);
                end;
        end;
        GenJnlLine.Validate(Amount, -TotAmountVV);
        if GenJnlLine."Amount (LCY)" <> 0 then
            GenJnlLine."Currency Factor" := GenJnlLine.Amount / GenJnlLine."Amount (LCY)"
        else
            GenJnlLine."Currency Factor" := 0;
        GenJnlLine.Validate("Amount (LCY)", -TotAmountLV);

        OnAfterMakeGenJournalLine(Rec, GenJnlLine, ForEachDocumentNo, ForEachDate, TotAmountVV, TotAmountLV);
    end;

    procedure CheckBalance()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalance(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Net Change Debit", "Net Change Credit");

        if "Opening Balance" - "Net Change Debit" + "Net Change Credit" <> "Closing Balance" then
            if Confirm(
                 StrSubstNo(
                   Text1000005 +
                   Text1000006 +
                   Text1000007,
                   "Opening Balance",
                   -"Net Change Debit" + "Net Change Credit",
                   "Closing Balance", Abs("Opening Balance" - "Net Change Debit" + "Net Change Credit" - "Closing Balance")), false)
            then begin
                "Closing Balance" := "Opening Balance" - "Net Change Debit" + "Net Change Credit";
                Modify();
                Commit();
            end else
                Error(Text1000008);
    end;

    procedure ProcessStatementASGenJournal()
    var
        GenJnlLine: Record "Gen. Journal Line" temporary;
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        PaymentHistLine: Record "Payment History Line";
        BankAcct: Record "Bank Account";
        TelebankInterface: Codeunit "Financial Interface Telebank";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        Status: Dialog;
        AmountLV: Decimal;
        AmountVV: Decimal;
        Counter: Integer;
        StatusCounter: Integer;
        NumberOfLines: Integer;
    begin
        OnBeforeProcessStatementASGenJournal(Rec);

        TelebankInterface.CheckCBGStatementCurrencyBeforePost(Rec);
        CheckBalance();
        TelebankInterface.CheckPaymReceived(Rec);
        Status.Open(Text1000010);
        StatusCounter := 0;
        LineFilter(CBGStatementLine);
        CBGStatementLine.SetCurrentKey("Journal Template Name", "No.");
        NumberOfLines := CBGStatementLine.Count();

        GenJournalTemplate.Get("Journal Template Name");
        GenJournalTemplate.TestField("Source Code");

        if CBGStatementLine.IsEmpty() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        if CBGStatementLine.Find('-') then begin
            Counter := CBGStatementLine."Line No.";
            repeat
                if CBGStatementLine."VAT Prod. Posting Group" <> '' then
                    VATReportingDateMgt.IsValidDate(CBGStatementLine, CBGStatementLine.FieldNo(Date), true);

                AmountVV := CBGStatementLine."Debit Incl. VAT" - CBGStatementLine."Credit Incl. VAT";
                GenJnlLine.Init();
                CBGStatementLine.CreateGenJournalLine(GenJnlLine);
                AmountLV := GenJnlLine."Amount (LCY)";
                GenJnlLine."Line No." := Counter;
                GenJnlLine."Source Code" := GenJournalTemplate."Source Code";
                GenJnlLine."Reason Code" := GenJournalTemplate."Reason Code";
                if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Employee then
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;

                if not ((GenJnlLine."Account No." = '') or (GenJnlLine.Amount = 0)) then begin
                    if CBGStatementLine."Shortcut Dimension 1 Code" <> '' then
                        GenJnlLine.Validate("Shortcut Dimension 1 Code", CBGStatementLine."Shortcut Dimension 1 Code");
                    if CBGStatementLine."Shortcut Dimension 2 Code" <> '' then
                        GenJnlLine.Validate("Shortcut Dimension 2 Code", CBGStatementLine."Shortcut Dimension 2 Code");
                    if CBGStatementLine."Dimension Set ID" <> 0 then
                        GenJnlLine."Dimension Set ID" := CBGStatementLine."Dimension Set ID";
                    GenJnlLine.Insert();
                    Counter := Counter + 10000;
                    OnAfterInsertGenJnlLine(Rec, CBGStatementLine, GenJnlLine);
                end;
                if CBGStatementLine.Identification <> '' then begin
                    CBGStatementLine.TestField("Applies-to ID");
                    if "Account Type" <> "Account Type"::"Bank Account" then
                        Error(Text1000011 + Text1000012 + Text1000013, "Journal Template Name");
                    PaymentHistLine.SetCurrentKey("Our Bank", Identification);
                    PaymentHistLine.SetRange("Our Bank", "Account No.");
                    PaymentHistLine.SetRange(Identification, CBGStatementLine.Identification);
                    PaymentHistLine.FindFirst();
                    TelebankInterface.ProcessPaymReceived(GenJnlLine, PaymentHistLine, CBGStatementLine);
                    Counter := GenJnlLine."Line No." + 10000;
                end;
                StatusCounter := StatusCounter + 1;
                Status.Update(1, Round(StatusCounter / NumberOfLines * 10000, 1));
                MakeGenJournalLine(GenJnlLine, CBGStatementLine."Document No.", CBGStatementLine.Date, AmountVV, AmountLV);
                GenJnlLine."Line No." := Counter;
                GenJnlLine."Source Code" := GenJournalTemplate."Source Code";
                GenJnlLine."Reason Code" := GenJournalTemplate."Reason Code";
                GenJnlLine.Description := CBGStatementLine.Description;
                if "Shortcut Dimension 1 Code" <> '' then
                    GenJnlLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
                if "Shortcut Dimension 2 Code" <> '' then
                    GenJnlLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
                if "Dimension Set ID" <> 0 then
                    GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                GenJnlLine.Insert();
                OnProcessStatementASGenJournalOnAfterGenJnlLineInsert(GenJnlLine, CBGStatementLine, Rec);
                Counter := Counter + 10000;
            until CBGStatementLine.Next() = 0;
            if GenJnlLine.Find('-') then
                repeat
                    GenJnlPostLine.RunWithCheck(GenJnlLine);
                until GenJnlLine.Next() = 0;
            GenJnlLine.DeleteAll(true);
        end;

        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAcct.Get("Account No.") then begin
                BankAcct."Balance Last Statement" := "Closing Balance";
                BankAcct.Modify();
            end;

        OnAfterProcessStatementASGenJournal(Rec);

        Delete(true);
        Commit();
        UpdateAnalysisView.UpdateAll(0, true);
        Status.Close();
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := DimManagement.GetDefaultDimID(
            DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure UpdateCBGStatementLine(ChangedFieldName: Text[100]; AskQuestion: Boolean)
    var
        Question: Text[250];
        UpdateLines: Boolean;
    begin
        if CBGStatementLinesExist() and AskQuestion then begin
            Question := StrSubstNo(
                Text1000014 +
                Text1000015, ChangedFieldName);
            if GuiAllowed then
                if not DIALOG.Confirm(Question, true) then
                    exit;

            UpdateLines := true;
        end;
        if CBGStatementLinesExist() then begin
            CBGStatementLine.LockTable();
            Modify();

            CBGStatementLine.Reset();
            CBGStatementLine.SetRange("Journal Template Name", "Journal Template Name");
            CBGStatementLine.SetRange("No.", "No.");
            if CBGStatementLine.FindSet() then
                repeat
                    if (ChangedFieldName = FieldCaption(Date)) and (CBGStatementLine."No." <> 0) then begin
                        CBGStatementLine.Validate(Date, Date);
                        CBGStatementLine.Modify(true);
                    end;
                until CBGStatementLine.Next() = 0;
        end;
    end;

    procedure CBGStatementLinesExist(): Boolean
    begin
        CBGStatementLine.Reset();
        CBGStatementLine.SetRange("Journal Template Name", "Journal Template Name");
        CBGStatementLine.SetRange("No.", "No.");
        exit(CBGStatementLine.FindFirst())
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" := DimManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Journal Template Name", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure GetNewRecNo(): Integer
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.SetRange("Journal Template Name", "Journal Template Name");
        if CBGStatement.FindLast() then
            exit(CBGStatement."No." + 1);
        exit(1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var CBGStatement: Record "CBG Statement"; var Rec: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGenJnlLine(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeGenJournalLine(CBGStatement: Record "CBG Statement"; var GenJournalLine: Record "Gen. Journal Line"; ForEachDocumentNo: Code[20]; ForEachDate: Date; TotAmountVV: Decimal; TotAmountLV: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessStatementASGenJournal(var CBGStatement: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalance(var CBGStatement: Record "CBG Statement"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessStatementASGenJournal(var CBGStatement: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; ForEachDocumentNo: Code[20]; ForEachDate: Date; TotAmountVV: Decimal; TotAmountLV: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessStatementASGenJournalOnAfterGenJnlLineInsert(var GenJnlLine: Record "Gen. Journal Line"; CBGStatementLine: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement")
    begin
    end;
}
