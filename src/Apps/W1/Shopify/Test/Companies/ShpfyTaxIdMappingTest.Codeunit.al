// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 134246 "Shpfy Tax Id Mapping Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure UnitTestGetTaxRegistrationIdForRegistrationNo()
    var
        Customer: Record Customer;
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        RegistrationNo: Text[50];
        RegistrationNoResult: Text[150];
    begin
        // [SCENARIO] GetTaxRegistrationId for Tax Registration No. implementation of mapping
        Initialize();

        // [GIVEN] Registration No.
        RegistrationNo := CopyStr(Any.AlphanumericText(50), 1, MaxStrLen(RegistrationNo));
        // [GIVEN] Customer
        CreateCustomerWithRegistrationNo(Customer, RegistrationNo);
        // [GIVEN] TaxRegistrationIdMapping interface is "Registration No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"Registration No.";

        // [WHEN] GetTaxRegistrationId is called
        RegistrationNoResult := TaxRegistrationIdMapping.GetTaxRegistrationId(Customer);

        // [THEN] The result is the same as the Registration No. field of the Customer record
        LibraryAssert.AreEqual(RegistrationNo, RegistrationNoResult, 'Registration No.');
    end;

    [Test]
    procedure UnitTestGetTaxRegistrationIdForVATRegistrationNo()
    var
        Customer: Record Customer;
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        VATRegistrationNo: Text[20];
        VATRegistrationNoResult: Text[150];
    begin
        // [SCENARIO] GetTaxRegistrationId for VAT Registration No. implementation of mapping
        Initialize();

        // [GIVEN] VAT Registration No.
        VATRegistrationNo := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(VATRegistrationNo));
        // [GIVEN] Customer
        CreateCustomerWithVATRegNo(Customer, VATRegistrationNo);
        // [GIVEN] TaxRegistrationIdMapping interface is "VAT Registration No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"VAT Registration No.";

        // [WHEN] GetTaxRegistrationId is called
        VATRegistrationNoResult := TaxRegistrationIdMapping.GetTaxRegistrationId(Customer);

        // [THEN] The result is the same as the VAT Registration No. field of the Customer record
        LibraryAssert.AreEqual(VATRegistrationNo, VATRegistrationNoResult, 'VAT Registration No.');
    end;

    [Test]
    procedure UnitTestSetMappingFiltersForCustomersWithRegistrationNo()
    var
        Customer: Record Customer;
        CompanyLocation: Record "Shpfy Company Location";
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        RegistrationNo: Text[50];
    begin
        // [SCENARIO] SetMappingFiltersForCustomers for Tax Registration Id implementation of mapping
        Initialize();

        // [GIVEN] Registration No. 
        RegistrationNo := CopyStr(Any.AlphanumericText(50), 1, MaxStrLen(RegistrationNo));
        // [GIVEN] Customer record with Registration No.
        CreateCustomerWithRegistrationNo(Customer, RegistrationNo);
        // [GIVEN] CompanyLocation record with Tax Registration Id
        CreateLocationWithTaxId(CompanyLocation, RegistrationNo);
        // [GIVEN] TaxRegistrationIdMapping interface is "Registration No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"Registration No.";

        // [WHEN] SetMappingFiltersForCustomers is called
        TaxRegistrationIdMapping.SetMappingFiltersForCustomers(Customer, CompanyLocation);

        // [THEN] The range of the Customer record is set to the Tax Registration Id of the CompanyLocation record
        LibraryAssert.AreEqual(RegistrationNo, Customer.GetFilter("Registration Number"), 'Registration No. filter is not set correctly.');
    end;

    [Test]
    procedure UnitTestSetMappingFiltersForCustomersWithVATRegistrationNo()
    var
        Customer: Record Customer;
        CompanyLocation: Record "Shpfy Company Location";
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        VATRegistrationNo: Text[50];
    begin
        // [SCENARIO] SetMappingFiltersForCustomers for VAT Registration No. implementation of mapping
        Initialize();

        // [GIVEN] VAT Registration No.
        VATRegistrationNo := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(VATRegistrationNo));
        // [GIVEN] Customer record with VAT Registration No.
        CreateCustomerWithRegistrationNo(Customer, VATRegistrationNo);
        // [GIVEN] CompanyLocation record with Tax Registration Id
        CreateLocationWithTaxId(CompanyLocation, VATRegistrationNo);
        // [GIVEN] TaxRegistrationIdMapping interface is "VAT Registration No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"VAT Registration No.";

        // [WHEN] SetMappingFiltersForCustomers is called
        TaxRegistrationIdMapping.SetMappingFiltersForCustomers(Customer, CompanyLocation);

        // [THEN] The range of the Customer record is set to the Tax Registration Id of the CompanyLocation record
        LibraryAssert.AreEqual(VATRegistrationNo, Customer.GetFilter("VAT Registration No."), 'VAT Registration No. filter is not set correctly.');
    end;

    [Test]
    procedure UnitTestUpdateTaxRegistrationIdForRegistrationNo()
    var
        Customer: Record Customer;
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        NewTaxRegistrationId: Text[150];
    begin
        // [SCENARIO] UpdateTaxRegistrationId for Registration No. implementation of mapping
        Initialize();

        // [GIVEN] New Tax Registration Id
        NewTaxRegistrationId := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(NewTaxRegistrationId));
        // [GIVEN] Customer with empty Registration Number
        CreateCustomerWithRegistrationNo(Customer, '');
        // [GIVEN] TaxRegistrationIdMapping interface is "Registration No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"Registration No.";

        // [WHEN] UpdateTaxRegistrationId is called
        TaxRegistrationIdMapping.UpdateTaxRegistrationId(Customer, NewTaxRegistrationId);

        // [THEN] The Registration Number field of the Customer record is updated
        Customer.Get(Customer."No.");
        LibraryAssert.AreEqual(NewTaxRegistrationId, Customer."Registration Number", 'Registration Number should be updated.');
    end;

    [Test]
    procedure UnitTestUpdateTaxRegistrationIdForVATRegistrationNo()
    var
        Customer: Record Customer;
        ShpfyTaxIdMappingTest: Codeunit "Shpfy Tax Id Mapping Test";
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        NewTaxRegistrationId: Text[150];
    begin
        // [SCENARIO] UpdateTaxRegistrationId for VAT Registration No. implementation of mapping
        Initialize();

        // [GIVEN] New Tax Registration Id
        NewTaxRegistrationId := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Customer."VAT Registration No."));
        // [GIVEN] Customer with empty VAT Registration No.
        CreateCustomerWithVATRegNo(Customer, '');
        // [GIVEN] TaxRegistrationIdMapping interface is "VAT Registration No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"VAT Registration No.";

        // [WHEN] UpdateTaxRegistrationId is called
        // Bypass localization-specific VAT Registration No. validation (e.g. BE requires Enterprise No. instead)
        BindSubscription(ShpfyTaxIdMappingTest);
        TaxRegistrationIdMapping.UpdateTaxRegistrationId(Customer, NewTaxRegistrationId);
        UnbindSubscription(ShpfyTaxIdMappingTest);

        // [THEN] The VAT Registration No. field of the Customer record is updated
        Customer.Get(Customer."No.");
        LibraryAssert.AreEqual(NewTaxRegistrationId, Customer."VAT Registration No.", 'VAT Registration No. should be updated.');
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();

        if IsInitialized then
            exit;

        IsInitialized := true;

        Commit();
    end;

    local procedure CreateCustomerWithRegistrationNo(var Customer: Record Customer; RegistrationNo: Text[50])
    begin
        Customer.Init();
        Customer."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Customer."No."));
        Customer."Registration Number" := RegistrationNo;
        Customer.Insert(false);
    end;

    local procedure CreateCustomerWithVATRegNo(var Customer: Record Customer; VATRegistrationNo: Text[20])
    begin
        Customer.Init();
        Customer."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Customer."No."));
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer.Insert(false);
    end;

    local procedure CreateLocationWithTaxId(var CompanyLocation: Record "Shpfy Company Location"; RegistrationNo: Text[50])
    begin
        CompanyLocation.Init();
        CompanyLocation.Id := Any.IntegerInRange(10000, 99999);
        CompanyLocation."Tax Registration Id" := RegistrationNo;
        CompanyLocation.Insert(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidateVATRegistrationNo', '', false, false)]
    local procedure HandleOnBeforeValidateVATRegistrationNo(var Customer: Record Customer; xCustomer: Record Customer; FieldNumber: Integer; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
