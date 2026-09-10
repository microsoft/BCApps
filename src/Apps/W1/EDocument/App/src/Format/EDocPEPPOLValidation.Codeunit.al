// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.IO.Peppol;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;

codeunit 6172 "E-Doc. PEPPOL Validation"
{

    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Validates if a reminder meets PEPPOL requirements.
    /// </summary>
    /// <param name="ReminderHeader">Record "Reminder Header" that contains the reminder document to validate.</param>
    /// <remarks>
    /// Checks both header and line information for PEPPOL compliance including:
    /// - Required fields
    /// - Currency codes
    /// - Country codes
    /// - Company/Customer identification
    /// - Banking information
    /// </remarks>
    procedure CheckReminder(ReminderHeader: Record "Reminder Header")
    var
        ReminderLine: Record "Reminder Line";
    begin
        this.CheckReminderHeader(ReminderHeader);
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        if ReminderLine.FindSet() then
            repeat
                this.CheckReminderLine(ReminderLine);
            until ReminderLine.Next() = 0;
    end;

    /// <summary>
    /// Validates if a finance charge memo meets PEPPOL requirements.
    /// </summary>
    /// <param name="FinChargeMemoHeader">Record "Finance Charge Memo Header" that contains the finance charge memo to validate.</param>
    /// <remarks>
    /// Checks both header and line information for PEPPOL compliance including:
    /// - Required fields
    /// - Currency codes
    /// - Country codes
    /// - Company/Customer identification
    /// - Banking information
    /// </remarks>
    procedure CheckFinChargeMemo(FinChargeMemoHeader: Record "Finance Charge Memo Header");
    var
        FinChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        this.CheckFinChargeMemoHeader(FinChargeMemoHeader);
        FinChargeMemoLine.SetRange("Finance Charge Memo No.", FinChargeMemoHeader."No.");
        if FinChargeMemoLine.FindSet() then
            repeat
                this.CheckFinChargeMemoLine(FinChargeMemoLine);
            until FinChargeMemoLine.Next() = 0;
    end;

    local procedure CheckReminderHeader(ReminderHeader: Record "Reminder Header")
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        this.CheckCurrencyCode(ReminderHeader."Currency Code");

        CompanyInfo.TestField(Name);
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Post Code");

        CompanyInfo.TestField("Country/Region Code");
        this.CheckCountryRegionCode(CompanyInfo."Country/Region Code");

        if CompanyInfo.GLN + CompanyInfo."VAT Registration No." = '' then
            Error(this.MissingCompInfGLNOrVATRegNoErr, CompanyInfo.TableCaption());
        ReminderHeader.TestField(Name);
        ReminderHeader.TestField(Address);
        ReminderHeader.TestField(City);
        ReminderHeader.TestField("Post Code");
        ReminderHeader.TestField("Country/Region Code");
        this.CheckCountryRegionCode(ReminderHeader."Country/Region Code");

        if Customer.Get(ReminderHeader."Customer No.")
        then
            if (Customer.GLN + Customer."VAT Registration No.") = '' then
                Error(MissingCustGLNOrVATRegNoErr, Customer."No.");

        ReminderHeader.TestField("Your Reference");
        ReminderHeader.TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
        CompanyInfo.TestField("SWIFT Code");
    end;

    local procedure CheckReminderLine(ReminderLine: Record "Reminder Line")
    begin
        if (ReminderLine.Type <> ReminderLine.Type::" ") and (ReminderLine.Description = '') then
            Error(this.MissingDescriptionErr);
    end;

    local procedure CheckFinChargeMemoHeader(FinChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        this.CheckCurrencyCode(FinChargeMemoHeader."Currency Code");

        CompanyInfo.TestField(Name);
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Post Code");

        CompanyInfo.TestField("Country/Region Code");
        this.CheckCountryRegionCode(CompanyInfo."Country/Region Code");

        if CompanyInfo.GLN + CompanyInfo."VAT Registration No." = '' then
            Error(this.MissingCompInfGLNOrVATRegNoErr, CompanyInfo.TableCaption());
        FinChargeMemoHeader.TestField(Name);
        FinChargeMemoHeader.TestField(Address);
        FinChargeMemoHeader.TestField(City);
        FinChargeMemoHeader.TestField("Post Code");
        FinChargeMemoHeader.TestField("Country/Region Code");
        this.CheckCountryRegionCode(FinChargeMemoHeader."Country/Region Code");

        if Customer.Get(FinChargeMemoHeader."Customer No.")
        then
            if (Customer.GLN + Customer."VAT Registration No.") = '' then
                Error(this.MissingCustGLNOrVATRegNoErr, Customer."No.");

        FinChargeMemoHeader.TestField("Your Reference");
        FinChargeMemoHeader.TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
        CompanyInfo.TestField("SWIFT Code");
    end;

    local procedure CheckFinChargeMemoLine(FinChargeMemoLine: Record "Finance Charge Memo Line")
    begin
        if (FinChargeMemoLine.Type <> FinChargeMemoLine.Type::" ") and (FinChargeMemoLine.Description = '') then
            Error(this.MissingDescriptionErr);
    end;

    /// <summary>
    /// Validates if a remittance advice built from an unposted vendor payment journal line meets PEPPOL requirements.
    /// </summary>
    /// <param name="GenJournalLine">Record "Gen. Journal Line" that anchors the remittance advice (the payment journal line).</param>
    /// <remarks>
    /// Checks company and vendor identification (Name/Country and VAT Registration No. or GLN endpoint).
    /// Structural checks (at least one applied document) are performed upstream by
    /// Codeunit "E-Doc. Remittance Advice Mgt." (CheckJournalPayment).
    /// </remarks>
    procedure CheckRemittanceAdvice(GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
    begin
        this.CheckCompanyInfoForRemittanceAdvice();
        Vendor.Get(GenJournalLine."Account No.");
        this.CheckVendorForRemittanceAdvice(Vendor);
    end;

    /// <summary>
    /// Validates if a remittance advice built from a posted payment Vendor Ledger Entry meets PEPPOL requirements.
    /// </summary>
    /// <param name="VendorLedgerEntry">Record "Vendor Ledger Entry" that anchors the remittance advice (the posted payment entry).</param>
    /// <remarks>
    /// Checks company and vendor identification (Name/Country and VAT Registration No. or GLN endpoint).
    /// Structural checks (at least one applied document) are performed upstream by
    /// Codeunit "E-Doc. Remittance Advice Mgt." (CheckPostedPayment).
    /// </remarks>
    procedure CheckRemittanceAdvice(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
    begin
        this.CheckCompanyInfoForRemittanceAdvice();
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        this.CheckVendorForRemittanceAdvice(Vendor);
    end;

    local procedure CheckCompanyInfoForRemittanceAdvice()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        CompanyInfo.TestField(Name);
        CompanyInfo.TestField("Country/Region Code");
        this.CheckCountryRegionCode(CompanyInfo."Country/Region Code");

        if CompanyInfo.GLN + CompanyInfo."VAT Registration No." = '' then
            Error(this.MissingCompInfGLNOrVATRegNoErr, CompanyInfo.TableCaption());
    end;

    local procedure CheckVendorForRemittanceAdvice(Vendor: Record Vendor)
    begin
        Vendor.TestField(Name);
        Vendor.TestField("Country/Region Code");
        this.CheckCountryRegionCode(Vendor."Country/Region Code");

        if Vendor.GLN + Vendor."VAT Registration No." = '' then
            Error(this.MissingVendGLNOrVATRegNoErr, Vendor."No.");
    end;

    local procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        MaxCurrencyCodeLength: Integer;
    begin
        MaxCurrencyCodeLength := 3;

        if CurrencyCode = '' then begin
            GLSetup.Get();
            GLSetup.TestField("LCY Code");
            CurrencyCode := GLSetup."LCY Code";
        end;

        if not Currency.Get(CurrencyCode) then begin
            if StrLen(CurrencyCode) <> MaxCurrencyCodeLength then
                GLSetup.FieldError("LCY Code", StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
            exit;
        end;

        if StrLen(Currency.Code) <> MaxCurrencyCodeLength then
            Currency.FieldError(Code, StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
    end;

    local procedure CheckCountryRegionCode(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
        CompanyInfo: Record "Company Information";
        MaxCountryCodeLength: Integer;
    begin
        MaxCountryCodeLength := 2;

        if CountryRegionCode = '' then begin
            CompanyInfo.Get();
            CompanyInfo.TestField("Country/Region Code");
            CountryRegionCode := CompanyInfo."Country/Region Code";
        end;

        CountryRegion.Get(CountryRegionCode);
        CountryRegion.TestField("ISO Code");
        if StrLen(CountryRegion."ISO Code") <> MaxCountryCodeLength then
            CountryRegion.FieldError("ISO Code", StrSubstNo(WrongLengthErr, MaxCountryCodeLength));
    end;

    var
        WrongLengthErr: Label 'should be %1 characters long', Comment = '%1 - number of characters';
        MissingDescriptionErr: Label 'Description field is empty. This field must be filled if you want to send the posted document as an electronic document.';
        MissingCustGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. for Customer %1.', Comment = '%1 - Customer No.';
        MissingCompInfGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. in %1.', Comment = '%1 - Company Information';
        MissingVendGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. for Vendor %1.', Comment = '%1 - Vendor No.';
}
