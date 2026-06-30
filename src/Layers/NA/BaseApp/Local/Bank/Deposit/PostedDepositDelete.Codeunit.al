// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 10144 "Posted Deposit-Delete"
{
    Permissions = TableData "Posted Deposit Header" = rd,
                  TableData "Posted Deposit Line" = rd;
    TableNo = "Posted Deposit Header";

    trigger OnRun()
    begin
        PostedDepositLine.SetRange("Deposit No.", Rec."No.");
        PostedDepositLine.DeleteAll();

        OnRunOnBeforeDelete(Rec);
        Rec.Delete();
    end;

    var
        PostedDepositLine: Record "Posted Deposit Line";

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeDelete(var Rec: Record "Posted Deposit Header")
    begin
    end;
}

