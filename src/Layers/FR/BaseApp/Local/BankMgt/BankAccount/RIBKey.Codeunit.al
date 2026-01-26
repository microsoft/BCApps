// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

codeunit 10801 "RIB Key"
{

    trigger OnRun()
    begin
    end;

    var
        Coding: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        Uncoding: Label '12345678912345678923456789';

    procedure Check(Bank: Text; Agency: Text; Account: Text; RIBKey: Integer) Result: Boolean
    var
        LongAccountNum: Code[30];
        Index: Integer;
        Remaining: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheck(Bank, Agency, Account, RIBKey, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ((StrLen(Bank) = 5) and
                (StrLen(Agency) = 5) and
                (StrLen(Account) = 11) and
                (RIBKey < 100))
        then
            exit(false);

        LongAccountNum :=
          CopyStr(Bank + Agency + Account + ConvertStr(Format(RIBKey, 2), ' ', '0'), 1, MaxStrLen(LongAccountNum));
        LongAccountNum := ConvertStr(LongAccountNum, Coding, Uncoding);

        Remaining := 0;
        for Index := 1 to 23 do
            Remaining := (Remaining * 10 + (LongAccountNum[Index] - '0')) mod 97;

        OnAfterCheck(Remaining);

        exit(Remaining = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheck(Remaining: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheck(Bank: Text; Agency: Text; Account: Text; RIBKey: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

