// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;

codeunit 2000040 "Coda Import Management"
{
    TableNo = "CODA Statement Source Line";

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'The enterprise number that is specified in the company information is not valid.';
        Text001: Label 'CODA statement source line %1 is not a %2 line.', Comment = 'Parameter 1 - integer number, 2 - type (Header,Old Balance,Movement,Information,Free Message,,,,New Balance,Trailer)';
        Text002: Label 'Enterprise number %1 does not match ID %2 of %3 record.';
        Text003: Label '%1 %2 of %3 %4 does not match %5 of %6 record.';
        Text005: Label '%1 of %2 %3 does not match %1 of %4 record.';
        Text006: Label '%1 records read, %2 records expected.';
        Text007: Label 'Debet total is %1, expected %2.';
        Text008: Label 'Credit total is %1, expected %2.';
        Text009: Label 'CODA statement source line %1 is a %2 line.';
        Text010: Label '%1 in %2.';
        Text012: Label '%1 on line %2 cannot be %3.';
        Text013: Label '%1 records read\%2 total debit amount\%3 total credit amount\%4 lines skipped (before first or after last record).';
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
        CodBankStmtSrcLine: Record "CODA Statement Source Line";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        EnterpriseNoCheck: Codeunit VATLogicalTests;
        LineCounter: array[2] of Integer;
        SkippedLines: Integer;
        TotalDebit: array[2] of Decimal;
        TotalCredit: array[2] of Decimal;
        VId: array[2] of Text[11];
        EnterpriseNo: Text[11];
        ProtocolNo: Text[3];
        VersionCode: Text[1];
        CODAStatementNo: Text[30];
        AccountType: Text[1];
        SWIFTCode: Text[11];
        OtherPartyAddrDetailsExist: Boolean;

    procedure InitCodaImport(BankAccNo: Code[20])
    var
        EnterpriseNoDec: Decimal;
    begin
        BankAcc.Get(BankAccNo);

        EnterpriseNo := '';
        CompanyInfo.Get();
        // numbers in VAT No
        EnterpriseNo := PaymJnlManagement.ConvertToDigit(CompanyInfo."Enterprise No.", MaxStrLen(EnterpriseNo));
        if EnterpriseNo = '' then
            EnterpriseNo := '0';
        if Evaluate(EnterpriseNoDec, EnterpriseNo) then
            if EnterpriseNoDec = 0 then
                EnterpriseNo := PadStr('', 11, '0')
            else begin
                if not EnterpriseNoCheck.MOD97Check(CompanyInfo."Enterprise No.") then
                    Error(Text000);
                EnterpriseNo := '0' + EnterpriseNo;
            end;
        Clear(LineCounter);
        Clear(TotalDebit);
        Clear(TotalCredit);
        OnAfterInitCodaImport(BankAcc, EnterpriseNo, LineCounter, TotalDebit, TotalCredit);
    end;

    procedure CheckCodaHeader(var CodedBankStmtSrcLine: Record "CODA Statement Source Line") Result: Boolean
    var
        EnterpriseNum: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCodaHeader(CodedBankStmtSrcLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        if CodBankStmtSrcLine.ID <> CodBankStmtSrcLine.ID::Header then begin
            CodBankStmtSrcLine.ID := CodBankStmtSrcLine.ID::Header;
            Error(Text001, CodBankStmtSrcLine."Line No.", CodBankStmtSrcLine.ID);
        end;
        ParseHeaderRecord();
        if not Evaluate(EnterpriseNum, '0' + VId[2]) then
            EnterpriseNum := 0;
        if (EnterpriseNum <> 0) and (EnterpriseNo <> VId[2]) then
            Error(Text002,
              EnterpriseNo,
              VId[2],
              CodBankStmtSrcLine.ID);
        if ProtocolNo <> BankAcc."Protocol No." then
            Error(Text003,
              BankAcc.FieldCaption("Protocol No."),
              BankAcc."Protocol No.",
              BankAcc.TableCaption(),
              BankAcc."No.",
              ProtocolNo,
              CodBankStmtSrcLine.ID);
        if VersionCode <> BankAcc."Version Code" then
            Error(Text003,
              BankAcc.FieldCaption("Version Code"),
              BankAcc."Version Code",
              BankAcc.TableCaption(),
              BankAcc."No.",
              VersionCode,
              CodBankStmtSrcLine.ID);
        if (VersionCode = '2') and (SWIFTCode <> '') then
            if SWIFTCode <> BankAcc."SWIFT Code" then
                Error(Text003,
                  BankAcc.FieldCaption("SWIFT Code"),
                  BankAcc."SWIFT Code",
                  BankAcc.TableCaption(),
                  BankAcc."No.",
                  SWIFTCode,
                  CodBankStmtSrcLine.ID);
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    local procedure ParseHeaderRecord()
    begin
        ProtocolNo := CopyStr(CodBankStmtSrcLine.Data, 12, 3);
        VersionCode := CopyStr(CodBankStmtSrcLine.Data, 128, 1);
        if VersionCode = '1' then
            VId[1] := DelChr(CopyStr(CodBankStmtSrcLine.Data, 61, 11), '>', ' ')
        else
            SWIFTCode := DelChr(CopyStr(CodBankStmtSrcLine.Data, 61, 11));
        VId[2] := DelChr(CopyStr(CodBankStmtSrcLine.Data, 72, 11), '>', ' ');
        CodBankStmtSrcLine."Transaction Date" := DDMMYY2Date(CopyStr(CodBankStmtSrcLine.Data, 6, 6), false);

        OnAfterParseHeaderRecord(CodBankStmtSrcLine);
    end;

    procedure CheckOldBalance(var CodedBankStmtSrcLine: Record "CODA Statement Source Line") OK: Boolean
    var
        IBANSrcLine: Text;
        BankAccountNo: Text[34];
        IBANNumber: Text[34];
        IsHandled: Boolean;
    begin
        OnBeforeCheckOldBalance(CodedBankStmtSrcLine, OK, IsHandled);
        if IsHandled then
            exit(OK);
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        Evaluate(CodBankStmtSrcLine."Statement No.", CopyStr(CodBankStmtSrcLine.Data, 3, 3));
        BankAccountNo :=
          PaymJnlManagement.ConvertToDigit(
            BankAcc."Bank Account No.",
            MaxStrLen(BankAcc."Bank Account No."));
        IBANNumber := DelChr(BankAcc.IBAN);
        AccountType := CopyStr(CodBankStmtSrcLine.Data, 2, 1);
        case AccountType of
            ' ', '0':
                if BankAccountNo <> CopyStr(CodBankStmtSrcLine.Data, 6, 12) then
                    Error(Text003,
                      BankAcc.FieldCaption("Bank Account No."),
                      BankAcc."Bank Account No.",
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      CopyStr(CodBankStmtSrcLine.Data, 6, 12),
                      CodBankStmtSrcLine.ID);
            '1':
                if BankAccountNo <> CopyStr(CodBankStmtSrcLine.Data, 6, 34).Trim() then
                    Error(Text003,
                      BankAcc.FieldCaption("Bank Account No."),
                      BankAcc."Bank Account No.",
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      CopyStr(CodBankStmtSrcLine.Data, 6, 34).Trim(),
                      CodBankStmtSrcLine.ID);
            '2':
                if IBANNumber <> CopyStr(CodBankStmtSrcLine.Data, 6, 16) then
                    Error(Text003,
                      BankAcc.FieldCaption(IBAN),
                      BankAcc.IBAN,
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      CopyStr(CodBankStmtSrcLine.Data, 6, 16),
                      CodBankStmtSrcLine.ID);
            // Support non-Belgian IBAN's
            '3':
                begin
                    IBANSrcLine := CopyStr(CodBankStmtSrcLine.Data, 6, CodBankStmtSrcLine.Data.IndexOf(' ') - 6);
                    if IBANNumber <> IBANSrcLine then
                        Error(Text003,
                          BankAcc.FieldCaption(IBAN),
                          BankAcc.IBAN,
                          BankAcc.TableCaption(),
                          BankAcc."No.",
                          IBANSrcLine,
                          CodBankStmtSrcLine.ID);
                end;
        end;
        if CodBankStmtSrcLine.Data[43] = '0' then
            Evaluate(CodBankStmtSrcLine.Amount, CopyStr(CodBankStmtSrcLine.Data, 44, 15))
        else
            Evaluate(CodBankStmtSrcLine.Amount, '-' + CopyStr(CodBankStmtSrcLine.Data, 44, 15));
        CodBankStmtSrcLine.Amount := CodBankStmtSrcLine.Amount / 1000;
        CodBankStmtSrcLine."Transaction Date" := DDMMYY2Date(CopyStr(CodBankStmtSrcLine.Data, 59, 6), false);
        Evaluate(CodBankStmtSrcLine."CODA Statement No.", CopyStr(CodBankStmtSrcLine.Data, 126, 3));
        Evaluate(CODAStatementNo, CopyStr(CodBankStmtSrcLine.Data, 3, 3));
        CodedBankStmtSrcLine := CodBankStmtSrcLine;

        OnAfterCheckOldBalance(CodedBankStmtSrcLine);

        exit(true);
    end;

    procedure CheckNewBalance(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"; AccountType2: Text[1]): Boolean
    var
        IBANSrcLine: Text;
        BankAccountNo: Text[34];
        IBANNumber: Text[34];
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        AccountType := AccountType2;
        Evaluate(CodBankStmtSrcLine."Statement No.", Format(CODAStatementNo));
        BankAccountNo :=
          PaymJnlManagement.ConvertToDigit(
            BankAcc."Bank Account No.",
            MaxStrLen(BankAcc."Bank Account No."));
        IBANNumber := DelChr(BankAcc.IBAN);
        case AccountType of
            ' ', '0':
                if BankAccountNo <> CopyStr(CodBankStmtSrcLine.Data, 5, 12) then
                    Error(Text005,
                      BankAcc.FieldCaption("Bank Account No."),
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      CodBankStmtSrcLine.ID);
            '1':
                if BankAccountNo <> CopyStr(CodBankStmtSrcLine.Data, 5, 34).Trim() then
                    Error(Text005,
                      BankAcc.FieldCaption("Bank Account No."),
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      CodBankStmtSrcLine.ID);
            '2':
                if IBANNumber <> CopyStr(CodBankStmtSrcLine.Data, 5, 16) then
                    Error(Text005,
                      BankAcc.FieldCaption(IBAN),
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      CodBankStmtSrcLine.ID);
            // Support non-Belgian IBAN's
            '3':
                begin
                    IBANSrcLine := CopyStr(CodBankStmtSrcLine.Data, 5, CodBankStmtSrcLine.Data.IndexOf(' ') - 5);
                    if IBANNumber <> IBANSrcLine then
                        Error(Text005,
                          BankAcc.FieldCaption(IBAN),
                          BankAcc.TableCaption(),
                          BankAcc."No.",
                          CodBankStmtSrcLine.ID);
                end;
        end;
        if CodBankStmtSrcLine.Data[42] = '0' then
            Evaluate(CodBankStmtSrcLine.Amount, CopyStr(CodBankStmtSrcLine.Data, 43, 15))
        else
            Evaluate(CodBankStmtSrcLine.Amount, '-' + CopyStr(CodBankStmtSrcLine.Data, 43, 15));
        CodBankStmtSrcLine.Amount := CodBankStmtSrcLine.Amount / 1000;
        CodBankStmtSrcLine."Transaction Date" := DDMMYY2Date(CopyStr(CodBankStmtSrcLine.Data, 58, 6), false);
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    procedure CheckCodaTrailer(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"): Boolean
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        if CodBankStmtSrcLine.ID <> CodBankStmtSrcLine.ID::Trailer then begin
            CodBankStmtSrcLine.ID := CodBankStmtSrcLine.ID::Trailer;
            Error(Text001, CodBankStmtSrcLine."Line No.", CodBankStmtSrcLine.ID);
        end;
        ParseTrailerRecord();
        if LineCounter[1] <> LineCounter[2] then
            Error(Text006,
              LineCounter[1], LineCounter[2]);
        if TotalDebit[1] <> TotalDebit[2] then
            Error(Text007,
              TotalDebit[1], TotalDebit[2]);
        if TotalCredit[1] <> TotalCredit[2] then
            Error(Text008,
              TotalCredit[1], TotalCredit[2]);
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    local procedure ParseTrailerRecord()
    begin
        Evaluate(LineCounter[2], CopyStr(CodBankStmtSrcLine.Data, 17, 6));
        Evaluate(TotalDebit[2], CopyStr(CodBankStmtSrcLine.Data, 23, 15));
        Evaluate(TotalCredit[2], CopyStr(CodBankStmtSrcLine.Data, 38, 15));
        TotalDebit[2] := TotalDebit[2] / 1000;
        TotalCredit[2] := TotalCredit[2] / 1000;
    end;

    procedure CheckCodaRecord(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"): Boolean
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        if CodBankStmtSrcLine.ID in [CodBankStmtSrcLine.ID::Movement, CodBankStmtSrcLine.ID::Information, CodBankStmtSrcLine.ID::"Free Message"] then
            ParseDataRecord()
        else
            Error(Text009, CodBankStmtSrcLine."Line No.", CodBankStmtSrcLine.ID);
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    local procedure ParseDataRecord()
    begin
        // Common Stuff
        Evaluate(CodBankStmtSrcLine."Item Code", CopyStr(CodBankStmtSrcLine.Data, 2, 1));
        if not Evaluate(CodBankStmtSrcLine."Sequence No.", CopyStr(CodBankStmtSrcLine.Data, 3, 4)) then
            Error(Text010,
              CodBankStmtSrcLine.FieldCaption("Sequence No."), CodBankStmtSrcLine.Data);
        if not Evaluate(CodBankStmtSrcLine."Detail No.", CopyStr(CodBankStmtSrcLine.Data, 7, 4)) then
            Error(Text010,
              CodBankStmtSrcLine.FieldCaption("Detail No."), CodBankStmtSrcLine.Data);
        if not Evaluate(CodBankStmtSrcLine."Binding Code", CopyStr(CodBankStmtSrcLine.Data, 128, 1)) then
            Error(Text010,
              CodBankStmtSrcLine.FieldCaption("Binding Code"), CodBankStmtSrcLine.Data);
        // Specific Stuff
        case CodBankStmtSrcLine.ID of
            CodBankStmtSrcLine.ID::Movement:
                ParseMovementRecord();
            CodBankStmtSrcLine.ID::Information:
                ParseInformationRecord();
            CodBankStmtSrcLine.ID::"Free Message":
                ParseFreeMessageRecord();
        end;
    end;

    local procedure ParseMovementRecord()
    begin
        if not Evaluate(CodBankStmtSrcLine."Sequence Code", CopyStr(CodBankStmtSrcLine.Data, 126, 1)) then
            Error(Text010,
              CodBankStmtSrcLine.FieldCaption("Sequence Code"), CodBankStmtSrcLine.Data);
        case CodBankStmtSrcLine."Item Code" of
            '1':
                begin
                    if BankAcc."Version Code" = '1' then begin
                        Evaluate(CodBankStmtSrcLine."Bank Reference No.", CopyStr(CodBankStmtSrcLine.Data, 11, 13));
                        Evaluate(CodBankStmtSrcLine."Ext. Reference No.", CopyStr(CodBankStmtSrcLine.Data, 24, 8));
                    end else
                        Evaluate(CodBankStmtSrcLine."Bank Reference No.", CopyStr(CodBankStmtSrcLine.Data, 11, 21));
                    if CodBankStmtSrcLine.Data[32] = '0' then
                        Evaluate(CodBankStmtSrcLine.Amount, CopyStr(CodBankStmtSrcLine.Data, 33, 15))
                    else
                        Evaluate(CodBankStmtSrcLine.Amount, '-' + CopyStr(CodBankStmtSrcLine.Data, 33, 15));
                    CodBankStmtSrcLine.Amount := CodBankStmtSrcLine.Amount / 1000;
                    CodBankStmtSrcLine."Transaction Date" := DDMMYY2Date(CopyStr(CodBankStmtSrcLine.Data, 48, 6), true);
                    Evaluate(CodBankStmtSrcLine."Transaction Type", CopyStr(CodBankStmtSrcLine.Data, 54, 1));
                    Evaluate(CodBankStmtSrcLine."Transaction Family", CopyStr(CodBankStmtSrcLine.Data, 55, 2));
                    Evaluate(CodBankStmtSrcLine.Transaction, CopyStr(CodBankStmtSrcLine.Data, 57, 2));
                    Evaluate(CodBankStmtSrcLine."Transaction Category", CopyStr(CodBankStmtSrcLine.Data, 59, 3));
                    Evaluate(CodBankStmtSrcLine."Message Type", CopyStr(CodBankStmtSrcLine.Data, 62, 1));
                    if CodBankStmtSrcLine."Message Type" = CodBankStmtSrcLine."Message Type"::"Standard format" then begin
                        Evaluate(CodBankStmtSrcLine."Type Standard Format Message", CopyStr(CodBankStmtSrcLine.Data, 63, 3));
                        Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 66, 50));
                    end else begin
                        Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 63, 53));
                        CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '>', ' ');
                    end;
                    CodBankStmtSrcLine."Posting Date" := DDMMYY2Date(CopyStr(CodBankStmtSrcLine.Data, 116, 6), true);
                    Evaluate(CodBankStmtSrcLine."Statement No.", Format(CODAStatementNo));
                    Evaluate(CodBankStmtSrcLine."Globalisation Code", CopyStr(CodBankStmtSrcLine.Data, 125, 1));
                end;
            '2':
                begin
                    Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 11, 53));
                    CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '>', ' ');
                    if BankAcc."Version Code" = '1' then begin
                        Evaluate(CodBankStmtSrcLine."Customer Reference", CopyStr(CodBankStmtSrcLine.Data, 64, 26));
                        Evaluate(CodBankStmtSrcLine."Original Transaction Currency", CopyStr(CodBankStmtSrcLine.Data, 90, 3));
                        Evaluate(CodBankStmtSrcLine."Original Transaction Amount", '0' + DelChr(CopyStr(CodBankStmtSrcLine.Data, 93, 15), '=', ' '));
                    end else begin
                        Evaluate(CodBankStmtSrcLine."Customer Reference", DelChr(CopyStr(CodBankStmtSrcLine.Data, 64, 35), '<>', ' '));
                        Evaluate(CodBankStmtSrcLine."SWIFT Address", DelChr(CopyStr(CodBankStmtSrcLine.Data, 99, 11)));
                    end;
                end;
            '3':
                if BankAcc."Version Code" = '1' then begin
                    Evaluate(CodBankStmtSrcLine."Bank Account No. Other Party", CopyStr(CodBankStmtSrcLine.Data, 11, 12));
                    Evaluate(CodBankStmtSrcLine."Internal Codes Other Party", CopyStr(CodBankStmtSrcLine.Data, 23, 10));
                    Evaluate(CodBankStmtSrcLine."Ext. Acc. No. Other Party", CopyStr(CodBankStmtSrcLine.Data, 33, 15));
                    Evaluate(CodBankStmtSrcLine."Name Other Party", CopyStr(CodBankStmtSrcLine.Data, 48, 26));
                    Evaluate(CodBankStmtSrcLine."Address Other Party", CopyStr(CodBankStmtSrcLine.Data, 74, 26));
                    Evaluate(CodBankStmtSrcLine."City Other Party", CopyStr(CodBankStmtSrcLine.Data, 100, 26));
                end else begin
                    Evaluate(CodBankStmtSrcLine."Bank Account No. Other Party", DelChr(CopyStr(CodBankStmtSrcLine.Data, 11, 34)));
                    Evaluate(CodBankStmtSrcLine."Name Other Party", CopyStr(CodBankStmtSrcLine.Data, 48, 35));
                    Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 83, 43));
                end;
            else
                Error(Text012,
                  CodBankStmtSrcLine.FieldCaption("Item Code"), CodBankStmtSrcLine."Line No.", CodBankStmtSrcLine."Item Code");
        end;
        // checksum
        if CodBankStmtSrcLine."Detail No." = 0 then
            UpdateTotalAmount();
    end;

    local procedure ParseInformationRecord()
    begin
        if not Evaluate(CodBankStmtSrcLine."Sequence Code", CopyStr(CodBankStmtSrcLine.Data, 126, 1)) then
            Error(Text010,
              CodBankStmtSrcLine.FieldCaption("Sequence Code"), CodBankStmtSrcLine.Data);
        case CodBankStmtSrcLine."Item Code" of
            '1':
                begin
                    if BankAcc."Version Code" = '1' then begin
                        Evaluate(CodBankStmtSrcLine."Bank Reference No.", CopyStr(CodBankStmtSrcLine.Data, 11, 13));
                        Evaluate(CodBankStmtSrcLine."Ext. Reference No.", CopyStr(CodBankStmtSrcLine.Data, 24, 8));
                    end else
                        Evaluate(CodBankStmtSrcLine."Bank Reference No.", CopyStr(CodBankStmtSrcLine.Data, 11, 21));
                    Evaluate(CodBankStmtSrcLine."Transaction Type", CopyStr(CodBankStmtSrcLine.Data, 32, 1));
                    Evaluate(CodBankStmtSrcLine."Transaction Family", CopyStr(CodBankStmtSrcLine.Data, 33, 2));
                    Evaluate(CodBankStmtSrcLine.Transaction, CopyStr(CodBankStmtSrcLine.Data, 35, 2));
                    Evaluate(CodBankStmtSrcLine."Transaction Category", CopyStr(CodBankStmtSrcLine.Data, 37, 3));
                    Evaluate(CodBankStmtSrcLine."Message Type", CopyStr(CodBankStmtSrcLine.Data, 40, 1));
                    if CodBankStmtSrcLine."Message Type" = CodBankStmtSrcLine."Message Type"::"Standard format" then begin
                        Evaluate(CodBankStmtSrcLine."Type Standard Format Message", CopyStr(CodBankStmtSrcLine.Data, 41, 3));
                        Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 44, 70));
                    end else begin
                        Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 41, 73));
                        CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '<>', ' ');
                    end;
                    OtherPartyAddrDetailsExist := (BankAcc."Version Code" = '2') and (CodBankStmtSrcLine."Type Standard Format Message" = 1);
                    if OtherPartyAddrDetailsExist then begin
                        Evaluate(CodBankStmtSrcLine."Name Other Party", CopyStr(CodBankStmtSrcLine.Data, 44, 35));
                        CodBankStmtSrcLine."Name Other Party" := DelChr(CodBankStmtSrcLine."Name Other Party", '<>', ' ');
                    end;
                end;
            '2':
                begin
                    Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 11, 105));
                    CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '<>', ' ');
                    if OtherPartyAddrDetailsExist then begin
                        Evaluate(CodBankStmtSrcLine."Address Other Party", CopyStr(CodBankStmtSrcLine.Data, 11, 35));
                        CodBankStmtSrcLine."Address Other Party" := DelChr(CodBankStmtSrcLine."Address Other Party", '<>', ' ');
                        Evaluate(CodBankStmtSrcLine."City Other Party", CopyStr(CodBankStmtSrcLine.Data, 46, 35));
                        CodBankStmtSrcLine."City Other Party" := DelChr(CodBankStmtSrcLine."City Other Party", '<>', ' ');
                    end;
                end;
            '3':
                begin
                    Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 11, 90));
                    CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '<>', ' ');
                end;
            else
                Error(Text012,
                  CodBankStmtSrcLine.FieldCaption("Item Code"), CodBankStmtSrcLine."Line No.", CodBankStmtSrcLine."Item Code");
        end;
    end;

    local procedure ParseFreeMessageRecord()
    begin
        if BankAcc."Version Code" = '1' then begin
            Evaluate(CodBankStmtSrcLine."Bank Reference No.", CopyStr(CodBankStmtSrcLine.Data, 11, 13));
            Evaluate(CodBankStmtSrcLine."Ext. Reference No.", CopyStr(CodBankStmtSrcLine.Data, 24, 8));
            Evaluate(CodBankStmtSrcLine."Message Type", CopyStr(CodBankStmtSrcLine.Data, 32, 1));
            if CodBankStmtSrcLine."Message Type" = CodBankStmtSrcLine."Message Type"::"Standard format" then begin
                Evaluate(CodBankStmtSrcLine."Type Standard Format Message", CopyStr(CodBankStmtSrcLine.Data, 33, 3));
                Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 36, 77));
            end else begin
                Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 33, 80));
                CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '>', ' ');
            end;
        end else begin
            Evaluate(CodBankStmtSrcLine."Bank Reference No.", CopyStr(CodBankStmtSrcLine.Data, 11, 21));
            Evaluate(CodBankStmtSrcLine."Statement Message", CopyStr(CodBankStmtSrcLine.Data, 33, 80));
            CodBankStmtSrcLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '>', ' ');
        end;

        if Evaluate(CodBankStmtSrcLine."Transaction Family", CopyStr(CodBankStmtSrcLine.Data, 113, 2)) then;
        if Evaluate(CodBankStmtSrcLine.Transaction, CopyStr(CodBankStmtSrcLine.Data, 115, 2)) then;
    end;

    procedure UpdateStatementNo(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"; xStatementNo: Code[20]; StatementNo: Code[20]): Code[20]
    begin
        CodBankStmtSrcLine.SetFilter("Bank Account No.", CodedBankStmtSrcLine."Bank Account No.");
        CodBankStmtSrcLine.SetFilter("Statement No.", xStatementNo);
        if CodBankStmtSrcLine.FindFirst() then
            repeat
                CodBankStmtSrcLine.Rename(CodBankStmtSrcLine."Bank Account No.", StatementNo, CodBankStmtSrcLine."Line No.");
            until CodBankStmtSrcLine.FindFirst() = false;
        exit(StatementNo);
    end;

    procedure UpdateTotalAmount()
    begin
        if CodBankStmtSrcLine.Amount > 0 then
            TotalCredit[1] := TotalCredit[1] + CodBankStmtSrcLine.Amount
        else
            TotalDebit[1] := TotalDebit[1] - CodBankStmtSrcLine.Amount
    end;

    procedure UpdateLineCounter(var CodedBankStmtSrcLine: Record "CODA Statement Source Line")
    begin
        if (CodedBankStmtSrcLine.ID > CodedBankStmtSrcLine.ID::Header) and (CodedBankStmtSrcLine.ID < CodedBankStmtSrcLine.ID::Trailer) then
            LineCounter[1] := LineCounter[1] + 1;
    end;

    procedure Success()
    begin
        Message(Text013, LineCounter[1], TotalDebit[1], TotalCredit[1], SkippedLines);

        Clear(LineCounter);
        Clear(TotalDebit);
        Clear(TotalCredit);
    end;

    procedure SkipLine()
    begin
        SkippedLines := SkippedLines + 1
    end;

    procedure DDMMYY2Date(DDMMYY: Text; AllowInvalidDate: Boolean): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        YearTxt: Text;
    begin
        if AllowInvalidDate then begin
            DDMMYY := DelChr(DDMMYY, '=', DelChr(DDMMYY, '=', '0123456789'));
            if StrLen(DDMMYY) <> 6 then
                exit(0D);
            if not Evaluate(Day, CopyStr(DDMMYY, 1, 2)) then
                exit(0D);
            if not Evaluate(Month, CopyStr(DDMMYY, 3, 2)) then
                exit(0D);
            YearTxt := '20' + CopyStr(DDMMYY, 5, 2);
            if not Evaluate(Year, YearTxt) then
                exit(0D);
        end;
        Evaluate(Day, CopyStr(DDMMYY, 1, 2));
        Evaluate(Month, CopyStr(DDMMYY, 3, 2));
        YearTxt := '20' + CopyStr(DDMMYY, 5, 2);
        Evaluate(Year, YearTxt);
        exit(DMY2Date(Day, Month, Year));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCodaImport(var BankAcc: record "Bank Account"; var EnterpriseNo: Text[11]; var LineCounter: array[2] of Integer; var TotalDebit: array[2] of Decimal; var TotalCredit: array[2] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCodaHeader(var CodaStatementSourceLine: Record "CODA Statement Source Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterParseHeaderRecord(var CODAStatementSourceLine: Record "CODA Statement Source Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckOldBalance(var CodaStatementSourceLine: Record "CODA Statement Source Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOldBalance(var CODAStatementSourceLine: Record "CODA Statement Source Line"; var OK: Boolean; var IsHandled: Boolean)
    begin
    end;

}

