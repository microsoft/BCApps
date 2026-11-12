// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 148234 "Banking FI SEPA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        CapturedXml: Text;
        Assert: Codeunit Assert;
        LibraryBanking: Codeunit "Library - Banking FI";
        Subscribers: Codeunit "Banking FI SEPA Tests";

    [Test]
    procedure InitializedBankFormatsIncludeReplacement02Exporter()
    var
        ExportSetup: Record "Bank Export/Import Setup";
        CurrentExportSetup: Record "Bank Export/Import Setup";
        BeforeCurrentExportSetup: Record "Bank Export/Import Setup";
        Events: Codeunit "Banking Payments Events FI";
    begin
        EnableFeature();
        if ExportSetup.Get('SEPACT V02') then
            ExportSetup.Delete();
        if not CurrentExportSetup.Get('SEPACTPAIN00100109') then begin
            CurrentExportSetup.Init();
            CurrentExportSetup.Code := 'SEPACTPAIN00100109';
            CurrentExportSetup.Direction := CurrentExportSetup.Direction::Export;
            CurrentExportSetup."Processing Codeunit ID" := Codeunit::"SEPA CT-Export File";
            CurrentExportSetup."Processing XMLport ID" := XmlPort::"SEPA CT pain.001.001.09";
            CurrentExportSetup."Check Export Codeunit" := Codeunit::"SEPA CT-Check Line";
            CurrentExportSetup.Insert();
        end;
        BeforeCurrentExportSetup := CurrentExportSetup;

        Events.InitializeBankExportImportSetup();

        ExportSetup.Get('SEPACT V02');
        Assert.AreEqual(Codeunit::"Export SEPA Payment File FI", ExportSetup."Processing Codeunit ID", 'The existing .02 format must use the relocated .02 exporter, not W1 .03 or .09.');
        Assert.AreEqual(ExportSetup.Direction::Export, ExportSetup.Direction, 'The initialized format must remain an export.');
        Assert.AreEqual(0, ExportSetup."Processing XMLport ID", 'The .02 exporter must retain its report-based processing.');
        Assert.AreEqual(0, ExportSetup."Check Export Codeunit", 'Initialization must retain the existing .02 validation setup.');
        Assert.IsFalse(ExportSetup."Preserve Non-Latin Characters", 'Initialization must retain the existing .02 character setting.');
        CurrentExportSetup.Get(BeforeCurrentExportSetup.Code);
        Assert.AreEqual(BeforeCurrentExportSetup."Processing Codeunit ID", CurrentExportSetup."Processing Codeunit ID", 'The independent .09 format must not be redirected to the FI exporter.');
        Assert.AreEqual(BeforeCurrentExportSetup."Processing XMLport ID", CurrentExportSetup."Processing XMLport ID", 'The independent .09 XMLport must remain unchanged.');
        Assert.AreEqual(BeforeCurrentExportSetup."Check Export Codeunit", CurrentExportSetup."Check Export Codeunit", 'The independent .09 check codeunit must remain unchanged.');
        Assert.AreEqual(BeforeCurrentExportSetup.SystemModifiedAt, CurrentExportSetup.SystemModifiedAt, 'Initializing .02 must not write the existing .09 setup.');
        DisableFeature();
    end;

    [Test]
    procedure RepeatedBankFormatInitializationPreservesUserConfiguration()
    var
        ExportSetup: Record "Bank Export/Import Setup";
        Events: Codeunit "Banking Payments Events FI";
        OriginalSystemId: Guid;
        OriginalModifiedAt: DateTime;
    begin
        EnableFeature();
        if not ExportSetup.Get('SEPACT V02') then begin
            ExportSetup.Code := 'SEPACT V02';
            ExportSetup.Insert();
        end;
        ExportSetup.Name := 'Configured export';
        ExportSetup."Processing Codeunit ID" := Codeunit::"SEPA CT pain.001.001.09 FI";
        ExportSetup."Preserve Non-Latin Characters" := true;
        ExportSetup.Modify();
        OriginalSystemId := ExportSetup.SystemId;
        OriginalModifiedAt := ExportSetup.SystemModifiedAt;

        Events.InitializeBankExportImportSetup();
        Events.InitializeBankExportImportSetup();

        ExportSetup.Get('SEPACT V02');
        Assert.AreEqual('Configured export', ExportSetup.Name, 'Initialization must not reset a configured format.');
        Assert.AreEqual(Codeunit::"SEPA CT pain.001.001.09 FI", ExportSetup."Processing Codeunit ID", 'Initialization must not replace the user-selected exporter.');
        Assert.IsTrue(ExportSetup."Preserve Non-Latin Characters", 'Initialization must retain user-selected character handling.');
        Assert.AreEqual(OriginalSystemId, ExportSetup.SystemId, 'Initialization must not recreate configured setup.');
        Assert.AreEqual(OriginalModifiedAt, ExportSetup.SystemModifiedAt, 'Repeated initialization must not stamp configured setup.');
        DisableFeature();
    end;

#if not CLEAN30
    [Test]
    procedure DisabledFeatureDoesNotInitializeReplacementBankFormat()
    var
        ExportSetup: Record "Bank Export/Import Setup";
        Events: Codeunit "Banking Payments Events FI";
    begin
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
        if ExportSetup.Get('SEPACT V02') then
            ExportSetup.Delete();

        Events.InitializeBankExportImportSetup();

        Assert.IsFalse(ExportSetup.Get('SEPACT V02'), 'The inactive extension must leave bank-format initialization to BaseApp.');
        UnbindSubscription(LibraryBanking);
    end;
#endif

    [Test]
    procedure Legacy02FormatRetainsNamespaceAndUtf8Text()
    var
        Xml: Text;
    begin
        EnableFeature();
        CreateExportFixture();
        BindSubscription(Subscribers);
        Report.Run(Report::"Export SEPA Payment File FI", false, false);
        Xml := Subscribers.GetCapturedXml();
        Assert.IsTrue(Xml.Contains('urn:iso:std:iso:20022:tech:xsd:pain.001.001.02'), 'The legacy .02 format must not become W1 .03.');
        VerifyPayload(Xml);
        UnbindSubscription(Subscribers);
        DisableFeature();
    end;

    [Test]
    procedure Current09FormatRetainsNamespaceAndUtf8Text()
    var
        Xml: Text;
    begin
        EnableFeature();
        CreateExportFixture();
        BindSubscription(Subscribers);
        Report.Run(Report::"SEPA CT pain.001.001.09 FI", false, false);
        Xml := Subscribers.GetCapturedXml();
        Assert.IsTrue(Xml.Contains('urn:iso:std:iso:20022:tech:xsd:pain.001.001.09'), 'The current Finnish format must remain .09.');
        VerifyPayload(Xml);
        UnbindSubscription(Subscribers);
        DisableFeature();
    end;

    [Test]
    procedure StandardSEPASourceUsesReplacementPayments()
    var
        TempJournal: Record "Gen. Journal Line" temporary;
    begin
        EnableFeature();
        CreateExportFixture();
        TempJournal.SetRange("Journal Template Name", 'FI-NONE');
        Codeunit.Run(Codeunit::"SEPA CT-Prepare Source", TempJournal);
        TempJournal.Reset();
        TempJournal.Get('', '', 1);
        Assert.AreEqual('FI-SEPA-TEST', TempJournal."Account No.", 'The replacement exported payment must supply the vendor.');
        Assert.AreEqual('268745', TempJournal."Payment Message", 'The replacement remittance message must reach the temporary journal.');
        Assert.AreEqual(WorkDate(), TempJournal."Planned Payment Date", 'The payment date must survive temporary-source preparation.');
        DisableFeature();
    end;

    procedure GetCapturedXml(): Text
    begin
        exit(CapturedXml);
    end;

    local procedure VerifyPayload(Xml: Text)
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
        Assert.IsTrue(Xml.Contains('Mäki &amp; Å'), 'UTF-8 characters and XML escaping must be preserved.');
        Assert.IsTrue(Xml.Contains('123.45'), 'The amount must be exported without locale-dependent formatting.');
        Assert.IsTrue(Xml.Contains('268745'), 'The remittance reference must be present.');
        Exported.Get(1);
        Assert.IsTrue(Exported.Transferred, 'Successfully exported payment rows must be marked transferred.');
    end;

    local procedure CreateExportFixture()
    var
        Country: Record "Country/Region";
        Company: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
        Bank: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Setup: Record "Reference File Setup FI";
        Exported: Record "Ref. Payment - Exported FI";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        if not Country.Get('FI') then begin
            Country.Code := 'FI';
            Country.Insert();
        end;
        Country."SEPA Payments Allowed" := true;
        Country.Modify();
        if not Company.Get() then
            Company.Insert();
        Company.Name := 'Mäki & Å';
        Company."Country/Region Code" := 'FI';
        Company.Modify();
        if not GeneralLedgerSetup.Get() then
            GeneralLedgerSetup.Insert();
        GeneralLedgerSetup."LCY Code" := 'EUR';
        GeneralLedgerSetup.Modify();
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '000001', '999999');
        if not PurchaseSetup.Get() then
            PurchaseSetup.Insert();
        PurchaseSetup."Payment Batch Nos." := NoSeries.Code;
        PurchaseSetup.Modify();
        Bank."No." := 'FI-SEPA-TEST';
        Bank."Country/Region Code" := 'FI';
        Bank.IBAN := 'FI2112345600000785';
        Bank."SWIFT Code" := 'NDEAFIHH';
        Bank.Insert();
        Vendor."No." := 'FI-SEPA-TEST';
        Vendor.Name := 'Mäki & Å';
        Vendor."Country/Region Code" := 'FI';
        Vendor.Insert();
        VendorBank."Vendor No." := Vendor."No.";
        VendorBank.Code := 'TEST';
        VendorBank.Name := Vendor.Name;
        VendorBank."Country/Region Code" := 'FI';
        VendorBank.IBAN := Bank.IBAN;
        VendorBank."SWIFT Code" := Bank."SWIFT Code";
        VendorBank."SEPA Payment Enabled" := true;
        VendorBank.Insert();
        Setup."No." := Bank."No.";
        Setup."File Name" := 'payments.xml';
        Setup."Bank Party ID" := '12345678';
        Setup.Insert();
        Exported.DeleteAll();
        Exported."No." := 1;
        Exported."Vendor No." := Vendor."No.";
        Exported."Vendor Account" := VendorBank.Code;
        Exported."Description 2" := Vendor.Name;
        Exported."Payment Account" := Bank."No.";
        Exported."Payment Date" := WorkDate();
        Exported."Document No." := 'INV26874';
        Exported.Amount := 123.45;
        Exported."Message Type" := Exported."Message Type"::"Reference No.";
        Exported."Invoice Message" := '268745';
        Exported."SEPA Payment" := true;
        Exported.Insert();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Export SEPA Payment File FI", 'OnBeforeDownloadFromBlob', '', false, false)]
    local procedure Capture02(var TempBlob: Codeunit "Temp Blob"; var CancelDownload: Boolean)
    begin
        Capture(TempBlob, CancelDownload);
    end;

    [EventSubscriber(ObjectType::Report, Report::"SEPA CT pain.001.001.09 FI", 'OnBeforeDownloadFromBlob', '', false, false)]
    local procedure Capture09(var TempBlob: Codeunit "Temp Blob"; var CancelDownload: Boolean)
    begin
        Capture(TempBlob, CancelDownload);
    end;

    local procedure Capture(var TempBlob: Codeunit "Temp Blob"; var CancelDownload: Boolean)
    var
        Input: InStream;
        Line: Text;
    begin
        TempBlob.CreateInStream(Input, TextEncoding::UTF8);
        Clear(CapturedXml);
        while not Input.EOS() do begin
            Input.ReadText(Line);
            CapturedXml += Line;
        end;
        CancelDownload := true;
    end;

    local procedure EnableFeature()
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
    end;

    local procedure DisableFeature()
    begin
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;
}
