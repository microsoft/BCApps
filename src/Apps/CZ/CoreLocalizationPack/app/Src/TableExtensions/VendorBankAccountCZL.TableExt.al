// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Company;

tableextension 11708 "Vendor Bank Account CZL" extends "Vendor Bank Account"
{
    fields
    {
        field(11790; "Third Party Bank Account CZL"; Boolean)
        {
            Caption = 'Third Party Bank Account';
            DataClassification = CustomerContent;
        }
    }

    procedure VendorVATRegistrationNoCZL(): Text[20]
    var
        Vendor: Record Vendor;
    begin
        if Rec."Vendor No." = '' then
            exit('');

        Vendor.Get(Rec."Vendor No.");
        exit(Vendor."VAT Registration No.");
    end;

    procedure IsPublicBankAccountCZL(): Boolean
    var
        Vendor: Record Vendor;
        UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
    begin
        if Rec."Third Party Bank Account CZL" then
            exit(false);
        if Rec."Vendor No." = '' then
            exit(false);
        if not Vendor.Get(Rec."Vendor No.") then
            exit(false);
        if not Vendor.IsUnreliablePayerCheckPossibleCZL() then
            exit(false);

        exit(UnreliablePayerMgtCZL.IsPublicBankAccount(Vendor."VAT Registration No.", Rec."Bank Account No.", Rec.IBAN));
    end;

    procedure IsForeignBankAccountCZL(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(("Country/Region Code" <> '') and ("Country/Region Code" <> CompanyInformation."Country/Region Code"));
    end;

    procedure IsStandardFormatBankAccountCZL(): Boolean
    begin
        exit(IBAN = '');
    end;
}
