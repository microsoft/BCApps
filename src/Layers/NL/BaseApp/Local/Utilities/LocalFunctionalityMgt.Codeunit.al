// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.Payment;

codeunit 11400 "Local Functionality Mgt."
{
    // General functions for Local Functionality.


    trigger OnRun()
    begin
    end;

    var
        Text1000031: Label 'PG0123456789';
        Text1000032: Label 'P';
        Text1000033: Label 'G';
        Text1000034: Label 'PG';

    procedure CheckBankAccNo(Acc: Text[30]; CountryCode: Code[10]; var AccountNo: Text[30]) Result: Boolean
    var
        Len: Integer;
        BaseLen: Integer;
        FirstCharacter: Char;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBankAccNo(Acc, CountryCode, AccountNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        AccountNo := Acc;
        if CountryCode <> '' then
            exit(true);
        Acc := CharacterFilter(UpperCase(Acc), Text1000031);
        Acc := DelChr(Acc, '>', Text1000034);
        BaseLen := StrLen(Acc);
        if (StrPos(Acc, Text1000032) = 1) or
           (StrPos(Acc, Text1000033) = 1)
        then begin
            FirstCharacter := Acc[1];
            Acc := CharacterFilter(Acc, '0123456789');
            if BaseLen <> StrLen(Acc) + 1 then
                exit(false);
            Len := StrLen(Acc);
            if (Len < 1) or (Len > 9) then
                exit(false);
            if Len = 1 then
                if Acc[1] = '0' then
                    exit(false);
            Clear(AccountNo);
            AccountNo[1] := FirstCharacter;
            AccountNo := AccountNo + Acc;
            exit(true);
        end;

        Acc := DelChr(Acc, '=', Text1000034);
        case StrLen(Acc) of
            9:
                Acc := '00' + Acc;
            10:
                Acc := CopyStr(Acc, 1, 1) + Acc;
            else
                exit(false)
        end;
        if BaseLen < 12 then
            AccountNo := CopyStr(Acc, 12 - BaseLen);
        exit(true);
    end;

    procedure CharacterFilter(Text: Text[250]; "Filter": Text[250]) Res: Text[250]
    begin
        exit(DelChr(Text, '=', DelChr(Text, '=', Filter)));
    end;

    procedure ConvertPhoneNumber(PhoneNumber: Text[20]) Res: Text[20]
    begin
        Res := CopyStr(CharacterFilter(PhoneNumber, '+0123456789'), 1, 20);

        if CopyStr(Res, 1, 3) <> '+31' then
            if CopyStr(Res, 1, 4) = '0031' then
                Res := '+31' + CopyStr(Res, 5)
            else
                Res := '+31' + CopyStr(Res, 2);

        if Res[4] = '0' then
            Res := '+31' + CopyStr(Res, 5);
    end;

    procedure GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory: Record "Payment History"; var PaymentHistoryLine: Record "Payment History Line"; var TotalAmount: Text[50]; var LineCount: Text[20])
    var
        TotalAmountDecimal: Decimal;
    begin
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
        PaymentHistoryLine.SetFilter(Status, '%1|%2|%3', PaymentHistoryLine.Status::New, PaymentHistoryLine.Status::Transmitted, PaymentHistoryLine.Status::"Request for Cancellation");
        LineCount := Format(PaymentHistoryLine.Count);

        TotalAmountDecimal := 0;
        PaymentHistoryLine.SetFilter("Foreign Amount", '<>0');
        PaymentHistoryLine.CalcSums("Foreign Amount");
        TotalAmountDecimal += PaymentHistoryLine."Foreign Amount";

        PaymentHistoryLine.SetFilter("Foreign Amount", '=0');
        PaymentHistoryLine.CalcSums(Amount);
        TotalAmountDecimal += PaymentHistoryLine.Amount;

        TotalAmount := Format(Abs(TotalAmountDecimal), 0, '<Precision,2:2><Standard Format,9>');
    end;

    [Scope('OnPrem')]
    procedure GetPmtHistLineCountAndAmtPmtInf(var TotalAmount: Text[50]; var LineCount: Text[20]; PaymentHistory: Record "Payment History"; GroupPaymentHistoryLine: Record "Payment History Line")
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.Reset();
        PaymentHistoryLine.SetCurrentKey(Date, "Sequence Type");
        PaymentHistoryLine.SetRange(Date, GroupPaymentHistoryLine.Date);
        PaymentHistoryLine.SetRange("Sequence Type", GroupPaymentHistoryLine."Sequence Type");
        GetPmtHistLineCountAndAmt(PaymentHistoryLine, TotalAmount, LineCount, PaymentHistory);
    end;

    procedure GetPmtHistLineCountAndAmt(var PaymentHistoryLine: Record "Payment History Line"; var TotalAmount: Text[50]; var LineCount: Text[20]; PaymentHistory: Record "Payment History")
    begin
        GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankAccNo(Acc: Text[30]; CountryCode: Code[10]; var AccountNo: Text[30]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

