// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;

codeunit 148915 "BC14 CustLedgerMigr Tests"
{
    // [FEATURE] [BC14 Cloud Migration Customer Ledger Entry]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        JournalBatchNameTxt: Label 'BC14CU0001', Locked = true;

    [Test]
    procedure TestGetDisplayName()
    var
        BC14CustLedgerMigrator: Codeunit "BC14 Cust. Ledger Migrator";
    begin
        // [SCENARIO] GetDisplayName returns the customer ledger migrator name.
        Assert.AreEqual('Customer Ledger Entry Migrator', BC14CustLedgerMigrator.GetDisplayName(), 'Unexpected display name.');
    end;

    [Test]
    procedure TestIsEnabled_ReceivablesModuleDisabled_ReturnsFalse()
    var
        BC14CustLedgerMigrator: Codeunit "BC14 Cust. Ledger Migrator";
    begin
        // [SCENARIO] The migrator opts out when the receivables module is disabled.
        SetReceivablesModule(false);
        Assert.IsFalse(BC14CustLedgerMigrator.IsEnabled(), 'IsEnabled should be false when receivables module disabled.');
    end;

    [Test]
    procedure TestIsEnabled_ReceivablesModuleEnabled_ReturnsTrue()
    var
        BC14CustLedgerMigrator: Codeunit "BC14 Cust. Ledger Migrator";
    begin
        // [SCENARIO] The migrator is enabled when the receivables module is enabled.
        SetReceivablesModule(true);
        Assert.IsTrue(BC14CustLedgerMigrator.IsEnabled(), 'IsEnabled should be true when receivables module enabled.');
    end;

    [Test]
    procedure TestCreateJournalLine_OpenEntry_BalancesToReceivablesControlAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14CustLedgerMigrator: Codeunit "BC14 Cust. Ledger Migrator";
    begin
        // [SCENARIO] An open customer ledger entry is staged as a customer journal line whose
        //            balancing account is the customer posting group's receivables control account
        //            (the net-zero G/L opening balance).
        CleanupTestData();
        SetReceivablesModule(true);
        CreateGLAccount('CUST-RECV', 'Receivables Control');
        CreatePostingGroupAndCustomer('CUSTPG', 'CUST-RECV', 'CUST-001');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Customer Ledger Migration');

        InsertCustLedgerEntry(1, 'CUST-001', 'CUSTPG', 'CDOC-001', 1500);

        // [WHEN] The migrator stages the entry
        BC14CustLedgerMigrator.CreateJournalLine(BC14CustLedgerEntry);

        // [THEN] A journal line balances the receivables control account
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Journal line should be created.');
        Assert.AreEqual(GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type", 'Account Type should be Customer.');
        Assert.AreEqual('CUST-001', GenJournalLine."Account No.", 'Account No. should be the customer.');
        Assert.AreEqual(1500, GenJournalLine.Amount, 'Amount should equal the remaining amount.');
        Assert.AreEqual(GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account Type", 'Bal. Account Type should be G/L Account.');
        Assert.AreEqual('CUST-RECV', GenJournalLine."Bal. Account No.", 'Bal. Account No. should be the receivables control account.');
    end;

    [Test]
    procedure TestCreateJournalLine_SettledEntry_IsSkipped()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14CustLedgerMigrator: Codeunit "BC14 Cust. Ledger Migrator";
    begin
        // [SCENARIO] A fully settled entry (remaining amount 0) is not staged.
        CleanupTestData();
        SetReceivablesModule(true);
        CreateGLAccount('CUST-RECV', 'Receivables Control');
        CreatePostingGroupAndCustomer('CUSTPG', 'CUST-RECV', 'CUST-002');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Customer Ledger Migration');

        InsertCustLedgerEntry(2, 'CUST-002', 'CUSTPG', 'CDOC-002', 0);

        // [WHEN] The migrator processes the entry
        BC14CustLedgerMigrator.CreateJournalLine(BC14CustLedgerEntry);

        // [THEN] No journal line is created
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.IsTrue(GenJournalLine.IsEmpty(), 'Settled entry should not produce a journal line.');
    end;

    [Test]
    procedure TestCreateJournalLine_Idempotent_DoesNotDuplicate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14CustLedgerMigrator: Codeunit "BC14 Cust. Ledger Migrator";
    begin
        // [SCENARIO] Re-running the migrator for the same entry does not create a duplicate line.
        CleanupTestData();
        SetReceivablesModule(true);
        CreateGLAccount('CUST-RECV', 'Receivables Control');
        CreatePostingGroupAndCustomer('CUSTPG', 'CUST-RECV', 'CUST-003');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Customer Ledger Migration');

        InsertCustLedgerEntry(3, 'CUST-003', 'CUSTPG', 'CDOC-003', 900);

        // [WHEN] The migrator runs twice for the same entry
        BC14CustLedgerMigrator.CreateJournalLine(BC14CustLedgerEntry);
        BC14CustLedgerMigrator.CreateJournalLine(BC14CustLedgerEntry);

        // [THEN] Only one journal line exists
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.AreEqual(1, GenJournalLine.Count(), 'Re-running should not duplicate the journal line.');
    end;

    local procedure CleanupTestData()
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14DetailedCustLE: Record "BC14 Detailed Cust. LE";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        BC14CustLedgerEntry.DeleteAll();
        BC14DetailedCustLE.DeleteAll();
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.DeleteAll();
        Customer.SetFilter("No.", 'CUST-*');
        Customer.DeleteAll();
        if CustomerPostingGroup.Get('CUSTPG') then
            CustomerPostingGroup.Delete();
        GLAccount.SetFilter("No.", 'CUST-RECV');
        GLAccount.DeleteAll();
    end;

    local procedure SetReceivablesModule(Enabled: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.Validate("Migrate Receivables Module", Enabled);
        BC14CompanySettings.Modify();
    end;

    local procedure CreateGLAccount(AccountNo: Code[20]; AccountName: Text[100])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit;
        GLAccount.Init();
        GLAccount."No." := AccountNo;
        GLAccount.Name := AccountName;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := true;
        GLAccount.Insert();
    end;

    local procedure CreatePostingGroupAndCustomer(PostingGroupCode: Code[20]; ReceivablesAccountNo: Code[20]; CustomerNo: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
    begin
        if not CustomerPostingGroup.Get(PostingGroupCode) then begin
            CustomerPostingGroup.Init();
            CustomerPostingGroup.Code := PostingGroupCode;
            CustomerPostingGroup."Receivables Account" := ReceivablesAccountNo;
            CustomerPostingGroup.Insert();
        end;

        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer."Customer Posting Group" := PostingGroupCode;
            Customer.Insert();
        end;
    end;

    local procedure InsertCustLedgerEntry(EntryNo: Integer; CustomerNo: Code[20]; PostingGroupCode: Code[20]; DocumentNo: Code[20]; RemainingAmount: Decimal)
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14DetailedCustLE: Record "BC14 Detailed Cust. LE";
    begin
        BC14CustLedgerEntry.Init();
        BC14CustLedgerEntry."Entry No." := EntryNo;
        BC14CustLedgerEntry."Customer No." := CustomerNo;
        BC14CustLedgerEntry."Posting Date" := WorkDate();
        BC14CustLedgerEntry."Document No." := DocumentNo;
        BC14CustLedgerEntry."Customer Posting Group" := PostingGroupCode;
        BC14CustLedgerEntry.Open := true;
        BC14CustLedgerEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14CustLedgerEntry.Insert();

        BC14DetailedCustLE.Init();
        BC14DetailedCustLE."Entry No." := EntryNo;
        BC14DetailedCustLE."Cust. Ledger Entry No." := EntryNo;
        BC14DetailedCustLE."Posting Date" := WorkDate();
        BC14DetailedCustLE.Amount := RemainingAmount;
        BC14DetailedCustLE."Ledger Entry Amount" := true;
        BC14DetailedCustLE.Insert();
    end;
}
