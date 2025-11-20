// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 15 "Gen. Jnl.-Show Card"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                begin
                    GLAcc."No." := Rec."Account No.";
                    PAGE.Run(PAGE::"G/L Account Card", GLAcc);
                end;
            Rec."Account Type"::Customer:
                begin
                    Cust."No." := Rec."Account No.";
                    PAGE.Run(PAGE::"Customer Card", Cust);
                end;
            Rec."Account Type"::Vendor:
                begin
                    Vend."No." := Rec."Account No.";
                    PAGE.Run(PAGE::"Vendor Card", Vend);
                end;
            Rec."Account Type"::Employee:
                begin
                    Empl."No." := Rec."Account No.";
                    PAGE.Run(PAGE::"Employee Card", Empl);
                end;
            Rec."Account Type"::"Bank Account":
                begin
                    BankAcc."No." := Rec."Account No.";
                    PAGE.Run(PAGE::"Bank Account Card", BankAcc);
                end;
            Rec."Account Type"::"Fixed Asset":
                begin
                    FA."No." := Rec."Account No.";
                    PAGE.Run(PAGE::"Fixed Asset Card", FA);
                end;
            Rec."Account Type"::"IC Partner":
                begin
                    ICPartner.Code := Rec."Account No.";
                    PAGE.Run(PAGE::"IC Partner Card", ICPartner);
                end;
        end;

        OnAfterRun(Rec);
    end;

    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Empl: Record Employee;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        ICPartner: Record "IC Partner";

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

