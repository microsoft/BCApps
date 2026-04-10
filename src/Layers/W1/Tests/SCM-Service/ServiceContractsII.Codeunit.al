// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using System.TestLibraries.Utilities;

codeunit 136145 "Service Contracts II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service Contract] [Service]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be equal to ''%2''  in %3: %4=%5. Current value is ''%6''.', Comment = '%1=Field name,%2=Field value,%3=Table name,%4=Field name,%5=Field value,%6=Field value';
        NoOfLinesError: Label 'No. of lines in %1 must be %2.', Comment = '%1=Table name';
        NewServiceItemLineError: Label 'You cannot add a new Service Item Line because the service contract has expired. Renew the Expiration Date on the service contract.';
        LineNotCreatedErr: Label 'Service item line is not created.';
        CreateInvoiceMsg: Label 'Do you want to create an invoice for the period';
        CreateServiceOrderBatchErr: Label 'New Service Order must be created.';
        UnexpectedConfirmTextErr: Label 'Unexpected confirmation text.';
        CreateContrUsingTemplateQst: Label 'Do you want to create the contract using a contract template?';
        SignServContractQst: Label 'Do you want to sign service contract %1?', Comment = '%1 = Contract No.';
        SignContractConfirmQst: Label 'Do you want to sign service contract';
        NewLinesAddedConfirmQst: Label 'New lines have been added to this contract.\Would you like to continue?';
        CurrentSaveValuesId: Integer;
        ConfirmLaterPostingDateQst: Label 'The posting date is later than the work date.\\Confirm that this is the correct date.';
        ConfirmLaterInvoiceToDateQst: Label 'The Invoice-to Date is later than the work date.\\Confirm that this is the correct date.';
        NextPlannedServiceDateConfirmQst: Label 'The Next Planned Service Date field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';
        CreateServiceInvoiceQst: Label 'Do you want to create an invoice for the contract?';
        DescriptionLbl: Label '%1 - %2', Comment = '%1 = Start Date of Month, %2 = End Date of Month';
        DescriptionMustMatchErr: Label 'Description must match.';
        WrongCountErr: Label 'Worong number of Service Line are created';

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,CreateContractServiceOrdersRequestPageHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceUpdationFromServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
        UnitPrice: Decimal;
    begin
        // Check updated Unit Price for posted Service Invoice Line created using CreateContractInvoices Batch Job.

        // 1. Setup: Create and Sign Service Contract, Create Service Order for Contract and Post it, Create Service Invoice for Contract and update Unit Price on Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), 1);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        SignContract(ServiceContractHeader);
        RunCreateContractServiceOrders();
        UpdateAndPostServiceOrder(ServiceContractHeader."Contract No.");

        LibraryVariableStorage.Enqueue(CalcDate(ServiceContractHeader."Service Period", WorkDate()));
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        UnitPrice := ServiceLine."Unit Price";

        // 2. Exercise: Post Service Invoice using Page.
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", ServiceLine."Document No.");
        LibrarySales.DisableConfirmOnPostingDoc();
        ServiceInvoice.Post.Invoke();

        // 3. Verify: Verify Unit Price in Service Ledger Entries.
        VerifyServiceLedgerEntry(ServiceContractHeader."Contract No.", -UnitPrice);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnChangedNextPlannedServiceDateOnContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
    begin
        // Check Default Next Planned Service Date on Service Contract Line.

        // 1. Setup.
        Initialize();
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));

        // 2. Exercise: Open Service Contract Page because some code is written on Page.
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");

        // 3. Verify: Verify Next Planned Service Date.
        ServiceContract.ServContractLines."Next Planned Service Date".AssertEquals(WorkDate());
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangedNextPlannedServiceDateOnContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
        FirstServiceDate: Date;
        ServicePeriod: DateFormula;
    begin
        // Check Next Planned Service Date and Service Period on Service Contract Line after updating them on Service Contract Header.

        // 1. Setup: Take Random First Service Date and Service Period. Update Service Contract Header.
        Initialize();
        FirstServiceDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'M>', WorkDate());
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Validate("First Service Date", FirstServiceDate);
        ServiceContractHeader.Modify(true);

        // 2. Exercise: Open Service Contract Page. Using page because there is no data available on Service Contract Line Record when Line is not created.
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");

        // 3. Verify: Verify Service Period and Next Planned Service Date.
        ServiceContract.ServContractLines."Service Period".AssertEquals(ServicePeriod);
        ServiceContract.ServContractLines."Next Planned Service Date".AssertEquals(FirstServiceDate);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoiceWithDifferentPrepaidAndNonPrepaidAccounts()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Invoice with Service Contracts Account Group having different Accounts.

        // 1. Setup: Create and Sign Service Contract, Create Service Invoice and Post it.
        Initialize();
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        PostServiceInvoiceAndVerifyPrepaidAccount(ServiceContractAccountGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoiceWithSamePrepaidAndNonPrepaidAccounts()
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Invoice with Service Contracts Account Group having similar Accounts.

        // 1. Setup: Create and Sign Service Contract, Create Service Invoice and Post it.
        Initialize();
        PostServiceInvoiceAndVerifyPrepaidAccount(CreateAndUpdateServiceContractAccountGroup());
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractCrMemoWithDifferentPrepaidAndNonPrepaidAccounts()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Credit Memo with Service Contracts Account Group having different Accounts.

        // Create Service Contract Account Group, Create and Sign Service Contract, Find Service Invoice and Post it, Create Service Credit Memo and Post.
        Initialize();
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreditMemoWithServiceContractAccountGroup(ServiceContractAccountGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractCrMemoWithSamePrepaidAndNonPrepaidAccounts()
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Credit Memo with Service Contracts Account Group having similar Accounts.

        // Create and Sign Service Contract, Find Service Invoice and Post it, Create Service Credit Memo and Post.
        Initialize();
        CreditMemoWithServiceContractAccountGroup(CreateAndUpdateServiceContractAccountGroup());
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryForServiceContractWithExpirationDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
    begin
        // [SCENARIO] Test Amount on Service Ledger Entries for a Service Contract with Expiration Date and is created using the Service Contract Template on which Invoice Period is set to one Year.
        Initialize();
        ContractStartingDate := CalcDate('<-CY>', WorkDate());
        ContractExpirationDate := CalcDate('<CY>', WorkDate());

        // [GIVEN] Signed Prepaid Service Contract with Starting Date = 01.01.22 and Expiration Date = 31.12.22.
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, true));
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        UpdateServiceContractStartingDate(ServiceContractHeader, ContractStartingDate);
        CreateContractLineAndUpdateContract(
          ServiceContractHeader, ServiceContractTemplate."Serv. Contract Acc. Gr. Code",
          ContractExpirationDate, ServiceContractHeader."Service Period");
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(ContractExpirationDate);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // [WHEN] Create Service Invoice using CreateContractInvoices Batch Job.
        RunCreateContractInvoices();

        // [THEN] 12 Service Ledger Entries were created due to Yearly Invoice Period on Contract.
        // [THEN] Amount of each Service Ledger Entry is equal to Annual Amount / 12, since the Invoice Period is Yearly.
        FindServiceLedgerEntries(ServiceLedgerEntry, ServiceContractHeader."Contract No.");
        Assert.AreEqual(12, ServiceLedgerEntry.Count, StrSubstNo(NoOfLinesError, ServiceLedgerEntry.TableCaption(), 1));
        VerifyServiceLedgerEntry(ServiceContractHeader."Contract No.", -Round(ServiceContractHeader."Annual Amount" / 12));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemLineOnExpiredServiceContract()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // Verify Program does not allow to add new Service Item line on Service Contract which is already expired.

        // 1. Setup: Create and sign Service Contract with Expiration Date. Open the Service Contract again.
        Initialize();
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractLineAndUpdateContract(
          ServiceContractHeader, ServiceContractAccountGroup.Code, CalcDate('<CY>', WorkDate()), ServiceContractHeader."Service Period");
        SignContract(ServiceContractHeader);
        ServiceContractHeader.Find();
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Find();
        SetExpirationDateLessThanLastInvoiceDate(ServiceContractHeader);

        // 2. Exercise: Add another Service Item line in the Service Contract.
        asserterror CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, 0D);  // Passing 0D for blank Contract Expiration Date.

        // 3. Verify: Verify error message which shows that Program does not allow to add new Service Item line on Service Contract which is already expired.
        Assert.ExpectedError(NewServiceItemLineError);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure AmountOnServiceInvoiceLineCreatedFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceLine: Record "Service Line";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        Amount: Decimal;
    begin
        // [SCENARIO] Test Amount on Service Invoice created from Service Contract with Invoice Period as Year and Prepaid False.
        Initialize();
        ContractStartingDate := CalcDate('<-CY>', WorkDate());
        ContractExpirationDate := CalcDate('<CY>', WorkDate());

        // [GIVEN] Signed non-prepaid Service Contract with Starting Date = 01.01.22 and Expiration Date = 31.12.22..
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, false));
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        UpdateServiceContractStartingDate(ServiceContractHeader, ContractStartingDate);
        CreateContractLineAndUpdateContract(
          ServiceContractHeader, ServiceContractTemplate."Serv. Contract Acc. Gr. Code",
          ContractExpirationDate, ServiceContractHeader."Service Period");
        Amount := FindServiceContractLineAmount(ServiceContractHeader);
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(ContractExpirationDate);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // [WHEN] Create Service Invoice using CreateContractInvoices Batch Job.
        RunCreateContractInvoices();

        // [THEN] Service Invoice with one Service Line with Amount = Contract Annual Amount in created.
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        ServiceLine.TestField(Amount, Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure AmountOnPostedServiceLineCreatedFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        Amount: Decimal;
    begin
        // [SCENARIO] Test Amount on Posted Service Invoice created from Service Contract with Invoice Period as Year and Prepaid False.
        Initialize();
        ContractStartingDate := CalcDate('<-CY>', WorkDate());
        ContractExpirationDate := CalcDate('<CY>', WorkDate());

        // [GIVEN] Signed non-prepaid Service Contract for Invoice Period Year; Service Contract Invoice created from Service Contract.
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, false));
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        UpdateServiceContractStartingDate(ServiceContractHeader, ContractStartingDate);
        CreateContractLineAndUpdateContract(
          ServiceContractHeader, ServiceContractTemplate."Serv. Contract Acc. Gr. Code",
          ContractExpirationDate, ServiceContractHeader."Service Period");
        Amount := FindServiceContractLineAmount(ServiceContractHeader);
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(ContractExpirationDate);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [WHEN] Post Service Invoice that was created from Service Contract.
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");

        // [THEN] Posted Service Invoice has one Line with Amount = Contract Annual Amount.
        VerifyServiceInvoiceLineAmount(ServiceContractHeader."Contract No.", Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure AddServiceContractLineWithEmptyContractHeaderExpiratoinDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Verify that service contract line can be added in case of empty expiration date

        // 1. Setup: Create Service Contract.
        Initialize();
        CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, false);
        LibraryVariableStorage.Enqueue(''); // empty service contract template
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        ServiceContractHeader."Last Invoice Date" := WorkDate(); // to cause expiration date analysis
        ServiceContractHeader.Modify();

        // 2. Exercise: add service contract line
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, 0D);

        // 3. Verify: line is created
        Assert.IsTrue(ServiceContractLine.Find(), LineNotCreatedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConditionalConfirmHandler,ServiceContractTemplateListHandler2,ConfirmCreateContractServiceOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServiceOrderFromServiceContractWithTwoLines()
    var
        ServiceContractNo: Code[20];
        ServiceContractLine1No: Integer;
        ServiceContractLine2No: Integer;
        NextPlannedServiceDate1: Date;
        NextPlannedServiceDate2: Date;
    begin
        // [SCENARIO 360643] Create service order from second line of Service Contract after creating order from first line.
        CurrentSaveValuesId := REPORT::"Create Contract Service Orders"; // Ensure SaveValues is cleared by Initialize
        Initialize();
        // [GIVEN] Create Service Contract with two line are having different Next Planned Service Date.
        CreateServiceContractWithTwoLines(ServiceContractNo, ServiceContractLine1No, ServiceContractLine2No,
          NextPlannedServiceDate1, NextPlannedServiceDate2);
        // [GIVEN] Create Service Order from first line.
        RunCreateContractServiceOrdersWithDates(NextPlannedServiceDate1,
          LibraryRandom.RandDateFrom(NextPlannedServiceDate1, 10));
        // [WHEN] Create Service Order from second line.
        RunCreateContractServiceOrdersWithDates(NextPlannedServiceDate2,
          LibraryRandom.RandDateFrom(NextPlannedServiceDate2, 10));
        // [THEN] Must be created new Service order from second line of Service Contract.
        // [THEN] Field Response Date of Service Item Line must be correctly calculated.
        VerifyCreatedServiceOrder(ServiceContractNo, ServiceContractLine1No, ServiceContractLine2No);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateContractInvWhenExpirationDateBeforeNextInvDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Contract Expiration Date] [Create Service Invoice]
        // [SCENARIO 374724] Service Ledger Entry is not created for Contract Invoice Line when Expiration Date is before Next Invoice Date
        Initialize();

        // [GIVEN] Signed Service Contract with two lines ("Service Item No." = "A" and "B")
        CreateServiceContractTemplate(ServiceContractTemplate, '<1M>', ServiceContractHeader."Invoice Period"::Month, true, false, true);
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), '<1M>', 2);
        SignContract(ServiceContractHeader);
        // [GIVEN] Expiration date in Service Contract Line with "Service Item No." = "A" is the day before Next Invoice Date = "X"
        ServiceItemNo :=
          ChangeExpirationDateOnContractLine(ServiceContractHeader, ServiceContractHeader."Next Invoice Date");

        // [WHEN] Run Create Contract Invoices batch job for Posting Date = "X"
        RunCreateContractInvoices();

        // [THEN] Service Ledger Entry for "Service Item No." = "A" and "Posting Date" = "X" is not created
        VerifyServiceLedgEntryDoesNotExist(
          ServiceContractHeader."Contract No.", ServiceItemNo, ServiceContractHeader."Next Invoice Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateNonPreparedContractInvWhenExpirationDateBeforeNextInvPeriodStart()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Contract Expiration Date]
        // [SCENARIO 375363] Service Ledger Entry is not created for Non Prepaid Contract Invoice Line when Expiration Date is before Next Invoice Period Start

        Initialize();
        // [GIVEN] Signed Non Prepaid Service Contract with two lines ("Service Item No." = "A" and "B")
        LibraryVariableStorage.Enqueue(CreateNonPrepaidServTemplateWithMonthInvPeriod());
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), '<1M>', 2);
        SignContract(ServiceContractHeader);

        // [GIVEN] Service Contract Line, where "Service Item No." = "A", "Expiration Date" = 23.01, "Next Invoice Period Start " = 24.01
        ServiceItemNo :=
          ChangeExpirationDateOnContractLine(ServiceContractHeader, ServiceContractHeader."Next Invoice Period Start");

        // [WHEN] Run Create Contract Invoices batch job for Posting Date = "X"
        RunCreateContractInvoices();

        // [THEN] Service Ledger Entry for "Service Item No." = "A" and "Posting Date" = 24.01 is not created
        VerifyServiceLedgEntryDoesNotExist(
          ServiceContractHeader."Contract No.", ServiceItemNo, ServiceContractHeader."Next Invoice Period Start");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePartialNonPrepaidServLine()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        InvoiceDate: Date;
        FullContractLineAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice] [Non-Prepaid Contract]
        // [SCENARIO 375877] Service Line created when invoice Non-Prepaid Contract with new Service Contract Line where "Starting Date" after "Next Invoice Period Start"
        // SCENARIO 376625 - Description line should show partial period

        // [GIVEN] Signed Non-Prepaid Service Contract with single line and Service Invoice for Period "X" - "Next Invoice Period Start" (01.01.22 - 31.12.22)
        // [GIVEN] New Service Line with "Starting Date" = 02.01.22 after "Next Invoice Period Start" added after reopening Service Contract
        // [GIVEN] Locked Service Contract without additional service invoice and shifting "Next Invoice Period"
        Initialize();
        ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(
          ServContractHeader, ServContractLine, false, 0D, InvoiceDate);
        FullContractLineAmount :=
          CalcContractLineAmount(
            ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractHeader."Next Invoice Period End");

        // [WHEN] Run Create Service Contract Invoices until the "Next Invoice Period End"
        RunCreateContractInvoices();

        // [THEN] Service Invoice created for new Service Line with non-zero amount
        // [THEN] Work item 359702: Description is equal to "02.01.22 - 31.12.22".
        VerifyFirstServiceLineForServiceContractLine(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", false), InvoiceDate,
          ServContractLine."Starting Date", ServContractHeader."Next Invoice Period End", FullContractLineAmount);
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePartialPrepaidServLine()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        InvoiceDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice] [Prepaid Contract]
        // [SCENARIO 376109] New prepaid service contract line with "Starting Date" after "Next Invoice Period Start" should split by periods when posting
        // Based on SCENARIO 375878 - Service Line created when invoice Prepaid Contract with new Service Contract Line where "Starting Date" after "Next Invoice Period Start"

        // [GIVEN] Signed Prepaid Service Contract (Inv. Period = Year) with single line and Service Invoice for Period "X" with "Next Invoice Period Start"  = 01.01.15 (Annual amount = 100)
        // [GIVEN] New Service Line where "Starting Date" = 05.01.15 added after reopening Service Contract (Line amount for partial period = 95)
        // [GIVEN] Locked Service Contract without additional service invoice and shifting "Next Invoice Period"
        Initialize();
        ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(
          ServContractHeader, ServContractLine, true, 0D, InvoiceDate);

        ExpectedAmount :=
          Round(
            ServContractManagement.CalcContractLineAmount(
              ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractHeader."Next Invoice Period End"));

        // [WHEN] Run Create Service Contract Invoices until the "Next Invoice Period End"
        RunCreateContractInvoices();

        // [THEN] 12 service lines created with total amount = 95
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), InvoiceDate, 12, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePartialPrepaidServLineWithExpDateSamePeriod()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        InvoiceDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice] [Prepaid Contract] [Service Contract Expiration Date]
        // [SCENARIO 376109] New prepaid service contract line with "Starting Date" after "Next Invoice Period Start" and "Contract Expiration Date" in the same period should be posted as one partial period

        // [GIVEN] Signed Prepaid Service Contract (Inv. Period = Year) with single line and Service Invoice for Period "X" with "Next Invoice Period Start"  = 01.01.15 (Annual amount = 100)
        // [GIVEN] New Service Line where "Starting Date" = 05.01.15 and "Expiration Date" = 27.01.15 added after reopening Service Contract (Line amount for partial period = 5)
        // [GIVEN] Locked Service Contract without additional service invoice and shifting "Next Invoice Period"
        Initialize();
        ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(
          ServContractHeader, ServContractLine, true, CalcDate('<CM-3D>', WorkDate()), InvoiceDate);

        ExpectedAmount :=
          Round(
            ServContractManagement.CalcContractLineAmount(
              ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractLine."Contract Expiration Date"));

        // [WHEN] Run Create Service Contract Invoices until the "Contract Expiration Date"
        RunCreateContractInvoices();

        // [THEN] 1 service line created with total amount = 5
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), InvoiceDate, 1, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Invoice] [Prices Incl. VAT]
        // [SCENARIO 377774] Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [WHEN] Create Service Invoice from Service Contract
        SignContractAndCreateServiceInvoice(ServiceContractHeader, true);

        // [THEN] Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceFromContractForCustomerPricesExclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Invoice] [Prices Excl. VAT]
        // [SCENARIO 377774] Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [WHEN] Create Service Invoice from Service Contract
        SignContractAndCreateServiceInvoice(ServiceContractHeader, false);

        // [THEN] Created Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [Invoice] [Prices Incl. VAT]
        // [SCENARIO 377774] Posted Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [GIVEN] Service Invoice created from Service Contract
        // [WHEN] Post Service Invoice
        SignContractAndPostServiceInvoice(ServiceContractHeader, true);

        // [THEN] Posted Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = "A"
        VerifyPostedServiceInvoiceAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceFromContractForCustomerPricesExclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [Invoice] [Prices Excl. VAT]
        // [SCENARIO 377774] Posted Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [GIVEN] Service Invoice created from Service Contract
        // [WHEN] Post Service Invoice
        SignContractAndPostServiceInvoice(ServiceContractHeader, false);

        // [THEN] Posted Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = "A"
        VerifyPostedServiceInvoiceAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Incl. VAT]
        // [SCENARIO 377774] Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [WHEN] Create Service Credit Memo from Service Contract
        SignContractAndPostServiceInvoice(ServiceContractHeader, true);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);

        // [THEN] Created Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoFromContractForCustomerPricesExcllVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Excl. VAT]
        // [SCENARIO 377774] Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [WHEN] Create Service Credit Memo from Service Contract
        SignContractAndPostServiceInvoice(ServiceContractHeader, false);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);

        // [THEN] Created Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Incl. VAT]
        // [SCENARIO 377774] Posted Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [GIVEN] Create Service Credit Memo from Service Contract
        // [WHEN] Post Service Credit Memo
        SignContractAndPostServiceInvoice(ServiceContractHeader, true);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = -"A"
        VerifyPostedServiceCrMemoAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoFromContractForCustomerPricesExclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Excl. VAT]
        // [SCENARIO 377774] Posted Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize();

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [GIVEN] Create Service Credit Memo from Service Contract
        // [WHEN] Post Service Credit Memo
        SignContractAndPostServiceInvoice(ServiceContractHeader, false);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = -"A"
        VerifyPostedServiceCrMemoAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleServLinesGeneratedWhenSignAlreadySignedContractWithNewLine()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        ExpectedAmount: Decimal;
        ContractStartingDate: Date;
    begin
        // [SCENARIO 379870] New prepaid service contract line with "Starting Date" after "Next Invoice Period Start" should split by periods when sign contract
        Initialize();

        // [GIVEN] Signed Service Contract with single line. Invoice Period = Year. Starting Year = 2017
        // [GIVEN] Posted Service Invoice for 2017 year. Next Invoice Period is 2018 year
        ContractStartingDate := CalcDate('<-CM>', WorkDate());
        ScenarioWithSignedAndInvoicedServiceContract(ServContractHeader, ContractStartingDate);

        // [GIVEN] New Service Contract Line added with Starting Date = 01.01.2017, Amount = 100
        AddLineToServiceContractWithSpecificStartingDate(
          ServContractHeader, ServContractLine, ServContractHeader."Next Invoice Period Start" + 1, 0D);
        ExpectedAmount :=
          Round(
            ServContractManagement.CalcContractLineAmount(
              ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractHeader."Last Invoice Period End"));

        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(NewLinesAddedConfirmQst);
        LibraryVariableStorage.Enqueue(CreateInvoiceMsg);

        // [WHEN] Sign Service Contract with new line added
        WorkDate := ServContractLine."Starting Date";
        SignContract(ServContractHeader);

        // [THEN] Posted Service Invoice created with 12 lines (one line = one month) and Total Amount = 100
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true),
          ServContractLine."Starting Date", 12, ExpectedAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoRoundingVarianceOnMultipleServiceInvoiceWithFCYPrepaidContractPositiveVarianceScenario()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustomExchRate: Decimal;
    begin
        // [FEATURE] [FCY] [Rounding]
        // [SCENARIO 379879] Total amount is correct without rounding variance in Service Invoice with multiple lines for Prepaid Service Contract
        Initialize();

        // [GIVEN] Prepaid Service Contract with FCY. Exchange Rate equal 1 / 7.95
        CustomExchRate := 1 / 7.95;
        CreateServiceContractHeaderWithCurrency(
          ServContractHeader, LibrarySales.CreateCustomerNo(),
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CustomExchRate, CustomExchRate));

        // [GIVEN] Service Contract Line has amount 39750
        CreateContractLineWithSpecificAmount(ServContractLine, ServContractHeader, 39750);
        UpdateServContractHeader(ServContractHeader);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(CreateInvoiceMsg);
        SignContract(ServContractHeader);

        LibraryVariableStorage.Enqueue(ServContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");

        // [WHEN] Create Service Invoice
        RunCreateContractInvoices();

        // [THEN] Total amount of multiple Service Lines is 5000 (39750 * 1 / 7.95)
        VerifyServContractLineAmountSplitByPeriod(
                ServContractHeader."Contract No.", ServContractLine."Service Item No.",
                GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true),
                ServContractHeader."Next Invoice Period Start", 12, 5000);

        // [THEN] Some service invoice lines are going to be different.
        FilterServiceLine(ServiceLine, ServContractHeader."Contract No.", GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), WorkDate());
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServContractHeader."Contract No.");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Line Amount", 416.67);
        Assert.AreEqual(8, ServiceLine.Count(), 'Some service invoice lines will have the values rounded up');
        ServiceLine.SetRange("Line Amount", 416.66); // slightly lesser to take care of rounding
        Assert.AreEqual(4, ServiceLine.Count(), 'Some service invoice lines will have the values rounded down');
        ServiceLine.SetRange("Line Amount");
        ServiceLine.FindSet();
        repeat
            Assert.AreEqual(0, ServiceLine."Line Discount Amount", 'Discount should be 0!');
        until ServiceLine.Next() = 0;

        // [GIVEN] First post the previous invoice for this contract
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServContractHeader."Contract No.");
        ServiceHeader.FindFirst();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Post Service Invoice with rounded amounts
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Match the total amount
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.CalcSums(Amount);
        Assert.AreEqual(5000, ServiceInvoiceLine.Amount, '5000 = (39750 * 1 / 7.95)');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoRoundingVarianceOnMultipleServiceInvoiceWithFCYPrepaidContractNegativeVarianceScenario()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustomExchRate: Decimal;
    begin
        // [FEATURE] [FCY] [Rounding]
        // [SCENARIO 379879] Total amount is correct without rounding variance in Service Invoice with multiple lines for Prepaid Service Contract

        Initialize();

        // [GIVEN] Prepaid Service Contract with FCY. Exchange Rate equal 100/64.8824
        CustomExchRate := 100 / 64.8824;
        CreateServiceContractHeaderWithCurrency(
          ServContractHeader, LibrarySales.CreateCustomerNo(),
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CustomExchRate, CustomExchRate));

        // [GIVEN] Service Contract Line has amount 36933
        CreateContractLineWithSpecificAmount(ServContractLine, ServContractHeader, 36933);
        UpdateServContractHeader(ServContractHeader);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(CreateInvoiceMsg);
        SignContract(ServContractHeader);

        WorkDate := ServContractHeader."Next Invoice Period Start";
        LibraryVariableStorage.Enqueue(ServContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");

        // [WHEN] Create Service Invoice
        RunCreateContractInvoices();

        // [THEN] Total amount of multiple Service Lines is 56922.99 (36933 * 100/64.8824)
        VerifyServContractLineAmountSplitByPeriod(
                ServContractHeader."Contract No.", ServContractLine."Service Item No.",
                GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true),
                ServContractHeader."Next Invoice Period Start", 12, 56922.99);

        // [THEN] Some service invoice lines are going to be different.
        FilterServiceLine(ServiceLine, ServContractHeader."Contract No.", GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), WorkDate());
        ServiceLine.SetRange("Line Amount", 4743.58);
        Assert.AreEqual(9, ServiceLine.Count(), 'Some service invoice lines will have the values rounded down');
        ServiceLine.SetRange("Line Amount", 4743.59); // slightly greater to take care of rounding
        Assert.AreEqual(3, ServiceLine.Count(), 'Some service invoice lines will have the values rounded up');
        ServiceLine.SetRange("Line Amount");
        ServiceLine.FindSet();
        repeat
            Assert.AreEqual(0, ServiceLine."Line Discount Amount", 'Discount should be 0!');
        until ServiceLine.Next() = 0;

        // [GIVEN] First post the previous invoice for this contract
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServContractHeader."Contract No.");
        ServiceHeader.FindFirst();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Post Service Invoice with rounded amounts
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Match the total amount
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.CalcSums(Amount);
        Assert.AreEqual(56922.99, ServiceInvoiceLine.Amount, '56922.99 = (36933 * 100/64.8824)');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,CreateContractInvoicesRequestPageHandler,MessageHandler,ServiceContractTemplateListHandler2')]
    [Scope('OnPrem')]
    procedure ServContractLineWithZeroAmountAndLineDiscCopiesToServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItemNo: array[3] of Code[20];
    begin
        // [SCENARIO 220762] Posted Service Invoice must contains correct amounts of discount after creating from Service Contract if Service Contract Line contains 100% discount
        Initialize();

        // [GIVEN] Signed Service Contract with 3 lines:
        // [GIVEN] The first line - "Discount %" = 100
        // [GIVEN] The second line - "Discount %" = 50
        // [GIVEN] The third line - "Discount %" = 0
        CreateServiceContractWithLinesWithDiscount(ServiceContractHeader, ServiceItemNo);
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        ServiceLedgerEntry.DeleteAll();

        // [GIVEN] Create Service Invoice from Service Contract
        RunCreateContractInvoices();

        // [WHEN] Post Service Invoice
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");

        // [THEN] Posted Service Invoice contains lines:
        // [THEN] The first line - "Discount %" = 100
        VerifyPostedServiceInvoiceDiscount(ServiceContractHeader."Customer No.", ServiceItemNo[1], 100);

        // [THEN] The second line - "Discount %" = 50.00001
        VerifyPostedServiceInvoiceDiscount(ServiceContractHeader."Customer No.", ServiceItemNo[2], 50.00001);

        // [THEN] The third line - "Discount %" = 0
        VerifyPostedServiceInvoiceDiscount(ServiceContractHeader."Customer No.", ServiceItemNo[3], 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConditionalNextPlannedDateConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractEmptyNextPlannedServiceDateConfirmationFalse()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO 303847] Answering "No" to confirmation dialog about empty "Next Planned Service Date" cancels signing the contract
        Initialize();

        // [GIVEN] Created Service Contract with one Line
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), 1);
        Commit();

        // [GIVEN] "Next Planned Service Date" empty on the Service Contract Line
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Next Planned Service Date", 0D);
        ServiceContractLine.Modify(true);

        // [WHEN] Sign contract and answer "No" to empty "Next Planned Service Date" confirmation dialog
        SignContract(ServiceContractHeader);

        // [THEN] No messages are shown
        // [THEN] Service contract is not signed
        VerifyServiceContractStatus(
          ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceContractHeader.Status::" ");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractEmptyNextPlannedServiceDateConfirmationTrue()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO 303847] Answering "Yes" to confirmation dialog about empty "Next Planned Service Date" allows signing the contract
        Initialize();

        // [GIVEN] Created Service Contract with one Line
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), 1);
        Commit();

        // [GIVEN] "Next Planned Service Date" empty on the Service Contract Line
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Next Planned Service Date", 0D);
        ServiceContractLine.Modify(true);

        // [WHEN] Sign contract and answer "Yes" to empty "Next Planned Service Date" confirmation dialog
        SignContract(ServiceContractHeader);

        // [THEN] Message "Service Invoice SCI0000022 was created."
        // [THEN] Service contract is signed
        VerifyServiceContractStatus(
          ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceContractHeader.Status::Signed);
    end;

    [Test]
    [HandlerFunctions('DoNotCreateContrUsingTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateServHeaderWithBillToSellToVATCalcSetToBillToPayToNo()
    var
        Customer: array[2] of Record Customer;
        GLSetup: Record "General Ledger Setup";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 326175] When creating Service Invoice from Service Contract fields affecting VAT is taken from Bill-to Customer if "Bill-to/Sell-to VAT Calc." is set to "Bill-to/Pay-to No.".
        Initialize();

        LibraryERM.SetBillToSellToVATCalc(GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        CreateCustomerWithGenBusPostingGroup(Customer[1]);
        CreateCustomerWithGenBusPostingGroup(Customer[2]);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer[1]."No.");
        ServiceContractHeader.Validate("Bill-to Customer No.", Customer[2]."No.");
        ServiceContractHeader.Modify(true);

        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice, ServContractManagement.CreateServHeader(ServiceContractHeader, WorkDate(), true));

        Assert.AreEqual(Customer[2]."VAT Bus. Posting Group", ServiceHeader."VAT Bus. Posting Group", '');
        Assert.AreEqual(Customer[2]."VAT Registration No.", ServiceHeader."VAT Registration No.", '');
        Assert.AreEqual(Customer[2]."Country/Region Code", ServiceHeader."VAT Country/Region Code", '');
        Assert.AreEqual(Customer[2]."Gen. Bus. Posting Group", ServiceHeader."Gen. Bus. Posting Group", '');
    end;

    [Test]
    [HandlerFunctions('DoNotCreateContrUsingTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateServHeaderWithBillToSellToVATCalcSetToSellToBuyFromNo()
    var
        Customer: array[2] of Record Customer;
        GLSetup: Record "General Ledger Setup";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 326175] When creating Service Invoice from Service Contract fields affecting VAT are taken from Sell-to Customer if "Bill-to/Sell-to VAT Calc." is set to "Sell-to/Buy-from No.".
        Initialize();

        LibraryERM.SetBillToSellToVATCalc(GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        CreateCustomerWithGenBusPostingGroup(Customer[1]);
        CreateCustomerWithGenBusPostingGroup(Customer[2]);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer[1]."No.");
        ServiceContractHeader.Validate("Bill-to Customer No.", Customer[2]."No.");
        ServiceContractHeader.Modify(true);

        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice, ServContractManagement.CreateServHeader(ServiceContractHeader, WorkDate(), true));

        Assert.AreEqual(Customer[1]."VAT Bus. Posting Group", ServiceHeader."VAT Bus. Posting Group", '');
        Assert.AreEqual(Customer[1]."VAT Registration No.", ServiceHeader."VAT Registration No.", '');
        Assert.AreEqual(Customer[1]."Country/Region Code", ServiceHeader."VAT Country/Region Code", '');
        Assert.AreEqual(Customer[1]."Gen. Bus. Posting Group", ServiceHeader."Gen. Bus. Posting Group", '');
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartMonthInvCreatedForPrepaidServContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractStartingDate: Date;
        PartMonthAmount: Decimal;
    begin
        // [FEATURE] [Prepaid Contract]
        // [SCENARIO 360045] Create Service Invoice by report "Create Service Contract Invoices" in case Starting Date of prepaid Contract is not the first day of month and Service Invoice for part of month exists.
        Initialize();
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Prepaid Service Contract with Starting Date = 10.02.22 and Invoice Period = Year; Contract has one line with Line Amount = 120.
        // [GIVEN] Stan accepted to create Service Invoice for period 10.02.22 - 28.02.22 when he signed contract.
        CreateServiceContractWithLine(
          ServiceContractHeader, ServiceContractLine, ContractStartingDate, 0D, ServiceContractHeader."Invoice Period"::Year, true);
        SignContractSilent(ServiceContractHeader);
        PartMonthAmount :=
          CalcContractLineAmount(
            ServiceContractLine."Line Amount", ServiceContractLine."Starting Date", ServiceContractHeader."Next Invoice Period Start" - 1);
        VerifyFirstServiceLineForServiceContractLine(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true), ServiceContractHeader."Starting Date",
          ServiceContractHeader."Starting Date", CalcDate('<CM>', ServiceContractHeader."Starting Date"), PartMonthAmount);

        // [WHEN] Run report "Create Service Contract Invoices" on Service Contract, set Posting Date = 27.01.22, InvoiceToDate = 01.03.22.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] 12 Service Ledger Entries are created, each line is for one month of Invoice Period 01.03.22 - 28.02.23 and has Amount = 120/12.
        // [THEN] Service Invoice with 12 Service Lines is created, each line is for one month of Invoice Period 01.03.22 - 28.02.23 and has Amount = 120/12.
        VerifyServContractLineAmountSplitByPeriod(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
          WorkDate(), 12, ServiceContractLine."Line Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartMonthInvCreatedForPrepaidServContractWithExpDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        FullContractLineAmount: Decimal;
        PartMonthAmount: Decimal;
    begin
        // [FEATURE] [Prepaid Contract]
        // [SCENARIO 360045] Create Service Invoice by report "Create Service Contract Invoices" in case Starting Date of prepaid Contract is not the first day of month and Service Invoice for part of month exists.
        // [SCENARIO 360045] Expiration Date is set.
        Initialize();
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);
        ContractExpirationDate := CalcDate('<6M-1D>', ContractStartingDate);

        // [GIVEN] Prepaid Service Contract with Starting Date = 10.02.22, Expiration Date = 09.08.22 and Invoice Period = Year; Contract has one line with Line Amount = 120.
        // [GIVEN] Stan accepted to create Service Invoice for period 10.02.22 - 28.02.22 when he signed contract.
        CreateServiceContractWithLine(
          ServiceContractHeader, ServiceContractLine, ContractStartingDate,
          ContractExpirationDate, ServiceContractHeader."Invoice Period"::Year, true);
        SignContractSilent(ServiceContractHeader);
        FullContractLineAmount :=
          CalcContractLineAmount(
            ServiceContractLine."Line Amount", ServiceContractLine."Starting Date", ServiceContractHeader."Expiration Date");
        PartMonthAmount :=
          CalcContractLineAmount(
            ServiceContractLine."Line Amount", ServiceContractLine."Starting Date", ServiceContractHeader."Next Invoice Period Start" - 1);
        VerifyFirstServiceLineForServiceContractLine(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true), ServiceContractHeader."Starting Date",
          ServiceContractHeader."Starting Date", CalcDate('<CM>', ServiceContractHeader."Starting Date"), PartMonthAmount);

        // [WHEN] Run report "Create Service Contract Invoices" on Service Contract, set Posting Date = 27.01.22, InvoiceToDate = 01.03.22.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] The first 5 Service Ledger Entries and Service Lines are for each month of Invoice Period 01.03.22 - 31.07.22, each line has Amount = 120/12.
        // [THEN] The last Service Ledger Entry and Service Line is for period 01.08.22 - 09.08.22 and has Amount = (120/12)*(9/31).
        VerifyServContractLineAmountSplitByPeriod(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
          WorkDate(), 6, FullContractLineAmount - PartMonthAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SignContractYesConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartMonthForNonPrepaidServContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractStartingDate: Date;
        FullContractLineAmount: Decimal;
    begin
        // [FEATURE] [Non-Prepaid Contract]
        // [SCENARIO 360045] Create Service Invoice by report "Create Service Contract Invoices" in case Starting Date of non-prepaid Contract is not the first day of month.
        // [SCENARIO 359702] Service Line Description contains contract Starting Date, so Description is equal to "10.02.22 - 28.02.23".
        Initialize();
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Signed non-prepaid Service Contract with Starting Date = 10.02.22 and Invoice Period = Year; Contract has one line with Line Amount = 120.
        CreateServiceContractWithLine(
          ServiceContractHeader, ServiceContractLine, ContractStartingDate, 0D, ServiceContractHeader."Invoice Period"::Year, false);
        SignContract(ServiceContractHeader);
        FullContractLineAmount :=
          CalcContractLineAmount(
            ServiceContractLine."Line Amount", ServiceContractLine."Starting Date", ServiceContractHeader."Next Invoice Period End");

        // [WHEN] Run report "Create Service Contract Invoices" on Service Contract, set Posting Date = 27.01.22, InvoiceToDate = 01.03.22.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] Service Ledger Entry for period 10.02.22 - 28.02.23 is created, Amount is equal to sum of amount for period 10.02.22 - 28.02.22 and Annual Amount, (120/12)*(19/28) + 120.
        // [THEN] Service Invoice with one Service Line for period 10.02.22 - 28.02.23 is created, Amount = (120/12)*(19/28) + 120.
        // [THEN] Work item 359702: Description = "10.02.22 - 28.02.23".
        VerifyFirstServiceLineForServiceContractLine(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true), WorkDate(),
          ServiceContractHeader."Starting Date", ServiceContractHeader."Next Invoice Period End", FullContractLineAmount);

        VerifyServContractLineAmountSplitByPeriod(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
          WorkDate(), 1, FullContractLineAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartMonthInvCreatedForNonPrepaidServContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractStartingDate: Date;
        PartMonthAmount: Decimal;
    begin
        // [FEATURE] [Non-Prepaid Contract]
        // [SCENARIO 360045] Create Service Invoice by report "Create Service Contract Invoices" in case Starting Date of non-prepaid Contract is not the first day of month and Service Invoice for part of month exists.
        Initialize();
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Non-prepaid Service Contract with Starting Date = 10.02.22 and Invoice Period = Year; Contract has one line with Line Amount = 120.
        // [GIVEN] Stan accepted to create Service Invoice for period 10.02.22 - 28.02.22 when he signed contract.
        CreateServiceContractWithLine(
          ServiceContractHeader, ServiceContractLine, ContractStartingDate, 0D, ServiceContractHeader."Invoice Period"::Year, false);
        SignContractSilent(ServiceContractHeader);
        PartMonthAmount :=
          CalcContractLineAmount(
            ServiceContractLine."Line Amount", ServiceContractLine."Starting Date", ServiceContractHeader."Next Invoice Period Start" - 1);
        VerifyFirstServiceLineForServiceContractLine(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true), ServiceContractHeader."Starting Date",
          ServiceContractHeader."Starting Date", CalcDate('<CM>', ServiceContractHeader."Starting Date"), PartMonthAmount);

        // [WHEN] Run report "Create Service Contract Invoices" on Service Contract, set Posting Date = 27.01.22, InvoiceToDate = 01.03.22.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] Service Ledger Entry for period 01.03.22 - 28.02.23 is created, Amount = 120.
        // [THEN] Service Invoice with one Service Line for period 01.03.22 - 28.02.23 is created, Amount = 120.
        VerifyServContractLineAmountSplitByPeriod(
          ServiceContractHeader."Contract No.", ServiceContractLine."Service Item No.",
          GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
          WorkDate(), 1, ServiceContractLine."Line Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContractLinesOnDescriptionServiceItemSerialNo()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ExpectedDescription: Text[100];
    begin
        // [SCENARIO 359493] Service Invoice contains a line with Service Item No., contract line Description and Service Item Serial No.
        Initialize();

        // [GIVEN] Signed prepaid Service Contract with Contract Lines On Description set.
        // [GIVEN] Service Contract Line with Service Item = "SI", Description = "DN", Service Item Serial No. = "SNO".
        CreateServiceContractWithLine(
            ServiceContractHeader, ServiceContractLine, CalcDate('<CM + 1D>', WorkDate()), 0D, ServiceContractHeader."Invoice Period"::Month, true);
        UpdateServiceContractLineDescription(ServiceContractLine, LibraryUtility.GenerateGUID());
        SignContractSilent(ServiceContractHeader);

        // [WHEN] Create Service Invoice for Service Contract.
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] Service Invoice contains a line with Description = "SI DN SNO".
        ExpectedDescription :=
            StrSubstNo('%1 %2 %3', ServiceContractLine."Service Item No.", ServiceContractLine.Description, ServiceContractLine."Serial No.");
        VerifyContractLinesOnInvoiceDescription(ServiceContractHeader."Contract No.", ServiceContractHeader."Next Invoice Date", ExpectedDescription);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContractLinesOnDescriptionServiceItemSerialNoOverflow()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        DummyServiceLine: Record "Service Line";
        ExpectedFullDescription: Text;
        ExpectedDescription: Text[100];
    begin
        // [SCENARIO 359493] Service Invoice contains two lines with Service Item No., contract line Description and Service Item Serial No. in case of text overflow.
        Initialize();

        // [GIVEN] Signed prepaid Service Contract with Contract Lines On Description set.
        // [GIVEN] Service Contract Line with Service Item = "SI", Description = "DNXXXXX", Service Item Serial No. = "SNO".
        // [GIVEN] Description value of Service Contract Line has its maxiumum length.
        CreateServiceContractWithLine(
            ServiceContractHeader, ServiceContractLine, CalcDate('<CM + 1D>', WorkDate()), 0D, ServiceContractHeader."Invoice Period"::Month, true);
        UpdateServiceContractLineDescription(ServiceContractLine, LibraryUtility.GenerateRandomXMLText(MaxStrLen(ServiceContractLine.Description)));
        SignContractSilent(ServiceContractHeader);

        // [WHEN] Create Service Invoice for Service Contract.
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] Service Invoice contains two lines with overall Description = "SI DNXXXXX SNO".
        // [THEN] Description is devided into two parts - the first one contains first 100 chars, the second one contains remaining part.
        ExpectedFullDescription :=
            StrSubstNo('%1 %2 %3', ServiceContractLine."Service Item No.", ServiceContractLine.Description, ServiceContractLine."Serial No.");

        ExpectedDescription := CopyStr(ExpectedFullDescription, 1, MaxStrLen(DummyServiceLine.Description));
        VerifyContractLinesOnInvoiceDescription(ServiceContractHeader."Contract No.", ServiceContractHeader."Next Invoice Date", ExpectedDescription);

        ExpectedDescription := CopyStr(ExpectedFullDescription, MaxStrLen(DummyServiceLine.Description) + 1);
        VerifyContractLinesOnInvoiceDescription(ServiceContractHeader."Contract No.", ServiceContractHeader."Next Invoice Date", ExpectedDescription);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunUpdateContractPricesReportOnServContractInvoicePeriodNone()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        PriceChangePercent: Decimal;
        AnnualAmount: Decimal;
    begin
        // [SCENARIO 392187] Run report "Update Service Contract Prices" on signed Service Contract with Invoice Period = None.
        Initialize();

        // [GIVEN] Signed Service Contract with Invoice Period = "None".
        CreateServiceContractWithLine(
          ServiceContractHeader, ServiceContractLine, CalcDate('<-CM - 1Y>', WorkDate()), 0D,
          ServiceContractHeader."Invoice Period"::None, false);
        SignContractSilent(ServiceContractHeader);
        AnnualAmount := ServiceContractHeader."Annual Amount";

        // [WHEN] Run report "Update Service Contract Prices" on Service Contract, set "Price Update %" = 5.
        PriceChangePercent := LibraryRandom.RandDecInRange(3, 9, 2);
        RunUpdateContractPricesReport(ServiceContractHeader, PriceChangePercent);

        // [THEN] Report run without errors. "Annual Amount" increased by 5%, "Amount per Period" remains 0.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField(
          "Annual Amount", Round(AnnualAmount + (AnnualAmount * PriceChangePercent / 100), LibraryERM.GetAmountRoundingPrecision()));
        ServiceContractHeader.TestField("Amount per Period", 0);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunUpdateContractPricesReportOnServContractInvoicePeriodHalfYear()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        PriceChangePercent: Decimal;
        AnnualAmount: Decimal;
    begin
        // [SCENARIO 392187] Run report "Update Service Contract Prices" on signed Service Contract with Invoice Period = Half Year.
        Initialize();

        // [GIVEN] Signed Service Contract with Invoice Period = "Half Year".
        CreateServiceContractWithLine(
          ServiceContractHeader, ServiceContractLine, CalcDate('<-CM - 1Y>', WorkDate()), 0D,
          ServiceContractHeader."Invoice Period"::"Half Year", false);
        SignContractSilent(ServiceContractHeader);
        AnnualAmount := ServiceContractHeader."Annual Amount";

        // [WHEN] Run report "Update Service Contract Prices" on Service Contract, set "Price Update %" = 5.
        PriceChangePercent := LibraryRandom.RandDecInRange(3, 9, 2);
        RunUpdateContractPricesReport(ServiceContractHeader, PriceChangePercent);

        // [THEN] Report run without errors. "Annual Amount" increased by 5%, "Amount per Period" = "Annual Amount" / 2.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField(
          "Annual Amount", Round(AnnualAmount + (AnnualAmount * PriceChangePercent / 100), LibraryERM.GetAmountRoundingPrecision()));
        ServiceContractHeader.TestField(
          "Amount per Period", Round(ServiceContractHeader."Annual Amount" / 2, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('Scenario421481ConfirmHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunCreateContractInvoicesForSignedContractWithNoInvoiceCreatedBefore()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceDocumentRegister: Record "Service Document Register";
    begin
        // [SCENARIO 421481] Create Service Contract Invoice run without error after contract signed without creating invoice
        Initialize();

        // [GIVEN] Prepaid Service Contract with Contract Line 
        CreateServiceContractWithLine(
            ServiceContractHeader, ServiceContractLine, CalcDate('<CM>', WorkDate()), 0D, ServiceContractHeader."Invoice Period"::Month, true);
        // [GIVEN] Sign contract without creating invoice
        SignContract(ServiceContractHeader);

        // [WHEN] Run Create Service Contract Invoice
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [THEN] Contract invoice created without error
        ServiceDocumentRegister.SetRange("Source Document No.", ServiceContractHeader."Contract No.");
        ServiceDocumentRegister.SetRange("Source Document Type", "Service Source Document Type"::Contract);
        ServiceDocumentRegister.SetRange("Destination Document Type", "Service Destination Document Type"::Invoice);
        Assert.RecordIsNotEmpty(ServiceDocumentRegister);
    end;

    [Test]
    [HandlerFunctions('SignContractYesConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartMonthForPrepaidServContractWithExpDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        FullContractLineAmount: Decimal;
        FirstMonthAmount: Decimal;
        LastMonthAmount: Decimal;
    begin
        // [SCENARIO 479307] Create a service invoice by report "Create Service Contract Invoices" in case the starting date of the prepaid contract is not the first day of the month and the expiration date is set.
        Initialize();

        // [GIVEN] Create the contract's starting date and expiration date.
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);
        ContractExpirationDate := CalcDate('<6M-1D>', ContractStartingDate);

        // [GIVEN] Create a service contract with an invoice period of "Year".
        CreateServiceContractWithLine(
            ServiceContractHeader,
            ServiceContractLine,
            ContractStartingDate,
            ContractExpirationDate,
            ServiceContractHeader."Invoice Period"::Year,
            true);

        // [GIVEN] Sign a contract.
        SignContract(ServiceContractHeader);

        // [GIVEN] Save a contract amount , the first and last month's contract amount.
        FullContractLineAmount := CalcContractLineAmount(
            ServiceContractLine."Line Amount",
            ServiceContractLine."Starting Date",
            ServiceContractHeader."Expiration Date");

        FirstMonthAmount := CalcContractLineAmount(
            ServiceContractLine."Line Amount",
            ServiceContractLine."Starting Date",
            ServiceContractHeader."Next Invoice Period Start" - 1);

        LastMonthAmount := CalcContractLineAmount(
            ServiceContractLine."Line Amount",
            CalcDate('<-CM>', ContractExpirationDate),
            ContractExpirationDate);

        // [WHEN] Run the report "Create Service Contract Invoices" on Service Contract.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [VERIFY] Verify the amount of service line for the first month of the contract.
        VerifyFirstServiceLineForServiceContractLine(
            ServiceContractHeader."Contract No.",
            ServiceContractLine."Service Item No.",
            GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
            WorkDate(),
            ServiceContractHeader."Starting Date",
            CalcDate('<CM>', ServiceContractHeader."Starting Date"),
            FirstMonthAmount);

        // [VERIFY] Verify the amount and count of service line.
        VerifyServContractLineAmountSplitByPeriod(
            ServiceContractHeader."Contract No.",
            ServiceContractLine."Service Item No.",
            GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
            WorkDate(),
            LibraryRandom.RandIntInRange(7, 7),
            FullContractLineAmount);

        // [WHEN] Filter Service Line.
        FilterServiceLine(
            ServiceLine,
            ServiceContractHeader."Contract No.",
            GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
            WorkDate());

        // [VERIFY] Verify the amount of service line for the last month of the contract.
        ServiceLine.FindLast();
        Assert.AreEqual(
            ServiceLine.Amount,
            LastMonthAmount,
            StrSubstNo(
                ValueMustBeEqualErr,
                ServiceLine.FieldCaption(Amount),
                LastMonthAmount,
                ServiceLine.TableCaption()));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SignContractYesConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartMonthForPrepaidServContractWithoutExpDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        ContractStartingDate: Date;
        FirstMonthAmount: Decimal;
        LastMonthAmount: Decimal;
    begin
        // [SCENARIO 479307] Create a service invoice by report "Create Service Contract Invoices" in case the starting date of the prepaid contract is not the first day of the month and the expiration date is blank.
        Initialize();

        // [GIVEN] Create the contract's starting date.
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Create a service contract with an invoice period of "Year".
        CreateServiceContractWithLine(
            ServiceContractHeader,
            ServiceContractLine,
            ContractStartingDate,
            ServiceContractHeader."Expiration Date",
            ServiceContractHeader."Invoice Period"::Year,
            true);

        // [GIVEN] Sign a contract.
        SignContract(ServiceContractHeader);

        // [GIVEN] Save a first and last month's contract amount.
        FirstMonthAmount := CalcContractLineAmount(
            ServiceContractLine."Line Amount",
            ServiceContractLine."Starting Date",
            ServiceContractHeader."Next Invoice Period Start" - 1);

        LastMonthAmount := CalcContractLineAmount(
            ServiceContractLine."Line Amount",
            CalcDate('<1Y-CM>', ServiceContractLine."Starting Date"),
            CalcDate('<1Y+CM>', ServiceContractLine."Starting Date"));

        // [WHEN] Run the report "Create Service Contract Invoices" on Service Contract.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [VERIFY] Verify the amount of service line for the first month of the contract.
        VerifyFirstServiceLineForServiceContractLine(
            ServiceContractHeader."Contract No.",
            ServiceContractLine."Service Item No.",
            GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
            WorkDate(),
            ServiceContractHeader."Starting Date",
            CalcDate('<CM>', ServiceContractHeader."Starting Date"),
            FirstMonthAmount);

        // [WHEN] Filter Service Line.
        FilterServiceLine(
            ServiceLine,
            ServiceContractHeader."Contract No.",
            GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
            WorkDate());

        // [VERIFY] Verify the amount of service line for the last month of the contract.
        ServiceLine.FindLast();
        Assert.AreEqual(
            ServiceLine.Amount,
            LastMonthAmount,
            StrSubstNo(
                ValueMustBeEqualErr,
                ServiceLine.FieldCaption(Amount),
                LastMonthAmount,
                ServiceLine.TableCaption()));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SignContractYesConfirmHandler,CreateContractInvoicesDiffDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesForPrepaidServContractWithoutExpDateAndPeriodQuarterly()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractStartingDate: Date;
        FirstMonthAmount: Decimal;
    begin
        // [SCENARIO 479307] Create a service invoice by report "Create Service Contract Invoices" in case the starting date of the prepaid contract is not the first day of the month and the expiration date is blank.
        Initialize();

        // [GIVEN] Create the contract's starting date.
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Create a service contract with an invoice period of "Quarter".
        CreateServiceContractWithLine(
            ServiceContractHeader,
            ServiceContractLine,
            ContractStartingDate,
            ServiceContractHeader."Expiration Date",
            ServiceContractHeader."Invoice Period"::Quarter,
            true);

        // [GIVEN] Sign a contract.
        SignContract(ServiceContractHeader);

        // [GIVEN] Save a first month contract amount.
        FirstMonthAmount := CalcContractLineAmount(
            ServiceContractLine."Line Amount",
            ServiceContractLine."Starting Date",
            ServiceContractHeader."Next Invoice Period Start" - 1);

        // [WHEN] Run the report "Create Service Contract Invoices" on Service Contract.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // [VERIFY] Verify the amount of service line for the first month of the contract.
        VerifyFirstServiceLineForServiceContractLine(
            ServiceContractHeader."Contract No.",
            ServiceContractLine."Service Item No.",
            GetServContractGLAcc(ServiceContractHeader."Serv. Contract Acc. Gr. Code", true),
            WorkDate(),
            ServiceContractHeader."Starting Date",
            CalcDate('<CM>', ServiceContractHeader."Starting Date"),
            FirstMonthAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServContractInvoicesPartialYearForPrepaidServContractWithExpDate()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        ServicePriceGroup: Record "Service Price Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceContract: TestPage "Service Contract";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        DefaultContractValue: Decimal;
        Description: Text[100];
    begin
        // [SCENARIO 489462] When Creating Service Invoice for a partial year prepaid contract, the invoice is not allocated out to the full end of the Contract's Expiration Date.
        Initialize();

        // [GIVEN] Generate and Save Contract Starting date in a Variable.
        ContractStartingDate := CalcDate('<-CM+14D>', WorkDate());

        // [GIVEN] Generate and Save Contract Expiration date in a Variable.
        ContractExpirationDate := CalcDate('<CM+7M+1D>', ContractStartingDate);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item Group.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);

        // [GIVEN] Create a Service Price Group.
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);

        // [GIVEN] Generate and save Default Contract Value in a Variable.
        DefaultContractValue := LibraryRandom.RandDecInRange(3000, 4000, 0);

        // [GIVEN] Create a Service Item.
        CreateServiceItemAndValidateFields(
            ServiceItem,
            Customer."No.",
            ServiceItemGroup.Code,
            ServicePriceGroup.Code,
            DefaultContractValue,
            ContractStartingDate);

        // [GIVEN] Create a Service Contract Header.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        CreateServiceContractHeaderAndValidateFields(
            ServiceContractHeader,
            Customer."No.",
            ContractStartingDate,
            ContractExpirationDate);

        // [GIVEN] Create a Service Contract Line.
        CreateServiceContractLineAndValidateFields(
            ServiceContractLine,
            ServiceContractHeader,
            ServiceItem."No.",
            DefaultContractValue,
            ContractStartingDate,
            ContractExpirationDate);

        // [GIVEN] Validate Allow Unbalanced Amounts, Annual Amount 
        // And Invoice Period in Service Contract Header.
        ServiceContractHeader.Validate("Allow Unbalanced Amounts", false);
        ServiceContractHeader.Validate("Annual Amount", DefaultContractValue);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Change WorkDate.
        WorkDate(CalcDate('<CM+2D>', ContractStartingDate));

        // [GIVEN] Lock Service Contract.
        LockOpenServContract.LockServContract(ServiceContractHeader);

        // [GIVEN] Sign Service Contract.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Open Service Contract page and run Create Service Contract action.
        ServiceContract.OpenEdit();
        ServiceContract.GoToRecord(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        ServiceContract.CreateServiceInvoice.Invoke();

        // [GIVEN] Generate and save Description in a Variable.
        Description := StrSubstNo(
            DescriptionLbl,
            CalcDate('<-CM>', ContractExpirationDate),
            ContractExpirationDate);

        // [WHEN] Find last Service Invoice Line.
        FindlastServiceLine(ServiceContractHeader, ServiceHeader, ServiceLine);

        // [VERIFY] Verify last Service Line is of Start and End Date of Expiration Date month.
        Assert.AreEqual(ServiceLine.Description, Description, DescriptionMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,ServiceContractConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServInvoiceLineFromContractWithYearForPrepaidServContractWithExpDate()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        ServicePriceGroup: Record "Service Price Group";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceContract: TestPage "Service Contract";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        DefaultContractValue: Decimal;
        FirstMonthExpectedAmount: Decimal;
        SecondMonthExpectedAmount: Decimal;
        LastMonthExpectedAmount: Decimal;
    begin
        // [SCENARIO 498661] When creating a Service Invoice from a Prepaid Service Contract, the values are wrong only when the Contract has ‘Contract Lines on Invoice’ = FALSE
        Initialize();

        // [GIVEN] Generate and Save Contract Starting date in a Variable.
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Generate and Save Contract Expiration date in a Variable.
        ContractExpirationDate := CalcDate('<1Y>', ContractStartingDate);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item Group.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);

        // [GIVEN] Create a Service Price Group.
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);

        // [GIVEN] Generate and save Default Contract Value in a Variable.
        DefaultContractValue := LibraryRandom.RandDecInRange(1000, 2000, 0);

        // [GIVEN] Create a Service Item.
        CreateServiceItemAndValidateFields(
            ServiceItem,
            Customer."No.",
            ServiceItemGroup.Code,
            ServicePriceGroup.Code,
            DefaultContractValue,
            ContractStartingDate);

        // [GIVEN] Create a Service Contract Header.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, true));
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));

        // [GIVEN] Update Starting Date and Expiration Date in a Service Contract Header
        ServiceContractHeader.Validate("Starting Date", ContractStartingDate);
        ServiceContractHeader."Expiration Date" := ContractExpirationDate;
        ServiceContractHeader.Modify();

        // [GIVEN] Create a Service Contract Line.
        CreateServiceContractLineAndValidateFields(
            ServiceContractLine,
            ServiceContractHeader,
            ServiceItem."No.",
            DefaultContractValue,
            ContractStartingDate,
            ContractExpirationDate);

        // [GIVEN] Validate Annual Amount, Invoice Period and "Contract Lines on Invoice" as false in Service Contract Header.
        ServiceContractHeader.Validate("Annual Amount", DefaultContractValue);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate("Contract Lines on Invoice", false);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract but do not create invoice
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Change WorkDate to next month
        WorkDate(CalcDate('<CM+1D>', ContractStartingDate));

        // [GIVEN] Open Service Contract page and run Create Service Invoice action.
        ServiceContract.OpenView();
        ServiceContract.GoToRecord(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        ServiceContract.CreateServiceInvoice.Invoke();

        // [GIVEN] Generate different months line amount in the Variable.
        FirstMonthExpectedAmount := CalcContractLineAmount(DefaultContractValue, ContractStartingDate, CalcDate('<CM>', ContractStartingDate));
        SecondMonthExpectedAmount := CalcContractLineAmount(DefaultContractValue, WorkDate(), CalcDate('<CM>', WorkDate()));
        LastMonthExpectedAmount := CalcContractLineAmount(DefaultContractValue, CalcDate('<-CM>', ContractExpirationDate), ContractExpirationDate);

        // [WHEN] Find first Service Invoice Line.
        FindFirstServiceLine(ServiceContractHeader, ServiceHeader, ServiceLine);

        // [THEN] Verify Service Line - Line Amount field of first, second and last month
        Assert.AreNearlyEqual(FirstMonthExpectedAmount, ServiceLine."Line Amount", 0.01, '');
        ServiceLine.Next();
        Assert.AreNearlyEqual(SecondMonthExpectedAmount, ServiceLine."Line Amount", 0.01, '');
        ServiceLine.FindLast();
        Assert.AreNearlyEqual(LastMonthExpectedAmount, ServiceLine."Line Amount", 0.01, '');
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,ServiceContractConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServiceLineFromContractWithoutDuplicateEntries()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItem1: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        ServicePriceGroup: Record "Service Price Group";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLine1: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        ServiceContract: TestPage "Service Contract";
        ContractStartingDate: Date;
        DefaultContractValue: Decimal;
        DefaultContractValue1: Decimal;
    begin
        // [SCENARIO 497522] Duplicated Service Invoice Lines for Service Item created from Service Contract
        Initialize();

        // [GIVEN] Generate and Save Contract Starting date in a Variable.
        ContractStartingDate := CalcDate('<-CY>', WorkDate());

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item Group.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);

        // [GIVEN] Create a Service Price Group.
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);

        // [GIVEN] Generate and save two Default Contract Values in  Variable.
        DefaultContractValue := LibraryRandom.RandDecInRange(100, 150, 0);
        DefaultContractValue1 := LibraryRandom.RandDecInRange(150, 200, 0);

        // [GIVEN] Create two Service Items with different Default Contract Values
        CreateServiceItemAndValidateFields(
            ServiceItem,
            Customer."No.",
            ServiceItemGroup.Code,
            ServicePriceGroup.Code,
            DefaultContractValue,
            0D);

        CreateServiceItemAndValidateFields(
            ServiceItem1,
            Customer."No.",
            ServiceItemGroup.Code,
            ServicePriceGroup.Code,
            DefaultContractValue1,
            0D);

        // [GIVEN] Create a Service Contract Header.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        CreateServiceContractTemplate(ServiceContractTemplate, '<1M>', ServiceContractHeader."Invoice Period"::Month, true, true, true);
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");

        // [GIVEN] Update Starting Date and Invoice Period in a Service Contract Header
        ServiceContractHeader.Validate("Starting Date", ContractStartingDate);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Modify();

        // [GIVEN] Create a Service Contract Line.
        CreateServiceContractLineAndValidateFields(
            ServiceContractLine,
            ServiceContractHeader,
            ServiceItem."No.",
            DefaultContractValue,
            ContractStartingDate,
            0D);

        // [GIVEN] Sign Service Contract 
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Open Service Contract page and run Create Service Invoice action.
        ServiceContract.OpenView();
        ServiceContract.GoToRecord(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        ServiceContract.CreateServiceInvoice.Invoke();
        ServiceContract.Close();

        // [GIVEN] Post the Service Invoice
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");

        // [GIVEN] Open the Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);

        // [GIVEN] Add new Service Contract Line
        CreateServiceContractLineAndValidateFields(
            ServiceContractLine1,
            ServiceContractHeader,
            ServiceItem1."No.",
            DefaultContractValue1,
            ContractStartingDate,
            0D);

        // [GIVEN] Lock the Service Contract, but do not create invoice
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LockOpenServContract.LockServContract(ServiceContractHeader);

        // [GIVEN] Change WorkDate to Next Year
        WorkDate(CalcDate('<1Y>', ContractStartingDate));

        // [WHEN] Create Service Invoice, but do not invoice for the previous period
        ServiceContract.OpenView();
        ServiceContract.GoToRecord(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        ServiceContract.CreateServiceInvoice.Invoke();

        // [THEN] No Duplicate entries should be created for new service item added
        Assert.AreEqual(24, CountofUnpostedServiceLines(ServiceContractHeader), WrongCountErr);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,ServiceContractConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServInvoiceLineFromContractWithLeapYearForMonthWiseCalculation()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        ServicePriceGroup: Record "Service Price Group";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceContract: TestPage "Service Contract";
        ContractStartingDate: Date;
        ContractExpirationDate: Date;
        DefaultContractValue: Decimal;
        MonthWiseExpectedAmount: Decimal;
        CurrentWorkDate: Date;
    begin
        // [SCENARIO 500869] Service Invoice for Contracts starting in February, Leap Year incorrect calculation breakdown of monthly alloactions
        Initialize();

        CurrentWorkDate := WorkDate();
        WorkDate(20240201D); // Set leap year work date

        // [GIVEN] Generate and Save Contract Starting date in a Variable.
        ContractStartingDate := LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 10, 20);

        // [GIVEN] Generate and Save Contract Expiration date in a Variable.
        ContractExpirationDate := CalcDate('<1Y>', ContractStartingDate);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item Group.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);

        // [GIVEN] Create a Service Price Group.
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);

        // [GIVEN] Generate and save Default Contract Value in a Variable.
        DefaultContractValue := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] Create a Service Item.
        CreateServiceItemAndValidateFields(
            ServiceItem,
            Customer."No.",
            ServiceItemGroup.Code,
            ServicePriceGroup.Code,
            DefaultContractValue,
            ContractStartingDate);

        // [GIVEN] Create a Service Contract Header.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, true));
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));

        // [GIVEN] Update Starting Date and Expiration Date in a Service Contract Header
        ServiceContractHeader.Validate("Starting Date", ContractStartingDate);
        ServiceContractHeader."Expiration Date" := ContractExpirationDate;
        ServiceContractHeader.Modify();

        // [GIVEN] Create a Service Contract Line.
        CreateServiceContractLineAndValidateFields(
            ServiceContractLine,
            ServiceContractHeader,
            ServiceItem."No.",
            DefaultContractValue,
            ContractStartingDate,
            ContractExpirationDate);

        // [GIVEN] Validate Annual Amount, Invoice Period and "Contract Lines on Invoice" as false in Service Contract Header.
        ServiceContractHeader.Validate("Annual Amount", DefaultContractValue);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate("Contract Lines on Invoice", false);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract but do not create invoice
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Change WorkDate to next month
        WorkDate(CalcDate('<CM+1D>', ContractStartingDate));

        // [GIVEN] Open Service Contract page and run Create Service Invoice action.
        ServiceContract.OpenView();
        ServiceContract.GoToRecord(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        ServiceContract.CreateServiceInvoice.Invoke();

        WorkDate(CurrentWorkDate);

        // [GIVEN] Generate different months line amount in the Variable.
        MonthWiseExpectedAmount := CalcContractLineAmount(DefaultContractValue, ContractStartingDate, ContractExpirationDate);

        // [WHEN] Find first Service Invoice Line.
        FindFirstServiceLine(ServiceContractHeader, ServiceHeader, ServiceLine);

        // [THEN] Verify Service Line - Line Amount field of full year
        ServiceLine.CalcSums(ServiceLine."Line Amount");
        Assert.AreNearlyEqual(MonthWiseExpectedAmount, ServiceLine."Line Amount", 0.01, '');
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,ServiceContractConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SumofServiceInvLinesAmtIsEqualToServiceContractAnnualAmtIfInvPeriodIsYearInServiceContractTemplate()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        ServicePriceGroup: Record "Service Price Group";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceContract: TestPage "Service Contract";
        ContractStartingDate: Date;
        DefaultContractValue: Decimal;
    begin
        // [SCENARIO 543588] Sum of Service Invoice Lines is equal to Annual Amount of Service Contract 
        // If Invoice Period is set to Year in Service Contract Template.
        Initialize();

        // [GIVEN] Generate and save Contract Starting Date in a Variable.
        ContractStartingDate := CalcDate('<-1Y-CY+3M+1D>', WorkDate());

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item Group.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);

        // [GIVEN] Create a Service Price Group.
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);

        // [GIVEN] Generate and save Default Contract Value in a Variable.
        DefaultContractValue := LibraryRandom.RandIntInRange(8200, 8200);

        // [GIVEN] Create two Service Items with different Default Contract Values
        CreateServiceItemAndValidateFields(
            ServiceItem,
            Customer."No.",
            ServiceItemGroup.Code,
            ServicePriceGroup.Code,
            DefaultContractValue,
            ContractStartingDate);

        // [GIVEN] Create a Service Contract Template.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        CreateServiceContractTemplate(ServiceContractTemplate, '<1Y>', ServiceContractHeader."Invoice Period"::Year, true, true, true);

        // [GIVEN] Create a Service Contract Header.
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        LibraryService.CreateServiceContractHeader(
            ServiceContractHeader,
            ServiceContractHeader."Contract Type"::Contract,
            Customer."No.");

        // [GIVEN] Validate Starting Date, Invoice Period and Expiration Date in Service Contract Header.
        ServiceContractHeader.Validate("Starting Date", ContractStartingDate);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate("Expiration Date", CalcDate('<-CY+3M>', WorkDate()));
        ServiceContractHeader.Modify();

        // [GIVEN] Create a Service Contract Line.
        CreateServiceContractLineAndValidateFields(
            ServiceContractLine,
            ServiceContractHeader,
            ServiceItem."No.",
            DefaultContractValue,
            ContractStartingDate,
            CalcDate('<-CY+3M>', WorkDate()));

        // [GIVEN] Update WorkDate.
        WorkDate(CalcDate('<-1Y-CY+4M>', WorkDate()));

        // [GIVEN] Sign Service Contract.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Open Service Contract page and run Create Service Invoice action.
        ServiceContract.OpenView();
        ServiceContract.GoToRecord(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        ServiceContract.CreateServiceInvoice.Invoke();

        // [WHEN] Find Service Line.
        ServiceLine.SetRange("Customer No.", Customer."No.");
        ServiceLine.CalcSums(Amount);

        // [THEN] Sum of Service Lines Amount is equal to Default Contract Value.
        Assert.AreEqual(
            DefaultContractValue,
            ServiceLine.Amount,
            StrSubstNo(
                ValueMustBeEqualErr,
                ServiceLine.FieldCaption(Amount),
                DefaultContractValue,
                ServiceLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Contracts II");
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        LibrarySetupStorage.Restore();
        WorkDate(CalcDate('<CM+1D+2W>', Today()));

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Contracts II");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        // Setup demonstration data
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Contracts II");
    end;

    local procedure AddLineToServiceContractWithSpecificStartingDate(var ServContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line"; LineStartingDate: Date; ContractExpirationDate: Date)
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        ServContractHeader.Find();
        LockOpenServContract.OpenServContract(ServContractHeader);
        CreateServiceContractLine(ServContractLine, ServContractHeader, 0D);
        ServContractLine.Validate("Starting Date", LineStartingDate);
        ServContractLine.Validate("Next Planned Service Date", ServContractLine."Starting Date");
        ServContractLine.Validate("Contract Expiration Date", ContractExpirationDate);
        ServContractLine.Modify(true);
        ServContractHeader.Find();
        UpdateAnnualAmountInServiceContract(ServContractHeader);
    end;

    local procedure CalcContractLineAmount(AnnualAmount: Decimal; PeriodStart: Date; PeriodEnd: Date): Decimal
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        exit(Round(ServContractManagement.CalcContractLineAmount(AnnualAmount, PeriodStart, PeriodEnd)));
    end;

    local procedure ChangeExpirationDateOnContractLine(var ServiceContractHeader: Record "Service Contract Header"; NextInvDate: Date): Code[20]
    var
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        ServiceContractHeader.Find();
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Contract Expiration Date", NextInvDate - 1);
        ServiceContractLine.Modify(true);
        ServiceContractHeader.Find();
        LockOpenServContract.LockServContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(CalcDate(ServiceContractHeader."Service Period", NextInvDate));
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        exit(ServiceContractLine."Service Item No.");
    end;

    local procedure CreateAndUpdateServiceContractAccountGroup(): Code[10]
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", ServiceContractAccountGroup."Non-Prepaid Contract Acc.");  // To take similar Account as Non-Prepaid Contract Acc.
        ServiceContractAccountGroup.Modify(true);
        exit(ServiceContractAccountGroup.Code);
    end;

    local procedure CreateContractLineAndUpdateContract(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractAccountGroupCode: Code[10]; ContractExpirationDate: Date; PriceUpdatePeriod: DateFormula)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ContractExpirationDate);
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroupCode);
        ServiceContractHeader.Validate("Starting Date");
        ServiceContractHeader.Validate("Price Update Period", PriceUpdatePeriod);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; ServicePeriod: Text; NoOfLines: Integer)
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        i: Integer;
    begin
        CreateServiceContractHeader(ServiceContractHeader, CustomerNo, ServicePeriod);
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        for i := 1 to NoOfLines do
            CreateContractLineAndUpdateContract(
              ServiceContractHeader, ServiceContractAccountGroup.Code, 0D, ServiceContractHeader."Service Period");  // Passing 0D for blank Contract Expiration Date.
    end;

    local procedure CreateServiceContractWithLine(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; StartingDate: Date; ExpirationDate: Date; InvoicePeriod: Enum "Service Contract Header Invoice Period"; IsPrepaid: Boolean)
    var
        PriceUpdatePeriod: DateFormula;
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        Evaluate(ServiceContractHeader."Service Period", '<3M>');
        ServiceContractHeader.Validate(Prepaid, IsPrepaid);
        ServiceContractHeader.Validate("Invoice Period", InvoicePeriod);
        ServiceContractHeader.Validate("Starting Date", StartingDate);
        ServiceContractHeader.Validate("Expiration Date", ExpirationDate);
        ServiceContractHeader.Validate("Combine Invoices", true);
        ServiceContractHeader.Validate("Contract Lines on Invoice", true);

        Evaluate(PriceUpdatePeriod, '<1Y>');
        CreateContractLineAndUpdateContract(
          ServiceContractHeader, CreateAndUpdateServiceContractAccountGroup(), ServiceContractHeader."Expiration Date", PriceUpdatePeriod);

        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
    end;

    local procedure CreateServiceContractWithTwoLines(var ServiceContractNo: Code[20]; var ServiceContractLine1No: Integer; var ServiceContractLine2No: Integer; var NextPlannedServiceDate1: Date; var NextPlannedServiceDate2: Date)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServicePeriod: DateFormula;
    begin
        GetDatesForServiceContractsLine(NextPlannedServiceDate1, NextPlannedServiceDate2);
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Modify(true);
        ServiceContractLine1No :=
          CreateServiceContractLineWithNextPlannedServiceDate(ServiceContractHeader, NextPlannedServiceDate1);
        ServiceContractLine2No :=
          CreateServiceContractLineWithNextPlannedServiceDate(ServiceContractHeader, NextPlannedServiceDate2);
        SignContract(ServiceContractHeader);
        ServiceContractNo := ServiceContractHeader."Contract No.";
    end;

    local procedure CreateServiceContractLineWithNextPlannedServiceDate(ServiceContractHeader: Record "Service Contract Header"; NextPlannedServiceDate: Date): Integer
    var
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Next Planned Service Date", NextPlannedServiceDate);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandDec(100, 2));
        ServiceContractLine.Validate("Line Amount", ServiceContractLine."Line Value");
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);
        UpdateAnnualAmountInServiceContract(ServiceContractHeader);
        exit(ServiceContractLine."Line No.");
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; ServicePeriod: Text)
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        Evaluate(ServiceContractHeader."Service Period", ServicePeriod);
    end;

    local procedure CreateServiceContractHeaderWithCurrency(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        // Pass confirmation dialog message to ConfirmHandler and Template No. in SelectServiceContractTemplateListHandler
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, true));

        CreateServiceContractHeader(ServiceContractHeader, CustomerNo, '<1Y>');
        ServiceContractHeader.Validate("Currency Code", CurrencyCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; ContractExpirationDate: Date)
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        UpdateServiceItemSerialNo(ServiceItem, LibraryUtility.GenerateGUID());
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 10000 * LibraryRandom.RandIntInRange(10, 100));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", 10000 * LibraryRandom.RandIntInRange(10, 100));  // Use Random because value is not important.
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Validate("Contract Expiration Date", ContractExpirationDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractLineWithDiscount(var ServiceItemNo: Code[20]; ServiceContractHeader: Record "Service Contract Header"; LineDiscount: Decimal)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceContractHeader."Expiration Date");
        ServiceContractLine.Validate("Line Discount %", LineDiscount);
        ServiceContractLine.Modify(true);
        ServiceItemNo := ServiceContractLine."Service Item No.";
    end;

    local procedure CreateContractLineWithSpecificAmount(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; LineValue: Decimal)
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LineValue);
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template"; ServicePeriodTxt: Text; InvoicePeriod: Enum "Service Contract Header Invoice Period"; CombineInvoices: Boolean; ContractLinesOnInvoice: Boolean; IsPrepaid: Boolean)
    var
        DefaultServicePeriod: DateFormula;
    begin
        Evaluate(DefaultServicePeriod, ServicePeriodTxt);

        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        ServiceContractTemplate.Validate("Invoice Period", InvoicePeriod);
        ServiceContractTemplate.Validate(Prepaid, IsPrepaid);
        ServiceContractTemplate.Validate("Combine Invoices", CombineInvoices);
        ServiceContractTemplate.Validate("Contract Lines on Invoice", ContractLinesOnInvoice);
        ServiceContractTemplate.Modify(true);
    end;

    local procedure CreateServiceContractTemplateInvPeriodYear(var ServiceContractTemplate: Record "Service Contract Template"; Prepaid: Boolean): Code[20]
    begin
        CreateServiceContractTemplate(ServiceContractTemplate, '<1M>', "Service Contract Header Invoice Period"::Year, true, false, Prepaid);
        exit(ServiceContractTemplate."No.");
    end;

    local procedure CreateServiceContractWithLinesWithDiscount(var ServiceContractHeader: Record "Service Contract Header"; var ServiceItemNo: array[3] of Code[20])
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        CreateServiceContractLineWithDiscount(ServiceItemNo[1], ServiceContractHeader, 100);
        CreateServiceContractLineWithDiscount(ServiceItemNo[2], ServiceContractHeader, 50);
        CreateServiceContractLineWithDiscount(ServiceItemNo[3], ServiceContractHeader, 0);
        UpdateAnnualAmountInServiceContract(ServiceContractHeader);
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceLineForServiceOrder(var ServiceHeader: Record "Service Header"; ContractNo: Code[20])
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.FindResource(Resource);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ContractNo);
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Take Random Quantity.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Take Random Unit Price.
        ServiceLine.Modify(true);
    end;

    local procedure CreditMemoWithServiceContractAccountGroup(ServiceContractAccountGroupCode: Code[10])
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // 1. Setup: Create and Sign Service Contract and Post Service Invoice created after signing the Contract, Create Credit Memo from Contract.
        SignContractAndPostServiceInvoiceWithAccGrCode(ServiceContractHeader, false, ServiceContractAccountGroupCode);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);

        // 2. Exercise: Post Service Credit Memo created from Service Contract.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify that Moved From Prepaid Account Field is carrying TRUE.
        VerifyServiceLedgerEntries(ServiceContractHeader."Contract No.");
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceHeader.Get(
          ServiceHeader."Document Type"::"Credit Memo",
          ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, false)); // Passing False to avoid Deletion of Service Contract Line.
    end;

    local procedure CreateNonPrepaidServTemplateWithMonthInvPeriod(): Code[20]
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, false);
        ServiceContractTemplate.Validate("Invoice Period", ServiceContractTemplate."Invoice Period"::Month);
        ServiceContractTemplate.Modify(true);
        exit(ServiceContractTemplate."No.");
    end;

    local procedure CreateCustomer(NewPricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Prices Including VAT", NewPricesInclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithGenBusPostingGroup(var Customer: Record Customer)
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure FilterServiceLedgEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractNo: Code[20])
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::"Service Contract");
        ServiceLedgerEntry.SetRange("No.", ServiceContractNo);
    end;

    local procedure FilterServiceLine(var ServiceLine: Record "Service Line"; ContractNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Posting Date", PostingDate);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ContractNo);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.SetRange("No.", GLAccNo);
    end;

    local procedure FindAndPostServiceInvoice(ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ContractNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure FindServiceLedgerEntries(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractNo: Code[20])
    begin
        FilterServiceLedgEntry(ServiceLedgerEntry, ServiceContractNo);
        ServiceLedgerEntry.FindSet();
    end;

    local procedure FindServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
    end;

    local procedure FindServiceContractLineAmount(ServiceContractHeader: Record "Service Contract Header"): Decimal
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        exit(ServiceContractLine."Line Amount");
    end;

    local procedure FindServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20])
    begin
        ServiceContractHeader.SetRange("Contract Type", ContractType);
        ServiceContractHeader.SetRange("Contract No.", ContractNo);
        ServiceContractHeader.FindLast();
    end;

    local procedure FindServiceDocumentHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; ContractNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindLast();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ContractNo);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetFilter(Type, '<>''''');
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceContractLineNo: Integer; ServiceContractNo: Code[20])
    begin
        ServiceItemLine.SetRange("Contract Line No.", ServiceContractLineNo);
        ServiceItemLine.SetRange("Contract No.", ServiceContractNo);
        ServiceItemLine.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ContractNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Contract No.", ContractNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ContractNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Contract No.", ContractNo);
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure GetDatesForServiceContractsLine(var NextPlannedServiceDate1: Date; var NextPlannedServiceDate2: Date)
    begin
        NextPlannedServiceDate1 := CalcDate('<+' + Format(LibraryRandom.RandInt(3)) + 'M>', WorkDate());
        NextPlannedServiceDate2 := CalcDate('<+' + Format(LibraryRandom.RandInt(3)) + 'M>', NextPlannedServiceDate1);
    end;

    local procedure GetServContractGLAcc(ServContractAccountGroupCode: Code[10]; Prepaid: Boolean): Code[20]
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        ServiceContractAccountGroup.Get(ServContractAccountGroupCode);
        if Prepaid then
            exit(ServiceContractAccountGroup."Prepaid Contract Acc.");
        exit(ServiceContractAccountGroup."Non-Prepaid Contract Acc.");
    end;

    local procedure GetServiceLedgerEntryPosAmount(ContractNo: Code[20]; EntryType: Enum "Service Ledger Entry Entry Type"): Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Entry Type", EntryType);
        ServiceLedgerEntry.SetFilter(Amount, '>%1', 0);
        ServiceLedgerEntry.FindFirst();
        exit(ServiceLedgerEntry.Amount);
    end;

    local procedure GetServiceLedgerEntryNegAmount(ContractNo: Code[20]; EntryType: Enum "Service Ledger Entry Entry Type"): Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Entry Type", EntryType);
        ServiceLedgerEntry.SetFilter(Amount, '<%1', 0);
        ServiceLedgerEntry.FindFirst();
        exit(ServiceLedgerEntry.Amount);
    end;

    local procedure GetServiceDocAmount(ServiceHeader: Record "Service Header"): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.CalcSums(Amount);
        exit(ServiceLine.Amount);
    end;

    local procedure GetPostedServiceInvoiceAmount(ContractNo: Code[20]): Decimal
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ContractNo);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.CalcSums(Amount);
        exit(ServiceInvoiceLine.Amount);
    end;

    local procedure GetPostedServiceCrMemoAmount(ContractNo: Code[20]): Decimal
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        FindServiceCrMemoHeader(ServiceCrMemoHeader, ContractNo);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.CalcSums(Amount);
        exit(ServiceCrMemoLine.Amount);
    end;

    local procedure PostServiceInvoiceAndVerifyPrepaidAccount(ServiceContractAccountGroupCode: Code[10])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // 2. Exercise: Create and Sign Contract and Post Service Invoice created after signing Service Contract.
        SignContractAndPostServiceInvoiceWithAccGrCode(ServiceContractHeader, false, ServiceContractAccountGroupCode);

        // 3. Verify: Verify that Moved From Prepaid Account Field is carrying TRUE.
        VerifyServiceLedgerEntries(ServiceContractHeader."Contract No.");
    end;

    local procedure RunCreateContractInvoices()
    var
        CreateContractInvoices: Report "Create Contract Invoices";
    begin
        Commit();  // Required to avoid Test Failure.
        CreateContractInvoices.SetHideDialog(true);
        CreateContractInvoices.Run();
    end;

    local procedure RunCreateContractServiceOrders()
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
    begin
        Commit();  // Required to avoid Test Failure.
        CreateContractServiceOrders.SetHideDialog(true);
        CreateContractServiceOrders.Run();
    end;

    local procedure RunCreateContractServiceOrdersWithDates(StartDate: Date; EndDate: Date)
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
        CreateServOrders: Option "Create Service Order","Print Only";
    begin
        Commit();  // Required to avoid Test Failure.
        Clear(CreateContractServiceOrders);
        CreateContractServiceOrders.InitializeRequest(StartDate, EndDate, CreateServOrders::"Create Service Order");
        CreateContractServiceOrders.Run();
    end;

    local procedure RunUpdateContractPricesReport(ServiceContractHeader: Record "Service Contract Header"; PriceChangePercent: Decimal)
    var
        UpdateContractPrices: Report "Update Contract Prices";
        PerformUpdate: Option "Update Contract Prices","Print Only";
    begin
        UpdateContractPrices.SetTableView(ServiceContractHeader);
        UpdateContractPrices.InitializeRequest(WorkDate(), PriceChangePercent, PerformUpdate::"Update Contract Prices");
        UpdateContractPrices.UseRequestPage(false);
        UpdateContractPrices.Run();
    end;

    local procedure ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(var ServContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line"; Prepaid: Boolean; ContractExpirationDate: Date; var InvoiceDate: Date)
    var
        ServiceContractTemplate: Record "Service Contract Template";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(
          CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, Prepaid));

        CreateServiceContract(ServContractHeader, CreateCustomer(false), '<2Y>', 2);
        UpdateServiceContractStartingDate(ServContractHeader, CalcDate('<-CM>', WorkDate()));
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        SignContract(ServContractHeader);

        AddLineToServiceContractWithSpecificStartingDate(
          ServContractHeader, ServContractLine, ServContractHeader."Next Invoice Period Start" + 1, ContractExpirationDate);
        LibraryVariableStorage.Enqueue(NewLinesAddedConfirmQst);

        LockOpenServContract.LockServContract(ServContractHeader);
        UpdateServiceContractLineStartingPlannedDate(ServContractLine, ServContractHeader."Next Invoice Period Start" + 1);
        InvoiceDate := ServContractHeader."Next Invoice Period End";
        LibraryVariableStorage.Enqueue(InvoiceDate);
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");
    end;

    local procedure ScenarioWithSignedAndInvoicedServiceContract(var ServContractHeader: Record "Service Contract Header"; ContractStatingDate: Date)
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplateInvPeriodYear(ServiceContractTemplate, true));
        CreateServiceContract(ServContractHeader, CreateCustomer(false), '<2Y>', 2);
        UpdateServiceContractStartingDate(ServContractHeader, ContractStatingDate);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        SignContract(ServContractHeader);
        ServContractHeader.Find();
        LibraryVariableStorage.Enqueue(ServContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");
        RunCreateContractInvoices();
    end;

    local procedure SetExpirationDateLessThanLastInvoiceDate(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader."Expiration Date" := ServiceContractHeader."Last Invoice Date" - 1;
        ServiceContractHeader.Modify(true);
    end;

    local procedure SignContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure SignContractSilent(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure SignContractAndCreateServiceInvoice(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean)
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        SignContractAndCreateServiceInvoiceWithAccGrCode(ServiceContractHeader, CustomerPricesInclVAT, ServiceContractAccountGroup.Code);
    end;

    local procedure SignContractAndCreateServiceInvoiceWithAccGrCode(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean; ServiceContractAccountGroupCode: Code[10])
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(CustomerPricesInclVAT));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractLineAndUpdateContract(
          ServiceContractHeader, ServiceContractAccountGroupCode, WorkDate(), ServiceContractHeader."Service Period");
        SignContract(ServiceContractHeader);
    end;

    local procedure SignContractAndPostServiceInvoice(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean)
    begin
        SignContractAndCreateServiceInvoice(ServiceContractHeader, CustomerPricesInclVAT);
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    local procedure SignContractAndPostServiceInvoiceWithAccGrCode(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean; ServiceContractAccountGroupCode: Code[10])
    begin
        SignContractAndCreateServiceInvoiceWithAccGrCode(
          ServiceContractHeader, CustomerPricesInclVAT, ServiceContractAccountGroupCode);
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    local procedure UpdateAndPostServiceOrder(ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceLineForServiceOrder(ServiceHeader, ContractNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure UpdateTemplateNoOnServiceContract(var ServiceContractTemplateList: TestPage "Service Contract Template List"; No: Text)
    begin
        ServiceContractTemplateList.FILTER.SetFilter("No.", No);
        ServiceContractTemplateList.OK().Invoke();
    end;

    local procedure UpdateAnnualAmountInServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        UpdateAnnualAmountInServiceContract(ServiceContractHeader);
        ServiceContractHeader.Validate("Starting Date");
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceContractStartingDate(var ServiceContractHeader: Record "Service Contract Header"; StartingDate: Date)
    begin
        ServiceContractHeader.Validate("Starting Date", StartingDate);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceContractLineStartingPlannedDate(var ServiceContractLine: Record "Service Contract Line"; StartingDate: Date)
    begin
        ServiceContractLine.Validate("Starting Date", StartingDate);
        ServiceContractLine.Validate("Next Planned Service Date", StartingDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateServiceItemSerialNo(var ServiceItem: Record "Service Item"; SerialNo: Code[50])
    begin
        ServiceItem.Validate("Serial No.", SerialNo);
        ServiceItem.Modify(true);
    end;

    local procedure UpdateServiceContractLineDescription(var ServiceContractLine: Record "Service Contract Line"; DescriptionText: Text[100])
    begin
        ServiceContractLine.Validate(Description, DescriptionText);
        ServiceContractLine.Modify(true);
    end;

    local procedure VerifyPostedServiceInvoiceDiscount(CustomerNo: Code[20]; ServiceItemNo: Code[20]; DiscountPct: Decimal)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceLine.SetRange("Service Item No.", ServiceItemNo);
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("Line Discount %", DiscountPct);
    end;

    local procedure VerifyServiceInvoiceLineAmount(ContractNo: Code[20]; Amount: Decimal)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Contract No.", ContractNo);
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField(Amount, Amount);
    end;

    local procedure VerifyServiceLedgerEntries(ServiceContractNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Moved from Prepaid Acc.", true);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(ServiceContractNo: Code[20]; AmountLCY: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        LibraryERM: Codeunit "Library - ERM";
    begin
        FindServiceLedgerEntries(ServiceLedgerEntry, ServiceContractNo);
        repeat
            Assert.AreNearlyEqual(
              AmountLCY, ServiceLedgerEntry."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(
                AmountError, ServiceLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, ServiceLedgerEntry.TableCaption(),
                ServiceLedgerEntry.FieldCaption("Entry No."), ServiceLedgerEntry."Entry No.", ServiceLedgerEntry."Amount (LCY)"));
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceLedgEntryDoesNotExist(ServiceContractNo: Code[20]; ServiceItemNo: Code[20]; PostingDate: Date)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FilterServiceLedgEntry(ServiceLedgerEntry, ServiceContractNo);
        ServiceLedgerEntry.SetRange("Service Item No. (Serviced)", ServiceItemNo);
        ServiceLedgerEntry.SetFilter("Posting Date", '%1..', PostingDate);
        Assert.RecordIsEmpty(ServiceLedgerEntry);
    end;

    local procedure VerifyCreatedServiceOrder(ServiceContractNo: Code[20]; ServiceContractLine1No: Integer; ServiceContractLine2No: Integer)
    var
        ServiceItemLine1: Record "Service Item Line";
        ServiceItemLine2: Record "Service Item Line";
    begin
        FindServiceItemLine(ServiceItemLine1, ServiceContractLine1No, ServiceContractNo);
        FindServiceItemLine(ServiceItemLine2, ServiceContractLine2No, ServiceContractNo);
        Assert.AreNotEqual(ServiceItemLine1."Document No.", ServiceItemLine2."Document No.", CreateServiceOrderBatchErr);
    end;

    local procedure VerifyServContractLineAmountSplitByPeriod(ContractNo: Code[20]; ServItemNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date; NoOfLines: Integer; ExpectedAmount: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServLedgerEntry: Record "Service Ledger Entry";
        FromServLedgEntryNo: Integer;
    begin
        FilterServiceLine(ServiceLine, ContractNo, GLAccNo, PostingDate);
        ServLedgerEntry.SetRange("Service Item No. (Serviced)", ServItemNo);
        FindServiceLedgerEntries(ServLedgerEntry, ContractNo);
        FromServLedgEntryNo := ServLedgerEntry."Entry No.";
        ServLedgerEntry.FindLast();
        ServiceLine.SetRange("Appl.-to Service Entry", FromServLedgEntryNo, ServLedgerEntry."Entry No.");
        Assert.RecordCount(ServiceLine, NoOfLines);
        ServiceLine.CalcSums(Amount);
        Assert.AreNearlyEqual(ExpectedAmount, ServiceLine.Amount, 0.01, '');
        ServiceLine.CalcSums("Line Amount");
        Assert.AreNearlyEqual(ExpectedAmount, ServiceLine."Line Amount", 0.01, '');
    end;

    local procedure VerifyFirstServiceLineForServiceContractLine(ContractNo: Code[20]; ServItemNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date; StartingDate: Date; EndingDate: Date; ExpectedAmount: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FilterServiceLine(ServiceLine, ContractNo, GLAccNo, PostingDate);
        ServiceLedgerEntry.SetRange("Service Item No. (Serviced)", ServItemNo);
        FindServiceLedgerEntries(ServiceLedgerEntry, ContractNo);
        ServiceLine.SetRange("Appl.-to Service Entry", ServiceLedgerEntry."Entry No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField(Description, StrSubstNo('%1 - %2', Format(StartingDate), Format(EndingDate)));
        ServiceLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyServiceDocAmount(DocumentType: Enum "Service Document Type"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceDocumentHeader(ServiceHeader, DocumentType, ContractNo);
        Assert.IsFalse(ServiceHeader."Prices Including VAT", ServiceHeader.FieldCaption("Prices Including VAT"));
        Assert.AreEqual(
          -GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale),
          GetServiceDocAmount(ServiceHeader), ServiceLine.FieldCaption(Amount));
    end;

    local procedure VerifyServiceContractStatus(ContractType: Enum "Service Contract Type"; ContractNo: Code[20]; ExpectedStatus: Enum "Service Contract Status")
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        FindServiceContractHeader(ServiceContractHeader, ContractType, ContractNo);
        Assert.AreEqual(ExpectedStatus, ServiceContractHeader.Status, 'Incorrect status.');
    end;

    local procedure VerifyPostedServiceInvoiceAmount(ContractNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Amount: Decimal;
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ContractNo);
        Assert.IsFalse(ServiceInvoiceHeader."Prices Including VAT", ServiceInvoiceHeader.FieldCaption("Prices Including VAT"));
        Amount := -GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale);
        Assert.AreEqual(
          Amount, GetPostedServiceInvoiceAmount(ContractNo), ServiceInvoiceLine.FieldCaption(Amount));
        Assert.AreEqual(
          Amount,
          GetServiceLedgerEntryPosAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Usage),
          ServiceLedgerEntry.FieldCaption(Amount));
    end;

    local procedure VerifyPostedServiceCrMemoAmount(ContractNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Amount: Decimal;
    begin
        FindServiceCrMemoHeader(ServiceCrMemoHeader, ContractNo);
        Assert.IsFalse(ServiceCrMemoHeader."Prices Including VAT", ServiceCrMemoHeader.FieldCaption("Prices Including VAT"));
        Amount := -GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale);
        Assert.AreEqual(
          Amount, GetPostedServiceCrMemoAmount(ContractNo), ServiceCrMemoLine.FieldCaption(Amount));
        Assert.AreEqual(
          -GetServiceLedgerEntryPosAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale),
          GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Usage),
          ServiceLedgerEntry.FieldCaption(Amount));
    end;

    local procedure VerifyContractLinesOnInvoiceDescription(ServiceContractNo: Code[20]; PostingDate: Date; ExpectedDescription: Text[100])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader.SetRange("Posting Date", PostingDate);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractNo);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::" ");
        ServiceLine.SetFilter("No.", '');

        ServiceLine.SetFilter(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(ServiceLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractInvoicesRequestPageHandler(var CreateContractInvoices: TestRequestPage "Create Contract Invoices")
    var
        InvoiceDate: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Create Contract Invoices";
        LibraryVariableStorage.Dequeue(InvoiceDate);
        CreateContractInvoices.PostingDate.SetValue(Format(InvoiceDate));
        CreateContractInvoices.InvoiceToDate.SetValue(Format(InvoiceDate));
        CreateContractInvoices.CreateInvoices.SetValue(Format(CreateContractInvoices.CreateInvoices.GetOption(1)));  // Passing 1 for First Option.
        CreateContractInvoices."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText());
        CreateContractInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractInvoicesDiffDatesRequestPageHandler(var CreateContractInvoices: TestRequestPage "Create Contract Invoices")
    begin
        CreateContractInvoices.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateContractInvoices.InvoiceToDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateContractInvoices.CreateInvoices.SetValue(Format(CreateContractInvoices.CreateInvoices.GetOption(1)));
        CreateContractInvoices."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText());
        CreateContractInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractServiceOrdersRequestPageHandler(var CreateContractServiceOrders: TestRequestPage "Create Contract Service Orders")
    begin
        CurrentSaveValuesId := REPORT::"Create Contract Service Orders";
        CreateContractServiceOrders.StartingDate.SetValue(Format(WorkDate()));
        CreateContractServiceOrders.EndingDate.SetValue(Format(WorkDate()));
        CreateContractServiceOrders.CreateServiceOrders.SetValue(Format(CreateContractServiceOrders.CreateServiceOrders.GetOption(1)));  // Passing 1 for First Option.
        CreateContractServiceOrders."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText());
        CreateContractServiceOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConfirmCreateContractServiceOrdersRequestPageHandler(var CreateContractServiceOrders: TestRequestPage "Create Contract Service Orders")
    begin
        CurrentSaveValuesId := REPORT::"Create Contract Service Orders";
        CreateContractServiceOrders.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        ServiceContractTemplate.SetRange("Invoice after Service", true);
        ServiceContractTemplate.FindFirst();
        UpdateTemplateNoOnServiceContract(ServiceContractTemplateList, ServiceContractTemplate."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateListHandler2(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        ServiceContractTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectServiceContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        UpdateTemplateNoOnServiceContract(ServiceContractTemplateList, LibraryVariableStorage.DequeueText());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageTest: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConditionalConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Message, CreateInvoiceMsg) = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DoNotCreateContrUsingTemplateConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Message, CreateContrUsingTemplateQst) = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConditionalNextPlannedDateConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Message, NextPlannedServiceDateConfirmQst) = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MultipleDialogsConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        // There should be no additonal confirm handler with CreateInvoiceMsg. If confirmation window opens then handler failes on the following assert

        Assert.AreNotEqual(0, StrPos(Question, LibraryVariableStorage.DequeueText()), UnexpectedConfirmTextErr);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SignContractYesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Question, SignContractConfirmQst) <> 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure Scenario421481ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Yes to confirm sign contract
        // No to create invoice while signing
        // Yes to confirm later Posting Date
        // Yes to confirm later Inoice-to Date
        Reply :=
            (StrPos(Question, SignContractConfirmQst) <> 0) or
            (StrPos(Question, ConfirmLaterPostingDateQst) <> 0) or
            (StrPos(Question, ConfirmLaterInvoiceToDateQst) <> 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SignContractConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    var
        CreateServiceInvoiceWithinPeriod: Boolean;
    begin
        CreateServiceInvoiceWithinPeriod := LibraryVariableStorage.DequeueBoolean();
        case true of
            SignContractMessage = Format(LibraryVariableStorage.DequeueText()):
                Result := true;
            SignContractMessage = Format(CreateServiceInvoiceQst):
                Result := true;
            CreateServiceInvoiceWithinPeriod = true:
                Result := true;
            else
                Result := false;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ServiceContractConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    var
        CreateServiceInvoiceWithinPeriod: Boolean;
    begin
        CreateServiceInvoiceWithinPeriod := LibraryVariableStorage.DequeueBoolean();
        case true of
            SignContractMessage = Format(LibraryVariableStorage.DequeueText()):
                Result := true;
            SignContractMessage = Format(CreateServiceInvoiceQst):
                Result := true;
            CreateServiceInvoiceWithinPeriod = true:
                Result := true;
            else
                Result := false;
        end;
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

    local procedure CreateServiceItemAndValidateFields(
        var ServiceItem: Record "Service Item";
        CustomerNo: Code[20];
        ServiceItemGroupCode: Code[10];
        ServicePriceGroupCode: Code[10];
        DefaultContractValue: Decimal;
        InstallationDate: Date)
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItem.Validate("Service Price Group Code", ServicePriceGroupCode);
        ServiceItem.Validate("Default Contract Value", DefaultContractValue);
        ServiceItem.Validate("Installation Date", InstallationDate);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceContractHeaderAndValidateFields(
        var ServiceContractHeader: Record "Service Contract Header";
        CustomerNo: Code[20];
        StartingDate: Date;
        ExpirationDate: Date)
    begin
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", StartingDate);
        ServiceContractHeader.Validate("Expiration Date", ExpirationDate);
        ServiceContractHeader.Validate("Combine Invoices", true);
        ServiceContractHeader.Validate("Contract Lines on Invoice", true);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLineAndValidateFields(
        var ServiceContractLine: Record "Service Contract Line";
        var ServiceContractHeader: Record "Service Contract Header";
        ServiceItemNo: Code[20];
        LineAmount: Decimal;
        StartingDate: Date;
        ExpirationDate: Date)
    begin
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItemNo);
        ServiceContractLine.Validate("Line Value", LineAmount);
        ServiceContractLine.Validate("Line Amount", LineAmount);
        ServiceContractLine.Validate("Starting Date", StartingDate);
        ServiceContractLine.Validate("Contract Expiration Date", ExpirationDate);
        ServiceContractLine.Validate("Next Planned Service Date", StartingDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure FindlastServiceLine(
        var ServiceContractHeader: Record "Service Contract Header";
        var Serviceheader: Record "Service Header";
        var ServiceLine: Record "Service Line")
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindLast();
    end;

    local procedure FindFirstServiceLine(
        var ServiceContractHeader: Record "Service Contract Header";
        var Serviceheader: Record "Service Header";
        var ServiceLine: Record "Service Line")
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindFirst();
    end;

    local procedure CountofUnpostedServiceLines(var ServiceContractHeader: Record "Service Contract Header"): Integer
    var
        Serviceheader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        exit(ServiceLine.Count);
    end;
}

