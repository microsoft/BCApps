// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Account;

codeunit 849 "Cash Flow Account - Indent"
{

    trigger OnRun()
    begin
        if not
           Confirm(
             Text1000 +
             Text1003, true)
        then
            exit;

        Indentation();
    end;

    var
        CFAccount: Record "Cash Flow Account";
        Window: Dialog;
        AccNo: array[10] of Code[20];
        i: Integer;

#pragma warning disable AA0074
        Text1000: Label 'This function updates the indentation of all the cash flow accounts in the chart of cash flow accounts. All accounts between a Begin-Total and the matching End-Total are indented one level. The Totaling for each End-total is also updated.\\';
        Text1003: Label 'Do you want to indent the chart of accounts?';
#pragma warning disable AA0470
        Text1004: Label 'Indenting the Chart of Accounts #1##########';
        Text1005: Label 'End-Total %1 is missing a matching Begin-Total.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ArrayExceededErr: Label 'You can only indent %1 levels for accounts of the type Begin-Total.', Comment = '%1 = A number bigger than 1';

    local procedure Indentation()
    begin
        Window.Open(Text1004);

        if CFAccount.Find('-') then
            repeat
                Window.Update(1, CFAccount."No.");

                if CFAccount."Account Type" = CFAccount."Account Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          Text1005,
                          CFAccount."No.");
                    CFAccount.Totaling := AccNo[i] + '..' + CFAccount."No.";
                    i := i - 1;
                end;

                CFAccount.Validate(CFAccount.Indentation, i);
                CFAccount.Modify();

                if CFAccount."Account Type" = CFAccount."Account Type"::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(AccNo) then
                        Error(ArrayExceededErr, ArrayLen(AccNo));
                    AccNo[i] := CFAccount."No.";
                end;
            until CFAccount.Next() = 0;

        Window.Close();
    end;
}

