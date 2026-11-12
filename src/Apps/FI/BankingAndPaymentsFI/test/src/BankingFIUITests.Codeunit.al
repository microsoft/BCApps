// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;

codeunit 148237 "Banking FI UI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

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
