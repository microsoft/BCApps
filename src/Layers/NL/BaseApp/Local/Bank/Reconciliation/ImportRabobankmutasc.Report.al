// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Reflection;

report 11000021 "Import Rabobank mut.asc"
{
    Caption = 'Import Rabobank mut.asc';
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
                    field(AutoReconciliation; AutoReconciliation)
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
                AutoReconciliation := ImportProtocol."Automatic Reconciliation";
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
            ImpPostingDate := 0D;
            ImpCurrencyDate := 0D;
            ImpAmount := 0;
            ImpDebCred := '';
            ImpIdentification := '';
            ImpBalAcctNo := '';
            ImpBalAcctName := '';

            ImportFile.Read(Line);
            LineType := GetText(Line, 24, 1);

            case LineType of
                '2':
                    begin
                        Clear(CBGStatementLineDesc);
                        ImpAcctNoPrincipal := DelChr(GetText(Line, 1, 10), '<', '0');
                        ImpCurrencyCode := GetText(Line, 11, 3);
                        ImpBalAcctNo := DelChr(GetText(Line, 39, 10), '<', '0');
                        ImpBalAcctName := GetText(Line, 49, 24);
                        ImpAmount := GetDecimal(Line, 74, 13, ',') / 100;
                        ImpDebCred := GetText(Line, 87, 1);
                        ImpPostingDate := GetDate(Line, 88, 6);
                        ImpCurrencyDate := GetDate(Line, 94, 6);
                        ImpIdentification := GetText(Line, 109, 16);

                        if FirstTime then begin
                            ProcessHeader();
                            FirstTime := false;
                        end;

                        ProcessLine();
                        TotalNetChange := TotalNetChange + CBGStatementLine.Amount;
                    end;
                '3':
                    begin
                        ProcessComment(GetText(Line, 57, 32), CBGStatementLineDesc."Information Type"::"Description and Sundries");
                        ProcessComment(GetText(Line, 89, 32), CBGStatementLineDesc."Information Type"::"Description and Sundries");
                    end;
                '4':
                    begin
                        ProcessComment(GetText(Line, 25, 32), CBGStatementLineDesc."Information Type"::"Description and Sundries");
                        ProcessComment(GetText(Line, 57, 32), CBGStatementLineDesc."Information Type"::"Description and Sundries");
                        ProcessComment(GetText(Line, 89, 32), CBGStatementLineDesc."Information Type"::"Description and Sundries");
                    end;
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
        ImpBalAcctNo: Text[10];
        ImpBalAcctName: Text[24];
        ImpIdentification: Text[16];
        ImpAcctNoPrincipal: Code[10];
        ImpCurrencyCode: Code[10];
        ImpDebCred: Code[1];
        ImpPostingDate: Date;
        ImpCurrencyDate: Date;
        ImpAmount: Decimal;
        TotalNetChange: Decimal;
        AutoReconciliation: Boolean;
        Text001: Label 'Could not find a %1 with %2 %3.';
        Text002: Label 'Could not find a %1 of type Bank for %2 %3.';
        Text1000003: Label 'Text Files|*.txt|All Files|*.*';
        Text1000007: Label 'Bank Account No. %1 from bank %2 does not match the account data %3 from the imported statement.';
        Text1000008: Label 'Check if the statement you want to import contains changes for exactly one bank account.';
        Text1000009: Label 'The currency %1 from Bank Journal %2 does not match the imported currency %3 from the statement.';

    local procedure GetText(String: Text[1024]; Position: Integer; Length: Integer): Text[1024]
    begin
        exit(CBGStatementLine.GetText(String, Position, Length));
    end;

    local procedure GetDecimal(String: Text[1024]; Position: Integer; Length: Integer; DecimalSeparator: Code[1]): Decimal
    begin
        exit(CBGStatementLine.GetDecimal(String, Position, Length, DecimalSeparator))
    end;

    local procedure GetDate(String: Text; Position: Integer; Length: Integer): Date
    begin
        exit(CBGStatementLine.GetDate(String, Position, Length, 'yyMMdd'))
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
        GLSetup: Record "General Ledger Setup";
        BankAcct: Record "Bank Account";
    begin
        BankAcct.Get(CBGStatement."Account No.");

        if TextFilter(BankAcct."Bank Account No.", '0123456789') <> TextFilter(ImpAcctNoPrincipal, '0123456789') then
            Error(Text1000007 + Text1000008, BankAcct."Bank Account No.", BankAcct."No.", ImpAcctNoPrincipal);

        if CBGStatement.Currency = '' then begin
            GLSetup.Get();
            if GLSetup."LCY Code" <> ImpCurrencyCode then
                Error(Text1000009, GLSetup."LCY Code", CBGStatement."Journal Template Name", ImpCurrencyCode);
        end else
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

        ProcessComment(ImpBalAcctNo, CBGStatementLineDesc."Information Type"::"Account No. Balancing Account");
        ProcessComment(ImpBalAcctName, CBGStatementLineDesc."Information Type"::"Name Acct. Holder");
        ProcessComment(ImpIdentification, CBGStatementLineDesc."Information Type"::"Payment Identification");

        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate(Date, ImpCurrencyDate);
        CBGStatementLine.Modify();
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

            if CBGStatementLineDesc.Description = '' then begin
                CBGStatementLine.Description := CopyStr(Comment, 1, MaxStrLen(CBGStatementLine.Description));
                if CBGStatementLine.Modify() then;
            end;
        end;
    end;

    local procedure ProcessClosingBalance()
    var
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        CBGStatement."Closing Balance" := CBGStatement."Opening Balance" + TotalNetChange;
        CBGStatement.Modify(true);

        if AutoReconciliation then begin
            CBGStatementReconciliation.SetHideMessages(true);
            CBGStatementReconciliation.MatchCBGStatement(CBGStatement);
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

    local procedure TextFilter(String: Text[1024]; "Filter": Text[1024]): Text[1024]
    begin
        exit(DelChr(String, '=', DelChr(String, '=', Filter)));
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

