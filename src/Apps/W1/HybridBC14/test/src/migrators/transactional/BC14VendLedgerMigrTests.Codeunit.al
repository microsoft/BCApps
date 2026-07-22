// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;

codeunit 148916 "BC14 VendLedgerMigr Tests"
{
    // [FEATURE] [BC14 Cloud Migration Vendor Ledger Entry]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        JournalBatchNameTxt: Label 'BC14VE0001', Locked = true;

    [Test]
    procedure TestGetDisplayName()
    var
        BC14VendorLedgerMigrator: Codeunit "BC14 Vendor Ledger Migrator";
    begin
        // [SCENARIO] GetDisplayName returns the vendor ledger migrator name.
        Assert.AreEqual('Vendor Ledger Entry Migrator', BC14VendorLedgerMigrator.GetDisplayName(), 'Unexpected display name.');
    end;

    [Test]
    procedure TestIsEnabled_PayablesModuleDisabled_ReturnsFalse()
    var
        BC14VendorLedgerMigrator: Codeunit "BC14 Vendor Ledger Migrator";
    begin
        // [SCENARIO] The migrator opts out when the payables module is disabled.
        SetPayablesModule(false);
        Assert.IsFalse(BC14VendorLedgerMigrator.IsEnabled(), 'IsEnabled should be false when payables module disabled.');
    end;

    [Test]
    procedure TestIsEnabled_PayablesModuleEnabled_ReturnsTrue()
    var
        BC14VendorLedgerMigrator: Codeunit "BC14 Vendor Ledger Migrator";
    begin
        // [SCENARIO] The migrator is enabled when the payables module is enabled.
        SetPayablesModule(true);
        Assert.IsTrue(BC14VendorLedgerMigrator.IsEnabled(), 'IsEnabled should be true when payables module enabled.');
    end;

    [Test]
    procedure TestCreateJournalLine_OpenEntry_BalancesToPayablesControlAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14VendorLedgerMigrator: Codeunit "BC14 Vendor Ledger Migrator";
    begin
        // [SCENARIO] An open vendor ledger entry is staged as a vendor journal line whose
        //            balancing account is the vendor posting group's payables control account
        //            (the net-zero G/L opening balance).
        CleanupTestData();
        SetPayablesModule(true);
        CreateGLAccount('VEND-PAY', 'Payables Control');
        CreatePostingGroupAndVendor('VENDPG', 'VEND-PAY', 'VEND-001');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Vendor Ledger Migration');

        InsertVendorLedgerEntry(1, 'VEND-001', 'VENDPG', 'VDOC-001', -1200);

        // [WHEN] The migrator stages the entry
        BC14VendorLedgerMigrator.CreateJournalLine(BC14VendorLedgerEntry);

        // [THEN] A journal line balances the payables control account
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Journal line should be created.');
        Assert.AreEqual(GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type", 'Account Type should be Vendor.');
        Assert.AreEqual('VEND-001', GenJournalLine."Account No.", 'Account No. should be the vendor.');
        Assert.AreEqual(-1200, GenJournalLine.Amount, 'Amount should equal the remaining amount.');
        Assert.AreEqual(GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account Type", 'Bal. Account Type should be G/L Account.');
        Assert.AreEqual('VEND-PAY', GenJournalLine."Bal. Account No.", 'Bal. Account No. should be the payables control account.');
    end;

    [Test]
    procedure TestCreateJournalLine_SettledEntry_IsSkipped()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14VendorLedgerMigrator: Codeunit "BC14 Vendor Ledger Migrator";
    begin
        // [SCENARIO] A fully settled entry (remaining amount 0) is not staged.
        CleanupTestData();
        SetPayablesModule(true);
        CreateGLAccount('VEND-PAY', 'Payables Control');
        CreatePostingGroupAndVendor('VENDPG', 'VEND-PAY', 'VEND-002');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Vendor Ledger Migration');

        InsertVendorLedgerEntry(2, 'VEND-002', 'VENDPG', 'VDOC-002', 0);

        // [WHEN] The migrator processes the entry
        BC14VendorLedgerMigrator.CreateJournalLine(BC14VendorLedgerEntry);

        // [THEN] No journal line is created
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.IsTrue(GenJournalLine.IsEmpty(), 'Settled entry should not produce a journal line.');
    end;

    local procedure CleanupTestData()
    var
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        BC14DetailedVendorLE: Record "BC14 Detailed Vendor LE";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        BC14VendorLedgerEntry.DeleteAll();
        BC14DetailedVendorLE.DeleteAll();
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.DeleteAll();
        Vendor.SetFilter("No.", 'VEND-*');
        Vendor.DeleteAll();
        if VendorPostingGroup.Get('VENDPG') then
            VendorPostingGroup.Delete();
        GLAccount.SetFilter("No.", 'VEND-PAY');
        GLAccount.DeleteAll();
    end;

    local procedure SetPayablesModule(Enabled: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.Validate("Migrate Payables Module", Enabled);
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

    local procedure CreatePostingGroupAndVendor(PostingGroupCode: Code[20]; PayablesAccountNo: Code[20]; VendorNo: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
    begin
        if not VendorPostingGroup.Get(PostingGroupCode) then begin
            VendorPostingGroup.Init();
            VendorPostingGroup.Code := PostingGroupCode;
            VendorPostingGroup."Payables Account" := PayablesAccountNo;
            VendorPostingGroup.Insert();
        end;

        if not Vendor.Get(VendorNo) then begin
            Vendor.Init();
            Vendor."No." := VendorNo;
            Vendor."Vendor Posting Group" := PostingGroupCode;
            Vendor.Insert();
        end;
    end;

    local procedure InsertVendorLedgerEntry(EntryNo: Integer; VendorNo: Code[20]; PostingGroupCode: Code[20]; DocumentNo: Code[20]; RemainingAmount: Decimal)
    var
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        BC14DetailedVendorLE: Record "BC14 Detailed Vendor LE";
    begin
        BC14VendorLedgerEntry.Init();
        BC14VendorLedgerEntry."Entry No." := EntryNo;
        BC14VendorLedgerEntry."Vendor No." := VendorNo;
        BC14VendorLedgerEntry."Posting Date" := WorkDate();
        BC14VendorLedgerEntry."Document No." := DocumentNo;
        BC14VendorLedgerEntry."Vendor Posting Group" := PostingGroupCode;
        BC14VendorLedgerEntry.Open := true;
        BC14VendorLedgerEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14VendorLedgerEntry.Insert();

        BC14DetailedVendorLE.Init();
        BC14DetailedVendorLE."Entry No." := EntryNo;
        BC14DetailedVendorLE."Vendor Ledger Entry No." := EntryNo;
        BC14DetailedVendorLE."Posting Date" := WorkDate();
        BC14DetailedVendorLE.Amount := RemainingAmount;
        BC14DetailedVendorLE."Ledger Entry Amount" := true;
        BC14DetailedVendorLE.Insert();
    end;
}
