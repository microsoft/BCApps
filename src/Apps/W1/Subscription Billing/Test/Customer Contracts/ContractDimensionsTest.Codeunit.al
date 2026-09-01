namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 139693 "Contract Dimensions Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    Access = Internal;

    var
        CustomerContract: Record "Customer Subscription Contract";
        ServiceContractSetup: Record "Subscription Contract Setup";
        ContractTestLibrary: Codeunit "Contract Test Library";
        DimensionManagement: Codeunit DimensionManagement;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    #region Tests

    [Test]
    procedure CheckCustomerContractDimensionValueCreatedAndAssigned()
    var
        DimensionValue: Record "Dimension Value";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
    begin
        Initialize();

        // [WHEN] Auto Insert Customer Subscription Contract Dimension Value is enabled
        ContractTestLibrary.SetAutomaticDimensions(true);

        // [WHEN] Customer Subscription Contract dimension value is created
        ContractTestLibrary.InsertCustomerContractDimensionCode();

        ContractTestLibrary.CreateCustomerContract(CustomerContract, '');

        ServiceContractSetup.Get();
        ServiceContractSetup.TestField("Dimension Code Cust. Contr.");

        // check Dimension Value created
        DimensionValue.Get(ServiceContractSetup."Dimension Code Cust. Contr.", CustomerContract."No.");

        // check Dimension Value assigned
        CustomerContract.TestField("Dimension Set ID");
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, CustomerContract."Dimension Set ID");
        TempDimensionSetEntry.Get(CustomerContract."Dimension Set ID", ServiceContractSetup."Dimension Code Cust. Contr.");
        TempDimensionSetEntry.TestField("Dimension Value Code", CustomerContract."No.");
    end;

    [Test]
    procedure ValidateShortcutDim1CodeOnSubscriptionLineUpdatesDimSetID()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        ServiceObject: Record "Subscription Header";
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Validating Shortcut Dimension 1 Code on a Subscription Line updates its Dimension Set ID
        Initialize();

        // [GIVEN] A Subscription Line exists
        ContractTestLibrary.CreateCustomerInLCY(Customer);
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, Customer."No.");
        FindFirstCustomerSubscriptionLine(SubscriptionLine, ServiceObject."No.");

        // [GIVEN] A dimension value for Global Dimension 1 exists
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");

        // [WHEN] Shortcut Dimension 1 Code is validated on the Subscription Line
        SubscriptionLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [THEN] The Dimension Set ID is updated and contains the correct dimension value
        Assert.AreNotEqual(0, SubscriptionLine."Dimension Set ID", 'Dimension Set ID should be non-zero after setting Shortcut Dimension 1 Code');
        VerifyDimensionInDimensionSet(SubscriptionLine."Dimension Set ID", GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code);
    end;

    [Test]
    procedure ValidateShortcutDim2CodeOnSubscriptionLineUpdatesDimSetID()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        ServiceObject: Record "Subscription Header";
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Validating Shortcut Dimension 2 Code on a Subscription Line updates its Dimension Set ID
        Initialize();

        // [GIVEN] A Subscription Line exists
        ContractTestLibrary.CreateCustomerInLCY(Customer);
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, Customer."No.");
        FindFirstCustomerSubscriptionLine(SubscriptionLine, ServiceObject."No.");

        // [GIVEN] A dimension value for Global Dimension 2 exists
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");

        // [WHEN] Shortcut Dimension 2 Code is validated on the Subscription Line
        SubscriptionLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);

        // [THEN] The Dimension Set ID is updated and contains the correct dimension value
        Assert.AreNotEqual(0, SubscriptionLine."Dimension Set ID", 'Dimension Set ID should be non-zero after setting Shortcut Dimension 2 Code');
        VerifyDimensionInDimensionSet(SubscriptionLine."Dimension Set ID", GeneralLedgerSetup."Global Dimension 2 Code", DimensionValue.Code);
    end;

    [Test]
    procedure ValidateShortcutDim1CodeOnCustSubLinePropagatesChangesToVendorLine()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        ServiceObject: Record "Subscription Header";
        CustomerSubscriptionLine: Record "Subscription Line";
        VendorSubscriptionLine: Record "Subscription Line";
        VendorContract: Record "Vendor Subscription Contract";
        Item: Record Item;
    begin
        // [SCENARIO] Changing Shortcut Dimension 1 Code on a Customer Subscription Line propagates to related Vendor Subscription Line
        Initialize();

        // [GIVEN] A Service Object with both Customer and Vendor Subscription Lines from the same package
        ContractTestLibrary.CreateServiceObjectForItemWithServiceCommitments(ServiceObject, Enum::"Invoicing Via"::Contract, false, Item, 1, 1);
        ContractTestLibrary.CreateCustomerInLCY(Customer);
        ServiceObject.SetHideValidationDialog(true);
        ServiceObject.Validate("End-User Customer No.", Customer."No.");
        ServiceObject.Modify(false);

        // [GIVEN] Customer Contract with the Customer Subscription Line
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, Customer."No.");
        FindFirstCustomerSubscriptionLine(CustomerSubscriptionLine, ServiceObject."No.");

        // [GIVEN] Vendor Contract with the Vendor Subscription Line
        ContractTestLibrary.CreateVendorInLCY(Vendor);
        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, Vendor."No.");
        FindFirstVendorSubscriptionLine(VendorSubscriptionLine, ServiceObject."No.");

        // [GIVEN] A dimension value for Global Dimension 1 exists
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");

        // [WHEN] Shortcut Dimension 1 Code is changed on the Customer Subscription Line
        CustomerSubscriptionLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [THEN] The Vendor Subscription Line's Dimension Set ID is updated with the same dimension
        VendorSubscriptionLine.Get(VendorSubscriptionLine."Entry No.");
        VerifyDimensionInDimensionSet(VendorSubscriptionLine."Dimension Set ID", GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code);
    end;

    #endregion Tests

    #region Procedures

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Contract Dimensions Test");
        ClearAll();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Contract Dimensions Test");
        ContractTestLibrary.InitContractsApp();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Contract Dimensions Test");
    end;

    local procedure FindFirstCustomerSubscriptionLine(var SubscriptionLine: Record "Subscription Line"; SubscriptionHeaderNo: Code[20])
    begin
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeaderNo);
        SubscriptionLine.SetRange(Partner, Enum::"Service Partner"::Customer);
        SubscriptionLine.FindFirst();
    end;

    local procedure FindFirstVendorSubscriptionLine(var SubscriptionLine: Record "Subscription Line"; SubscriptionHeaderNo: Code[20])
    begin
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeaderNo);
        SubscriptionLine.SetRange(Partner, Enum::"Service Partner"::Vendor);
        SubscriptionLine.FindFirst();
    end;

    local procedure VerifyDimensionInDimensionSet(DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
    begin
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, DimensionSetID);
        TempDimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        Assert.RecordIsNotEmpty(TempDimensionSetEntry);
        TempDimensionSetEntry.FindFirst();
        TempDimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    #endregion Procedures
}
