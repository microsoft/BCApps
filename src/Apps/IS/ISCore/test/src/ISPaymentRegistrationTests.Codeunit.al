// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Registration;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 148490 "IS Payment Registration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        ResolvedSource: RecordId;
        ResolvedRegistrationNo: Text[50];

    [Test]
    procedure JournalRecipientUsesGetterWithoutChangingTwentyCharacters()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        ISPaymentRegistrationTests: Codeunit "IS Payment Registration Tests";
        RegistrationNo: Text[50];
    begin
        SetFeatureEnabled(true);
        CreateVendorPayment(Vendor, GenJournalLine, 'STORED');
        RegistrationNo := PadStr('0012-/ ', 20, 'X');
        ISPaymentRegistrationTests.SetResolvedRegistrationNo(Vendor.RecordId(), RegistrationNo);
        BindSubscription(ISPaymentRegistrationTests);

        PmtExportMgtGenJnlLine.OnBeforeInsertPmtExportDataJnlFromGenJnlLine(TempPaymentExportData, GenJournalLine, GeneralLedgerSetup);
        UnbindSubscription(ISPaymentRegistrationTests);
        TempPaymentExportData.Insert(true);

        Assert.AreEqual(RegistrationNo, TempPaymentExportData."Recipient Reg. No.", 'The payment must use the complete getter result.');
        Vendor.Get(Vendor."No.");
        Vendor.TestField("Registration Number", 'STORED');
    end;

    [Test]
    procedure VendorLedgerRecipientRejectsOverflow()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        SetFeatureEnabled(true);
        CreateVendorPayment(Vendor, GenJournalLine, PadStr('0012', 50, 'X'));
        VendorLedgerEntry."Vendor No." := Vendor."No.";

        asserterror PmtExportMgtVendLedgEntry.OnBeforeInsertPmtExportDataJnlFromVendorLedgerEntry(
            TempPaymentExportData, VendorLedgerEntry, GeneralLedgerSetup);

        Assert.ExpectedError('maximum length of 20');
    end;

    [Test]
    procedure JournalRecipientRejectsCodeNormalization()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        SetFeatureEnabled(true);
        CreateVendorPayment(Vendor, GenJournalLine, 'Ab-0012');
        TempPaymentExportData.SetPreserveNonLatinCharacters(true);

        asserterror PmtExportMgtGenJnlLine.OnBeforeInsertPmtExportDataJnlFromGenJnlLine(
            TempPaymentExportData, GenJournalLine, GeneralLedgerSetup);

        Assert.ExpectedError('cannot be exported unchanged');
    end;

    [Test]
    procedure JournalRecipientRejectsLossyASCIIConversion()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        SetFeatureEnabled(true);
        CreateVendorPayment(Vendor, GenJournalLine, 'AB_0012');

        asserterror PmtExportMgtGenJnlLine.OnBeforeInsertPmtExportDataJnlFromGenJnlLine(
            TempPaymentExportData, GenJournalLine, GeneralLedgerSetup);

        Assert.ExpectedError('cannot be exported unchanged');
    end;

    [Test]
    procedure UnicodeRecipientIsPreservedByCapableFormat()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        NonLatinCharacter: Char;
        RegistrationNo: Text[50];
    begin
        SetFeatureEnabled(true);
        NonLatinCharacter := 198;
        RegistrationNo := '0012-' + Format(NonLatinCharacter);
        CreateVendorPayment(Vendor, GenJournalLine, RegistrationNo);
        TempPaymentExportData.SetPreserveNonLatinCharacters(true);

        PmtExportMgtGenJnlLine.OnBeforeInsertPmtExportDataJnlFromGenJnlLine(TempPaymentExportData, GenJournalLine, GeneralLedgerSetup);
        TempPaymentExportData.Insert(true);

        Assert.AreEqual(RegistrationNo, TempPaymentExportData."Recipient Reg. No.", 'A capable format must not transliterate a legal identifier.');
    end;

    [Test]
    procedure DisabledFeatureRetainsLegacyRecipientNarrowing()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        SetFeatureEnabled(false);
        CreateVendorPayment(Vendor, GenJournalLine, PadStr('Ab-/ ', 50, 'x'));

        PmtExportMgtGenJnlLine.OnBeforeInsertPmtExportDataJnlFromGenJnlLine(TempPaymentExportData, GenJournalLine, GeneralLedgerSetup);

        TempPaymentExportData.TestField("Recipient Reg. No.", UpperCase(CopyStr(Vendor."Registration Number", 1, 20)));
    end;

    [Test]
    procedure EmployeeRecipientRetainsBankBranchSemantics()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        SetFeatureEnabled(true);
        TempPaymentExportData."Recipient Reg. No." := '0123';
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Employee;

        PmtExportMgtGenJnlLine.OnBeforeInsertPmtExportDataJnlFromGenJnlLine(TempPaymentExportData, GenJournalLine, GeneralLedgerSetup);

        TempPaymentExportData.TestField("Recipient Reg. No.", '0123');
    end;

    local procedure CreateVendorPayment(var Vendor: Record Vendor; var GenJournalLine: Record "Gen. Journal Line"; RegistrationNo: Text[50])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Registration Number" := RegistrationNo;
        Vendor.Modify();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := Vendor."No.";
    end;

    procedure SetResolvedRegistrationNo(Source: RecordId; RegistrationNo: Text[50])
    begin
        ResolvedSource := Source;
        ResolvedRegistrationNo := RegistrationNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Registration No. Mgt.", 'OnResolveRegistrationNo', '', false, false)]
    local procedure ResolveRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var ResolvedRegistrationNo: Text[50])
    begin
        if SourceRecordId = ResolvedSource then
            ResolvedRegistrationNo := this.ResolvedRegistrationNo;
    end;

    local procedure SetFeatureEnabled(Enabled: Boolean)
    var
        FeatureKey: Record "Feature Key";
        Status: Record "Feature Data Update Status";
        Feature: Codeunit "Registration No. Feature";
    begin
        if not FeatureKey.Get(Feature.GetFeatureKey()) then begin
            FeatureKey.ID := Feature.GetFeatureKey();
            FeatureKey.Insert();
        end;
        if Enabled then
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users"
        else
            FeatureKey.Enabled := FeatureKey.Enabled::None;
        FeatureKey."Data Update Required" := true;
        FeatureKey.Modify();
        if not Status.Get(FeatureKey.ID, CompanyName()) then begin
            Status."Feature Key" := FeatureKey.ID;
            Status."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Status."Company Name"));
            Status.Insert();
        end;
        Status."Feature Status" := Status."Feature Status"::Complete;
        Status."Data Update Required" := true;
        Status.Modify();
    end;
}
