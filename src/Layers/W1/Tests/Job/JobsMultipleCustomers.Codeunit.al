codeunit 136323 "Jobs - Multiple Customers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Projects] [Multiple Customers]
        Initialized := false
    end;

    var
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        Assert: Codeunit Assert;
        Initialized: Boolean;
        CustomersAreNotEqualMsg: Label 'Customers on Project Task and %1 are not equal.', Comment = '%1 = Table caption';
        LinesTransferedToInvoiceMsg: Label 'The lines were successfully transferred to an invoice.';
        UpdateBillingMethodErr: Label 'You cannot select %1 in %2, because one or more Project Tasks exist for this %3.', Comment = '%1 = Caption of the Task Billing Method field value; %2 = Caption of the Task Billing Method field; %3 = Caption of the Project table';
        AssociatedEntriesExistErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = Name of field used in the error; %2 = The name of the Project table';
        TasksNotUpdatedMsg: Label 'You have changed %1 on the project, but it has not been changed on the existing project tasks.', Comment = '%1 = a Field Caption like Location Code';
        UpdateTasksManuallyMsg: Label 'You must update the existing project tasks manually.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;
        OneInvoicesAreCreatedMsg: Label '1 invoice is created.';
        PostJournalLineQst: Label 'Do you want to post the journal lines?';
        PostedJournalLinesMsg: Label 'The journal lines were successfully posted.';
        UpdateBillToCustMsg: Label 'You have changed a customer. Prices and costs needs to be updated on a related lines.\\Do you want to update related lines?';
        MultipleInvoiceCreatedMsg: Label '%1 invoices are created.', Comment = '%1= Invoice count';

    [Test]
    procedure DefaultTaskBillingMethodIsPulledOnNewProject()
    var
        Job: Record Job;
    begin
        // [SCENARIO 348602] Default Task Billing Method is Pulled on new Project
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [WHEN] Create new Project
        LibraryJob.CreateJob(Job);

        // [THEN] Verify results
        Assert.IsTrue(Job."Task Billing Method" = Job."Task Billing Method"::"Multiple customers", 'Task Billing Method is not Multiple Customers');
    end;

    [Test]
    procedure CustomerControlsAreVisibleOnJobTaskSubformForMultiCustomerTaskBillingMethod()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO 348602] Customer Controls are Visible on Job Task Subform for Multi-Customer Task Billing Method
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job);

        // [WHEN] Open Job Card
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);

        // [THEN] Verify results
        Assert.IsTrue(JobCard.JobTaskLines."Sell-to Customer No.".Visible(), 'Customer control is not visible for Multi Customer Billing Method');
        Assert.IsTrue(JobCard.JobTaskLines."Bill-to Customer No.".Visible(), 'Customer control is not visible for Multi Customer Billing Method');
    end;

    [Test]
    procedure CustomerIsInitializedOnJobTaskForMultiCustomerBillingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 348602] Customer is Initialized on Job Task for Multi-Customer Billing Method
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [WHEN] Create new Project and Project Task
        CreateJobAndJobTask(Job, JobTask);

        // [THEN] Verify results
        Assert.AreEqual(Job."Sell-to Customer No.", JobTask."Sell-to Customer No.", StrSubstNo(CustomersAreNotEqualMsg, Job.TableCaption));
        Assert.AreEqual(Job."Bill-to Customer No.", JobTask."Bill-to Customer No.", StrSubstNo(CustomersAreNotEqualMsg, Job.TableCaption));
    end;

    [Test]
    procedure IsNotAllowedToReturnBillingMethodToOneCustomerIfJobTaskExist()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [SCENARIO 348602] Is not Allowed to Return Billing Method to One Customer if Job Task Exist
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Project and Project Task
        CreateJobAndJobTask(Job, JobTask);

        // [WHEN] Try to set Billing Method to One Customer
        asserterror Job.Validate("Task Billing Method", Job."Task Billing Method"::"One customer");

        // [THEN] Verify results
        RecRef.GetTable(Job);
        FldRef := RecRef.Field(Job.FieldNo("Task Billing Method"));
        Assert.ExpectedError(StrSubstNo(UpdateBillingMethodErr, FldRef.GetEnumValueCaption(Job."Task Billing Method".AsInteger()), Job.FieldCaption("Task Billing Method"), Job.TableCaption()));
    end;

    [Test]
    procedure CheckCustomersDataOnJobAndJobTaskForMultiCustomersBillingOption()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 348602] 
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers with Address
        LibrarySales.CreateCustomerWithAddress(Customers[1]);
        LibrarySales.CreateCustomerWithAddress(Customers[2]);

        // [GIVEN] Create Ship-to Address Customer
        CreateShiptoAddrCustomer(Customers[1]."No.");

        // [GIVEN] Set Bill-to Customer
        Customers[1].Validate("Bill-to Customer No.", Customers[2]."No.");
        Customers[1].Modify(true);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [WHEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [THEN] Verify results
        Assert.AreEqual(Job."Sell-to Customer No.", JobTask."Sell-to Customer No.", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Customer Name", JobTask."Sell-to Customer Name", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Customer Name 2", JobTask."Sell-to Customer Name 2", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Address", JobTask."Sell-to Address", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Address 2", JobTask."Sell-to Address 2", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to City", JobTask."Sell-to City", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Contact", JobTask."Sell-to Contact", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Post Code", JobTask."Sell-to Post Code", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to County", JobTask."Sell-to County", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Country/Region Code", JobTask."Sell-to Country/Region Code", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Sell-to Contact No.", JobTask."Sell-to Contact No.", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Customer No.", JobTask."Bill-to Customer No.", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Name", JobTask."Bill-to Name", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Address", JobTask."Bill-to Address", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Address 2", JobTask."Bill-to Address 2", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to City", JobTask."Bill-to City", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to County", JobTask."Bill-to County", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Post Code", JobTask."Bill-to Post Code", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Country/Region Code", JobTask."Bill-to Country/Region Code", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Name 2", JobTask."Bill-to Name 2", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Contact No.", JobTask."Bill-to Contact No.", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Bill-to Contact", JobTask."Bill-to Contact", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Code", JobTask."Ship-to Code", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Name", JobTask."Ship-to Name", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Name 2", JobTask."Ship-to Name 2", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Address", JobTask."Ship-to Address", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Address 2", JobTask."Ship-to Address 2", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to City", JobTask."Ship-to City", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Contact", JobTask."Ship-to Contact", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Post Code", JobTask."Ship-to Post Code", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to County", JobTask."Ship-to County", 'Customers data are not equal on Project and Project Task');
        Assert.AreEqual(Job."Ship-to Country/Region Code", JobTask."Ship-to Country/Region Code", 'Customers data are not equal on Project and Project Task');
    end;

    [Test]
    procedure InvoiceCurrencyCodeOnJobTaskIsNotEditableForJobWithCurrencyCode()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Currency: Record Currency;
        JobTaskCard: TestPage "Job Task Card";
    begin
        // [SCENARIO 348602] Invoice Currency Code on Job Task is not editable for Job with Currency Code
        Initialize();

        // [GIVEN] Create Currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Project and Project Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Set Currency Code on Project
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify();

        // [WHEN] Open Job Task card
        JobTaskCard.OpenEdit();
        JobTaskCard.GoToRecord(JobTask);

        // [THEN] Verify results
        Assert.IsFalse(JobTaskCard."Invoice Currency Code".Editable(), 'Invoice Currency Code is editable');
    end;

    [Test]
    procedure JobTaskDimensionsAreRecalculatedOnUpdateCustomer()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobTaskDimension: Record "Job Task Dimension";
        Customers: array[2] of Record Customer;
        DimensionValues: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 348602] Job Task Dimensions are recalculated on Update Customer on Job Task
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers with Dimensions
        CreateCustomerwithDimension(Customers[1], DimensionValues[1]);
        CreateCustomerwithDimension(Customers[2], DimensionValues[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Find Job Task Dimensions
        FindJobTaskDimension(JobTask, JobTaskDimension, DimensionValues[1]);

        // [THEN] Verify Job Task Dimensions
        Assert.AreEqual(JobTaskDimension."Dimension Value Code", DimensionValues[1].Code, 'Job Task Dimension is not equal to Customer Dimension');

        // [GIVEN] Update Customer on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [WHEN] Find Job Task Dimensions
        FindJobTaskDimension(JobTask, JobTaskDimension, DimensionValues[2]);

        // [THEN] Verify results
        Assert.AreEqual(JobTaskDimension."Dimension Value Code", DimensionValues[2].Code, 'Job Task Dimension is not equal to Customer Dimension');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SalesPriceIsPulledFromCustomerOnJobTask()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PriceListHeader: Record "Price List Header";
        PriceListLines: array[2] of Record "Price List Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 348602] Sales Price is Pulled from Customer on Job Task
        Initialize();

        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Sales Prices for Item and Customers
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[1], Customers[1]."No.", Item."No.");
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[2], Customers[2]."No.", Item."No.");

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[1]."Unit Price", 'Sales Price is not equal to Customer Sales Price');

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Update Customer on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [WHEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[2]."Unit Price", 'Sales Price is not equal to Customer Sales Price');
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure SalesInvoiceIsCreatedForJobTaskCustomer()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 348602] Sales Invoice is Created for Job Task Customer
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Update Customer on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [WHEN] Create Sales Invoice        
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Find Sales Document
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [THEN] Verify results
        Assert.AreEqual(SalesHeader."Sell-to Customer No.", Customers[2]."No.", StrSubstNo(CustomersAreNotEqualMsg, SalesHeader.TableCaption));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure AllowChangeCustomerOnJobWithRelatedPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PriceListHeader: Record "Price List Header";
        PriceListLines: array[2] of Record "Price List Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 433788] Allow Change Customer on Job with Related Planning Line
        Initialize();

        // [GIVEN] Set One Customer billing method on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Create new Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Sales Prices for Item and Customers
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[1], Customers[1]."No.", Item."No.");
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[2], Customers[2]."No.", Item."No.");

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[1]."Unit Price", 'Sales Price is not equal to Customer Sales Price');

        // [WHEN] Update Customer on Project
        Job.Validate("Sell-to Customer No.", Customers[2]."No.");
        Job.Modify(true);

        // [THEN] Verify results
        JobPlanningLine.Find('=');
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[2]."Unit Price", 'Sales Price is not equal to Customer Sales Price');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure AllowChangeBillToCustomerOnJobWithRelatedPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PriceListHeader: Record "Price List Header";
        PriceListLines: array[2] of Record "Price List Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 433788] Allow Change Bill-to Customer on Job with Related Planning Line
        Initialize();

        // [GIVEN] Set One Customer billing method on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Create new Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Sales Prices for Item and Customers
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[1], Customers[1]."No.", Item."No.");
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[2], Customers[2]."No.", Item."No.");

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[1]."Unit Price", 'Sales Price is not equal to Customer Sales Price');

        // [WHEN] Update Customer on Project
        Job.Validate("Bill-to Customer No.", Customers[2]."No.");
        Job.Modify(true);

        // [THEN] Verify results
        JobPlanningLine.Find('=');
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[2]."Unit Price", 'Sales Price is not equal to Customer Sales Price');
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure CustomerUpdateIsNotAllowedForJobWithPostedSalesInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 433788] Customer Update is not Allowed for Job with Posted Sales Invoice
        Initialize();

        // [GIVEN] Set One Customer billing method on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [GIVEN] Create Sales Invoice        
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Find Sales Document
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [GIVEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Update Customer on Project
        asserterror Job.Validate("Sell-to Customer No.", Customers[2]."No.");

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(AssociatedEntriesExistErr, Job.FieldCaption("Sell-to Customer No."), Job.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure AllowChangeCustomerOnJobTaskWithRelatedPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PriceListHeader: Record "Price List Header";
        PriceListLines: array[2] of Record "Price List Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 433788] Allow Change Customer on Job Task with Related Planning Line
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Create new Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Sales Prices for Item and Customers
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[1], Customers[1]."No.", Item."No.");
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[2], Customers[2]."No.", Item."No.");

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[1]."Unit Price", 'Sales Price is not equal to Customer Sales Price');

        // [WHEN] Update Customer on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [THEN] Verify results
        JobPlanningLine.Find('=');
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[2]."Unit Price", 'Sales Price is not equal to Customer Sales Price');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure AllowChangeBillToCustomerOnJobTaskWithRelatedPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PriceListHeader: Record "Price List Header";
        PriceListLines: array[2] of Record "Price List Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 433788] Allow Change Bill-to Customer on Job Task with Related Planning Line
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Create new Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Sales Prices for Item and Customers
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[1], Customers[1]."No.", Item."No.");
        CreatePriceLineForCustomer(PriceListHeader, PriceListLines[2], Customers[2]."No.", Item."No.");

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[1]."Unit Price", 'Sales Price is not equal to Customer Sales Price');

        // [WHEN] Update Customer on Project Task
        JobTask.Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [THEN] Verify results
        JobPlanningLine.Find('=');
        Assert.AreEqual(JobPlanningLine."Unit Price", PriceListLines[2]."Unit Price", 'Sales Price is not equal to Customer Sales Price');
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure CustomerUpdateIsNotAllowedForJobTaskWithPostedSalesInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 433788] Customer Update is not Allowed for Job Task with Posted Sales Invoice
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [GIVEN] Create Sales Invoice        
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Find Sales Document
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [GIVEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Update Customer on Project
        asserterror JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(AssociatedEntriesExistErr, JobTask.FieldCaption("Sell-to Customer No."), JobTask.TableCaption()));
    end;

    [Test]
    procedure InvoiceCurrencyCodeOnJobTaskIsClearedOnValidateCurrencyCodeOnJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Currency: array[2] of Record Currency;
    begin
        // [SCENARIO 498974] Invoice Currency Code on Job Task is cleared on Validate Currency Code on Job
        Initialize();

        // [GIVEN] Create Currencies
        LibraryERM.CreateCurrency(Currency[1]);
        LibraryERM.CreateCurrency(Currency[2]);

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Project and Project Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Set Invoice Currency Code on Project Task
        JobTask.Validate("Invoice Currency Code", Currency[1].Code);
        JobTask.Modify();

        // [WHEN] Set Currency Code on Project
        Job.Validate("Currency Code", Currency[2].Code);
        Job.Modify();

        // [THEN] Verify results
        JobTask.Find('=');
        Assert.AreEqual(JobTask."Invoice Currency Code", '', 'Invoice Currency Code is not cleared');
    end;

    [Test]
    [HandlerFunctions('JobTaskMessageHandler')]
    procedure ShowWarningMessageAboutJobChangesThatJobTaskWillNotBeUpdated()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        Currency: Record Currency;
    begin
        // [SCENARIO 498976] Show Warning Message about Job Changes that Job Task will not be Updated 
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Project and Project Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Payment Method
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [WHEN] Update Payment Method Code on Project
        LibraryVariableStorage.Enqueue(JobTask.FieldCaption("Payment Method Code"));
        Job.Validate("Payment Method Code", PaymentMethod.Code);

        // [THEN] Verify results

        // [GIVEN] Create Payment Terms
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // [WHEN] Update Payment Terms Code on Project
        LibraryVariableStorage.Enqueue(JobTask.FieldCaption("Payment Terms Code"));
        Job.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] Verify results

        // [GIVEN] Create Currency
        LibraryERM.CreateCurrency(Currency);

        // [WHEN] Update Invoice Currency Code on Project
        LibraryVariableStorage.Enqueue(JobTask.FieldCaption("Invoice Currency Code"));
        Job.Validate("Invoice Currency Code", Currency.Code);

        // [THEN] Verify results
    end;

    [Test]
    procedure ClearJobTaskCustomerDataOnCopyJobForOneCustomerTaskBillingOptionOnTargetJob()
    var
        JobTasks: array[2] of Record "Job Task";
        Jobs: array[2] of Record Job;
        Customers: array[2] of Record Customer;
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 498973] Clear Job Task Customer Data on Copy Job for One Customer Task Billing Option on Target Job
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Jobs[1], Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Jobs[1], JobTasks[1]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Jobs[2], Customers[2]."No.");

        // [GIVEN] Set One Customer billing method on Project
        Jobs[2].Validate("Task Billing Method", Jobs[2]."Task Billing Method"::"One customer");
        Jobs[2].Modify(true);

        // [WHEN] Copy Project Tasks
        CopyJob.CopyJobTasks(Jobs[1], Jobs[2]);

        // [THEN] Verify results
        JobTasks[2].Get(Jobs[2]."No.", JobTasks[1]."Job Task No.");
        JobTasks[2].TestField("Sell-to Customer No.", '');
        JobTasks[2].TestField("Bill-to Customer No.", '');
    end;

    [Test]
    procedure InitializeJobTaskCustomerDataOnCopyJobForMultipleCustomerTaskBillingOptionOnTargetJob()
    var
        JobTasks: array[2] of Record "Job Task";
        Jobs: array[2] of Record Job;
        Customers: array[2] of Record Customer;
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 498973] Initialize Job Task Customer Data on Copy Job for Multiple Customer Task Billing Option on Target Job
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Jobs[1], Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Jobs[1], JobTasks[1]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Jobs[2], Customers[2]."No.");

        // [WHEN] Copy Project Tasks
        CopyJob.CopyJobTasks(Jobs[1], Jobs[2]);

        // [THEN] Verify results
        JobTasks[2].Get(Jobs[2]."No.", JobTasks[1]."Job Task No.");
        JobTasks[2].TestField("Sell-to Customer No.", Customers[2]."No.");
        JobTasks[2].TestField("Bill-to Customer No.", Customers[2]."No.");
    end;

    [Test]
    [HandlerFunctions('GetJobPlanLines')]
    procedure AllowCreatingSalesInvoiceLineOutsideOfProjectForMultipleCustomersBillingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
        Qty: Decimal;
    begin
        // [SCENARIO 500367] Allow Creating Sales Invoice Line Outside of Project for Multiple Customers Billing Method
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Update Customer on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, Qty);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customers[2]."No.");

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [WHEN] Get Job Planning Lines
        // [HANDLER] [GetJobPlanLines] Get Job Plan Lines        
        Codeunit.Run(Codeunit::"Job-Process Plan. Lines", SalesLine);

        // [THEN] Verify Job Info on Sales Line
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Job No.", JobTask."Job No.");
        SalesLine.TestField("Job Task No.", JobTask."Job Task No.");
        SalesLine.TestField("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
    end;

    [Test]
    [HandlerFunctions('GetJobPlanLines')]
    procedure CheckInvoicedQtyOnJobPlanningLinesAfterSalesInvoiceCreatedFromJobPlanningLineIsPostedForMultipleCustomersBillingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 500367] Check Invoiced Qty. on Job Planning Line after Sales Invoice created from Job Planning Line is posted for Multiple Customers Billing Method
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Update Customer on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Modify(true);

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customers[2]."No.");

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Get Job Planning Lines
        // [HANDLER] [GetPJobPlanLines] Get Job Plan Lines        
        Codeunit.Run(Codeunit::"Job-Process Plan. Lines", SalesLine);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify Qty. Invoiced and Qty. Transferred to Invoice on Job Planning Line
        JobPlanningLine.CalcFields("Qty. Invoiced", "Qty. Transferred to Invoice");
        JobPlanningLine.TestField("Qty. Invoiced", JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Qty. Transferred to Invoice", JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetJobPlanLines')]
    procedure SalesInvoiceLineIsCreatedIfCurrencyIsMatchingOnSalesInvoiceAndJobTaskForMultipleCustomersBillingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
        CurrencyCode: Code[10];
        Qty: Decimal;
    begin
        // [SCENARIO 500367] Sales Invoice Line is Created if Currency is Matching on Sales Invoice and Job Task for Multiple Customers Billing Method
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Currency
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Update Customer and Currency on Project Task
        JobTask.Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTask.Validate("Invoice Currency Code", CurrencyCode);
        JobTask.Modify(true);

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, Qty);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customers[2]."No.");

        // [GIVEN] Update Currency on Sales Invoice
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [WHEN] Get Job Planning Lines
        // [HANDLER] [GetJobPlanLines] Get Job Plan Lines        
        Codeunit.Run(Codeunit::"Job-Process Plan. Lines", SalesLine);

        // [THEN] Verify Job Info on Sales Line
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Job No.", JobTask."Job No.");
        SalesLine.TestField("Job Task No.", JobTask."Job Task No.");
        SalesLine.TestField("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler')]
    procedure SalesInvoicesAreCreatedForJobTasksWithMultipleCustomersBillingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        JobTasks: array[4] of Record "Job Task";
        Customers: array[2] of Record Customer;
        SalesHeaders: array[4] of Record "Sales Header";
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
        CurrencyCode: Code[10];
        Qty: Decimal;
        FourInvoicesAreCreatedMsg: Label '4 invoices are created.';
    begin
        // [SCENARIO 500362] Sales Invoices are Created for Job Tasks with Multiple Customers Billing Method 
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Currency
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Create Payment Method and Payment Terms
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create Project Task 1 with Customer 1
        LibraryJob.CreateJobTask(Job, JobTasks[1]);
        JobTasks[1]."Your Reference" := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(JobTasks[1]."Your Reference")), 1, MaxStrLen(JobTasks[1]."Your Reference"));
        JobTasks[1].Modify(true);

        // [GIVEN] Create Project Task 2 with Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[2]);
        JobTasks[2].Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTasks[2]."External Document No." := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(JobTasks[2]."External Document No.")), 1, MaxStrLen(JobTasks[2]."External Document No."));
        JobTasks[2].Modify(true);

        // [GIVEN] Create Project Task 3 with Sell-to Customer 1 and Bill-to Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[3]);
        JobTasks[3].Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTasks[3].Validate("Payment Method Code", PaymentMethod.Code);
        JobTasks[3].Validate("Payment Terms Code", PaymentTerms.Code);
        JobTasks[3].Modify(true);

        // [GIVEN] Create Project Task 4 with Customer 1 and Invoice Currency Code
        LibraryJob.CreateJobTask(Job, JobTasks[4]);
        JobTasks[4].Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTasks[4].Validate("Bill-to Customer No.", Customers[1]."No.");
        JobTasks[4].Validate("Invoice Currency Code", CurrencyCode);
        JobTasks[4].Modify(true);

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        Qty := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[1], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[2], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[3], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[4], Qty, Qty);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(FourInvoicesAreCreatedMsg);

        // [WHEN] Run batch job "Create Job Sales Invoice" for Job Tasks
        Commit();  // Commit required for batch report.
        JobTask.SetFilter("Job No.", '%1', Job."No.");
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();

        // [GIVEN] Find Sales Invoices 
        FindSalesHeader(SalesHeaders[1], Customers[1]."No.", Customers[1]."No.", SalesHeaders[1]."Document Type"::Invoice);
        FindSalesHeader(SalesHeaders[2], Customers[2]."No.", Customers[2]."No.", SalesHeaders[2]."Document Type"::Invoice);
        FindSalesHeader(SalesHeaders[3], Customers[1]."No.", Customers[2]."No.", SalesHeaders[3]."Document Type"::Invoice);
        FindSalesHeader(SalesHeaders[4], Customers[2]."No.", Customers[1]."No.", SalesHeaders[4]."Document Type"::Invoice);

        // [THEN] Verify results
        SalesHeaders[1].TestField("Your Reference", JobTasks[1]."Your Reference");
        SalesHeaders[2].TestField("External Document No.", JobTasks[2]."External Document No.");
        SalesHeaders[3].TestField("Payment Method Code", PaymentMethod.Code);
        SalesHeaders[3].TestField("Payment Terms Code", PaymentTerms.Code);
        SalesHeaders[4].TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure CreateMultipleSalesInvoicesFromJobPlanningLinesForMultipleCustomersBillingMethod()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
        JobTasks: array[3] of Record "Job Task";
        SalesHeaders: array[3] of Record "Sales Header";
        Qty: Decimal;
    begin
        // [SCENARIO 500394] Create Multiple Sales Invoices from Job Planning Lines for Multiple Customers Billing Method
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create Project Task 1 with Customer 1 and Billing Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[1]);
        JobTasks[1].Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTasks[1].Modify(true);

        // [GIVEN] Create Project Task 2 with Customer 2 and Billing Customer 1
        LibraryJob.CreateJobTask(Job, JobTasks[2]);
        JobTasks[2].Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTasks[2].Validate("Bill-to Customer No.", Customers[1]."No.");
        JobTasks[2].Modify(true);

        // [GIVEN] Create Project Task 3 with Customer 2 and Billing Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[3]);
        JobTasks[3].Validate("Sell-to Customer No.", Customers[2]."No.");
        JobTasks[3].Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTasks[3].Modify(true);

        // [GIVEN] Create Job Planning Lines with Qty to Transfer to Invoice
        Qty := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[1], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[2], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[3], Qty, Qty);
        Commit();

        // [GIVEN] Filter Job Planning Lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetFilter("Job No.", '%1', Job."No.");
        JobPlanningLine.FindSet();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [WHEN] Create Sales Invoices
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Find Sales Invoices 
        FindSalesHeader(SalesHeaders[1], Customers[1]."No.", Customers[2]."No.", SalesHeaders[1]."Document Type"::Invoice);
        FindSalesHeader(SalesHeaders[2], Customers[2]."No.", Customers[1]."No.", SalesHeaders[2]."Document Type"::Invoice);
        FindSalesHeader(SalesHeaders[3], Customers[2]."No.", Customers[2]."No.", SalesHeaders[3]."Document Type"::Invoice);

        // [THEN] Post Sales Invoices
        LibrarySales.PostSalesDocument(SalesHeaders[1], true, true);
        LibrarySales.PostSalesDocument(SalesHeaders[2], true, true);
        LibrarySales.PostSalesDocument(SalesHeaders[3], true, true);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure CreateMultipleSalesInvoicesFromJobPlanningLinesForMultipleCustomersBillingMethodAndCurrencyJobTask()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
        JobTasks: array[2] of Record "Job Task";
        SalesHeaders: array[2] of Record "Sales Header";
        CurrencyCode: Code[10];
        Qty: Decimal;
    begin
        // [SCENARIO 500394] Create Multiple Sales Invoices from Job Planning Lines for Multiple Customers Billing Method and Currency Job Task
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create Currency
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create Project Task 1 with Customer 1 and Billing Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[1]);
        JobTasks[1].Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTasks[1].Modify(true);

        // [GIVEN] Create Project Task 2 with Customer 1 and Billing Customer 1
        LibraryJob.CreateJobTask(Job, JobTasks[2]);
        JobTasks[2].Validate("Invoice Currency Code", CurrencyCode);
        JobTasks[2].Modify(true);

        // [GIVEN] Create Job Planning Lines with Qty to Transfer to Invoice
        Qty := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[1], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[2], Qty, Qty);
        Commit();

        // [GIVEN] Filter Job Planning Lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetFilter("Job No.", '%1', Job."No.");
        JobPlanningLine.FindSet();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [WHEN] Create Sales Invoices
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Find Sales Invoices 
        FindSalesHeader(SalesHeaders[1], Customers[1]."No.", Customers[2]."No.", SalesHeaders[1]."Document Type"::Invoice);
        FindSalesHeader(SalesHeaders[2], Customers[1]."No.", Customers[1]."No.", SalesHeaders[2]."Document Type"::Invoice);

        // [THEN] Post Sales Invoices
        LibrarySales.PostSalesDocument(SalesHeaders[1], true, true);
        LibrarySales.PostSalesDocument(SalesHeaders[2], true, true);
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler')]
    procedure OneSalesInvoiceIsCreatedForJobTasksWithMultipleCustomersBillingMethodAndSameCustomerAndCurrencyData()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobTasks: array[2] of Record "Job Task";
        Customers: array[2] of Record Customer;
        SalesHeaders: array[4] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
        Qty: Decimal;
    begin
        // [SCENARIO 501468] One Sales Invoice is Created for Job Tasks with Multiple Customers Billing Method and Same Customer and Currency Data
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create Project Task 1 with Customer 1 and Bill-to Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[1]);
        JobTasks[1].Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTasks[1].Modify(true);

        // [GIVEN] Create Project Task 2 with Customer 1 and Bill-to Customer 2
        LibraryJob.CreateJobTask(Job, JobTasks[2]);
        JobTasks[2].Validate("Bill-to Customer No.", Customers[2]."No.");
        JobTasks[2].Modify(true);

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        Qty := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[1], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[2], Qty, Qty);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(OneInvoicesAreCreatedMsg);

        // [WHEN] Run batch job "Create Job Sales Invoice" for Job Tasks
        Commit();  // Commit required for batch report.
        JobTask.SetFilter("Job No.", '%1', Job."No.");
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();

        // [GIVEN] Find Sales Invoice
        FindSalesHeader(SalesHeaders[1], Customers[1]."No.", Customers[2]."No.", SalesHeaders[1]."Document Type"::Invoice);
        SalesLine.SetRange("Document Type", SalesHeaders[1]."Document Type");
        SalesLine.SetRange("Document No.", SalesHeaders[1]."No.");

        // [THEN] Verify results
        Assert.RecordCount(SalesLine, 2);
    end;

    [Test]
    procedure CheckVisibilityOnCustomerControlsOnJobTaskSubformDependingOnTaskBillingMethod()
    var
        Customer: Record Customer;
        Jobs: array[2] of Record Job;
        JobCard: TestPage "Job Card";
        TaskBillingMethod: Enum "Task Billing Method";
    begin
        // [SCENARIO 498972] Check whether customer controls are visible on Job Task depending on Task Billing Method
        Initialize();

        // [GIVEN] Set One Customer billing method on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Projects
        LibraryJob.CreateJob(Jobs[1], Customer."No.");
        LibraryJob.CreateJob(Jobs[2], Customer."No.");

        // [GIVEN] Open Job Card
        JobCard.OpenEdit();
        JobCard.GoToRecord(Jobs[1]);

        // [WHEN] Update Task Billing Method to Multiple Customers
        JobCard."Task Billing Method".SetValue(TaskBillingMethod::"Multiple customers");

        // [THEN] Verify results
        Assert.IsTrue(JobCard.JobTaskLines."Sell-to Customer No.".Visible(), 'Customer control is not visible for Multi Customer Billing Method');
        Assert.IsTrue(JobCard.JobTaskLines."Bill-to Customer No.".Visible(), 'Customer control is not visible for Multi Customer Billing Method');

        // [WHEN] Go to next Job record
        JobCard.Next();

        // [THEN] Verify results
        Assert.IsFalse(JobCard.JobTaskLines."Sell-to Customer No.".Visible(), 'Customer control is visible for One Customer Billing Method');
        Assert.IsFalse(JobCard.JobTaskLines."Bill-to Customer No.".Visible(), 'Customer control is visible for One Customer Billing Method');
    end;

    [Test]
    procedure CheckVisibilityOnCustomerControlsOnJobTaskSubformDependingOnTaskBillingMethodWithJobTaskRec()
    var
        Customer: Record Customer;
        Jobs: array[2] of Record Job;
        JobTasks: array[2] of Record "Job Task";
        JobCard: TestPage "Job Card";
        TaskBillingMethod: Enum "Task Billing Method";
    begin
        // [SCENARIO 498972] Check whether customer controls are visible on Job Task depending on Task Billing Method with Job Task record
        Initialize();

        // [GIVEN] Set One Customer billing method on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Projects
        LibraryJob.CreateJob(Jobs[1], Customer."No.");
        LibraryJob.CreateJob(Jobs[2], Customer."No.");

        // [GIVEN] Create Project Tasks
        LibraryJob.CreateJobTask(Jobs[1], JobTasks[1]);
        LibraryJob.CreateJobTask(Jobs[2], JobTasks[2]);

        // [GIVEN] Set Multiple Customers billing method
        Jobs[1]."Task Billing Method" := TaskBillingMethod::"Multiple customers";
        Jobs[1].Modify(true);

        // [GIVEN] Open Job Card
        JobCard.OpenEdit();
        JobCard.GoToRecord(Jobs[1]);

        // [WHEN] Go to next Job record
        JobCard.Next();

        // [THEN] Verify results
        Assert.IsFalse(JobCard.JobTaskLines."Sell-to Customer No.".Visible(), 'Customer control is visible for One Customer Billing Method');
        Assert.IsFalse(JobCard.JobTaskLines."Bill-to Customer No.".Visible(), 'Customer control is visible for One Customer Billing Method');

        // [WHEN] Go to previous record
        JobCard.Previous();

        // [THEN] Verify results
        Assert.IsTrue(JobCard.JobTaskLines."Sell-to Customer No.".Visible(), 'Customer control is not visible for Multi Customer Billing Method');
        Assert.IsTrue(JobCard.JobTaskLines."Bill-to Customer No.".Visible(), 'Customer control is not visible for Multi Customer Billing Method');
    end;

    [Test]
    procedure InvoiceCurrencyCodeIsClearedWithoutAnyMessage()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Customer: Record Customer;
        CurrencyCode, CurrencyCode2 : Code[10];
        Qty: Decimal;
    begin
        // [SCENARIO 501639] Invoice Currency code is cleared on Job and Job Tasks without any message on validate Currency Code
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Currencies
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyCode2 := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Set Invoice Currency Code
        Job.Validate("Invoice Currency Code", CurrencyCode);
        Job.Modify(true);

        // [WHEN] Create Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [THEN] Verify Invoice Currency Code on Job Task
        JobTask.Get(JobTask."Job No.", JobTask."Job Task No.");
        JobTask.TestField("Invoice Currency Code", CurrencyCode);

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        Qty := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, Qty);

        // [WHEN] Set Currency Code on Job
        Job.Validate("Currency Code", CurrencyCode2);
        Job.Modify(true);

        // [THEN] Verify Invoice Currency Code is cleared on Job Task
        JobTask.Get(JobTask."Job No.", JobTask."Job Task No.");
        JobTask.TestField("Invoice Currency Code", '');
    end;

    [Test]
    procedure CustomerDataAreClearedForNonPostingTaskType()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Customer: Record Customer;
    begin
        // [SCENARIO 504322] Customer Data are cleared for Non-Posting Task Type
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Create Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Update Task Type to Non-Posting
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::"End-Total");

        // [THEN] Verify results
        JobTask.TestField("Sell-to Customer No.", '');
        JobTask.TestField("Bill-to Customer No.", '');

        // [WHEN] Return Task Type to Posting
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::"Posting");

        // [THEN] Verify customer data are reinitialzed
        JobTask.TestField("Sell-to Customer No.", Customer."No.");
        JobTask.TestField("Bill-to Customer No.", Customer."No.");
    end;

    [Test]
    [HandlerFunctions('JobTransferToExistingSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure CreateSalesInvoiceAttachJobPlanningLineToExistingSalesInvoice()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Customer: Record Customer;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [SCENARIO 505083] Create Sales Invoice attach Job Planning Line to existing Sales Invoice
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Create Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Lines with Qty to Transfer to Invoice
        Qty := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, Qty);

        // [GIVEN] Create Sales Invoice Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        Commit();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [WHEN] Create Sales Invoices
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Find Sales Line and verify Document No.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesLine.Type::Resource, Job."No.");
        SalesLine.TestField("Document No.", SalesHeader."No.");
    end;

    [Test]
    procedure CopyTotalsProjectTasksTypeIntoProjectsWithMultipleCustomerBillingOption()
    var
        JobTasks: array[3] of Record "Job Task";
        Jobs: array[2] of Record Job;
        Customers: array[2] of Record Customer;
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 522645] Copy Totals Project Tasks Type into Projects with Multiple Customer Billing Option
        Initialize();

        // [GIVEN] Set One Customer Billing option on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customers[1]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Jobs[1], Customers[1]."No.");

        // [GIVEN] Create new Project Task of Type Begin Total
        LibraryJob.CreateJobTask(Jobs[1], JobTasks[1]);
        JobTasks[1]."Job Task Type" := JobTasks[1]."Job Task Type"::"Begin-Total";
        JobTasks[1].Modify(true);

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Jobs[1], JobTasks[2]);

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Jobs[2], Customers[1]."No.");

        // [WHEN] Copy Project Tasks
        CopyJob.CopyJobTasks(Jobs[1], Jobs[2]);

        // [THEN] Verify results
        JobTasks[3].Get(Jobs[2]."No.", JobTasks[1]."Job Task No.");
        JobTasks[3].TestField("Sell-to Customer No.", '');
        JobTasks[3].TestField("Bill-to Customer No.", '');

        JobTasks[3].Get(Jobs[2]."No.", JobTasks[2]."Job Task No.");
        JobTasks[3].TestField("Sell-to Customer No.", Jobs[2]."Sell-to Customer No.");
        JobTasks[3].TestField("Bill-to Customer No.", Jobs[2]."Bill-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure BillToCustomerUpdateIsNotAllowedForJobWithOpenSalesInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 527084] Bill-to Customer Update is not Allowed for Job with Open Sales Invoice
        Initialize();

        // [GIVEN] Set One Customer billing method on Project Setup
        SetOneCustomerBillingMethodOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [GIVEN] Create Sales Invoice        
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [WHEN] Update Bill-to Customer on Project
        asserterror Job.Validate("Bill-to Customer No.", Customers[2]."No.");

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(AssociatedEntriesExistErr, Job.FieldCaption("Bill-to Customer No."), Job.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure BillToCustomerUpdateIsNotAllowedForJobTaskWithOpenSalesInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Customers: array[2] of Record Customer;
    begin
        // [SCENARIO 527084] Bill-to Customer Update is not Allowed for Job Task with Open Sales Invoice
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create new Project Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [GIVEN] Create Sales Invoice        
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [WHEN] Update Bill-to Customer on Project
        asserterror JobTask.Validate("Bill-to Customer No.", Customers[2]."No.");

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(AssociatedEntriesExistErr, JobTask.FieldCaption("Bill-to Customer No."), JobTask.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmSpecificMessageHandler,JobCreateSalesInvoiceHandler,MessageHandler')]
    procedure CreateSalesInvoiceSecondTimeFromProjectCardWithoutJobTaskFilter()
    var
        Job: Record Job;
        Customer: Record Customer;
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        JobTasks: array[2] of Record "Job Task";
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
    begin
        // [SCENARIO 542476] Create Sales Invoice second time from Project Card without Job Task filter
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Create two Project Tasks
        LibraryJob.CreateJobTask(Job, JobTasks[1]);
        LibraryJob.CreateJobTask(Job, JobTasks[2]);

        // [GIVEN] Create Job Journal Lines
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), LibraryJob.ResourceType(), JobTasks[1], JobJournalLine);
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), LibraryJob.ResourceType(), JobTasks[2], JobJournalLine);

        // [GIVEN] Post Job Journal
        LibraryVariableStorage.Enqueue(PostJournalLineQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(PostedJournalLinesMsg);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(OneInvoicesAreCreatedMsg);

        // [GIVEN] Run batch job "Create Job Sales Invoice" for Job Tasks
        Commit();  // Commit required for batch report.
        JobTask.SetFilter("Job No.", '%1', Job."No.");
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();

        // [GIVEN] Find and Post Sales Invoice
        FindSalesHeader(SalesHeader, Customer."No.", Customer."No.", SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Job Journal Lines again
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), LibraryJob.ResourceType(), JobTasks[1], JobJournalLine);
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), LibraryJob.ResourceType(), JobTasks[2], JobJournalLine);

        // [GIVEN] Post Job Journal
        LibraryVariableStorage.Enqueue(PostJournalLineQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(PostedJournalLinesMsg);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(OneInvoicesAreCreatedMsg);

        // [THEN] Verify Sales Invoice is created
        Commit();  // Commit required for batch report.
        JobTask.SetFilter("Job No.", '%1', Job."No.");
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler,ConfirmSpecificMessageHandler')]
    procedure CreateSalesInvoiceForDifferentBillToCustOnNewProjectTaskIfSalesInvoiceExistForOtherProjectTasks()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobTasks: array[3] of Record "Job Task";
        Customers: array[2] of Record Customer;
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
        Quantity: Decimal;
    begin
        // [SCENARIO 554289] Create Sales Invoice for different Bill-to Customer on new Project Task if Sales Invoice exist for other Project Tasks
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Create two Project Tasks
        LibraryJob.CreateJobTask(Job, JobTasks[1]);
        LibraryJob.CreateJobTask(Job, JobTasks[2]);

        // [GIVEN] Create Job Planning Lines
        Quantity := LibraryRandom.RandInt(10);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[1], Quantity, Quantity);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[2], Quantity, Quantity);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(OneInvoicesAreCreatedMsg);

        // [GIVEN] Run batch job "Create Job Sales Invoice" for Job Tasks
        Commit();  // Commit required for batch report.
        JobTask.SetFilter("Job No.", '%1', Job."No.");
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();

        // [WHEN] Create new Project Tasks and Project Planning Line
        LibraryJob.CreateJobTask(Job, JobTasks[3]);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[3], Quantity, Quantity);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(UpdateBillToCustMsg);
        LibraryVariableStorage.Enqueue(true);

        // [THEN] Verify Update Bill-to Customer on new Project Task
        JobTasks[3].Validate("Bill-to Customer No.", Customers[2]."No.");
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoicePerTaskHandler,MessageHandler')]
    procedure InvoicePerProjectTaskCreateSaleInvoiceForMultipleCustomers()
    var
        Customers: array[2] of Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobTasks: array[4] of Record "Job Task";
        SalesLine: Record "Sales Line";
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
        JobChoice: Option Job,"Job Task";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 562511]  When run report "Job Create Sales Invoice" for Invoice Per as Job task, each Job task has individual invoice for multiple customer
        Initialize();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(Customers[1]);
        LibrarySales.CreateCustomer(Customers[2]);

        // [GIVEN] Create new Project
        LibraryJob.CreateJob(Job, Customers[1]."No.");

        // [GIVEN] Set "Task Billing Method": to Multiple Customer.
        Job.Validate("Task Billing Method", Job."Task Billing Method"::"Multiple customers");
        Job.Modify();

        // [GIVEN] Create multiple Job Task for multiple customers
        CreateJobTaskForMultipleCustomer(JobTasks, Job, Customers);

        // [GIVEN] Create multiple Job Planning Lines
        CreateMultipleJobPlanningLines(JobTasks);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(JobChoice::"Job Task");
        LibraryVariableStorage.Enqueue(StrSubstNo(MultipleInvoiceCreatedMsg, ArrayLen(JobTasks)));

        // [WHEN] Commit required to run the report
        Commit();

        // [WHEN] Filter the Job Task to run the report "Job Create Sales Invoice"
        JobTask.SetRange("Job No.", Job."No.");
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();

        // [WHEN] Find the sales lines
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLineType::Resource, Job."No.");

        // [THEN] Count the Sales Line, It will be same as Job task
        Assert.RecordCount(SalesLine, ArrayLen(JobTasks));

        // Clear the Variable storage
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ProjectDimensionsInheritedWithMultipleCustomers()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Customer: Record Customer;
        JobTaskDimension: Record "Job Task Dimension";
        ProjectDimensionValue: Record "Dimension Value";
        CustomerDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 573363] Custom dimension values should be inherited from Project to Task when Task Billing Method = Multiple customers
        Initialize();

        // [GIVEN] Set Multiple Customers on Project Setup
        SetMultiupleCustomersOnProjectSetup();

        // [GIVEN] Create a customer with a default dimension
        CreateCustomerwithDimension(Customer, CustomerDimensionValue);

        // [GIVEN] Create a project with a different custom dimension and Task Billing Method = Multiple customers
        LibraryJob.CreateJob(Job, Customer."No.");
        CreateJobWithProjectDimension(Job, ProjectDimensionValue);

        // [WHEN] Create a job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [THEN] Verify job task should have both project dimensions and customer dimensions
        JobTaskDimension.Reset();
        JobTaskDimension.SetRange("Job No.", JobTask."Job No.");
        JobTaskDimension.SetRange("Job Task No.", JobTask."Job Task No.");
        JobTaskDimension.SetRange("Dimension Code", ProjectDimensionValue."Dimension Code");
        JobTaskDimension.FindFirst();
        Assert.AreEqual(ProjectDimensionValue.Code, JobTaskDimension."Dimension Value Code", 'Project dimension value should match');

        // Verify customer dimension is also present
        JobTaskDimension.SetRange("Dimension Code", CustomerDimensionValue."Dimension Code");
        JobTaskDimension.FindFirst();
        Assert.AreEqual(CustomerDimensionValue.Code, JobTaskDimension."Dimension Value Code", 'Customer dimension value should match');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Jobs - Multiple Customers");
        LibraryVariableStorage.AssertEmpty();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Jobs - Multiple Customers");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Jobs - Multiple Customers");
    end;

    local procedure SetMultiupleCustomersOnProjectSetup()
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        JobsSetup."Default Task Billing Method" := JobsSetup."Default Task Billing Method"::"Multiple customers";
        JobsSetup.Modify();
    end;

    local procedure SetOneCustomerBillingMethodOnProjectSetup()
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        JobsSetup."Default Task Billing Method" := JobsSetup."Default Task Billing Method"::"One customer";
        JobsSetup.Modify();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[20]
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateJobAndJobTask(var Job: Record Job; var JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLineWithItem(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateCustomerwithDimension(var Customer: Record Customer; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure FindJobTaskDimension(JobTask: Record "Job Task"; var JobTaskDimension: Record "Job Task Dimension"; DimensionValue: Record "Dimension Value")
    begin
        JobTaskDimension.Reset();
        JobTaskDimension.SetRange("Job No.", JobTask."Job No.");
        JobTaskDimension.SetRange("Job Task No.", JobTask."Job Task No.");
        JobTaskDimension.SetRange("Dimension Code", DimensionValue."Dimension Code");
        JobTaskDimension.FindFirst();
    end;

    local procedure CreatePriceLineForCustomer(var PriceListHeader: Record "Price List Header"; var PriceListLine: Record "Price List Line"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, CustomerNo);
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, ItemNo);
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();
    end;

    local procedure CreateShiptoAddrCustomer(CustomerNo: Code[20]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo(Name));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo("Name 2"));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo(Address));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo("Address 2"));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo(County));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        ShipToAddress.Validate("Post Code", CreatePostCode());
        ShipToAddress.Modify();
    end;

    local procedure CreatePostCode(): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryUtility.FillFieldMaxText(PostCode, PostCode.FieldNo(County));
        exit(PostCode.Code);
    end;

    local procedure CreateJobPlanningLineWithQtyToTransferToInvoice(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; Quantity: Decimal; QtyToTransferToInvoice: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", QtyToTransferToInvoice);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateSimpleSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
    end;

    local procedure CreateJobTaskForMultipleCustomer(var JobTasks: array[4] of Record "Job Task";
    Job: Record Job;
    Customers: array[2] of Record Customer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(JobTasks) do begin
            LibraryJob.CreateJobTask(Job, JobTasks[i]);
            if i > 2 then
                JobTasks[i].Validate("Bill-to Customer No.", Customers[1]."No.")
            else
                JobTasks[i].Validate("Bill-to Customer No.", Customers[2]."No.");
            JobTasks[i].Modify(true);
        end;
    end;

    local procedure CreateMultipleJobPlanningLines(JobTasks: array[4] of Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
        i: Integer;
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandInt(10);
        for i := 1 to ArrayLen(JobTasks) do
            CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTasks[i], Qty, Qty);
    end;

    local procedure CreateJobWithProjectDimension(var Job: Record Job; var ProjectDimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(ProjectDimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Job, Job."No.", ProjectDimensionValue."Dimension Code", ProjectDimensionValue.Code);
    end;

    [RequestPageHandler]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobTransferToExistingSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    var
        DocumentNo: Text;
    begin
        DocumentNo := LibraryVariableStorage.DequeueText();
        JobTransferToSalesInvoice.CreateNewInvoice.SetValue(false);
        JobTransferToSalesInvoice.AppendToSalesInvoiceNo.SetValue(DocumentNo);
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    procedure JobTaskMessageHandler(Message: Text[1024])
    var
        MessageText: Text;
    begin
        MessageText := StrSubstNo(TasksNotUpdatedMsg, LibraryVariableStorage.DequeueText());
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, UpdateTasksManuallyMsg);
        Assert.ExpectedMessage(MessageText, Message);
    end;

    [ModalPageHandler]
    procedure GetJobPlanLines(var GetJobPlanningLines: TestPage "Get Job Planning Lines")
    begin
        GetJobPlanningLines.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobCreateSalesInvoiceHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobCreateSalesInvoicePerTaskHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    var
        JoBChoice: Variant;
    begin
        LibraryVariableStorage.Dequeue(JoBChoice);
        JobCreateSalesInvoice.JobChoice.SetValue(JoBChoice);
        JobCreateSalesInvoice.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmSpecificMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

