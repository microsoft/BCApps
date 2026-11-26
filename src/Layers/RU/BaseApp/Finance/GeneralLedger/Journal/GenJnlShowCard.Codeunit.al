// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Displays account card pages based on general journal line account type for detailed account information and maintenance.
/// Opens appropriate account card page based on account type.
/// </summary>
/// <remarks>
/// Account card navigation functionality providing seamless access to account master data from journal lines.
/// Account type-specific card display: G/L Account Card, Customer Card, Vendor Card, Employee Card, Bank Account Card, Fixed Asset Card.
/// Extensible through integration events for additional account types.
/// Key features: Context-sensitive card opening, account number positioning, direct navigation from journal interface.
/// Integration: Provides drill-down capability from journal lines to corresponding account master records.
/// </remarks>
codeunit 15 "Gen. Jnl.-Show Card"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        OnBeforeRun(Rec, IsHandled);
        if not IsHandled then
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
                        Vend.Get(Rec."Account No.");
                        Vend."No." := Rec."Account No.";
                        case Vend."Vendor Type" of
                            Vend."Vendor Type"::Vendor:
                                PAGE.Run(PAGE::"Vendor Card", Vend);
                            Vend."Vendor Type"::"Resp. Employee":
                                PAGE.Run(PAGE::"Resp. Employee Card", Vend);
                            Vend."Vendor Type"::"Tax Authority":
                                PAGE.Run(PAGE::"Tax Authority/Fund Card", Vend);
                        end;
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

    /// <summary>
    /// Integration event raised before displaying account card page from journal line.
    /// Enables extensions to handle additional account types.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that triggered the card display operation.</param>
    /// <param name="IsHandled">Set to true to skip the default account card handling.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after displaying account card page from journal line.
    /// Enables custom processing after account card navigation is completed.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that triggered the card display operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

