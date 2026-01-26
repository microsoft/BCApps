// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.BankAccount;

using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Setup;

codeunit 32000002 "Bank Nos Check"
{

    trigger OnRun()
    begin
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        Vend: Record Vendor;
        LinePos: Integer;
        OrigCheckValue: Text[30];
        CheckValueChar: Text[2];
        ReferenceNumber: Code[40];
        Multiplicand: Integer;
        CheckValue: Integer;
        RoundNumber: Integer;
        NumberLen: Integer;
        Counter: Integer;
        Length: Integer;
        NoSeriesRefNo: Code[10];
        WeightStr: Text[20];
        Text1090000: Label 'Type account number in correct format with hyphen.\If the account is in a foreign bank select correct Country Code.';
        Text1090001: Label 'Error in Bank Account number, check the number.';
        Text1090002: Label 'Reference number cannot be over 20 character long.\Change the setting in Sales & Receivables Setup.';
        Text1090003: Label 'Enter %1 for vendor %2.';
        Text1090004: Label '%1 missing for vendor %2.';
        Text1090005: Label 'Minimum length for a Reference is 2 characters.';
        Text1090006: Label 'Incorrect reference number.';
        Text1090007: Label 'Check account number for bank account %1.';
        ZeroReferenceNoErr: Label 'Reference number cannot contain only zeros.';
        RefStartPos: Integer;

    procedure ConvertBankAcc(var BankAccNro: Text[15]; BankAccCode: Code[20])
    begin
        if BankAccNro = '' then
            Error(Text1090007, BankAccCode);
        Length := StrLen(BankAccNro);
        LinePos := StrPos(BankAccNro, '-');
        BankAccNro := CopyStr(BankAccNro, 1, LinePos - 1) + CopyStr(BankAccNro, LinePos + 1);
        Length := StrLen(BankAccNro);

        if Length < 14 then
            repeat
                if (CopyStr(BankAccNro, 1, 1) = '4') or (CopyStr(BankAccNro, 1, 1) = '5') then
                    BankAccNro := CopyStr(BankAccNro, 1, 7) + '0' + CopyStr(BankAccNro, 7 + 1)
                else
                    BankAccNro := CopyStr(BankAccNro, 1, 6) + '0' + CopyStr(BankAccNro, 6 + 1);
                Length := Length + 1;
            until Length = 14;
    end;

    [Scope('OnPrem')]
    procedure CheckBankAccount(BankAccNro: Text[15]; BankAccCode: Code[20]) FormatOK: Boolean
    begin
        Length := StrLen(BankAccNro);
        LinePos := StrPos(BankAccNro, '-');
        if LinePos < 1 then
            Error(Text1090000);

        ConvertBankAcc(BankAccNro, BankAccCode);

        Length := StrLen(BankAccNro);
        OrigCheckValue := CopyStr(BankAccNro, Length, 1);
        BankAccNro := CopyStr(BankAccNro, 1, Length - 1);
        NumberLen := StrLen(BankAccNro);

        for Counter := 1 to NumberLen do
            case Counter of
                1, 3, 5, 7, 9, 11, 13, 15:
                    begin
                        Evaluate(Multiplicand, CopyStr(BankAccNro, NumberLen + 1 - Counter, 1));
                        Multiplicand := Multiplicand * 2;
                        case Multiplicand of
                            10:
                                Multiplicand := 1;
                            11:
                                Multiplicand := 2;
                            12:
                                Multiplicand := 3;
                            13:
                                Multiplicand := 4;
                            14:
                                Multiplicand := 5;
                            15:
                                Multiplicand := 6;
                            16:
                                Multiplicand := 7;
                            17:
                                Multiplicand := 8;
                            18:
                                Multiplicand := 9;
                        end;
                        CheckValue := CheckValue + Multiplicand;
                    end;
                2, 4, 6, 8, 10, 12, 14:
                    begin
                        Evaluate(Multiplicand, CopyStr(BankAccNro, NumberLen + 1 - Counter, 1));
                        CheckValue := CheckValue + Multiplicand * 1;
                    end;
            end;
        RoundNumber := Round(CheckValue, 10, '>');
        CheckValue := RoundNumber - CheckValue;
        CheckValueChar := Format(CheckValue, 1);
        FormatOK := true;
        if CheckValueChar <> OrigCheckValue then
            Error(Text1090001);

        ClearAll();
    end;

    [Scope('OnPrem')]
    procedure InvReferenceCheck(PurchInvReference: Text[70])
    begin
        Length := StrLen(PurchInvReference);
        if Length < 2 then
            Error(Text1090005);

        if DelChr(PurchInvReference, '=', '0') = '' then
            Error(ZeroReferenceNoErr);

        OrigCheckValue := CopyStr(PurchInvReference, Length);
        PurchInvReference := CopyStr(PurchInvReference, 1, Length - 1);
        NumberLen := StrLen(PurchInvReference);

        Clear(Multiplicand);
        Clear(CheckValue);

        for Counter := 1 to NumberLen do
            case Counter of
                1, 4, 7, 10, 13, 16, 19:
                    begin
                        Evaluate(Multiplicand, CopyStr(PurchInvReference, NumberLen + 1 - Counter, 1));
                        CheckValue := CheckValue + Multiplicand * 7;
                    end;
                2, 5, 8, 11, 14, 17, 20:
                    begin
                        Evaluate(Multiplicand, CopyStr(PurchInvReference, NumberLen + 1 - Counter, 1));
                        CheckValue := CheckValue + Multiplicand * 3;
                    end;
                3, 6, 9, 12, 15, 18:
                    begin
                        Evaluate(Multiplicand, CopyStr(PurchInvReference, NumberLen + 1 - Counter, 1));
                        CheckValue := CheckValue + Multiplicand * 1;
                    end;
            end;

        RoundNumber := Round(CheckValue, 10, '>');
        CheckValue := RoundNumber - CheckValue;
        CheckValueChar := Format(CheckValue, 1);

        if not (CheckValueChar = OrigCheckValue) then
            Error(Text1090006);
    end;

    procedure CreateSalesInvReference(PostingNo: Code[20]; BillToCustomer: Code[20]) NewRefNo: Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SalesSetup.Get();
        Clear(ReferenceNumber);
        if not SalesSetup."Invoice No." then
            SalesSetup.TestField("Reference Nos.");
        if SalesSetup."Reference Nos." = '' then
            SalesSetup.TestField("Invoice No.", true);
        WeightStr := '7137137137137137137';
        if SalesSetup."Reference Nos." <> '' then
                NoSeriesRefNo := NoSeries.GetNextNo(SalesSetup."Reference Nos.");
        if SalesSetup."Invoice No." then
            ReferenceNumber := DelChr(PostingNo, '=', DelChr(PostingNo, '=', '0123456789'));
        if NoSeriesRefNo <> '' then
            ReferenceNumber := NoSeriesRefNo + ReferenceNumber;
        if SalesSetup."Customer No." then
            ReferenceNumber := DelChr(BillToCustomer, '=', DelChr(BillToCustomer, '=', '0123456789')) + ReferenceNumber;
        if SalesSetup.Date then
            ReferenceNumber := Format(WorkDate(), 0, '<day,2><Month,2><year,2>') + ReferenceNumber;
        if SalesSetup."Default Number" <> '' then
            ReferenceNumber := SalesSetup."Default Number" + ReferenceNumber;

        NumberLen := StrLen(ReferenceNumber);
        if NumberLen > 19 then
            Error(Text1090002);

        CheckValue := StrCheckSum(ReferenceNumber, CopyStr(WeightStr, 20 - NumberLen));
        NewRefNo := CopyStr(ReferenceNumber + Format(CheckValue), 1, MaxStrLen(NewRefNo));

        Counter := 1;
        repeat
            if CopyStr(NewRefNo, Counter, 1) <> '0' then begin
                RefStartPos := Counter;
                Counter := 19;
            end;
            Counter := Counter + 1;
        until Counter = 20;
        NewRefNo := CopyStr(NewRefNo, RefStartPos);
    end;

    [Scope('OnPrem')]
    procedure PurchMessageCheck(var Rec: Record "Purchase Header")
    var
        MsgText1: Text[10];
        MsgText2: Text[15];
        MsgText3: Text[6];
        MsgLen: Integer;
    begin
        Vend.Get(Rec."Pay-to Vendor No.");
        case Rec."Message Type" of
            0:
                Rec."Invoice Message" := '';
            1:
                if Vend."Our Account No." <> '' then begin
                    if Rec."Vendor Invoice No." = '' then begin
                        Message(Text1090003, Rec.FieldCaption("Vendor Invoice No."), Vend."No.");
                        Rec."Invoice Message" := '';
                        Rec."Message Type" := 0;
                        exit;
                    end;

                    MsgText1 := CopyStr(Vend."Our Account No.", 1, 10);
                    MsgLen := StrLen(MsgText1);
                    if MsgLen < 10 then
                        repeat
                            MsgText1 := MsgText1 + ' ';
                            MsgLen := MsgLen + 1
                        until MsgLen = 10;

                    MsgText2 := CopyStr(Rec."Vendor Invoice No.", 1, 15);
                    MsgLen := StrLen(MsgText2);
                    if MsgLen < 15 then
                        repeat
                            MsgText2 := MsgText2 + ' ';
                            MsgLen := MsgLen + 1
                        until MsgLen = 15;

                    MsgText3 := Format(Rec."Document Date", 0, '<Year,2><Month,2><Day,2>');
                    Rec."Invoice Message" := MsgText1 + MsgText2 + MsgText3;
                end else begin
                    Message(Text1090004, Vend.FieldCaption("Our Account No."), Vend."No.");
                    Rec."Invoice Message" := '';
                    exit;
                end;
            2:
                Rec."Invoice Message" := '';
        end;
    end;
}
