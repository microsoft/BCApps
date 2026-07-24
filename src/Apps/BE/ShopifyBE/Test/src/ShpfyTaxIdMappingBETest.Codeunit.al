// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.BE.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 148710 "Shpfy Tax Id Mapping BE Test"
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
    procedure UnitTestGetTaxRegistrationIdForEnterpriseNo()
    var
        Customer: Record Customer;
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        EnterpriseNo: Text[50];
        EnterpriseNoResult: Text[150];
    begin
        // [SCENARIO] GetTaxRegistrationId for the Belgian Enterprise No. implementation of the mapping
        Initialize();

        // [GIVEN] Enterprise No.
        EnterpriseNo := CopyStr(Any.AlphanumericText(50), 1, MaxStrLen(EnterpriseNo));
        // [GIVEN] Customer with the Enterprise No.
        CreateCustomerWithEnterpriseNo(Customer, EnterpriseNo);
        // [GIVEN] TaxRegistrationIdMapping interface is "Enterprise No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"Enterprise No.";

        // [WHEN] GetTaxRegistrationId is called
        EnterpriseNoResult := TaxRegistrationIdMapping.GetTaxRegistrationId(Customer);

        // [THEN] The result is the same as the Enterprise No. field of the Customer record
        LibraryAssert.AreEqual(EnterpriseNo, EnterpriseNoResult, 'Enterprise No.');
    end;

    [Test]
    procedure UnitTestSetMappingFiltersForCustomersWithEnterpriseNo()
    var
        Customer: Record Customer;
        CompanyLocation: Record "Shpfy Company Location";
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        EnterpriseNo: Text[50];
    begin
        // [SCENARIO] SetMappingFiltersForCustomers for the Belgian Enterprise No. implementation of the mapping
        Initialize();

        // [GIVEN] Enterprise No.
        EnterpriseNo := CopyStr(Any.AlphanumericText(50), 1, MaxStrLen(EnterpriseNo));
        // [GIVEN] Customer record with the Enterprise No.
        CreateCustomerWithEnterpriseNo(Customer, EnterpriseNo);
        // [GIVEN] CompanyLocation record with Tax Registration Id
        CreateLocationWithTaxId(CompanyLocation, EnterpriseNo);
        // [GIVEN] TaxRegistrationIdMapping interface is "Enterprise No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"Enterprise No.";

        // [WHEN] SetMappingFiltersForCustomers is called
        TaxRegistrationIdMapping.SetMappingFiltersForCustomers(Customer, CompanyLocation);

        // [THEN] The range of the Customer record is set to the Tax Registration Id of the CompanyLocation record
        LibraryAssert.AreEqual(EnterpriseNo, Customer.GetFilter("Enterprise No."), 'Enterprise No. filter is not set correctly.');
    end;

    [Test]
    procedure UnitTestUpdateTaxRegistrationIdForEnterpriseNo()
    var
        Customer: Record Customer;
        ShpfyTaxIdMappingBETest: Codeunit "Shpfy Tax Id Mapping BE Test";
        TaxRegistrationIdMapping: Interface "Shpfy Tax Registration Id Mapping";
        NewTaxRegistrationId: Text[150];
    begin
        // [SCENARIO] UpdateTaxRegistrationId for the Belgian Enterprise No. implementation of the mapping
        Initialize();

        // [GIVEN] New Tax Registration Id
        NewTaxRegistrationId := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Customer."Enterprise No."));
        // [GIVEN] Customer with empty Enterprise No.
        CreateCustomerWithEnterpriseNo(Customer, '');
        // [GIVEN] TaxRegistrationIdMapping interface is "Enterprise No."
        TaxRegistrationIdMapping := Enum::"Shpfy Comp. Tax Id Mapping"::"Enterprise No.";

        // [WHEN] UpdateTaxRegistrationId is called
        // Bypass the Belgian Enterprise No. validation (country/MOD97 checks) to isolate the mapping logic
        BindSubscription(ShpfyTaxIdMappingBETest);
        TaxRegistrationIdMapping.UpdateTaxRegistrationId(Customer, NewTaxRegistrationId);
        UnbindSubscription(ShpfyTaxIdMappingBETest);

        // [THEN] The Enterprise No. field of the Customer record is updated
        Customer.Get(Customer."No.");
        LibraryAssert.AreEqual(NewTaxRegistrationId, Customer."Enterprise No.", 'Enterprise No. should be updated.');
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();

        if IsInitialized then
            exit;

        IsInitialized := true;

        Commit();
    end;

    local procedure CreateCustomerWithEnterpriseNo(var Customer: Record Customer; EnterpriseNo: Text[50])
    begin
        Customer.Init();
        Customer."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Customer."No."));
        Customer."Enterprise No." := EnterpriseNo;
        Customer.Insert(false);
    end;

    local procedure CreateLocationWithTaxId(var CompanyLocation: Record "Shpfy Company Location"; TaxRegistrationId: Text[50])
    begin
        CompanyLocation.Init();
        CompanyLocation.Id := Any.IntegerInRange(10000, 99999);
        CompanyLocation."Tax Registration Id" := TaxRegistrationId;
        CompanyLocation.Insert(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidateEnterpriseNo', '', false, false)]
    local procedure HandleOnBeforeValidateEnterpriseNo(var Customer: Record Customer; xCustomer: Record Customer; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
