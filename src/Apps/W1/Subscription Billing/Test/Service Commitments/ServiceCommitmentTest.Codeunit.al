namespace Microsoft.SubscriptionBilling;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;

codeunit 148156 "Service Commitment Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    Access = Internal;

    var
        CustomerContract: Record "Customer Subscription Contract";
        CustomerContractLine: Record "Cust. Sub. Contract Line";
        Item: Record Item;
        ServiceCommPackageLine: Record "Subscription Package Line";
        ServiceCommitment: Record "Subscription Line";
        ServiceCommitmentPackage: Record "Subscription Package";
        ServiceCommitmentTemplate: Record "Sub. Package Line Template";
        ServiceObject: Record "Subscription Header";
        VendorContract: Record "Vendor Subscription Contract";
        Assert: Codeunit Assert;
        ContractTestLibrary: Codeunit "Contract Test Library";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PackageLineMissingInvoicingItemNoErr: Label 'The %1 %2 can not be used with Item %3, because at least one of the Service Commitment Package lines is missing an %4.', Locked = true;
        NaturalNumberRatioErr: Label 'The ratio of ''%1'' and ''%2'' or vice versa must give a natural number.', Comment = '%1=Field Caption, %2=Field Caption', Locked = true;
        DiscountCanBeInvoicedViaContractErr: Label 'Recurring discounts can only be granted for Invoicing via Contract.', Locked = true;
        DiscountCannotBeAssignedErr: Label 'Subscription Package Lines, which are discounts, can only be assigned to Subscription Items.', Locked = true;
        RecurringDiscountCannotBeGrantedErr: Label 'Recurring discounts cannot be granted in conjunction with Usage Based Billing', Locked = true;
        BillingLineForServiceCommitmentExistErr: Label 'The contract line is in the current billing. Delete the billing line to be able to adjust the Subscription Line start date.', Locked = true;
        BillingLineArchiveForServiceCommitmentExistErr: Label 'The contract line has already been billed. The Subscription Line start date can no longer be changed.', Locked = true;
        TermUntilNotCalculatedErr: Label '"Term Until" Date is not calculated correctly.', Locked = true;
        CancellationPossibleUntilNotCalculatedErr: Label '"Cancellation Possible Until" Date is not calculated correctly.', Locked = true;

    #region Tests

    [Test]
    procedure CheckCalculationBaseDateFormulaEntry()
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServiceCommitmentPackage, ServiceCommPackageLine);
        Commit(); // retain data after asserterror

        ValidateDateFormulaCombinations('<5D>', '<20D>');
        ValidateDateFormulaCombinations('<1W>', '<4W>');
        ValidateDateFormulaCombinations('<1M>', '<6Q>');
        ValidateDateFormulaCombinations('<1Q>', '<3Q>');
        ValidateDateFormulaCombinations('<1Y>', '<2Y>');
        ValidateDateFormulaCombinations('<3M>', '<1Y>');
        ValidateDateFormulaCombinations('<6M>', '<1Q>');

        asserterror ValidateDateFormulaCombinations('<1D>', '<1M>');
        asserterror ValidateDateFormulaCombinations('<1W>', '<1M>');
        asserterror ValidateDateFormulaCombinations('<2M>', '<7M>');
        asserterror ValidateDateFormulaCombinations('<2Q>', '<5Q>');
        asserterror ValidateDateFormulaCombinations('<2Y>', '<3Y>');
        asserterror ValidateDateFormulaCombinations('<CM>', '<1Y>');
        asserterror ValidateDateFormulaCombinations('<1M + 1Q>', '<1Y>');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure CheckCalculationBaseTypeChangeForVendorOnServiceCommitmentPackageLine()
    begin
        Initialize();
        ServiceCommitmentTemplate."Calculation Base Type" := Enum::"Calculation Base Type"::"Document Price And Discount";
        ServiceCommitmentTemplate.Modify(false);

        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);
        ServiceCommPackageLine.Validate(Partner, ServiceCommPackageLine.Partner::Vendor);
        ServiceCommPackageLine.TestField("Calculation Base Type", Enum::"Calculation Base Type"::"Document Price");

        ContractTestLibrary.CreateServiceCommitmentPackageLine(ServiceCommitmentPackage.Code, '', ServiceCommPackageLine);
        ServiceCommPackageLine.Validate(Partner, ServiceCommPackageLine.Partner::Vendor);
        ServiceCommPackageLine.Validate(Template, ServiceCommitmentTemplate.Code);
        ServiceCommPackageLine.TestField("Calculation Base Type", Enum::"Calculation Base Type"::"Document Price");

        ContractTestLibrary.CreateServiceCommitmentPackageLine(ServiceCommitmentPackage.Code, '', ServiceCommPackageLine);
        ServiceCommPackageLine.Validate(Partner, ServiceCommPackageLine.Partner::Vendor);
        asserterror ServiceCommPackageLine.Validate("Calculation Base Type", Enum::"Calculation Base Type"::"Document Price And Discount");
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure DeleteServiceCommitmentAfterDeleteCustomerContractLine()
    begin
        Initialize();
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true);
        CustomerContractLine.SetRange("Subscription Contract No.", CustomerContract."No.");
        CustomerContractLine.DeleteAll(true);
        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        ServiceCommitment.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure DeleteServiceCommitmentAfterDeleteVendorContractLine()
    var
        VendorContractLine: Record "Vend. Sub. Contract Line";
    begin
        Initialize();
        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, '', true);
        VendorContractLine.SetRange("Subscription Contract No.", VendorContract."No.");
        VendorContractLine.DeleteAll(true);
        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        ServiceCommitment.DeleteAll(true);
    end;

    [Test]
    procedure CheckItemNoEntryOnPackageLine()
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);
        ServiceCommPackageLine.Validate("Invoicing via", Enum::"Invoicing Via"::Contract);
        ServiceCommPackageLine.Modify(false);
        ServiceCommPackageLine.Validate("Invoicing Item No.", Item."No.");
        ServiceCommPackageLine.TestField("Invoicing Item No.", Item."No.");
        ServiceCommPackageLine.Validate("Invoicing via", Enum::"Invoicing Via"::Sales);
        ServiceCommPackageLine.TestField("Invoicing Item No.", '');
        asserterror ServiceCommPackageLine.Validate("Invoicing Item No.", Item."No.");
    end;

    [Test]
    procedure CheckItemNoEntryOnServiceCommitmentTemplate()
    begin
        Initialize();
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");
        ServiceCommitmentTemplate.Validate("Invoicing via", Enum::"Invoicing Via"::Contract);
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommitmentTemplate.Validate("Invoicing Item No.", Item."No.");
        ServiceCommitmentTemplate.TestField("Invoicing Item No.", Item."No.");
        ServiceCommitmentTemplate.Validate("Invoicing via", Enum::"Invoicing Via"::Sales);
        ServiceCommitmentTemplate.TestField("Invoicing Item No.", '');
        asserterror ServiceCommitmentTemplate.Validate("Invoicing Item No.", Item."No.");
    end;

    [Test]
    procedure CheckIfDateFormulasAreNegative()
    var
        NegativeDateFormula: DateFormula;
        PositiveDateFormula: DateFormula;
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServiceCommitmentPackage, ServiceCommPackageLine);
        Commit(); // retain data after asserterror

        Evaluate(NegativeDateFormula, '<-1M>');
        asserterror ServiceCommPackageLine.Validate("Billing Base Period", NegativeDateFormula);
        asserterror ServiceCommPackageLine.Validate("Billing Rhythm", NegativeDateFormula);
        asserterror ServiceCommPackageLine.Validate("Initial Term", NegativeDateFormula);
        asserterror ServiceCommPackageLine.Validate("Extension Term", NegativeDateFormula);
        asserterror ServiceCommPackageLine.Validate("Notice Period", NegativeDateFormula);

        Evaluate(PositiveDateFormula, '<1M>');
        ServiceCommPackageLine.Validate("Billing Base Period", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Billing Rhythm", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Sub. Line Start Formula", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Initial Term", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Extension Term", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Notice Period", PositiveDateFormula);
    end;

    [Test]
    procedure CheckIfExtensionTermEnteredBeforeNoticePeriod()
    var
        PositiveDateFormula: DateFormula;
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServiceCommitmentPackage, ServiceCommPackageLine);
        Commit(); // retain data after asserterror

        Evaluate(PositiveDateFormula, '<1M>');
        asserterror ServiceCommPackageLine.Validate("Notice Period", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Extension Term", PositiveDateFormula);
        ServiceCommPackageLine.Validate("Notice Period", PositiveDateFormula);
    end;

    [Test]
    procedure CheckPackageDeletion()
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);
        ServiceCommPackageLine.SetRange("Subscription Package Code", ServiceCommitmentPackage.Code);
        ServiceCommitmentPackage.Delete(true);
        Assert.RecordIsEmpty(ServiceCommPackageLine);
    end;

    [Test]
    procedure CheckServiceCommitmentPackageLineDefaultAndAssignedInvoiceViaValue()
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServiceCommitmentPackage, ServiceCommPackageLine);
        ServiceCommPackageLine.TestField("Invoicing via", Enum::"Invoicing Via"::Contract);
        ServiceCommitmentTemplate.Validate("Invoicing via", Enum::"Invoicing Via"::Sales);
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommPackageLine.Validate(Template, ServiceCommitmentTemplate.Code);
        ServiceCommPackageLine.TestField("Invoicing via", Enum::"Invoicing Via"::Sales);
    end;

    [Test]
    procedure CheckServiceCommitmentTemplateAssignmentOnPackageLine()
    begin
        Initialize();
        ServiceCommitmentTemplate.Description += ' Temp';
        ServiceCommitmentTemplate."Calculation Base Type" := Enum::"Calculation Base Type"::"Document Price";
        ServiceCommitmentTemplate."Calculation Base %" := 10;
        Evaluate(ServiceCommitmentTemplate."Billing Base Period", '<12M>');
        ServiceCommitmentTemplate.Modify(false);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);
        ServiceCommPackageLine.TestField(Description, ServiceCommitmentTemplate.Description);
        ServiceCommPackageLine.TestField("Calculation Base Type", ServiceCommitmentTemplate."Calculation Base Type");
        ServiceCommPackageLine.TestField("Calculation Base %", ServiceCommitmentTemplate."Calculation Base %");
        ServiceCommPackageLine.TestField("Billing Base Period", ServiceCommitmentTemplate."Billing Base Period");
        ServiceCommPackageLine.TestField("Invoicing via", ServiceCommitmentTemplate."Invoicing via");
        ServiceCommPackageLine.TestField("Invoicing Item No.", ServiceCommitmentTemplate."Invoicing Item No.");
        ServiceCommPackageLine.TestField(Discount, ServiceCommitmentTemplate.Discount);
    end;

    [Test]
    procedure CopyServiceCommitmentItemLineFromSalesQuoteToSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FromDocNo: Code[20];
    begin
        // [SCENARIO] When sales order is created from sales quote expect that qty to invoice is set to 0 in case of Subscription Items
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN]  Create Subscription Item
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");

        // [GIVEN] Create sales quote
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Quote, '', Item."No.", LibraryRandom.RandInt(10), '', LibraryRandom.RandDate(12));
        FromDocNo := SalesHeader."No.";

        // [GIVEN] Set sales header for the order
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy lines from sales quote to sales order
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type"::Quote, FromDocNo, false, true);

        // [THEN] Qty to Invoice = 0 in sales order line
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, Enum::"Sales Line Type"::Item);
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Document Type", "Sales Document Type"::Order);
        SalesLine.TestField("Qty. to Invoice", 0);
    end;

    [Test]
    procedure ExpectErrorDuringCommitmentTemplateDeletion()
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);
        ServiceCommitmentTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler,ConfirmHandlerYes')]
    procedure DeleteServiceCommitmentAfterCustomerContractLineSetToClosed()
    var
    begin
        Initialize();
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true);
        UpdateServiceDatesAndCloseContractLines();

        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        ServiceCommitment.DeleteAll(true);
    end;

    [Test]
    procedure ExpectErrorOnChangeItemServiceCommTypeFromSrvCommToSalesWithSrvComm()
    var
        SrvCommItem: Record Item;
        ServCommPackage: Record "Subscription Package";
        ServCommPackageLine: Record "Subscription Package Line";
    begin
        // [SCENARIO] When changing the Service Commitment Option of an Item from "Service Commitment Item" to "Sales with Service Commitment", error is thrown if the item is assigned to a Service Commitment Package with "Invoicing via" = Contract and "Invoicing Item No." is blank

        // [GIVEN] Item with Service Commitment Option = Service Commitment Item
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(SrvCommItem, Enum::"Item Service Commitment Type"::"Service Commitment Item");

        // [GIVEN] Service Commitment Package with a line where "Invoicing Via" = Sales
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServCommPackage, ServCommPackageLine);
        ServCommPackageLine.Validate("Invoicing via", Enum::"Invoicing Via"::Sales);
        ServCommPackageLine.Modify(false);

        // [GIVEN] Assigning an Item to the Service Commitment Package
        ContractTestLibrary.AssignItemToServiceCommitmentPackage(SrvCommItem, ServCommPackage.Code);

        // [GIVEN] Service Commitment Package Line has been updated in the meantime (mistakenly) to "Invoicing Via" = Contract with a blank "Invoicing Item No."
        ServCommPackageLine.Validate("Invoicing via", Enum::"Invoicing Via"::Contract);
        ServCommPackageLine.Modify(false);

        // [WHEN] Changing the Service Commitment Option of the Item to "Sales with Service Commitment"
        asserterror SrvCommItem.Validate("Subscription Option", Enum::"Item Service Commitment Type"::"Sales with Service Commitment");

        // [THEN] Error expected that the item cannot be used with a package while there is a package line with "Invoicing Via" = Contract and "Invoicing Item No." is blank
        Assert.ExpectedError(StrSubstNo(PackageLineMissingInvoicingItemNoErr, ServCommPackage.TableCaption, ServCommPackage.Code, SrvCommItem."No.", ServCommPackageLine.FieldCaption("Invoicing Item No.")));
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenDeleteServiceCommitmentIfOpenContractLineExists()
    var
        OpenContractLinesExistErr: Label 'The Subscription Line cannot be deleted because it is linked to a contract line which is not yet marked as "Closed".';
    begin
        Initialize();
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true);
        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        asserterror ServiceCommitment.DeleteAll(true);
        Assert.ExpectedError(OpenContractLinesExistErr);
    end;

    [Test]
    procedure ExpectErrorWhenDeleteServiceCommitmentServiceStartDateAndNextBillingDateAreDifferent()
    var
        SubscriptionLineStartDateDifferentThanNextBillingDateErr: Label 'The %1 must be the same as the %2 to delete the %3.', Comment = '%1 = Service Start Date; %2 = Next Billing Date; %3 = Service Commitment', Locked = true;
    begin
        ClearAll();
        ContractTestLibrary.CreateServiceObjectForItem(ServiceObject, Item, false);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);
        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, ServiceCommitmentPackage.Code);
        ServiceObject.InsertServiceCommitmentsFromServCommPackage(WorkDate(), ServiceCommitmentPackage);

        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        ServiceCommitment.ModifyAll("Subscription Line Start Date", CalcDate('<-1D>', WorkDate()), false);
        ServiceCommitment.ModifyAll("Next Billing Date", CalcDate('<+1D>', WorkDate()), false);
        asserterror ServiceCommitment.DeleteAll(true);
        Assert.ExpectedError(StrSubstNo(SubscriptionLineStartDateDifferentThanNextBillingDateErr,
            ServiceCommitment.FieldCaption("Subscription Line Start Date"),
            ServiceCommitment.FieldCaption("Next Billing Date"),
            ServiceCommitment.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenDeleteServiceCommitmentAndOpenCustomerContractDeferralsExist()
    var
        UnreleasedCustSubContractDeferralExistsErr: Label 'Contract lines cannot be deleted as long as open Contract Deferrals exists. Please release the Contract Deferrals before deleting the Contract line.', Locked = true;
    begin
        // [SCENARIO]: When deleting a service commitment, expect an error if there are open deferrals for the service commitment

        // [GIVEN]: Create a customer contract and service commitments
        Initialize();
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true);
        UpdateServiceDatesAndCloseContractLines();

        // [GIVEN]: Create open deferrals for the customer contract lines
        MockContractDeferralForServiceObject(ServiceObject."No.");

        // [THEN]: expect an error when trying to delete the service commitment
        asserterror ServiceCommitment.DeleteAll(true);
        Assert.ExpectedError(UnreleasedCustSubContractDeferralExistsErr);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenDeleteServiceCommitmentAndOpenVendorContractDeferralsExist()
    var
        UnreleasedVendorContractDeferralExistsErr: Label 'Contract lines cannot be deleted as long as open Contract Deferrals exists. Please release the Contract Deferrals before deleting the Contract line.', Locked = true;
    begin
        // [SCENARIO]: When deleting a service commitment, expect an error if there are open deferrals for the service commitment

        // [GIVEN]: Create a Vendor contract and service commitments
        Initialize();
        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, '', true);
        UpdateServiceDatesAndCloseContractLines();

        // [GIVEN]: Create open deferrals for the customer contract lines
        MockContractDeferralForServiceObject(ServiceObject."No.");

        // [THEN]: expect an error when trying to delete the service commitment
        asserterror ServiceCommitment.DeleteAll(true);
        Assert.ExpectedError(UnreleasedVendorContractDeferralExistsErr);
    end;

    [Test]
    procedure ExpectErrorWhenItemAssignedToServCommPackageWhenInvoicingItemIsEmptyForPackageLine()
    var
        SalesWithServCommItem: Record Item;
        ServCommPackage: Record "Subscription Package";
        ServCommPackageLine: Record "Subscription Package Line";
    begin
        // [SCENARIO] When Service Commitment Package has one line with "Invoice Via" = Contract and "Invoicing Item No." is empty, then the item cannot be assigned to the package

        // [GIVEN] Service Commitment Package with a line where Invoicing Item is empty and "Invoicing Via" = Contract
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServCommPackage, ServCommPackageLine);
        ServCommPackageLine.Validate("Invoicing via", Enum::"Invoicing Via"::Contract);
        ServCommPackageLine.Modify(false);

        // [WHEN] Assigning an Item with Service Commitment Option = Sales with Service Commitment to the Service Commitment Package
        ContractTestLibrary.CreateItemForServiceObject(SalesWithServCommItem, false);
        asserterror ContractTestLibrary.AssignItemToServiceCommitmentPackage(SalesWithServCommItem."No.", ServCommPackage.Code, true, true);

        // [THEN] Error expected that the item cannot be used with a package while there is a package line with "Invoicing Via" = Contract and "Invoicing Item No." is blank
        Assert.ExpectedError(StrSubstNo(PackageLineMissingInvoicingItemNoErr, ServCommPackage.TableCaption, ServCommPackage.Code, SalesWithServCommItem."No.", ServCommPackageLine.FieldCaption("Invoicing Item No.")));
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler,ConfirmHandlerYes')]
    procedure DeleteServiceCommitmentAfterVendorContractLineSetToClosed()
    var
    begin
        Initialize();
        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, '', true);
        UpdateServiceDatesAndCloseContractLines();

        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        ServiceCommitment.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorOnModifyClosedServiceCommitment()
    var
    begin
        Initialize();
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true);
        UpdateServiceDatesAndCloseContractLines();

        ServiceCommitment."Next Billing Date" := CalcDate('<1D>', ServiceCommitment."Next Billing Date");
        asserterror ServiceCommitment.Modify(true);
    end;

    [Test]
    procedure PreventInvalidDateFormulaRatioForSubscriptionLine()
    var
        FifteenMonthsDateFormula: DateFormula;
    begin
        // [SCENARIO] When a Subscription Line has been created with a Billing Base Period and a Billing Rhythm that do not have a valid ratio, the error is thrown as soon as an invalid date formula is entered

        // [GIVEN] A single Subscription Line with Billing Base Period and Billing Rhythm equal to 12M has been created
        Initialize();
        ContractTestLibrary.CreateServiceObjectForItemWithServiceCommitments(ServiceObject, Enum::"Invoicing Via"::Contract, false, Item, 1, 0, '<12M>', '<12M>');

        Commit(); // retain data after asserterror

        // [WHEN] An invalid date formula is created for the purpose of validating Billing Base Period and Billing Rhythm
        Evaluate(FifteenMonthsDateFormula, '<15M>');

        // [THEN] Error expected when invalid date formula is entered for Billing Base Period or Billing Rhythm
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        ServiceCommitment.FindFirst();
        asserterror ServiceCommitment.Validate("Billing Base Period", FifteenMonthsDateFormula);
        Assert.ExpectedError(StrSubstNo(NaturalNumberRatioErr, ServiceCommitment.FieldCaption("Billing Base Period"), ServiceCommitment.FieldCaption("Billing Rhythm")));
        asserterror ServiceCommitment.Validate("Billing Rhythm", FifteenMonthsDateFormula);
        Assert.ExpectedError(StrSubstNo(NaturalNumberRatioErr, ServiceCommitment.FieldCaption("Billing Base Period"), ServiceCommitment.FieldCaption("Billing Rhythm")));
    end;

    [Test]
    procedure PreventInvalidDateFormulaRatioForSubscriptionPackageLine()
    var
        FifteenMonthsDateFormula: DateFormula;
    begin
        // [SCENARIO] When a Subscription Package Line has been created with a Billing Base Period and a Billing Rhythm that do not have a valid ratio, the error is thrown as soon as an invalid date formula is entered

        // [GIVEN] A single Subscription Package Line with Billing Base Period and Billing Rhythm equal to 12M has been created
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine('', ServiceCommitmentPackage, ServiceCommPackageLine);
        Commit(); // retain data after asserterror

        // [WHEN] An invalid date formula is created for the purpose of validating Billing Base Period and Billing Rhythm
        Evaluate(FifteenMonthsDateFormula, '<15M>');

        // [THEN] Error expected when invalid date formula is entered for Billing Base Period or Billing Rhythm
        asserterror ServiceCommPackageLine.Validate("Billing Base Period", FifteenMonthsDateFormula);
        Assert.ExpectedError(StrSubstNo(NaturalNumberRatioErr, ServiceCommPackageLine.FieldCaption("Billing Base Period"), ServiceCommPackageLine.FieldCaption("Billing Rhythm")));
        asserterror ServiceCommPackageLine.Validate("Billing Rhythm", FifteenMonthsDateFormula);
        Assert.ExpectedError(StrSubstNo(NaturalNumberRatioErr, ServiceCommPackageLine.FieldCaption("Billing Base Period"), ServiceCommPackageLine.FieldCaption("Billing Rhythm")));
    end;


    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestOverdueServiceCommitments()
    var
        TempOverdueServiceCommitments: Record "Overdue Subscription Line";
        ServiceContractSetup: Record "Subscription Contract Setup";
        i: Integer;
        InsertCounter: Integer;
        MaxInsertCount: Integer;
    begin
        ContractTestLibrary.InitContractsApp();
        Initialize();
        ServiceContractSetup.Get();
        Evaluate(ServiceContractSetup."Overdue Date Formula", '<1M>');
        ServiceContractSetup.Modify(false);

        // Create closed Subscription Lines that should not be considered
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true); // ExchangeRateSelectionModalPageHandler,MessageHandler
        UpdateServiceDatesAndCloseContractLines();

        // Create Subscription Lines to consider
        MaxInsertCount := LibraryRandom.RandIntInRange(2, 9);
        InsertCounter := 0;
        for i := 1 to MaxInsertCount do begin
            InsertServiceCommitment(ServiceCommitment.Partner::Customer, InsertCounter);
            if i mod 2 = 0 then
                InsertServiceCommitment(ServiceCommitment.Partner::Vendor, InsertCounter);
        end;

        Assert.AreEqual(InsertCounter, TempOverdueServiceCommitments.CountOverdueServiceCommitments(), 'Only service commitments that are open and within the correct date range should be counted.');
    end;

    [Test]
    procedure TestServiceCommitmentPackageCopy()
    var
        CopiedServiceCommPackageLines: Record "Subscription Package Line";
        CopiedServiceCommPackage: Record "Subscription Package";
        NewPackageFilter: Code[20];
    begin
        Initialize();
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommPackageLine);

        NewPackageFilter := ServiceCommitmentPackage.Code;
        ServiceCommitmentPackage.CreateNewCodeForServiceCommPackageCopy(NewPackageFilter);

        ServiceCommitmentPackage.CopyServiceCommitmentPackage();
        CopiedServiceCommPackage.Get(NewPackageFilter);
        CopiedServiceCommPackageLines.SetRange("Subscription Package Code", CopiedServiceCommPackage.Code);
        CopiedServiceCommPackageLines.FindFirst();
        CopiedServiceCommPackageLines.TestField(Partner, ServiceCommPackageLine.Partner);
        CopiedServiceCommPackageLines.TestField(Template, ServiceCommPackageLine.Template);
        CopiedServiceCommPackageLines.TestField(Description, ServiceCommPackageLine.Description);
        CopiedServiceCommPackageLines.TestField("Invoicing via", ServiceCommPackageLine."Invoicing via");
        CopiedServiceCommPackageLines.TestField("Invoicing Item No.", ServiceCommPackageLine."Invoicing Item No.");
        CopiedServiceCommPackageLines.TestField("Calculation Base Type", ServiceCommPackageLine."Calculation Base Type");
        CopiedServiceCommPackageLines.TestField("Calculation Base %", ServiceCommPackageLine."Calculation Base %");
        CopiedServiceCommPackageLines.TestField("Billing Base Period", ServiceCommPackageLine."Billing Base Period");
        CopiedServiceCommPackageLines.TestField("Billing Rhythm", ServiceCommPackageLine."Billing Rhythm");
        CopiedServiceCommPackageLines.TestField("Sub. Line Start Formula", ServiceCommPackageLine."Sub. Line Start Formula");
        CopiedServiceCommPackageLines.TestField("Notice Period", ServiceCommPackageLine."Notice Period");
        CopiedServiceCommPackageLines.TestField("Extension Term", ServiceCommPackageLine."Extension Term");
        CopiedServiceCommPackageLines.TestField("Initial Term", ServiceCommPackageLine."Initial Term");
    end;

    [Test]
    procedure UT_PreventMarkingSubscriptionLineAsDiscountWhenInvoicingViaSales()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Subscription line cannot be marked as discount when invoicing via sales

        // [GIVEN] A mocked subscription line set up for sales invoicing
        MockSubscriptionLine(SubscriptionLine);
        SubscriptionLine."Invoicing via" := SubscriptionLine."Invoicing via"::Sales;

        // [WHEN] Attempting to mark the line as discount
        // [THEN] The operation should be prevented
        asserterror SubscriptionLine.Validate(Discount, true);
        Assert.ExpectedError(DiscountCanBeInvoicedViaContractErr);
    end;

    [Test]
    procedure UT_PreventMarkingSubscriptionLineAsDiscountForNonSubscriptionItem()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Subscription line cannot be marked as discount for non-subscription item

        // [GIVEN]  Create Subscription Item
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");

        // [GIVEN] A mocked subscription line with subscription item
        MockSubscriptionLine(SubscriptionLine);
        SubscriptionLine."Invoicing Item No." := Item."No.";

        // [WHEN] Attempting to mark the line as discount
        // [THEN] The operation should be prevented
        asserterror SubscriptionLine.Validate(Discount, true);
        Assert.ExpectedError(DiscountCannotBeAssignedErr);
    end;

    [Test]
    procedure UT_PreventMarkingSubscriptionLineAsDiscountForUsageBasedBilling()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Subscription line cannot be marked as discount for usage-based billing

        // [GIVEN] A mocked subscription line with usage-based billing
        MockSubscriptionLine(SubscriptionLine);
        SubscriptionLine."Usage Based Billing" := true;

        // [WHEN] Attempting to mark the line as discount
        // [THEN] The operation should be prevented
        asserterror SubscriptionLine.Validate(Discount, true);
        Assert.ExpectedError(RecurringDiscountCannotBeGrantedErr);
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure PreventStartDateChangeOnSubscriptionLinesPageAfterBilling()
    var
        BillingLine: Record "Billing Line";
        BillingTemplate: Record "Billing Template";
        SalesHeader: Record "Sales Header";
        SubscriptionLine: Record "Subscription Line";
        ServiceCommitmentsPage: TestPage "Service Commitments";
    begin
        // [SCENARIO] The Subscription Line Start Date can no longer be changed on the Subscription Lines page after the Subscription Line has been billed

        // [GIVEN] A Customer Subscription Contract with a Subscription Line for which an invoice has been posted
        Initialize();
        BillContractAndPostInvoice(BillingTemplate, BillingLine, SalesHeader);
        SubscriptionLine.Get(BillingLine."Subscription Line Entry No.");
        Assert.AreNotEqual(SubscriptionLine."Subscription Line Start Date", SubscriptionLine."Next Billing Date", 'The Subscription Line should have been billed.');
        Commit(); // retain data after asserterror

        // [WHEN] The Subscription Line Start Date is changed on the Subscription Lines page
        ServiceCommitmentsPage.OpenEdit();
        ServiceCommitmentsPage.GoToRecord(SubscriptionLine);

        // [THEN] The change is rejected with the same error as on the contract line list
        asserterror ServiceCommitmentsPage."Service Start Date".SetValue(GetDifferentDateAllowedByLicense(SubscriptionLine."Subscription Line Start Date"));
        Assert.ExpectedError(BillingLineArchiveForServiceCommitmentExistErr);
    end;

    [Test]
    procedure UT_PreventStartDateChangeWhenBilledSubscriptionLineHasZeroAmount()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] The Subscription Line Start Date can no longer be changed for a Subscription Line which has been billed at zero value

        // [GIVEN] A billed Subscription Line whose archived billing lines add up to zero
        Initialize();
        MockBilledSubscriptionLine(SubscriptionLine);
        MockBillingLineArchive(SubscriptionLine."Entry No.", 0);

        // [WHEN] The Subscription Line Start Date is changed
        // [THEN] The change is rejected
        asserterror SubscriptionLine.Validate("Subscription Line Start Date", CalcDate('<+2M>', SubscriptionLine."Subscription Line Start Date"));
        Assert.ExpectedError(BillingLineArchiveForServiceCommitmentExistErr);
    end;

    [Test]
    procedure UT_PreventStartDateChangeWhenSubscriptionLineIsInCurrentBilling()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] The Subscription Line Start Date cannot be changed as long as the Subscription Line is part of the current billing

        // [GIVEN] A Subscription Line with an open Billing Line
        Initialize();
        MockBilledSubscriptionLine(SubscriptionLine);
        MockBillingLine(SubscriptionLine."Entry No.");

        // [WHEN] The Subscription Line Start Date is changed
        // [THEN] The change is rejected
        asserterror SubscriptionLine.Validate("Subscription Line Start Date", CalcDate('<+2M>', SubscriptionLine."Subscription Line Start Date"));
        Assert.ExpectedError(BillingLineForServiceCommitmentExistErr);
    end;

    [Test]
    procedure UT_AllowStartDateChangeWhenNextBillingDateIsOnStartDate()
    var
        SubscriptionLine: Record "Subscription Line";
        NewStartDate: Date;
    begin
        // [SCENARIO] The Subscription Line Start Date may be corrected as long as the Next Billing Date is back on the Subscription Line Start Date

        // [GIVEN] A billed Subscription Line whose Next Billing Date has been reset to the Subscription Line Start Date by a credit memo
        Initialize();
        MockBilledSubscriptionLine(SubscriptionLine);
        MockBillingLineArchive(SubscriptionLine."Entry No.", LibraryRandom.RandDec(100, 2));
        SubscriptionLine."Next Billing Date" := SubscriptionLine."Subscription Line Start Date";
        SubscriptionLine.Modify(false);

        // [WHEN] The Subscription Line Start Date is changed
        NewStartDate := CalcDate('<+2M>', SubscriptionLine."Subscription Line Start Date");
        SubscriptionLine.Validate("Subscription Line Start Date", NewStartDate);

        // [THEN] The change is accepted and the Next Billing Date follows the new Subscription Line Start Date
        SubscriptionLine.TestField("Subscription Line Start Date", NewStartDate);
        SubscriptionLine.TestField("Next Billing Date", NewStartDate);
    end;

    [Test]
    procedure UT_AllowStartDateChangeWhenSubscriptionLineHasNotBeenBilled()
    var
        SubscriptionLine: Record "Subscription Line";
        NewStartDate: Date;
    begin
        // [SCENARIO] The Subscription Line Start Date may be changed as long as no billing has been performed for the Subscription Line

        // [GIVEN] A Subscription Line without any Billing Line and without any Billing Line Archive
        Initialize();
        MockBilledSubscriptionLine(SubscriptionLine);

        // [WHEN] The Subscription Line Start Date is changed
        NewStartDate := CalcDate('<+2M>', SubscriptionLine."Subscription Line Start Date");
        SubscriptionLine.Validate("Subscription Line Start Date", NewStartDate);

        // [THEN] The change is accepted and the Next Billing Date follows the new Subscription Line Start Date
        SubscriptionLine.TestField("Subscription Line Start Date", NewStartDate);
        SubscriptionLine.TestField("Next Billing Date", NewStartDate);
    end;

    [Test]
    procedure UT_AllowStartDateChangeOnTemporarySubscriptionLine()
    var
        SubscriptionLine: Record "Subscription Line";
        TempSubscriptionLine: Record "Subscription Line" temporary;
        NewStartDate: Date;
    begin
        // [SCENARIO] Buffering a billed Subscription Line in a temporary record, as the contract renewal does, is not blocked by the start date check

        // [GIVEN] A billed Subscription Line and a temporary Subscription Line carrying its Entry No.
        Initialize();
        MockBilledSubscriptionLine(SubscriptionLine);
        MockBillingLineArchive(SubscriptionLine."Entry No.", LibraryRandom.RandDec(100, 2));
        TempSubscriptionLine.Init();
        TempSubscriptionLine."Entry No." := SubscriptionLine."Entry No.";

        // [WHEN] The Subscription Line Start Date is set on the temporary record
        NewStartDate := CalcDate('<+2M>', SubscriptionLine."Subscription Line Start Date");
        TempSubscriptionLine.Validate("Subscription Line Start Date", NewStartDate);

        // [THEN] The value is accepted
        TempSubscriptionLine.TestField("Subscription Line Start Date", NewStartDate);
    end;

    [Test]
    procedure UT_CancellationPossibleUntilIsNotMovedToMonthEndForDayNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A Notice Period expressed in days is subtracted from a month end "Term Until" without being rounded up to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line starting 01.01.2026 with Initial Term 12M, Subsequent Term 12M and Notice Period 60D
        MockSubscriptionLineWithTerms(SubscriptionLine, DMY2Date(1, 1, 2026), '<12M>', '<12M>', '<60D>');

        // [WHEN] The termination dates are calculated
        SubscriptionLine.CalculateTermUntilDate();

        // [THEN] "Term Until" is the last day of the initial term
        Assert.AreEqual(DMY2Date(31, 12, 2026), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);

        // [THEN] "Cancellation Possible Until" is exactly 60 days earlier and not moved to the end of November
        Assert.AreEqual(DMY2Date(1, 11, 2026), SubscriptionLine."Cancellation Possible Until", CancellationPossibleUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_CancellationPossibleUntilIsNotMovedToMonthEndForWeekNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A Notice Period expressed in weeks is subtracted from a month end "Term Until" without being rounded up to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line starting 01.01.2026 with Initial Term 12M, Subsequent Term 12M and Notice Period 4W
        MockSubscriptionLineWithTerms(SubscriptionLine, DMY2Date(1, 1, 2026), '<12M>', '<12M>', '<4W>');

        // [WHEN] The termination dates are calculated
        SubscriptionLine.CalculateTermUntilDate();

        // [THEN] "Cancellation Possible Until" is exactly 4 weeks before 31.12.2026 and not moved back to 31.12.2026
        Assert.AreEqual(DMY2Date(31, 12, 2026), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
        Assert.AreEqual(DMY2Date(3, 12, 2026), SubscriptionLine."Cancellation Possible Until", CancellationPossibleUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_CancellationPossibleUntilIsMovedToMonthEndForMonthNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A Notice Period expressed in months keeps aligning "Cancellation Possible Until" to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line starting 01.03.2025 with Initial Term 12M, Subsequent Term 12M and Notice Period 1M
        MockSubscriptionLineWithTerms(SubscriptionLine, DMY2Date(1, 3, 2025), '<12M>', '<12M>', '<1M>');

        // [WHEN] The termination dates are calculated
        SubscriptionLine.CalculateTermUntilDate();

        // [THEN] "Term Until" is 28.02.2026 and "Cancellation Possible Until" is moved from 28.01.2026 to the end of January
        Assert.AreEqual(DMY2Date(28, 2, 2026), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
        Assert.AreEqual(DMY2Date(31, 1, 2026), SubscriptionLine."Cancellation Possible Until", CancellationPossibleUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_CancellationPossibleUntilIsMovedToMonthEndForQuarterNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A Notice Period expressed in quarters keeps aligning "Cancellation Possible Until" to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line starting 01.03.2025 with Initial Term 12M, Subsequent Term 12M and Notice Period 1Q
        MockSubscriptionLineWithTerms(SubscriptionLine, DMY2Date(1, 3, 2025), '<12M>', '<12M>', '<1Q>');

        // [WHEN] The termination dates are calculated
        SubscriptionLine.CalculateTermUntilDate();

        // [THEN] "Term Until" is 28.02.2026 and "Cancellation Possible Until" is moved from 28.11.2025 to the end of November
        Assert.AreEqual(DMY2Date(28, 2, 2026), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
        Assert.AreEqual(DMY2Date(30, 11, 2025), SubscriptionLine."Cancellation Possible Until", CancellationPossibleUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_TermUntilIsNotMovedToMonthEndForDayNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Entering a month end "Cancellation Possible Until" with a Notice Period expressed in days calculates "Term Until" without rounding it to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line with Notice Period 60D
        MockSubscriptionLine(SubscriptionLine);
        Evaluate(SubscriptionLine."Notice Period", '<60D>');

        // [WHEN] "Cancellation Possible Until" is set to the last day of November 2026
        SubscriptionLine.Validate("Cancellation Possible Until", DMY2Date(30, 11, 2026));

        // [THEN] "Term Until" is exactly 60 days later and not moved to the end of January
        Assert.AreEqual(DMY2Date(29, 1, 2027), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_TermUntilIsMovedToMonthEndForMonthNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] Entering a month end "Cancellation Possible Until" with a Notice Period expressed in months keeps aligning "Term Until" to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line with Notice Period 1M
        MockSubscriptionLine(SubscriptionLine);
        Evaluate(SubscriptionLine."Notice Period", '<1M>');

        // [WHEN] "Cancellation Possible Until" is set to the last day of February 2026
        SubscriptionLine.Validate("Cancellation Possible Until", DMY2Date(28, 2, 2026));

        // [THEN] "Term Until" is moved from 28.03.2026 to the end of March
        Assert.AreEqual(DMY2Date(31, 3, 2026), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_IsMonthBasedDateFormulaExcludesDayAndWeekComponents()
    var
        DateFormulaManagement: Codeunit "Date Formula Management";
        EmptyDateFormula: DateFormula;
    begin
        // [SCENARIO] A date formula is month based when it carries no day and no week component, no matter how many terms it has

        Initialize();

        // [THEN] Days and weeks are not month based
        Assert.IsFalse(IsMonthBasedDateFormula('<60D>'), 'A date formula in days must not be month based.');
        Assert.IsFalse(IsMonthBasedDateFormula('<4W>'), 'A date formula in weeks must not be month based.');

        // [THEN] Months, quarters and years are month based
        Assert.IsTrue(IsMonthBasedDateFormula('<1M>'), 'A date formula in months must be month based.');
        Assert.IsTrue(IsMonthBasedDateFormula('<1Q>'), 'A date formula in quarters must be month based.');
        Assert.IsTrue(IsMonthBasedDateFormula('<1Y>'), 'A date formula in years must be month based.');

        // [THEN] A composite date formula built only from months, quarters and years is month based as well
        Assert.IsTrue(IsMonthBasedDateFormula('<1Y+6M>'), 'A composite date formula in years and months must be month based.');
        Assert.IsTrue(IsMonthBasedDateFormula('<1Q+1M>'), 'A composite date formula in quarters and months must be month based.');

        // [THEN] A composite date formula carrying a day or week component is not month based
        Assert.IsFalse(IsMonthBasedDateFormula('<1M+15D>'), 'A composite date formula with a day component must not be month based.');
        Assert.IsFalse(IsMonthBasedDateFormula('<1M+2W>'), 'A composite date formula with a week component must not be month based.');

        // [THEN] Current period and empty date formulas are not month based
        Assert.IsFalse(IsMonthBasedDateFormula('<CM>'), 'A current period date formula must not be month based.');
        Assert.IsFalse(DateFormulaManagement.IsMonthBasedDateFormula(EmptyDateFormula), 'An empty date formula must not be month based.');
    end;

    [Test]
    procedure UT_TermUntilIsMovedToMonthEndForCompositeMonthNoticePeriod()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A composite Notice Period built only from months and years keeps aligning "Term Until" to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line with Notice Period 1Y+6M
        MockSubscriptionLine(SubscriptionLine);
        Evaluate(SubscriptionLine."Notice Period", '<1Y+6M>');

        // [WHEN] "Cancellation Possible Until" is set to the last day of February 2026
        SubscriptionLine.Validate("Cancellation Possible Until", DMY2Date(28, 2, 2026));

        // [THEN] "Term Until" is moved from 28.08.2027 to the end of August
        Assert.AreEqual(DMY2Date(31, 8, 2027), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_TermUntilIsNotMovedToMonthEndForDayExtensionTerm()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A Subsequent Term expressed in days extends a month end "Term Until" by exactly that many days

        Initialize();

        // [GIVEN] A Subscription Line whose term runs until 31.12.2026, with a Subsequent Term of 30D
        MockSubscriptionLine(SubscriptionLine);
        SubscriptionLine."Term Until" := DMY2Date(31, 12, 2026);
        Evaluate(SubscriptionLine."Extension Term", '<30D>');

        // [WHEN] The term is extended
        SubscriptionLine.CalculateTermUntilUsingExtensionTerm();

        // [THEN] "Term Until" is exactly 30 days later and not moved to the end of January
        Assert.AreEqual(DMY2Date(30, 1, 2027), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
    end;

    [Test]
    procedure UT_TermUntilIsMovedToMonthEndForMonthExtensionTerm()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A Subsequent Term expressed in months keeps aligning "Term Until" to the end of the month

        Initialize();

        // [GIVEN] A Subscription Line whose term runs until 28.02.2026, with a Subsequent Term of 1M
        MockSubscriptionLine(SubscriptionLine);
        SubscriptionLine."Term Until" := DMY2Date(28, 2, 2026);
        Evaluate(SubscriptionLine."Extension Term", '<1M>');

        // [WHEN] The term is extended
        SubscriptionLine.CalculateTermUntilUsingExtensionTerm();

        // [THEN] "Term Until" is moved from 28.03.2026 to the end of March
        Assert.AreEqual(DMY2Date(31, 3, 2026), SubscriptionLine."Term Until", TermUntilNotCalculatedErr);
    end;

    #endregion Tests

    #region Procedures

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Commitment Test");
        ClearAll();

        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
    end;

    local procedure InsertServiceCommitment(ServicePartner: Enum "Service Partner"; var InsertCounter: Integer)
    begin
        ServiceCommitment.Init();
        ServiceCommitment.Partner := ServicePartner;
        ServiceCommitment."Subscription Header No." := ServiceObject."No.";
        ServiceCommitment."Entry No." := 0;
        ServiceCommitment."Next Billing Date" := CalcDate('<-1M>', WorkDate());
        ServiceCommitment.Insert(false);
        InsertCounter += 1;
    end;

    local procedure MockContractDeferralForServiceObject(SubscriptionHeaderNo: Code[20])
    begin
        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", SubscriptionHeaderNo);
        ServiceCommitment.FindSet();
        repeat
            ServiceCommitment.TestField("Subscription Contract No.");
            ServiceCommitment.TestField("Subscription Contract Line No.");
            case ServiceCommitment.Partner of
                ServiceCommitment.Partner::Customer:
                    ContractTestLibrary.MockCustomerContractDeferralLine(ServiceCommitment."Subscription Contract No.", ServiceCommitment."Subscription Contract Line No.");
                ServiceCommitment.Partner::Vendor:
                    ContractTestLibrary.MockVendorContractDeferralLine(ServiceCommitment."Subscription Contract No.", ServiceCommitment."Subscription Contract Line No.");
            end;
        until ServiceCommitment.Next() = 0;
    end;

    local procedure BillContractAndPostInvoice(var BillingTemplate: Record "Billing Template"; var BillingLine: Record "Billing Line"; var SalesHeader: Record "Sales Header")
    begin
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '');
        ContractTestLibrary.DisableDeferralsForCustomerContract(CustomerContract, false);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);
        BillingLine.SetRange("Billing Template Code", BillingTemplate.Code);
        BillingLine.SetRange(Partner, BillingLine.Partner::Customer);
        Codeunit.Run(Codeunit::"Create Billing Documents", BillingLine);
        BillingLine.FindLast();
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, BillingLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure GetDifferentDateAllowedByLicense(ReferenceDate: Date) NewDate: Date
    begin
        // the date filter of the demo license only allows dates in November, December, January and February
        NewDate := DMY2Date(1, 2, Date2DMY(ReferenceDate, 3));
        if NewDate = ReferenceDate then
            NewDate := DMY2Date(1, 1, Date2DMY(ReferenceDate, 3));
    end;

    local procedure MockBilledSubscriptionLine(var SubscriptionLine: Record "Subscription Line")
    begin
        SubscriptionLine.Init();
        SubscriptionLine."Entry No." := 0;
        SubscriptionLine."Invoicing via" := SubscriptionLine."Invoicing via"::Contract;
        SubscriptionLine."Subscription Line Start Date" := WorkDate();
        SubscriptionLine."Next Billing Date" := CalcDate('<+1M>', WorkDate());
        SubscriptionLine.Insert(false);
    end;

    local procedure MockBillingLine(SubscriptionLineEntryNo: Integer)
    var
        BillingLine: Record "Billing Line";
    begin
        BillingLine.Init();
        BillingLine."Entry No." := 0;
        BillingLine."Subscription Line Entry No." := SubscriptionLineEntryNo;
        BillingLine.Insert(false);
    end;

    local procedure MockBillingLineArchive(SubscriptionLineEntryNo: Integer; ArchivedAmount: Decimal)
    var
        BillingLineArchive: Record "Billing Line Archive";
    begin
        BillingLineArchive.Init();
        BillingLineArchive."Entry No." := 0;
        BillingLineArchive."Subscription Line Entry No." := SubscriptionLineEntryNo;
        BillingLineArchive.Amount := ArchivedAmount;
        BillingLineArchive.Insert(false);
    end;

    local procedure MockSubscriptionLine(var SubscriptionLine: Record "Subscription Line")
    begin
        SubscriptionLine.Init();
        SubscriptionLine."Entry No." := 0;
        SubscriptionLine."Invoicing via" := SubscriptionLine."Invoicing via"::Contract;
        SubscriptionLine.Insert(false);
    end;

    local procedure IsMonthBasedDateFormula(DateFormulaText: Text): Boolean
    var
        DateFormulaManagement: Codeunit "Date Formula Management";
        DateFormulaValue: DateFormula;
    begin
        Evaluate(DateFormulaValue, DateFormulaText);
        exit(DateFormulaManagement.IsMonthBasedDateFormula(DateFormulaValue));
    end;

    local procedure MockSubscriptionLineWithTerms(var SubscriptionLine: Record "Subscription Line"; StartDate: Date; InitialTermText: Text; ExtensionTermText: Text; NoticePeriodText: Text)
    var
        InitialTerm: DateFormula;
        ExtensionTerm: DateFormula;
        NoticePeriod: DateFormula;
    begin
        MockSubscriptionLine(SubscriptionLine);
        // The start date is validated before the terms, so that the termination dates are only calculated by the procedure under test.
        SubscriptionLine.Validate("Subscription Line Start Date", StartDate);
        Evaluate(InitialTerm, InitialTermText);
        SubscriptionLine.Validate("Initial Term", InitialTerm);
        Evaluate(ExtensionTerm, ExtensionTermText);
        SubscriptionLine.Validate("Extension Term", ExtensionTerm);
        Evaluate(NoticePeriod, NoticePeriodText);
        SubscriptionLine.Validate("Notice Period", NoticePeriod);
    end;

    local procedure UpdateServiceDatesAndCloseContractLines()
    begin
        ServiceCommitment.Reset();
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObject."No.");
        if ServiceCommitment.FindSet() then
            repeat
                ServiceCommitment."Subscription Line Start Date" := CalcDate('<-2D>', Today());
                ServiceCommitment."Subscription Line End Date" := CalcDate('<-1D>', Today());
                ServiceCommitment."Next Billing Date" := CalcDate('<+1D>', ServiceCommitment."Subscription Line End Date");
                ServiceCommitment.Modify(false);
            until ServiceCommitment.Next() = 0;
        ServiceObject.UpdateServicesDates();
    end;

    local procedure ValidateDateFormulaCombinations(DateFormulaText1: Text; DateFormulaText2: Text)
    var
        EvaluatedDateFormula: DateFormula;
    begin
        ServiceCommPackageLine.Get(ServiceCommPackageLine."Subscription Package Code", ServiceCommPackageLine."Line No.");
        Evaluate(EvaluatedDateFormula, DateFormulaText1);
        ServiceCommPackageLine."Billing Base Period" := EvaluatedDateFormula;
        Evaluate(EvaluatedDateFormula, DateFormulaText2);
        ServiceCommPackageLine.Validate("Billing Rhythm", EvaluatedDateFormula);
        ServiceCommPackageLine.Modify(false);
    end;

    #endregion Procedures

    #region Handlers

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure CreateCustomerBillingDocsPageHandler(var CreateCustomerBillingDocs: TestPage "Create Customer Billing Docs")
    begin
        CreateCustomerBillingDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExchangeRateSelectionModalPageHandler(var ExchangeRateSelectionPage: TestPage "Exchange Rate Selection")
    begin
        ExchangeRateSelectionPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    #endregion Handlers
}
