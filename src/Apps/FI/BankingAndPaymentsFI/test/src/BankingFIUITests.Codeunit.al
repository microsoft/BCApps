// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.RoleCenters;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Service.History;

codeunit 148237 "Banking FI UI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    [Test]
    procedure RoleCentersShowOnlyReplacementBankingAfterCutover()
    var
        LibraryBanking: Codeunit "Library - Banking FI";
    begin
        LibraryBanking.SetCompletedFeatureFixture();
        VerifyRoleCenterActions(true);
    end;

#if not CLEAN30
    [Test]
    procedure RoleCentersRetainLegacyBankingBeforeCutover()
    var
        LibraryBanking: Codeunit "Library - Banking FI";
    begin
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
        VerifyRoleCenterActions(false);
        UnbindSubscription(LibraryBanking);
    end;
#endif

    [Test]
    procedure PostedServiceInvoiceShowsReplacementReference()
    var
        Header: Record "Service Invoice Header";
        Invoice: TestPage "Posted Service Invoice";
#if not CLEAN30
        LibraryBanking: Codeunit "Library - Banking FI";
#endif
        Assert: Codeunit Assert;
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
        Header."No." := 'FI-REFERENCE-UI';
        Header."Payment Reference No." := '268745';
        Header.Insert();
        Invoice.OpenView();
        Invoice.GoToRecord(Header);
        Assert.IsTrue(Invoice."Payment Reference No.".Visible(), 'The replacement service reference must be visible after cutover.');
        Invoice."Payment Reference No.".AssertEquals(Header."Payment Reference No.");
#if not CLEAN30
#pragma warning disable AL0432
        Assert.IsFalse(Invoice."Reference No.".Visible(), 'The stale legacy reference must be hidden after cutover.');
#pragma warning restore AL0432
#endif
        Invoice.Close();
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;

#if not CLEAN30
    [Test]
    procedure PostedServiceInvoiceRetainsLegacyReferenceWhenDisabled()
    var
        Invoice: TestPage "Posted Service Invoice";
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;
    begin
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
        Invoice.OpenView();
        Assert.IsFalse(Invoice."Payment Reference No.".Visible(), 'The replacement service reference must be hidden while disabled.');
#pragma warning disable AL0432
        Assert.IsTrue(Invoice."Reference No.".Visible(), 'The original service control must remain available before cutover.');
#pragma warning restore AL0432
        Invoice.Close();
        UnbindSubscription(LibraryBanking);
    end;
#endif

    [Test]
    procedure SharedCompanyIdentityEditableWhenBankingEnabled()
#if not CLEAN30
    var
        LibraryBanking: Codeunit "Library - Banking FI";
#endif
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
        VerifySharedCompanyIdentityEditable();
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;

#if not CLEAN30
    [Test]
    procedure SharedCompanyIdentityEditableWhenBankingDisabled()
    var
        LibraryBanking: Codeunit "Library - Banking FI";
    begin
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
        VerifySharedCompanyIdentityEditable();
        UnbindSubscription(LibraryBanking);
    end;
#endif

    [Test]
    procedure PaymentTermsReplacementVisibleWhenEnabled()
    var
        Terms: TestPage "Payment Terms";
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
        Terms.OpenView();
        Assert.IsTrue(Terms."Disreg. Full Payment Discount".Visible(), 'The replacement discount policy must be visible when enabled.');
#if not CLEAN30
#pragma warning disable AL0432
        Assert.IsFalse(Terms."Disreg. Pmt. Disc. at Full Pmt".Visible(), 'The legacy and replacement controls must not be visible together.');
#pragma warning restore AL0432
#endif
        Terms.Close();
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;

#if not CLEAN30
    [Test]
    procedure PaymentTermsReplacementHiddenWhenDisabled()
    var
        Terms: TestPage "Payment Terms";
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;
    begin
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
        Terms.OpenView();
        Assert.IsFalse(Terms."Disreg. Full Payment Discount".Visible(), 'The replacement control must be hidden when disabled.');
#pragma warning disable AL0432
        Assert.IsTrue(Terms."Disreg. Pmt. Disc. at Full Pmt".Visible(), 'The legacy control must remain accessible while disabled.');
#pragma warning restore AL0432
        Terms.Close();
        UnbindSubscription(LibraryBanking);
    end;
#endif

    local procedure VerifyRoleCenterActions(Enabled: Boolean)
    var
        Bookkeeper: TestPage "Bookkeeper Role Center";
        Payables: TestPage "Acc. Payables Coordinator RC";
        FinanceManager: TestPage "Finance Manager Role Center";
        Assert: Codeunit Assert;
    begin
        Bookkeeper.OpenView();
        Assert.AreEqual(Enabled, Bookkeeper."Bank payments to send FI".Visible(), 'The bookkeeper replacement action must follow cutover state.');
#if not CLEAN30
#pragma warning disable AL0432
        Assert.AreEqual(not Enabled, Bookkeeper."Bank payments to send".Visible(), 'Both bookkeeper payment routes must never be shown together.');
#pragma warning restore AL0432
#endif
        Bookkeeper.Close();
        Payables.OpenView();
        Assert.AreEqual(Enabled, Payables."Bank payments to send FI".Visible(), 'The payables replacement action must follow cutover state.');
#if not CLEAN30
#pragma warning disable AL0432
        Assert.AreEqual(not Enabled, Payables."Bank payments to send".Visible(), 'Both payables payment routes must never be shown together.');
#pragma warning restore AL0432
#endif
        Payables.Close();
        FinanceManager.OpenView();
        Assert.AreEqual(Enabled, FinanceManager."Bank Reference Payments FI".Visible(), 'The finance manager payment route must follow cutover state.');
        Assert.AreEqual(Enabled, FinanceManager."Transferfiles FI".Visible(), 'The replacement reference setup must follow cutover state.');
        Assert.AreEqual(Enabled, FinanceManager."Payment Method Codes FI".Visible(), 'The replacement payment-method setup must follow cutover state.');
#if not CLEAN30
#pragma warning disable AL0432
        Assert.AreEqual(not Enabled, FinanceManager."Bank Reference Payments".Visible(), 'The old finance manager payment route must be hidden after cutover.');
        Assert.AreEqual(not Enabled, FinanceManager.Transferfiles.Visible(), 'The old reference setup must be hidden after cutover.');
        Assert.AreEqual(not Enabled, FinanceManager."Payment Method Codes".Visible(), 'The old payment-method setup must be hidden after cutover.');
#pragma warning restore AL0432
#endif
        FinanceManager.Close();
    end;

    local procedure VerifySharedCompanyIdentityEditable()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        Assert: Codeunit Assert;
    begin
        if not CompanyInformation.Get() then
            CompanyInformation.Insert();

        CompanyInformationPage.OpenEdit();
        Assert.IsTrue(CompanyInformationPage."Business Identity Code".Visible(), 'The shared company identifier must remain available independently of banking activation.');
        CompanyInformationPage."Business Identity Code".SetValue('FI-UI-IDENTITY');
        CompanyInformationPage.Close();

        CompanyInformation.Get();
        Assert.AreEqual('FI-UI-IDENTITY', CompanyInformation."Business Identity Code", 'The existing page must continue editing the shared field, not a banking-specific copy.');
    end;
}
