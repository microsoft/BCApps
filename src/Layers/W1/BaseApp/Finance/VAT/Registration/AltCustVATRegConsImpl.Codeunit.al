// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 204 "Alt. Cust. VAT Reg. Cons.Impl." implements "Alt. Cust. VAT Reg. Consist."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CountryCodeMatchesCustomerErr: Label 'You cannot have the same VAT Country/Region Code as the Customer Country/Region Code';
        InconsistentSetupErr: Label 'Not possible to have Alternative Customer VAT Registration with the same Customer No. and VAT Country/Region Code';
        ChangeCountryOfCustQst: Label 'There is an alternative customer VAT registration with the same country/region code that is not allowed. Do you want to change the country/region code in the customer card and remove the alternative customer VAT registration?';

    procedure CheckAltCustVATRegConsistent(AltCustVATReg: Record "Alt. Cust. VAT Reg.")
    var
        ExistingAltCustVATReg: Record "Alt. Cust. VAT Reg.";
        Customer: Record Customer;
    begin
        AltCustVATReg.TestField("Customer No.");
        AltCustVATReg.TestField("VAT Country/Region Code");
        Customer.SetLoadFields("Country/Region Code");
        Customer.Get(AltCustVATReg."Customer No.");
        if AltCustVATReg."VAT Country/Region Code" = Customer."Country/Region Code" then
            error(CountryCodeMatchesCustomerErr);
        ExistingAltCustVATReg.SetFilter(Id, '<>%1', AltCustVATReg.Id);
        ExistingAltCustVATReg.SetRange("Customer No.", AltCustVATReg."Customer No.");
        ExistingAltCustVATReg.SetRange("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        if not ExistingAltCustVATReg.IsEmpty() then
            error(InconsistentSetupErr);
    end;

    procedure CheckCustomerConsistency(Customer: Record Customer)
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        AltCustVATReg.SetRange("Customer No.", Customer."No.");
        AltCustVATReg.SetRange("VAT Country/Region Code", Customer."Country/Region Code");
        if AltCustVATReg.IsEmpty() then
            exit;
        if not ConfirmManagement.GetResponse(ChangeCountryOfCustQst, false) then
            error('');
        AltCustVATReg.DeleteAll(true);
    end;
}