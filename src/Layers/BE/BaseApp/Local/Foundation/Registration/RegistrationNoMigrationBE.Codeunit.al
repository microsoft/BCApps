// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 11312 "Registration No. Migration BE"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Registration No. Feature", 'OnCollectMigrationCandidates', '', false, false)]
    local procedure CollectMigrationCandidates(var TempMigration: Record "Registration No. Migration" temporary)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CompanyInformation: Record "Company Information";
        RegistrationNoFeature: Codeunit "Registration No. Feature";
    begin
        Customer.SetFilter("Enterprise No.", '<>%1', '');
        if Customer.FindSet() then
            repeat
                RegistrationNoFeature.AddMigrationCandidate(TempMigration, Customer, Customer.FieldNo("Enterprise No."), Customer.FieldNo("Registration Number"), Customer.FieldNo("Country/Region Code"));
            until Customer.Next() = 0;
        Vendor.SetFilter("Enterprise No.", '<>%1', '');
        if Vendor.FindSet() then
            repeat
                RegistrationNoFeature.AddMigrationCandidate(TempMigration, Vendor, Vendor.FieldNo("Enterprise No."), Vendor.FieldNo("Registration Number"), Vendor.FieldNo("Country/Region Code"));
            until Vendor.Next() = 0;
        Contact.SetFilter("Enterprise No.", '<>%1', '');
        if Contact.FindSet() then
            repeat
                RegistrationNoFeature.AddMigrationCandidate(TempMigration, Contact, Contact.FieldNo("Enterprise No."), Contact.FieldNo("Registration Number"), Contact.FieldNo("Country/Region Code"));
            until Contact.Next() = 0;
        if CompanyInformation.Get() then
            RegistrationNoFeature.AddMigrationCandidate(TempMigration, CompanyInformation, CompanyInformation.FieldNo("Enterprise No."), CompanyInformation.FieldNo("Registration No."), CompanyInformation.FieldNo("Country/Region Code"));
    end;
}
