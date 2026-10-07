// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 148310 "Expense API Curr. Helper Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        CurrencyHelper: Codeunit "Expense API Currency Helper";

    [Test]
    procedure BlankCurrencyFallsBackToLCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Result: Code[10];
    begin
        GeneralLedgerSetup.Get();

        Result := CurrencyHelper.GetCurrencyCodeForAPI('');

        Assert.AreEqual(
            GeneralLedgerSetup."LCY Code",
            Result,
            'Currency code should default to the LCY code when empty.');
    end;

    [Test]
    procedure NonLCYCurrencyRemainsUnchangedForAPI()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        NonLCYCode: Code[10];
    begin
        GeneralLedgerSetup.Get();
        NonLCYCode := SelectNonLCYCode(GeneralLedgerSetup."LCY Code");

        Assert.AreEqual(
            NonLCYCode,
            CurrencyHelper.GetCurrencyCodeForAPI(NonLCYCode),
            'Non-LCY currency codes should pass through unchanged.');
    end;

    [Test]
    procedure LCYCurrencyFromAPIConvertsToBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();

        Assert.AreEqual(
            '',
            CurrencyHelper.GetCurrencyCodeFromAPI(GeneralLedgerSetup."LCY Code"),
            'Incoming LCY currency codes should be stored as blank.');
    end;

    [Test]
    procedure NonLCYCurrencyFromAPIRemainsUnchanged()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        NonLCYCode: Code[10];
    begin
        GeneralLedgerSetup.Get();
        NonLCYCode := SelectNonLCYCode(GeneralLedgerSetup."LCY Code");

        Assert.AreEqual(
            NonLCYCode,
            CurrencyHelper.GetCurrencyCodeFromAPI(NonLCYCode),
            'Non-LCY currency codes should remain as provided.');
    end;

    local procedure SelectNonLCYCode(LCYCode: Code[10]): Code[10]
    var
        Candidate: Code[10];
    begin
        Candidate := 'NONLCY';
        if Candidate = LCYCode then
            Candidate := 'ALTLCY';

        exit(Candidate);
    end;
}
