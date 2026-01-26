// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Reflection;

report 11000022 "Import Rabobank vvmut.asc"
{
    Caption = 'Import Rabobank vvmut.asc';
    ProcessingOnly = true;

    dataset
    {
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
                    field(AutoReconcilation; AutoReconcilation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Automatic Reconciliation';
                        ToolTip = 'Specifies if the bank statement is automatically reconciled when you import it from Rabobank.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            ImportProtocol: Record "Import Protocol";
            ImportProtocolMgt: Codeunit "Import Protocol Management";
        begin
            if ImportProtocolMgt.GetCurrentImportProtocol(ImportProtocol) then begin
                ImportFileName := ImportProtocol."Default File Name";
                AutoReconcilation := ImportProtocol."Automatic Reconciliation";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ImportFile: File;
        Line: Text[1024];
        LineType: Code[1];
        FirstTime: Boolean;
    begin
        FirstTime := true;
        TotalNetChange := 0;

        Clear(CBGStatement);
        Clear(CBGStatementLine);
        Clear(CBGStatementLineDesc);

        UploadFile(ImportFileName);

        ImportFile.TextMode := true;
        ImportFile.WriteMode := false;
        ImportFile.Open(ImportFileName);

        while ImportFile.Pos < ImportFile.Len do begin
            ImpAcctNoPrincipal := '';
            ImpCurrencyCode := '';
            ImpNetChangeDate := 0D;
            ImpCurrencyDate := 0D;
            ImpAmount := 0;
            ImpDebCred := '';
            Clear(ImpDescription);
            Clear(ImpBalAcctName);
            ImpBalAcctAddress := '';
            ImpBalAcctCity := '';
            Clear(CBGStatementLineDesc);

            ImportFile.Read(Line);
            LineType := GetText(Line, 45, 1);

            if LineType = '1' then begin
                ImpAcctNoPrincipal := GetText(Line, 1, 9);
                ImpCurrencyCode := GetText(Line, 10, 3);
                ImpNetChangeDate := GetDate(Line, 13, 8);
                ImpCurrencyDate := GetDate(Line, 21, 8);
                ImpAmount := GetDecimal(Line, 29, 15, ',') / 100;
                ImpDebCred := GetText(Line, 44, 1);
                ImpDescription[1] := GetText(Line, 46, 35);
                ImpDescription[2] := GetText(Line, 81, 35);
                ImpDescription[3] := GetText(Line, 116, 35);
                ImpDescription[4] := GetText(Line, 151, 35);
                ImpBalAcctName[1] := GetText(Line, 186, 35);
                ImpBalAcctName[2] := GetText(Line, 221, 35);
                ImpBalAcctAddress := GetText(Line, 256, 35);
                ImpBalAcctCity := GetText(Line, 291, 35);

                if FirstTime then begin
                    ProcessHeader();
                    FirstTime := false;
                end;

                ProcessLine();
                TotalNetChange := TotalNetChange + CBGStatementLine.Amount;
            end;
        end;

        ImportFile.Close();

        ProcessClosingBalance();
    end;

    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineDesc: Record "CBG Statement Line Add. Info.";
        ImportFileName: Text[260];
        ImpDescription: array[4] of Text[35];
        ImpBalAcctName: array[2] of Text[35];
        ImpBalAcctAddress: Text[35];
        ImpBalAcctCity: Text[35];
        ImpDebCred: Code[1];
        ImpAcctNoPrincipal: Code[10];
        ImpCurrencyCode: Code[10];
        ImpNetChangeDate: Date;
        ImpCurrencyDate: Date;
        ImpAmount: Decimal;
        TotalNetChange: Decimal;
        AutoReconcilation: Boolean;
        Text001: Label 'Could not find a %1 with %2 %3.';
        Text002: Label 'Could not find a %1 of type Bank for %2 %3.';
        Text1000003: Label 'Text Files|*.txt|All Files|*.*';
        Text1000007: Label 'Bank Account No. %1 from bank %2 does not match the account data %3 from the imported statement.';
        Text1000008: Label 'Check if the statement you want to import contains changes for exactly one bank account.';
        Text1000009: Label 'The currency %1 from Bank Journal %2 does not match the imported currency %3 from the statement.';

    local procedure GetText(String: Text[1024]; Position: Integer; Length: Integer): Text[1024]
    begin
        exit(CBGStatementLine.GetText(String, Position, Length))
    end;

    local procedure GetDate(String: Text; Position: Integer; Length: Integer): Date
    begin
        exit(CBGStatementLine.GetDate(String, Position, Length, 'ddMMyyyy'))
    end;

    local procedure GetDecimal(String: Text[1024]; Position: Integer; Length: Integer; DecimalSeparator: Code[1]): Decimal
    begin
        exit(CBGStatementLine.GetDecimal(String, Position, Length, DecimalSeparator))
    end;

    local procedure ProcessHeader()
    var
        BankAcct: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        BankAcctCode: Code[20];
    begin
        Clear(CBGStatement);

        BankAcctCode := FindBankAcct(ImpAcctNoPrincipal);

        if BankAcctCode = '' then
            Error(Text001, BankAcct.TableCaption(), BankAcct.FieldCaption("Bank Account No."), ImpAcctNoPrincipal);

        GenJnlTemplate.SetCurrentKey(Type, "Bal. Account Type", "Bal. Account No.");
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Bank);
        GenJnlTemplate.SetRange("Bal. Account Type", GenJnlTemplate."Bal. Account Type"::"Bank Account");
        GenJnlTemplate.SetRange("Bal. Account No.", BankAcctCode);

        if not GenJnlTemplate.FindFirst() then
            Error(Text002, GenJnlTemplate.TableCaption(), BankAcct.TableCaption(), BankAcctCode);

        CBGStatement.InitRecord(GenJnlTemplate.Name);
        CBGStatement.Insert(true);
    end;

    local procedure ProcessLine()
    var
        BankAcct: Record "Bank Account";
        i: Integer;
    begin
        BankAcct.Get(CBGStatement."Account No.");

        if TextFilter(BankAcct."Bank Account No.", '0123456789') <> TextFilter(ImpAcctNoPrincipal, '012345467989') then
            Error(Text1000007 + Text1000008, BankAcct."Bank Account No.", BankAcct."No.", ImpAcctNoPrincipal);

        if CBGStatement.Currency <> ImpCurrencyCode then
            Error(Text1000009, CBGStatement.Currency, CBGStatement."Journal Template Name", ImpCurrencyCode);

        CBGStatementLine."Journal Template Name" := CBGStatement."Journal Template Name";
        CBGStatementLine."No." := CBGStatement."No.";
        CBGStatementLine."Line No." := CBGStatementLine."Line No." + 10000;
        CBGStatementLine.Init();
        CBGStatementLine.InitRecord(CBGStatementLine);

        CBGStatementLine.Validate(Date, ImpCurrencyDate);

        case ImpDebCred of
            'D':
                CBGStatementLine.Validate(Debit, ImpAmount);
            'C':
                CBGStatementLine.Validate(Credit, ImpAmount);
        end;

        for i := 1 to 4 do begin
            if CBGStatementLine.Description = '' then
                CBGStatementLine.Description := CopyStr(ImpDescription[i], 1, MaxStrLen(CBGStatementLine.Description));
            ProcessComment(ImpDescription[i], CBGStatementLineDesc."Information Type"::"Description and Sundries");
        end;

        for i := 1 to 2 do
            ProcessComment(ImpBalAcctName[i], CBGStatementLineDesc."Information Type"::"Name Acct. Holder");

        ProcessComment(ImpBalAcctAddress, CBGStatementLineDesc."Information Type"::"Address Acct. Holder");
        ProcessComment(ImpBalAcctCity, CBGStatementLineDesc."Information Type"::"City Acct. Holder");

        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate(Date, ImpCurrencyDate);
        CBGStatementLine.Modify();
    end;

    local procedure ProcessClosingBalance()
    var
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        CBGStatement."Closing Balance" := CBGStatement."Opening Balance" + TotalNetChange;
        CBGStatement.Modify(true);

        if AutoReconcilation then begin
            CBGStatementReconciliation.SetHideMessages(true);
            CBGStatementReconciliation.MatchCBGStatement(CBGStatement);
        end;
    end;

    local procedure ProcessComment(Comment: Text[100]; Type: Enum "CBG Statement Information Type")
    begin
        if Comment <> '' then begin
            CBGStatementLineDesc."Journal Template Name" := CBGStatementLine."Journal Template Name";
            CBGStatementLineDesc."CBG Statement No." := CBGStatementLine."No.";
            CBGStatementLineDesc."CBG Statement Line No." := CBGStatementLine."Line No.";
            CBGStatementLineDesc."Line No." := CBGStatementLineDesc."Line No." + 10000;
            CBGStatementLineDesc.Init();
            CBGStatementLineDesc.Description := Comment;
            CBGStatementLineDesc."Information Type" := Type;
            CBGStatementLineDesc.Insert(true);
        end;
    end;

    local procedure GetCaption() Result: Text[50]
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ID: Integer;
    begin
        if not Evaluate(ID, CurrReport.ObjectId(false)) then
            exit;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ID) then
            exit;

        exit(CopyStr(AllObjWithCaption."Object Caption", 1, MaxStrLen(Result)));
    end;

    local procedure TextFilter(String: Text[1024]; "Filter": Text[1024]): Text[1024]
    begin
        exit(DelChr(String, '=', DelChr(String, '=', Filter)));
    end;

    local procedure FindBankAcct(AcctNo: Text[30]): Code[20]
    var
        BankAcct: Record "Bank Account";
    begin
        if BankAcct.FindSet(false, false) then
            repeat
                if TextFilter(BankAcct."Bank Account No.", '0123456789') = TextFilter(AcctNo, '0123456789') then
                    exit(BankAcct."No.");
            until BankAcct.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UploadFile(var FileName: Text[1024])
    var
        NewFileName: Text[1024];
    begin
        if not Upload(GetCaption(), '', Text1000003, FileName, NewFileName) then
            NewFileName := '';

        if NewFileName <> '' then
            FileName := NewFileName;
    end;
}

