// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Reports;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 136102 "Service Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Service Contract]
        isInitialized := false;
        InitialWorkDate := WorkDate();
    end;

    var
        ServiceContractHeader2: Record "Service Contract Header";
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceGetShipment: Codeunit "Service-Get Shipment";
        isInitialized: Boolean;
        UnknownErr: Label 'Unknown error.';
        NoServiceLineServiceTierMsg: Label 'There is no Service Contract Line within the filter.  Filters: Contract No.: %1';
        CopyDocumentErr: Label 'You can only copy the document with the same Customer No..';
        CustomerNotBlankErr: Label 'Customer No. must not be blank in Service Contract Header %1';
        ServiceCtrctTemplateExistErr: Label 'The %1 must not exist. Identification field and value: %2=''%3''.', Comment = '%1= field value,%2 = Filed Value,%3 = Field Value';
        ServiceCtrctHeaderExistErr: Label 'The %1 must not exist. Identification field and value: %2=''%3'', %4=''%5''.', Comment = '%1= Field value,%2 = field Caption,%3= Field Value,%4 = Field Caption,%5 = Field Value';
        InvoiceCreationMsg: Label 'Do you want to create an invoice';
        ServiceLedgerEntryErr: Label 'No. of Records in %1 must be equal to %2';
        EntryMustExistErr: Label '%1 must exist for Contract: %2.';
        InvoiceCreatedMsg: Label '%1 invoice was created.';
        OrderCreationMsg: Label '1 service order was created.';
        AccountFilterMsg: Label '%1|%2', Comment = '%1=Non-Prepaid Contract Acc.Field;%2=Prepaid Contract Acc.Field';
        InitialWorkDate: Date;
        UnitCostErr: Label 'Unit Cost(LCY) must not have Zero Value.';
        ServiceEntriesExistForServiceLineErr: Label 'You cannot modify the service line because one or more service entries exist for this line.';
        DimensionNotChangeableServiceEntriesExistErr: Label 'You cannot change the dimension because there are service entries connected to this line.';
        DimensionEditableErr: Label 'Dimension Code field must be editable.';
        DimensionNonEditableErr: Label 'Dimension Code field must not be editable.';
        ServiceTemplateMsg: Label 'Do you want to create the contract using a contract template?';
        ServiceContractErr: Label '%1 in Service Contract is not correct.';
        GLEntryErr: Label '%1 in GL Entry is not correct.';
        GLEntriesExistsErr: Label 'G/L entries exists.';
        IncorrectAmountPerPeriodErr: Label 'Incorrect Amount Per Period.';
        IncorrectInvAmountErr: Label 'Incorrect Invoice Amount.';
        IncorrectCreditMemoAmountErr: Label 'Incorrect Credit Memo Amount.';
        ServiceDocLinkNotFoundErr: Label '%1 is missing a link.';
        ServiceLineAmountErr: Label 'Incorrect Service Line Amount.';
        PositiveValueErrorErr: Label 'Line Value must not be';
        PositiveValueErrorCodeErr: Label 'NCLCSRTS:TableErrorStr';
        CannotCreateServiceOrderMsg: Label 'A service order cannot be created for contract no. %1 because customer no. %2 does not have a %3.', Comment = '%1 - Contract No. %2 - Customer No. %3 - Ship-to Code';
        ZeroOrderCreatedMsg: Label '0 service order was created.';
        ServItemHasDiffShipToCodeMsg: Label 'Service item %1 has a different ship-to code for this customer.\\Do you want to continue?';
        FieldEmptyMsg: Label 'The %1 field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?';
        ConvertMsg: Label 'Do you want to convert the contract quote into a contract?';

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        CustomerNo: Code[20];
    begin
        // Covers document number TC0134 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks to Change customer No. on Service Contract.

        // 1. Setup: create Service Contract Header and Service Contract Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Change Customer No. in Service Contract.
        CustomerNo := ChangeCustomerNo(ServiceContractHeader);

        // 3. Verify: Check that Customer No. is changed in Service Contract.
        CheckChangeCustomerNo(ServiceContractHeader, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure NewLineOnServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0135 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks to New Line field is Set to true after Creating New Line in Service Contract Line.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Open and create New Service Contract Line in Service Contract.
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        // 3. Verify: Check that "New Line" field is set to true after creating new line in Service Contract Line.
        ServiceContractLine.TestField("New Line", true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure DeleteContractLineIfLocked()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0136 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Error on Deletion of Line while change status is locked on Service Contract Header.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Check Service Contract Line deletion error On Locked change status.
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        asserterror ServiceContractLine.DeleteAll(true);
        Assert.ExpectedTestFieldError(ServiceContractHeader.FieldCaption("Change Status"), Format(ServiceContractHeader."Change Status"::Open));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure QtyOnSeviceContractInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0137 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Quantity on Service Invoice is same after Creation of Service Contract Invoice.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Check that Quantity on Service Invoice is same after Creation of Service Contract Invoice.
        CheckInvoiceQuantity(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure CreditMemofromServiceContract()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0138 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Customer No. on Service Credit Memo Header is the same after creating Service Credit Memo from Service
        // Contract's Customer No. field.
        // [SCENARIO 224033] Fields "Bill-to Contact No." and "Bill-to Contact" must be copied from Service Contract to Service Credit Memo by function ServContractManagement.CreateServHeader

        // 1. Setup: Create and Sign Service Contract and Set Workdate.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Post Service Invoice and Create Service Credit Memo from Service Contract.
        Commit();
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        REPORT.RunModal(REPORT::"Batch Post Service Invoices", false, true, ServiceHeader);
        ServiceContractHeader.Find();
        ModifyServiceContractStatus(ServiceContractHeader);
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.", WorkDate());

        // 3. Verify: Check that the Customer No. on Service Credit Memo Header is the same after creating Service Credit Memo from Service
        // Contract's Customer No. field.
        CheckServiceCreditMemo(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure CreditMemofromServiceContractVerifyAmountAndUnitPrice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ExpectedAmount: Decimal;
        ExpectedUnitPrice: Decimal;
    begin
        // [SCENARIO 230832] When create Service Credit Memo for Service Contract then "Amount" and "Unit Price" in Service Line are the same as ones in Service Invoice
        Initialize();

        // [GIVEN] Created and Signed Service Contract.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        LibraryService.SignContract(ServiceContractHeader);

        // [GIVEN] Posted Service Invoice with Line "Unit Price" = 100; "Amount" = 200.
        PostServiceInvoiceFromContract(ExpectedAmount, ExpectedUnitPrice, ServiceContractHeader."Contract No.");
        ServiceContractHeader.Find();
        ModifyServiceContractStatus(ServiceContractHeader);

        // [WHEN] Create Service Credit Memo from Service Contract
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.", WorkDate());

        // [THEN] Created Service Memo has Line with "Unit Price" = 100; "Amount" = 200.
        VerifyServiceCreditMemoAmountAndUnitPrice(ServiceContractHeader."Contract No.", ExpectedAmount, ExpectedUnitPrice);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure CustomerOnContractInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0139,CU-5944-8 - refer to TFS ID 21730,172909.
        // [SCENARIO] The Test Case checks Customer No. on Service Contract Invoice and the creation of Service Invoice.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Contract Invoice.
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader);

        // 3. Verify: Check Customer No. on Service Contract Invoice and the creation of Service Invoice.
        CheckCustomerNoOnInvoice(ServiceContractHeader);
        VerifyServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure NoErrorWhenCreatingContractInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServicePeriod: DateFormula;
    begin
        // Covers TFS ID 353488.
        // [SCENARIO] The Test Case creates invoice for a service header running for a year with a fixed expiry date.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        Evaluate(ServicePeriod, '<1Y>');
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Expiration Date", CalcDate('<1Y+CM+1D>', ServiceContractHeader."Starting Date"));
        ServiceContractHeader.Validate("Contract Lines on Invoice", true);
        ServiceContractHeader.Modify(true);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        SignServContractDoc.SignContract(ServiceContractHeader);

        // Set the expiry date as the last invoicing date 
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader."Next Invoice Period End" := ServiceContractHeader."Expiration Date";
        ServiceContractHeader.Modify();

        // 2. Exercise: Create Service Contract Invoice.
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader, CalcDate('<CM+1D>', ServiceContractHeader."Starting Date"), CalcDate('<CM+1D>', ServiceContractHeader."Starting Date"));

        // 3. Verify: Check the creation of Service Invoice.
        VerifyServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure OrderDateServiceOrderContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0140 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks "Order Date" matched with Service Contract's "First Invoiced Date" field on Service Contract Order.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Contract Order.
        CreateServiceContractOrder(ServiceContractHeader);

        // 3. Verify: Verify that "Order Date" matched with Service Contract's "First Invoiced Date" field on Service Contract Order.
        CheckOrderDate(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure UpdatedPriceonServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        PricePercentage: Decimal;
    begin
        // Covers document number TC0141 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks updated Price percentage on Service Contract.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Starting Date", LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 5));
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Update Contract Price in Service Contract.
        PricePercentage := UpdateContractPrice(ServiceContractHeader);

        // 3. Verify: Check that updated Price percentage on Service Contract.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Last Price Update %", PricePercentage);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure PrepaidTransactionOnContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0142 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks "Moved from Prepaid Acc." set to TRUE in Service Ledger Entry.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Check "Moved from Prepaid Acc." set to TRUE in Service Ledger Entry.
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("Moved from Prepaid Acc.", true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure RemoveContractLineOnContract()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0143 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Removed Contract Line does not exist after deletion.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();

        // 2. Exercise: Post and remove the Contract Line from Service Contract.
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        REPORT.RunModal(REPORT::"Batch Post Service Invoices", false, true, ServiceHeader);
        ServiceContractHeader.Find();
        ModifyServiceContractStatus(ServiceContractHeader);
        RemoveContractLine(ServiceContractHeader."Contract No.");

        // 3. Verify: Check that Removed Contract Line does not exist after deletion.
        Assert.IsFalse(
          ServiceContractLine.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.", ServiceContractLine."Line No."),
          StrSubstNo(NoServiceLineServiceTierMsg, ServiceContractLine."Contract No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateServiceAccountGroup()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // Covers document number TC0071 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Service Account Group is created from ServiceAccGroup function.

        // Setup.
        Initialize();

        // 2. Exercise: Create Service Account Group.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);

        // 3. Verify: Check that Service Account Group is created from ServiceAccGroup function.
        ServiceContractAccountGroup.Get(ServiceContractAccountGroup.Code);

        // 4. Cleanup
        ServiceContractAccountGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteServiceContractTemplate()
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        // Covers document number TC0072 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Service Contract Template does not Exist after deletion.

        // 1. Setup: Create Service Contract Template.
        Initialize();
        CreatePrepaidServiceContractTemplate(ServiceContractTemplate);

        // 2. Exercise: Delete newly created Service Contract Template.
        ServiceContractTemplate.Delete(true);

        // 3. Verify: Check that Service Contract Template does not Exist after deletion.
        Assert.IsFalse(
          ServiceContractTemplate.Get(ServiceContractTemplate."No."),
          StrSubstNo(ServiceCtrctTemplateExistErr, ServiceContractTemplate.TableCaption(), ServiceContractTemplate.FieldCaption("No."),
            ServiceContractTemplate."No."));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateFields()
    var
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Covers document number TC0072 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks After creating Service Contract Template all fields TRUE automatic in Service Contract.

        // 1. Setup: Create New Service Contract Template.
        Initialize();
        CreatePrepaidServiceContractTemplate(ServiceContractTemplate);

        // 2. Exercise: Create and Modify Service Contract Header and Service Contract Line.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 3. Verify: Check that Service Contract Template set fields TRUE in Service Contract.
        ServiceContractHeader.TestField(Prepaid, true);
        ServiceContractHeader.TestField("Combine Invoices", true);
        ServiceContractHeader.TestField("Contract Lines on Invoice", true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuotetLineValue()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Covers document number TC0073 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Service Contract Quote Line is same as Service Contract Quote Header.

        // Setup.
        Initialize();

        // 2. Exercise: Create Service Contract Quote Header and Service Contract Quote Line.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 3. Verify: Check that Service Contract Quote Line is same as Service Contract Quote Header.
        CheckSrvcCntractQuoteLinValues(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SignedServiceContractQuote()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0073 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Service Contract Quote does not exist after Signing Service Contract Quote.

        // 1. Setup: Create Service Contract Quote Header and Service Contract Quote Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign Service Contract Quote.
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // 3. Verify: Check that the Service Contract Quote does not exist after Signing Service Contract Quote.
        Assert.IsFalse(
          ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No."),
          StrSubstNo(ServiceCtrctHeaderExistErr, ServiceContractHeader.TableCaption(), ServiceContractHeader.FieldCaption("Contract Type"),
            ServiceContractHeader."Contract Type", ServiceContractHeader.FieldCaption("Contract No."), ServiceContractHeader."Contract No."));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractAfterQuote()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceItemNo: Code[20];
    begin
        // Covers document number TC0074, CU-5944-4 - refer to TFS ID 21730,172909.
        // [SCENARIO] The Test Case checks Service Item No is same after making Service Contract from Service Contract Quote and checks the Service
        // Contract that is created by Service Contract Quote.

        // 1. Setup: Create Service Contract Quote Header and Service Contract Quote Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceItemNo := ServiceContractLine."Service Item No.";

        // 2. Exercise: Sign Service Contract Quote.
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // 3. Verify: Check Service Item No is same after making Service Contract from Service Contract Quote and check the Service Contract
        // creation.
        ServiceContractLine.TestField("Service Item No.", ServiceItemNo);
        VerifyContractCreationByQuote(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractAfterSigned()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHour: Record "Service Hour";
        ServiceItemGroup: Record "Service Item Group";
        ContractServiceDiscount: Record "Contract/Service Discount";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0074 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks Status and Change Status field is changed after Sign Contract.

        // 1. Setup: Create Service Contract, Service Hours, Service Discount and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        CreateServiceContractLineItem(ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        LibraryService.CreateServiceHour(ServiceHour, ServiceContractHeader, ServiceHour.Day::Monday);

        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateContractServiceDiscount(
          ContractServiceDiscount, ServiceContractHeader, ContractServiceDiscount.Type::"Service Item Group", ServiceItemGroup.Code);

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Check that Status and Change Status field is changed after Sign Contract.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField(Status, ServiceContractHeader.Status::Signed);
        ServiceContractHeader.TestField("Change Status", ServiceContractHeader."Change Status"::Locked);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,FormModalHandler')]
    [Scope('OnPrem')]
    procedure CustomerNoOnServiceContract()
    begin
        // Covers document number TC0075 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks error raised when Customer No. does not exist in Header.

        // Setup.
        Initialize();

        // 2. Exercise: Create Service Contract Header without Customer No.
        ServiceContractHeader2.Init();
        ServiceContractHeader2.Validate("Contract Type", ServiceContractHeader2."Contract Type"::Contract);
        ServiceContractHeader2.Insert(true);
        Commit();

        // 3. Verify: Verify that error raised when Customer No. does not exist in Header.
        asserterror PAGE.RunModal(PAGE::"Service Contract");
        Assert.AreEqual(
          StrSubstNo(CustomerNotBlankErr, ServiceContractHeader2."Contract No."), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnCopyDocument()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // Covers document number TC0075 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case checks error raised on Copy Document when Customer No. not same.

        // Setup
        Initialize();

        // 2. Exercise: Create Service Contract Header.
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());

        // 3. Verify: Verify that error raised on Copy Document when Customer No. not same.
        asserterror CheckErrorOnCopyDocument(ServiceContractHeader);
        Assert.AreEqual(StrSubstNo(CopyDocumentErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure CopyDocumentOnServiceContract()
    var
        ServiceContractHeaderFrom: Record "Service Contract Header";
        ServiceContractHeaderTo: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLineTo: Record "Service Contract Line";
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
    begin
        // Covers document number TC0076, CU5940-1 - refer to TFS ID 21730, 172908.
        // [SCENARIO] The Test Case checks Service Contract Line fields are same after Copy Document.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeaderFrom, ServiceContractHeaderFrom."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeaderFrom);
        ModifyServiceContractHeader(ServiceContractHeaderFrom, ServiceContractHeaderFrom."Service Period");

        // 2. Exercise: Create Service Contract and Copy Document.
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeaderTo, ServiceContractHeaderTo."Contract Type"::Contract, ServiceContractHeaderFrom."Customer No.");
        ModifyServiceContractHeader(ServiceContractHeaderTo, ServiceContractHeaderTo."Service Period");
        CopyServiceContractMgt.CopyServiceContractLines(
            ServiceContractHeaderTo, ServiceContractHeaderFrom."Contract Type",
            ServiceContractHeaderFrom."Contract No.", ServiceContractLineTo);

        // 3. Verify: Check that Service Contract Line fields are same after Copy Document.
        ServiceContractLineTo.TestField("Service Item No.", ServiceContractLine."Service Item No.");
        ServiceContractLineTo.TestField("Line Value", ServiceContractLine."Line Value");
        ServiceContractLineTo.TestField("New Line", true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteDetailReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceContractQuoteDetail: Report "Service Contract Quote-Detail";
        FilePath: Text[1024];
        LineType: Enum "Service Comment Line Type";
    begin
        // Covers document number TC0076 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case Save Service Contract Quote Details report in XML and XLSX format after adding comments Date in Service Contract header and check that some data exist in saved files.

        // 1. Setup: Create Service Contract Quote Header and Service Contract Quote Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        LibraryService.CreateCommentLineForServCntrct(ServiceCommentLine, ServiceContractLine, LineType);
        ServiceCommentLine.Validate(Date, ServiceContractHeader."Starting Date");
        ServiceCommentLine.Modify(true);

        // 2. Exercise: Save Report as XML in local Temp folder.
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Clear(ServiceContractQuoteDetail);
        ServiceContractQuoteDetail.SetTableView(ServiceContractHeader);
        FilePath := TemporaryPath + Format(ServiceContractHeader."Contract Type") + ServiceContractHeader."Contract No." + '.xlsx';
        ServiceContractQuoteDetail.SaveAsExcel(FilePath);

        // 3. Verify: Verify that Saved file have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractDetailReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceContractDetailRep: Report "Service Contract-Detail";
        FilePath: Text[1024];
    begin
        // Covers document number TC0077 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case Save Service Contract Details report in XML and XLSX format after adding comments and Date in Service Contract header and check that some data exist in saved files.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        LibraryService.CreateCommentLineForServCntrct(
            ServiceCommentLine, ServiceContractLine,
            "Service Comment Line Type".FromInteger(ServiceContractHeader."Contract Type".AsInteger()));
        ServiceCommentLine.Validate(Comment, Format(ServiceContractHeader.Description + ServiceContractHeader."Contract No."));
        ServiceCommentLine.Validate(Date, ServiceContractHeader."Starting Date");
        ServiceCommentLine.Modify(true);

        // 2. Exercise: Save Report as XML and XLSX in local Temp folder.
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Clear(ServiceContractDetailRep);
        ServiceContractDetailRep.SetTableView(ServiceContractHeader);
        FilePath := TemporaryPath + Format(ServiceContractHeader."Contract Type") + ServiceContractHeader."Contract No." + '.xlsx';
        ServiceContractDetailRep.SaveAsExcel(FilePath);

        // 3. Verify: Verify that Saved file have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TotalGroupByCustomerReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractCustomerRep: Report "Service Contract - Customer";
        FilePath: Text[1024];
    begin
        // Covers document number TC0078 - refer to TFS ID 21730.
        // [SCENARIO] The Test Case Save Service Contract Customer report in XML and XLSX format and check that some data exist in saved files.

        // Setup. Create Service Contract Header and Service Contract Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Save Service Contract Customer Report as XML and XLSX in local Temp folder.
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Clear(ServiceContractCustomerRep);
        ServiceContractCustomerRep.SetTableView(ServiceContractHeader);
        FilePath := TemporaryPath + Format(ServiceContractHeader."Contract Type") + ServiceContractHeader."Contract No." + '.xlsx';
        ServiceContractCustomerRep.SaveAsExcel(FilePath);

        // 3. Verify: Verify that Saved file have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemInformationOnLine()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Covers Test Case 144526 - refer to TFS ID 168064.
        // [SCENARIO] Test the Service Item on Service Contract Line.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Creating Service Contract.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);

        // 3. Verify: Service Item Details in Service Item Line must be same.
        VerifyServiceContractLine(ServiceContractLine);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure SumOfLineAmountOnHeader()
    var
        ServiceContractHeader: Record "Service Contract Header";
        LineAmount: Decimal;
    begin
        // Covers Test Case 144526 - refer to TFS ID 168064.
        // [SCENARIO] The Test the Service Contract Header details.

        // 1. Setup: Find a Customer, create Service Contract Header.
        Initialize();
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());

        // 2. Exercise: Creating multiple Service Contract Lines, adding the Line Amount.
        CreateMultipleContractLines(ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        LineAmount := SumOfLineAmount(ServiceContractHeader."Contract No.");

        // 3. Verify: Verify the Service Contract Header.
        VerifyServiceContractHeader(ServiceContractHeader, LineAmount);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure LockServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeader3: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // Covers document number CU5940-2 - refer to TFS ID 172908.
        // [SCENARIO] Test Service Invoice created on Lock Service Contract after Copy Document.

        // 1. Setup: Create two Service Contract and Sign last Service Contract.
        Initialize();
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        CreateAndModifyServiceContract(
          ServiceContractHeader3, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract Type"::Contract);
        SignServContractDoc.SignContract(ServiceContractHeader3);
        ServiceContractHeader3.Get(ServiceContractHeader3."Contract Type", ServiceContractHeader3."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader3);

        // 2. Exercise: Copy Document and Lock the Service Contract.
        ServiceContractHeader3.Get(ServiceContractHeader3."Contract Type", ServiceContractHeader3."Contract No.");
        CopyServiceContractMgt.CopyServiceContractLines(
            ServiceContractHeader3, ServiceContractHeader."Contract Type",
            ServiceContractHeader."Contract No.", ServiceContractLine);
        ServiceContractHeader3.Get(ServiceContractHeader3."Contract Type", ServiceContractHeader3."Contract No.");
        LockOpenServContract.LockServContract(ServiceContractHeader3);

        // 3. Verify: Verify that the Service Invoice Created after Lock Service Contract.
        ServiceContractHeader3.Get(ServiceContractHeader3."Contract Type", ServiceContractHeader3."Contract No.");
        ServiceContractHeader3.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader3.TestField("No. of Unposted Invoices", 2);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractInvPeriodText()
    var
        ServiceContractHeader: Record "Service Contract Header";
        StandardText: Record "Standard Text";
        ServiceLine: Record "Service Line";
        Currency: Record Currency;
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5940-3 - refer to TFS ID 172908.
        // [SCENARIO] Test Service Invoice created after Signing Service Contract with Contract Inv. Period Text Code on Service Mgt. Setup.

        // 1. Setup: Update Contract Inv. Period Text Code on Service Mgt. Setup and Create Service Contract.
        Initialize();
        FindStandardText(StandardText);
        UpdateContractPeriodTextCode(StandardText.Code);
        LibraryERM.FindCurrency(Currency);
        CreateServiceContractWithCurrency(ServiceContractHeader, Currency.Code, LibrarySales.CreateCustomerNo());

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Verify Created Invoice and Description on Created Service Invoice Line.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", 1);

        ServiceLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceLine.FindLast();
        Assert.AreEqual(StandardText.Description, CopyStr(ServiceLine.Description, 1, StrLen(StandardText.Description)), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ContractPriceIncreaseText()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        StandardText: Record "Standard Text";
        ServiceLine: Record "Service Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5940-7 - refer to TFS ID 172908.
        // [SCENARIO] Test Service Invoice creation with Price Inv. Increase Code and Print Increase Text True on Service Contract.

        // 1. Setup: Create and Sign Service Contract with Price Inv. Increase Code and Print Increase Text True.
        Initialize();
        FindStandardText(StandardText);
        CreateServiceContractHeader(ServiceContractHeader, StandardText.Code);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Invoice.
        CreateServiceInvoice(ServiceContractHeader);

        // 3. Verify: Verify Created Invoice and Description on Created Service Invoice Line.
        VerifyValuesOnContractHeader(ServiceContractHeader);

        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        ServiceLine.FindLast();
        Assert.AreEqual(StandardText.Description, CopyStr(ServiceLine.Description, 1, StrLen(StandardText.Description)), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure LineDiscountServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Test Service Invoice creation and verify lines have blank Line Discount % values.

        // 1. Setup: Create and Sign Service Contract with Service Period: Year and Prepaid = False.
        Initialize();
        CreateServiceContractMultiLines(
          ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        UpdateContractLineBlankServiceItemNo(ServiceContractLine);
        UpdateContractLineItemNo(ServiceContractLine);
        UpdateContractHeaderPrepaid(ServiceContractHeader, false);
        UpdateContractLineCostAndValue(ServiceContractLine);
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, CalcDate('<-CY>', WorkDate()),
          ServiceContractHeader."Invoice Period"::Year);

        // 2. Exercise: Sign Contract and Create Service Contract Invoice.
        SignServContractDoc.SignContract(ServiceContractHeader);
        CreateServiceInvoice(ServiceContractHeader);

        // 3. Verify: Verify Line Discount % is blank on Created Service Invoice Lines.
        VerifyLineDiscountOnServiceInvoice(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ContractLineInvLineTextCode()
    var
        ServiceContractHeader: Record "Service Contract Header";
        StandardText: Record "Standard Text";
        StandardText2: Record "Standard Text";
        ServiceLine: Record "Service Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5940-8 - refer to TFS ID 172908.
        // [SCENARIO] Test Service Invoice creation with Contract Inv. Line Text Code and Contract Line Inv. Text Code on Service Mgt. Setup.

        // 1. Setup: Update Contract Inv. Line Text Code and Contract Line Inv. Text Code on Service Mgt. Setup, Create and Sign Service
        // Contract.
        Initialize();
        FindStandardText(StandardText);
        FindDifferentStandardText(StandardText2, StandardText.Code);
        UpdateContractInvAndLineText(StandardText.Code, StandardText2.Code);
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Invoice.
        CreateServiceInvoice(ServiceContractHeader);

        // 3. Verify: Verify Created Invoice and Description on Created Service Invoice Lines.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", 1);

        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        Assert.AreEqual(StandardText2.Description, CopyStr(ServiceLine.Description, 1, StrLen(StandardText2.Description)), UnknownErr);
        ServiceLine.Next();
        Assert.AreEqual(StandardText.Description, CopyStr(ServiceLine.Description, 1, StrLen(StandardText.Description)), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SignContractWithPrepaidFalse()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document no CU-5944-3 - refer to TFS ID 172909.
        // [SCENARIO] The Test Case checks Signed Service Contract with Prepaid False.

        // 1. Setup: Create Service Contract Header, create Service Contract Line and modify the Service Contract Header.
        Initialize();
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        PrepaidFalseInServiceContract(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign the Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Verify the No of Service Invoice created by Service Contract.
        VerifyContractCreationByQuote(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure CopyDefaultHourOnContractQuote()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Covers document no CU-5944-5 - refer to TFS ID 172909.
        // [SCENARIO] The Test Case checks that Default Hours on Service Contract Quote is copied from Default Service Hours Setup.

        // 1. Setup: Create Service Contract Quote.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);

        // 2. Exercise: Copy the Default Hours from Default Service Hours Setup.
        CopyDefaultHoursFromSetup(ServiceContractHeader."Contract No.");

        // 3. Verify: Verify the Service Hours for Service Contract Quote with Service Hours Setup.
        VerifyServiceHoursWithSetup(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ContractByQuoteWithComment()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU-5944-6 - refer to TFS ID 172909.
        // [SCENARIO] The Test Case checks Service Contract creation by Service Contract Quote with Service Comments.

        // 1. Setup: Create Service Contract Quote, Comments for Quote, modify Service Contract Header.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        CreateCommentForServiceQuote(ServiceContractHeader."Contract No.");
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Create the Service Contract by Service Contract Quote.
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // 3. Verify: Verify that the Service Contract is created by Service Contract Quote.
        VerifyContractCreationByQuote(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ContractByQuoteWithDiscount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU-5944-6 - refer to TFS ID 172909.
        // [SCENARIO] The Test Case checks Service Contract creation by Service Contract Quote with Service Discount.

        // 1. Setup: Create Service Contract Quote, Comments for Quote, modify Service Contract Header.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        CreateServiceDiscountForQuote(ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Create the Service Contract by Service Contract Quote.
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // 3. Verify: Verify that the Service Contract is created by Service Contract Quote.
        VerifyContractCreationByQuote(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ContractByQuotePrepaidFalse()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU-5944-7 - refer to TFS ID 172909.
        // [SCENARIO] The Test Case checks Service Contract creation by Service Contract Quote with Prepaid False.

        // 1. Setup: Create Service Contract Quote,make Prepaid false in Service Contract Quote, modify Service Contract Header.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        PrepaidFalseInServiceContract(ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Create the Service Contract by Service Contract Quote.
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // 3. Verify: Verify that the Service Contract is created by Service Contract Quote.
        VerifyContractCreationByQuote(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ChangeBillToCustomerOnContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: Record "Service Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5988-3-1 - refer to TFS ID 172912.
        // [SCENARIO] Test Service Invoice creation from Signing Contract with Different Bill to Customer No.

        // 1. Setup: Create Service Contract and update different Bill to Customer No on Service Contract.
        Initialize();
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        UpdateBillToCostomerNo(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Verify Bill to Customer No. on Created Invoice.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", 1);

        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        ServiceLine.FindLast();
        ServiceLine.TestField("Bill-to Customer No.", ServiceContractHeader."Bill-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure PostInvoiceBillToCustomer()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5988-3-2 - refer to TFS ID 172912.
        // [SCENARIO] Test Post Service Invoice created from Signing Contract with Different Bill to Customer No.

        // 1. Setup: Create Service Contract, update different Bill to Customer No on Service Contract and Sign Service Contract.
        Initialize();
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        UpdateBillToCostomerNo(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Post Created Service Invoice.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify No. of Unposted Invoices and No. of Posted Invoices updated on Service Contract Header.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.CalcFields("No. of Unposted Invoices", "No. of Posted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", 0);
        ServiceContractHeader.TestField("No. of Posted Invoices", 1);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBySeviceContract()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        CurrentWorkDate: Date;
    begin
        // [SCENARIO] Test that Create Contract Invoices batch job creates a new Service Invoice.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Contract Invoice.
        CurrentWorkDate := WorkDate();
        WorkDate := ServiceContractHeader."Next Invoice Date";
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader);

        // 3. Verify: Verify creation of Service Invoice and values on Service Invoice.
        ServiceContractAccountGroup.Get(ServiceContractHeader."Serv. Contract Acc. Gr. Code");  // Find Service Contract Account Group.
        VerifyValuesOnServiceInvoice(ServiceContractHeader, ServiceContractAccountGroup."Prepaid Contract Acc.");

        // 4. Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceLinesOrder()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Test that Create Contract Invoices batch job creates a new Service Invoice from Service Contract with several lines.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContractMultiLines(
          ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign Contract and Create Service Contract Invoice.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Verify: Verify order of lines in Service Invoice.
        VerifyLinesOnServiceInvoice(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithLedgerEntry()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Test for Calculation of correct service ledger entry while creating a Service invoice on Contract card.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        UpdateInvoicePeriod(ServiceContractHeader, ServiceContractHeader."Invoice Period"::Year);
        UpdateContractLineCostAndValue(ServiceContractLine);
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Starting Date", LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 5));
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Invoice.
        CreateServiceInvoice(ServiceContractHeader);

        // 3. Verify: Verify Service Invoice and values of Cost Amount and Line Amount on Service Ledger Entry.
        VerifyServiceInvoice(ServiceContractHeader."Contract No.");

        Assert.AreEqual(12,
          GetServiceLedgerEntryLines(ServiceContractHeader."Contract No."),
          StrSubstNo(ServiceLedgerEntryErr, ServiceLedgerEntry.TableCaption(), Format(12))); // 12 for Invoice Period Year.

        VerifyAmountServiceLedgerEntry(ServiceContractHeader."Contract No.", ServiceContractLine."Line Cost" / 12);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceForExistingServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Test for creating a new service invoice for an existing service contract.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractExpirationDate(ServiceContractHeader, CalcDate('<5Y>', WorkDate()));
        UpdateInvoicePeriod(ServiceContractHeader, ServiceContractHeader."Invoice Period"::Year);
        UpdateContractLineCostAndValue(ServiceContractLine);
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 2. Exercise: Create Service Invoice.
        CreateServiceInvoice(ServiceContractHeader);

        // Post Created Service Invoice.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Reopen Service Contract.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);

        // Add Second Service Contract Line.
        CreateServiceContractLineUpdateAnnualAmount(ServiceContractHeader);

        // Lock Service Contract.
        LockOpenServContract.LockServContract(ServiceContractHeader);

        // Verify: Find created Service Invoice.
        FindServiceInvoiceHeader(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnServiceContract()
    var
        DefaultDimension: Record "Default Dimension";
        ServiceOrderType: Record "Service Order Type";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO] Test Dimension on Service Contract after updating Service Order Type on Service Contract Header.

        // 1. Setup: Create Service Order Type, Default Dimension for Service Order Type and Service Contract.
        Initialize();
        LibraryService.CreateServiceOrderType(ServiceOrderType);
        CreateDefaultDimension(DefaultDimension, ServiceOrderType.Code);
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Update Service Order Type on Service Contract Header.
        UpdateServiceOrderType(ServiceContractHeader, ServiceOrderType.Code);

        // 3. Verify: Verify Dimension on Service Contract Header.
        VerifyDimensionSetEntry(DefaultDimension, ServiceContractHeader."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnServiceOrder()
    var
        DefaultDimension: Record "Default Dimension";
        ServiceOrderType: Record "Service Order Type";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Test Dimension on Service Order Created from Service Contract with Default Dimensions.

        // 1. Setup: Create Service Order Type, Default Dimension for Service Order Type, Service Contract, Update Service Order Type on
        // Service Contract Header and Sign the Service Contract.
        Initialize();
        LibraryService.CreateServiceOrderType(ServiceOrderType);
        CreateDefaultDimension(DefaultDimension, ServiceOrderType.Code);
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        UpdateServiceOrderType(ServiceContractHeader, ServiceOrderType.Code);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Order from Service Contract.
        CreateServiceContractOrder(ServiceContractHeader);

        // 3. Verify: Verify Dimension on Service Order for Service Header and Service Item Line.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractHeader."Contract No.");
        VerifyDimensionSetEntry(DefaultDimension, ServiceHeader."Dimension Set ID");

        FindServiceItemLine(ServiceItemLine, ServiceHeader);
        VerifyDimensionSetEntry(DefaultDimension, ServiceItemLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderDimensionsFromServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        SignServContractDoc: Codeunit SignServContractDoc;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // [SCENARIO] Test Dimension on Service Order Created from Service Contract..

        // 1. Setup: Create Dimension, Service Contract, Update dimension on
        // Service Contract Header and Sign the Service Contract.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Dimension Set ID",
          LibraryDimension.CreateDimSet(ServiceContractHeader."Dimension Set ID", Dimension.Code, DimensionValue.Code));
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Create Service Order from Service Contract.
        CreateServiceContractOrder(ServiceContractHeader);

        // 3. Verify: Verify Dimension on Service Order for Service Header and Service Item Line.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractHeader."Contract No.");
        Assert.AreEqual(ServiceHeader."Dimension Set ID", ServiceContractHeader."Dimension Set ID", 'Dimension set id matches');
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,MsgHandler,ServiceInvoicePostHandler,PostedServInvoiceHandler')]
    [Scope('OnPrem')]
    procedure PostInvoiceFromServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContract: TestPage "Service Contract";
        ServiceDocumentRegisters: TestPage "Service Document Registers";
        LineAmount: Variant;
        Amount: Decimal;
    begin
        // [SCENARIO] Test post the Service Invoice from Unposted Invoices On the Service Contract Card of the Signed Service Contract with no error.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateContractHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.SignContract.Invoke();
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // 2. Exercise: Post the Service Invoice from the handler.
        ServiceDocumentRegisters.OpenEdit();
        ServiceDocumentRegisters.FILTER.SetFilter("Source Document No.", ServiceContract."Contract No.".Value);
        ServiceDocumentRegisters.ShowDocument.Invoke();
        LibraryVariableStorage.Dequeue(LineAmount);
        Evaluate(Amount, Format(LineAmount));

        // 3. Verify: Verify GL Entry, Detailed Cust Ledger Entry for the Service Invoice Line Amount.
        VerifyAmountOnGLEntry(ServiceContractHeader."Contract No.", ServiceContractHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceContractCard()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContract: TestPage "Service Contract";
        CurrentWorkDate: Date;
    begin
        // [SCENARIO] Test to verify program creates a Service Invoice on Contract Card through Create Service Invoice function after changing
        // the Line value on Contract Line.

        // 1. Setup: Create and Sign Service Contract and modify WORKDATE.
        Initialize();
        CurrentWorkDate := WorkDate();
        CreateContractHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        UpdateContractLineCostAndValue(ServiceContractLine);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.SignContract.Invoke();
        WorkDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', DMY2Date(1, Date2DMY(WorkDate(), 2), Date2DMY(WorkDate(), 3)));

        // 2. Exercise: Create a Service Invoice.
        ServiceContract.CreateServiceInvoice.Invoke();

        // 3. Verify: Verify Service Invoice created, updated Line Value and Cost Value.
        VerifyServiceInvoice(ServiceContractHeader."Contract No.");
        VerifyAmountServiceLedgerEntry(ServiceContractHeader."Contract No.", ServiceContractLine."Line Value" / 12);

        // 4. TearDown: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ContractTemplateConfirmHandlerFalse,ContractLineSelectionHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractLineSelection()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
    begin
        // [SCENARIO] Test to verify that program should close the Contract Line Selection page after clicking Cancel button when service Item No
        // is blank on the Contract Line Selection page.

        // 1. Setup: Create and modify Service Contract Header.
        Initialize();
        CreateContractHeader(ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Open Contract Line Selection page from Service Contract.
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.SelectContractLines.Invoke();

        // 3. Verify: Verify that the Contract Line Selection page is blank and is closed by clicking Cancel through the handler ContractLineSelectionHandler.
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractInvoiceByPage()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        CurrentWorkDate: Date;
    begin
        // [SCENARIO] Test using Page Testability that Create Contract Invoices batch job creates a new Service Invoice.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Open Service Contract Page and Create Service Contract Invoice.
        CurrentWorkDate := WorkDate();
        WorkDate := ServiceContractHeader."Next Invoice Date";
        OpenServiceContractPage(ServiceContractHeader."Contract No.");

        // 3. Verify: Verify creation of Service Invoice and values on Service Invoice.
        ServiceContractAccountGroup.Get(ServiceContractHeader."Serv. Contract Acc. Gr. Code");  // Find Service Contract Account Group.
        VerifyValuesOnServiceInvoice(ServiceContractHeader, ServiceContractAccountGroup."Prepaid Contract Acc.");

        // 4. Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,InvoiceConfirmHandler')]
    [Scope('OnPrem')]
    procedure SignContractWithNoInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceInvoiceCount: Integer;
    begin
        // [SCENARIO] Check that Service Invoice is not created after signing Service Contract and decline the message to create Service Invoice.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        ServiceInvoiceCount := GetServiceInvoiceCount();  // Store Old Service Invoice Count.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // 2. Exercise: Sign Service Contract.
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 3. Verify: Verify that no new Service Invoice is created after signing Contract and declining the message to create Service Invoice for signed Contract.
        Assert.AreEqual(
          ServiceInvoiceCount, GetServiceInvoiceCount(), StrSubstNo(ServiceLedgerEntryErr, ServiceHeader.TableCaption(), ServiceInvoiceCount));
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,InvoiceConfirmHandler,CreateContractServiceOrdersRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ContractServiceOrderForContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Check that Service Order created after running Create Contract Service Orders batch job for Contract.

        // 1. Setup: Create Service Contract Header and Service Contract Line, sign Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // 2. Exercise.
        RunCreateContractServiceOrders();

        // 3. Verify: Verify that Service Order Created after running Create Contract Service Orders batch job.
        Assert.IsTrue(
          FindServiceDocumentWithContractNo(ServiceHeader."Document Type"::Order, ServiceContractHeader."Contract No."),
          StrSubstNo(EntryMustExistErr, ServiceHeader.TableCaption(), ServiceContractHeader."Contract No."));
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,InvoiceConfirmHandler,CreateContractServiceOrdersRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ShipServiceOrderCreatedFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Check that Service Shipment contains Contract No. when Service Order created through Create Contract Service Orders batch job posted as Ship only.

        // 1. Setup: Create Service Contract Header and Service Contract Line, sign Contract, run Create Contract Service Order batch report.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractServiceOrders();

        // 2. Exercise: Post Service Order created from Contract with Ship option.
        CreateServiceLineForServiceOrder(ServiceHeader, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify that posted Shipment contain Contract No.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Assert.IsTrue(
          ServiceShipmentHeader.FindFirst(),
          StrSubstNo(EntryMustExistErr, ServiceShipmentHeader.TableCaption(), ServiceContractHeader."Contract No."));
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,InvoiceConfirmHandler,CreateContractServiceOrdersRequestPageHandler,CreateContractInvoicesRequestPageHandler,InvoiceCreationMessageHandler')]
    [Scope('OnPrem')]
    procedure UnsuccessfulInvoiceCreationFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceInvoiceCount: Integer;
    begin
        // [SCENARIO] Check that Service Invoice Creation Message appears for un-successful creation of Invoice after running Create Contract Invoice Batch Job.

        // 1. Setup: Create Service Contract, sign Contract, run Create Contract Service Order batch report. Find Service Order and Post it as Ship.
        Initialize();
        ServiceInvoiceCount := GetServiceInvoiceCount();  // Store Old Service Invoice Count.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        LibraryVariableStorage.Enqueue('');
        RunCreateContractServiceOrders();
        CreateServiceLineForServiceOrder(ServiceHeader, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(InvoiceCreatedMsg, 0));
        RunCreateContractInvoices();

        // 3. Verify: Verify message '0 Invoice was created.' and verify that no new Service Invoice Created.
        Assert.AreEqual(
          ServiceInvoiceCount, GetServiceInvoiceCount(), StrSubstNo(ServiceLedgerEntryErr, ServiceHeader.TableCaption(), ServiceInvoiceCount));
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,InvoiceConfirmHandler,CreateContractServiceOrdersRequestPageHandler,CreateContractInvoicesRequestPageHandler,InvoiceCreationMessageHandler')]
    [Scope('OnPrem')]
    procedure SuccessfulInvoiceCreationFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Check that Service Invoice Creation Message appears for successful creation of Invoice after running Create Contract Invoice Batch Job.

        // 1. Setup: Create Service Contract, sign Contract, run Create Contract Service Order batch report. Find Service Order and Post it as Ship and Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        LibraryVariableStorage.Enqueue('');
        RunCreateContractServiceOrders();
        CreateServiceLineForServiceOrder(ServiceHeader, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 2. Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CalcDate(ServiceContractHeader."Service Period", WorkDate()));
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(InvoiceCreatedMsg, 1));
        RunCreateContractInvoices();

        // 3. Verify: Verify message '1 Invoice was created.' and created Invoice Contain correct Contract No.
        Assert.IsTrue(
          FindServiceDocumentWithContractNo(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No."),
          StrSubstNo(EntryMustExistErr, ServiceHeader.TableCaption(), ServiceContractHeader."Contract No."));
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesAfterPostingServiceInvoice()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        PostedServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SignServContractDoc: Codeunit SignServContractDoc;
        InvoiceNo: Code[20];
        TotalAmount: Decimal;
        Amount: Decimal;
        VATPercent: Decimal;
        CurrentWorkDate: Date;
    begin
        // [SCENARIO] Test GL Entries when post Service Invoice after signing Service Contract.

        // 1. Setup: Create Service Contract with Yearly Invoice Period and Line Discount and Sign the Contract.
        Initialize();
        CreateContractWithInvPeriodYear(ServiceContractHeader, ServiceContractLine);
        ServiceContractLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Take Random value for Discount%.
        ServiceContractLine.Modify(true);
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // Added part to correct the starting date if invoice date and starting date are the same then set starting date back by one
        if ServiceContractHeader."Next Invoice Date" = ServiceContractHeader."Starting Date" then begin
            ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Starting Date" - 1);
            ServiceContractHeader.Modify(true);
        end;
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SetHideDialog := true;
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Commit();

        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        Customer.Get(ServiceContractHeader."Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        ServiceContractAccountGroup.Get(ServiceContractHeader."Serv. Contract Acc. Gr. Code");
        GLAccount.Get(ServiceContractAccountGroup."Prepaid Contract Acc.");
        VATPostingSetup.Get(Customer."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        Amount := ServiceContractLine."Line Value" - (ServiceContractLine."Line Value" * ServiceContractLine."Line Discount %" / 100);

        VATPercent := 0;
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
            VATPercent := VATPostingSetup."VAT %" / 100;

        TotalAmount := Amount + (Amount * VATPercent);

        // 2. Exercise: Create and Post Service Invoices.
        InvoiceNo := InitCurrWorkDateAndPostServiceInvoice(CurrentWorkDate, ServiceContractHeader);

        // 3. Verify: Verify GL Entries after posting Service invoice.
        PostedServiceInvoiceHeader.SetRange("Pre-Assigned No.", InvoiceNo);
        PostedServiceInvoiceHeader.FindFirst();

        VerifyInvoicedGLAmt(PostedServiceInvoiceHeader."No.", CustomerPostingGroup."Receivables Account", TotalAmount);

        // 4. Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesAfterPostingPrepaidContractEntries()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceHeader: Record "Service Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SignServContractDoc: Codeunit SignServContractDoc;
        InvoiceNo: Code[20];
        Amount: Decimal;
        CurrentWorkDate: Date;
    begin
        // [SCENARIO] Test GL Entries after posting Prepaid Contract Entries for a Service Contrct.

        // 1. Setup: Create Service Contract with Yearly Invoice Period and Line Discount and Sign the Contract.
        Initialize();
        LibrarySales.SetDiscountPostingSilent(SalesReceivablesSetup."Discount Posting"::"All Discounts");
        CurrentWorkDate := WorkDate();
        CreateContractWithInvPeriodYear(ServiceContractHeader, ServiceContractLine);
        ServiceContractLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Take Random value for Discount%.
        ServiceContractLine.Modify(true);
        ServiceContractAccountGroup.Get(ServiceContractHeader."Serv. Contract Acc. Gr. Code");
        UpdateServContractAccGroup(ServiceContractAccountGroup);
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Next Invoice Date");
        WorkDate := ServiceContractHeader."Next Invoice Date";
        SignServContractDoc.SetHideDialog := true;
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        Amount := RoundBasedOnCurrencyPrecision(ServiceContractLine."Line Value" / 12);  // Take 12 because Invoice Period is yearly.

        // Create and Post Service Invoices.
        InvoiceNo := CreateServiceInvoice(ServiceContractHeader);
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, InvoiceNo);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Commit();

        // 2. Exercise: Post Prepaid Contract Entries.
        PostPrepaidContractEntryWithNextInvoiceDate(ServiceContractHeader);

        // 3. Verify: Verify GL Entries after posting Service invoice.
        VerifyGLEntryForPostPrepaidContract(
          ServiceContractAccountGroup."Non-Prepaid Contract Acc.", ServiceContractHeader."Contract No.", -Amount);

        // 4. Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,AnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewEntriesAfterPostingServiceInvoice()
    var
        AnalysisView: Record "Analysis View";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
        Amount: Decimal;
    begin
        // [SCENARIO] Test Analysis View Entries when post Service Invoice after signing Service Contract.

        // 1. Setup: Create Analysis View, Create Service Contract and Sign the Contract.
        Initialize();
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreateAndSignContractOnToday(ServiceContractHeader, ServiceContractLine, ServiceContractAccountGroup);
        CreateAnalysisView(
          AnalysisView,
          StrSubstNo(
            AccountFilterMsg, ServiceContractAccountGroup."Non-Prepaid Contract Acc.",
            ServiceContractAccountGroup."Prepaid Contract Acc."), WorkDate());
        Amount := RoundBasedOnCurrencyPrecision(ServiceContractLine."Line Amount" / 12);

        // 2. Exercise: Create and Post Service Invoice.
        CreateServiceInvoice(ServiceContractHeader);
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);

        // 3. Verify: Open Analysis View List and Verify Sales Analysis By Dimension matrix Page through 'SalesAnalysisbyDimMatrixPageHandler'.
        AnalysisViewList.OpenEdit();
        AnalysisViewList.FILTER.SetFilter(Code, AnalysisView.Code);
        AnalysisbyDimensions.Trap();
        AnalysisViewList."&Update".Invoke();
        AnalysisViewList.EditAnalysis.Invoke();

        Assert.AreEqual(
          -Amount,
          GetAnalysisViewTotalAmount(AnalysisbyDimensions, ServiceContractAccountGroup."Prepaid Contract Acc."),
          'Prepaid Contract Acc.');

        Assert.AreEqual(
          0,
          GetAnalysisViewTotalAmount(AnalysisbyDimensions, ServiceContractAccountGroup."Non-Prepaid Contract Acc."),
          'Non-Prepaid Contract Acc.');
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,AnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewEntriesAfterPostingPrepaidContractEntries()
    var
        AnalysisView: Record "Analysis View";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
        Amount: Decimal;
    begin
        // [SCENARIO] Test Analysis View Entries after posting Prepaid Contract Entries for a Service Contract.

        // 1. Setup: Create Analysis View, Create Service Contract and Sign the Contract, create and post the Service Invoice.
        Initialize();

        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreateAndSignContractOnToday(ServiceContractHeader, ServiceContractLine, ServiceContractAccountGroup);
        CreateAnalysisView(
          AnalysisView,
          StrSubstNo(
            AccountFilterMsg, ServiceContractAccountGroup."Non-Prepaid Contract Acc.",
            ServiceContractAccountGroup."Prepaid Contract Acc."), WorkDate());
        Amount := RoundBasedOnCurrencyPrecision(ServiceContractLine."Line Amount" / 12);

        CreateServiceInvoice(ServiceContractHeader);
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);

        // 2. Exercise: Post Prepaid Contract Entries.
        PostPrepaidContractEntryWithNextInvoiceDate(ServiceContractHeader);

        // 3. Verify: Open Analysis View List and Verify Sales Analysis By Dimension matrix Page through 'SalesAnalysisbyDimMatrixPageHandler'.
        AnalysisViewList.OpenEdit();
        AnalysisViewList.FILTER.SetFilter(Code, AnalysisView.Code);
        AnalysisbyDimensions.Trap();
        AnalysisViewList."&Update".Invoke();
        AnalysisViewList.EditAnalysis.Invoke();

        Assert.AreEqual(
          -Amount,
          GetAnalysisViewTotalAmount(AnalysisbyDimensions, ServiceContractAccountGroup."Non-Prepaid Contract Acc."),
          'Non-Prepaid Contract Acc.');

        Assert.AreEqual(
          0,
          GetAnalysisViewTotalAmount(AnalysisbyDimensions, ServiceContractAccountGroup."Prepaid Contract Acc."),
          'Prepaid Contract Acc.');
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBySeviceContractWithInvoicePeriod()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO] Test Amount on GL Entry equal to Customer Balance(LCY) when Service Invoice is Posted with Invoice Period Quarter.

        // Setup: Create and Sign Service Contract.
        Initialize();
        CreateSignedServiceContractWithInvoicePeriod(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader);

        // Exercise: Create Service Contract Invoice.
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // Verify: Verify creation of Service Invoice and values on Service Invoice.
        VerifyAmountOnGLEntry(ServiceContractHeader."Contract No.", ServiceContractHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditmemoWithGetPrepaidContractEntries()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO] Test Service Lines in the Credit Memo correspond to the Service Lines in the Posted Service Invoice when Invoice is Posted with Invoice Period Quarter.

        // Setup: Create and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateSignedServiceContractWithInvoicePeriod(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Customer No.");

        // Exercise: Create Service Credit Memo by inserting Credit Memo Header and running Get Prepaid Contract Entries.
        GetPrepaidContractEntry(ServiceHeader, ServiceContractHeader."Contract No.");

        // Verify: Verify Unit Cost(LCY) not equal to Zero on Service Credit Memo Lines.
        VerifyUnitCostNotEqualToZeroOnCreditMemoLines(
          ServiceContractLine."Customer No.", ServiceContractLine."Service Item No.", ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('InvoiceConfirmHandler,ServContrctTemplateListHandler,CreateContractInvoicesRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceCreatedWithMultipleContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeader2: Record "Service Contract Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Test Service Invoice Created Sucessfully for multiples Service Contracts by batch report Create Contract Service Invoice.

        // Setup: Create and sign Service Contract with No Invoice.
        Initialize();
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        CreateAndModifyServiceContract(
          ServiceContractHeader2, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract Type"::Contract);
        SignServContractDoc.SignContract(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader2);
        LibraryVariableStorage.Enqueue(CalcDate(StrSubstNo('<%1Y>', LibraryRandom.RandInt(10)), WorkDate()));
        LibraryVariableStorage.Enqueue(
          StrSubstNo(AccountFilterMsg, ServiceContractHeader."Contract No.", ServiceContractHeader2."Contract No."));

        // Exercise: Run Create Contract Invoices Report.
        Commit(); // Due to limitation in Page Testability Commit is required for this Test Case.
        RunCreateContractInvoices();

        // Verify: Verify Service Invoice Created.
        VerifyServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesAfterPostingServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO] Test Service Ledger entries Created with Shipment and Invoice after Posting Service Invoice.

        // Setup: Create and sign Service Contract. Post the Service Invoice when Invoice Period is Quarter.
        Initialize();
        CreateSignedServiceContractWithInvoicePeriod(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader);

        // Exercise: Create Service Contract Invoice.
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // Verify: Verify Service Ledger Entry Lines created with Document Type Shipment and Invoice
        // Verify entries created with Document Type Shipment Reverse of Document Type Invoice
        // And also verify Unit Cost Shipment equal to Unit Cost of Invoice.
        VerifyServiceLedgerEntry(ServiceContractHeader."Contract No.", ServiceLedgerEntry."Document Type"::Invoice, -1);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesAfterPostingServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO] Test Service Ledger entries Created with Document Types Shipment and Creditmemo after Posting Service Credit Memo when Invoice is Posted with Invoice Period Quarter.

        // Setup: Create Service Contract with signed and Service Credit Memo by inserting Credit Memo Header and running Get Prepaid Contract Entries.
        Initialize();
        CreateSignedServiceContractWithInvoicePeriod(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.SetRecFilter();
        CreateServiceContractInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Customer No.");
        GetPrepaidContractEntry(ServiceHeader, ServiceContractHeader."Contract No.");

        // Exercise: Post Service Credit Memo with Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Service Ledger Entry Lines created with Document Type Shipment and Credit Memo
        // Verify entries created with Document Type Shipment Reverse of Document Type Credit Memo
        // And also verify Unit Cost Shipment equal to Unit Cost of Credit Memo.
        VerifyServiceLedgerEntry(ServiceContractHeader."Contract No.", ServiceLedgerEntry."Document Type"::"Credit Memo", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnModifyTypeOnServiceLine()
    var
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Test program does not allow to update the Type value on service line and populates error message.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        InitServiceLineWithSignedContract(ServiceLine);

        // Exercise: Update Type on Service Line.
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::" ");

        // Verify: Verify program not allow to update Type field value.
        Assert.ExpectedError(ServiceEntriesExistForServiceLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnModifyNoOnServiceLine()
    var
        ServiceLine: Record "Service Line";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] Test program does not allow to update the No. field value on service line and populates error message.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        GLAccount.FindFirst();
        InitServiceLineWithSignedContract(ServiceLine);

        // Exercise: Update Type on Service Line.
        asserterror ServiceLine.Validate("No.", GLAccount."No.");

        // Verify: Verify program not allow to update No. field value.
        Assert.ExpectedError(ServiceEntriesExistForServiceLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnModifyUnitPriceOnServiceLine()
    var
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Test program does not allow to update the unit price on service line and populates error message.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        ServiceLine."Document Type" := ServiceLine."Document Type"::Invoice;
        ServiceLine."Document No." := LibraryUtility.GenerateGUID();
        ServiceLine."Line No." := 10000;
        ServiceLine.Insert();
        InitServiceLineWithSignedContract(ServiceLine);

        // Exercise: Call OnModify trigger.
        asserterror ServiceLine.Modify(true);

        // Verify: Verify program not allow to update Unit Price value.
        Assert.ExpectedError(ServiceEntriesExistForServiceLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnModifyShortCutDimension1CodeOnServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Test program does not allow to update the Shortcut Dimension 1 Code on Service Header and populates error message.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        InitServiceInvoiceWithContract(ServiceHeader);

        // Exercise: Change Shortcut Dimension 1 Code on service header.
        asserterror ServiceHeader.Validate("Shortcut Dimension 1 Code", '');

        // Verify: Verify program not allow to update Shortcut Dimension Code value.
        Assert.ExpectedError(DimensionNotChangeableServiceEntriesExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnModifyShortCutDimension2CodeOnServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Test program does not allow to update the Shortcut Dimension 2 Code on service Header and populates error message.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        InitServiceInvoiceWithContract(ServiceHeader);

        // Exercise: Change Shortcut Dimension 2 Code on service header.
        asserterror ServiceHeader.Validate("Shortcut Dimension 2 Code", '');

        // Verify: Verify program not allow to update Shortcut Dimension Code value.
        Assert.ExpectedError(DimensionNotChangeableServiceEntriesExistErr);
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,MsgHandler,DimensionSetEntriesNotEditablePageHandler')]
    [Scope('OnPrem')]
    procedure CheckDimensionSetEntriesPageWithContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Dimension Set Entries page is in non editable mode when we check the line dimension with Contract No.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        CreateAndSignServiceContractWithInvoice(ServiceLine);

        // Exercise: Invoke Line Dimension With Contract No.
        InvokeLineDimensionFromServiceInvoice(ServiceLine, ServiceLine."Contract No.");

        // Verify: Verification is done in 'DimensionSetEntriesNotEditablePageHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,DimensionSetEntriesEditablePageHandler')]
    [Scope('OnPrem')]
    procedure CheckDimensionSetEntriesPageWithContractNoAndNotApplied()
    var
        ServiceLine: Record "Service Line";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO] Dimension Set Entries page is in editable mode when we check the line dimension with Contract No and empty 'Appl.-to Service Entry'.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        CreateServiceInvoiceNotApplied(ServiceContractHeader, ServiceLine);

        // Exercise: Invoke Line Dimension With Contract No.
        InvokeLineDimensionFromServiceInvoice(ServiceLine, ServiceLine."Contract No.");

        // Verify: Verification is done in 'DimensionSetEntriesEditablePageHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,MsgHandler,DimensionSetEntriesEditablePageHandler')]
    [Scope('OnPrem')]
    procedure CheckEditDimensionSetEntriesPageWithoutContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Edit Dimension Set Entries page is in editable mode when we check the line dimension with blank Contract No.

        // Setup: Create and sign Service Contract with Invoice.
        Initialize();
        CreateAndSignServiceContractWithInvoice(ServiceLine);

        // Exercise: Invoke Line Dimension With Blank Contract No.
        InvokeLineDimensionFromServiceInvoice(ServiceLine, '');

        // Verify: Verification is done in 'DimensionSetEntriesEditablePageHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ContractNoOnServiceItemLineWithExpirationDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemNo: Code[20];
    begin
        // [SCENARIO] Test Contract No on the Service Item line should be populated when Service Order is created with Expiration Date of service contract header.

        // Setup: Create and sign Service Contract.
        Initialize();
        ServiceItemNo := CreateServiceContractWithExpirationDate(ServiceContractHeader);

        // Exercise: Create Service Order with expiration date.
        CreateServiceHeaderWithExpirartionDate(ServiceHeader, ServiceContractHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);

        // Verify: Verify Contract No on Service item line.
        ServiceItemLine.TestField("Contract No.", ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler,MsgHandler,ServContrListServItemListHandler')]
    [Scope('OnPrem')]
    procedure ContractNoOnServiceItemListWithExpirationDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderPage: TestPage "Service Order";
        ServiceItemNo: Code[20];
    begin
        // [SCENARIO] Test Contract No on Service contract List page when Service order Created with Expiration Date of Service Contract Header.

        // Setup: Create and sign Service Contract.
        Initialize();
        ServiceItemNo := CreateServiceContractWithExpirationDate(ServiceContractHeader);
        CreateServiceHeaderWithExpirartionDate(ServiceHeader, ServiceContractHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // Exercise: Open Service Order Page and call contract no field lookup.
        ServiceOrderPage.OpenEdit();
        ServiceOrderPage.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceOrderPage.ServItemLines."Contract No.".Lookup();

        // Verify: Verify has been done in ServContrListServItemListHandler.
    end;

    [Test]
    [HandlerFunctions('ServContractConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure LastInvoiceDateOnServiceContractHeader()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Test Last Invoice Date on Service Contract Header when Starting Date updated after Locked.

        // Setup: Create and modify Starting Date after Opening Service Contract.
        Initialize();
        CreateSignedServiceContractWithServicePeriod(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        ServiceContractLine.Delete(true);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, CalcDate('<CM>', WorkDate()),
          ServiceContractHeader."Invoice Period"::Month);

        // Exercise: Lock Service Contract after modifing.
        LockOpenServContract.LockServContract(ServiceContractHeader);

        // Verify: Verify Last Invoice Date on Service Contract Header.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Last Invoice Date", ServiceContractHeader."Starting Date");
    end;

    [Test]
    [HandlerFunctions('ServContractConfirmHandler,MsgHandler,CreateContractInvoicesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunCreateServiceInvoiceAfterServiceContractLocked()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Verify no Error message appear after create Service Invoice When Service Contractlocked.

        // Setup: Create and Lock Service Contract.
        Initialize();
        CreateSignedServiceContractWithServicePeriod(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        ServiceContractLine.Delete(true);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, CalcDate('<CM>', WorkDate()),
          ServiceContractHeader."Invoice Period"::Month);
        LockOpenServContract.LockServContract(ServiceContractHeader);

        // Exercise: Run Create Contract Invoices Report.
        Commit();  // Due to limitation in Request Page Testability Commit is required for this Test Case.
        LibraryVariableStorage.Enqueue(CalcDate('<CM+1M>', WorkDate()));
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();

        // Verify: Verify Invoice created with Contract No. with out any error Message.
        Assert.IsTrue(
          FindServiceDocumentWithContractNo(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No."),
          StrSubstNo(EntryMustExistErr, ServiceHeader.TableCaption(), ServiceContractHeader."Contract No."));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure MixedCurrenciesOnContracts()
    var
        ServiceContractHeader: Record "Service Contract Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO] Service Invoices for one and the same customer cannot be combined if they are created from Service Contracts with different currencies.
        Initialize();

        // [GIVEN] Two signed Service Contracts with different currencies, both were created for Customer = "C1".
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateServiceContractWithCurrency(ServiceContractHeader, LibraryERM.CreateCurrencyWithRandomExchRates(), CustomerNo);
        ServiceContractHeader.Validate("Starting Date", LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 5));
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        Clear(ServiceContractHeader);
        CreateServiceContractWithCurrency(ServiceContractHeader, LibraryERM.CreateCurrencyWithRandomExchRates(), CustomerNo);
        ServiceContractHeader.Validate("Starting Date", LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 5));
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [WHEN] Create Service Invoices for Service Contracts.
        ServiceContractHeader.SetRange("Bill-to Customer No.", CustomerNo);
        asserterror CreateServiceContractInvoice(ServiceContractHeader);

        // [THEN] Error "Service Contracts with different currencies cannot be combined on one invoice" occurs.
        Assert.ExpectedError(StrSubstNo('Customer %1 has service contracts with different currency codes', CustomerNo));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,ReportHandler')]
    [Scope('OnPrem')]
    procedure ChangingCustomerNoOnContracts()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        CreateContractInvoices: Report "Create Contract Invoices";
        ContractNo: array[3] of Variant;
        i: Integer;
        ExpectedCount: Integer;
        CustomerNo: Code[20];
        ShiptoAddressCode: Code[10];
    begin
        Initialize();
        // [SCENARIO] Create 3 contracts with 2 different customer numbers:
        LibraryVariableStorage.Enqueue(3);
        for i := 1 to 3 do begin
            PrepareServiceContractsForInvoiceGeneration(ServiceContractHeader, i, 3);
            if i = 2 then begin
                CustomerNo := ServiceContractHeader."Customer No.";
                ShiptoAddressCode := ServiceContractHeader."Ship-to Code";
            end;
            if i = 3 then begin
                ServiceContractHeader."Customer No." := CustomerNo;
                ServiceContractHeader."Bill-to Customer No." := CustomerNo;
                ServiceContractHeader."Ship-to Code" := ShiptoAddressCode;
            end;
            ServiceContractHeader.Modify(true);
        end;
        Commit();
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ExpectedCount := ServiceHeader.Count();
        Clear(ServiceContractHeader);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        for i := 1 to 3 do
            LibraryVariableStorage.Peek(ContractNo[i], i + 1);
        ServiceContractHeader.SetFilter("Contract No.", '%1|%2|%3', ContractNo[1], ContractNo[2], ContractNo[3]);
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(WorkDate(), WorkDate(), 0); // 0 => Create invoices
        CreateContractInvoices.SetHideDialog(true);
        CreateContractInvoices.Run();
        Assert.AreEqual(ExpectedCount + 2, ServiceHeader.Count, 'Wrong number of service invoices created.');
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler,CreateContractServiceOrdersRequestPageHandler,ServiceGetShipmentHandler')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceByGetShipmentLines()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Test No. of Posted Invoices should be updated when creating and posting a service invoice by Get Shipment Lines function

        // Setup: Create Service Contract and Sign Service Contract.
        Initialize();
        CreateAndSignServiceContract(ServiceContractHeader);

        // Create a Service Order. Create Service Line and update Qty to Invoice. Post Created Service Order
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractServiceOrders();
        CreateServiceLineForServiceOrder(ServiceHeader, ServiceContractHeader."Contract No.");
        UpdateServiceLineForQtyToInvoice(ServiceLine, ServiceHeader."No.", ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Post Ship and Invoice.

        // Exercise: Create a Service Invoice by Get Shipment Lines function. Post Service Invoice.
        CreateAndPostServiceInvoiceByGetShipmentLines(ServiceLine."Customer No.", ServiceHeader."No.");

        // Verify: Verify No. of Posted Invoices updated on Service Contract Header.
        VerifyServiceContractHeaderForNoOfUnpostedInvoices(ServiceContractHeader, 2);
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceFromServiceContractWithLineDiscount()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Test GL Entries after posting Prepaid Contract Entries for a Service Contrct with All Discount.
        PostServiceInvoiceFromServiceContractWithDiscount(SalesReceivablesSetup."Discount Posting"::"Line Discounts");
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceFromServiceContractWithNoDiscount()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Test GL Entries after posting Prepaid Contract Entries for a Service Contrct with No Discount.
        PostServiceInvoiceFromServiceContractWithDiscount(SalesReceivablesSetup."Discount Posting"::"No Discounts");
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoGLEntriesWhenPostPrepaidServContractEntriesOnInvAndCrMemo()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        CurrentWorkDate: Date;
        NonPrepaidContrAccCode: Code[20];
    begin
        // [SCENARIO 360390] Test verifies that no GL Entries created after posting Prepaid Contract Entries for Service Contract with Invoice and Credit Memo

        // [GIVEN] Signed Service Contract with "Invoice Period" = Year
        Initialize();
        CreateContractWithInvPeriodYear(ServiceContractHeader, ServiceContractLine);
        NonPrepaidContrAccCode :=
          GetNonPerpaidContractAccFromCust(ServiceContractHeader."Customer No.", ServiceContractHeader."Serv. Contract Acc. Gr. Code");

        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SetStartingDateAsNextInvDateAndSignContract(ServiceContractHeader);

        // [GIVEN] Posted Service Invoice
        InitCurrWorkDateAndPostServiceInvoice(CurrentWorkDate, ServiceContractHeader);

        // [GIVEN] Posted Credit Memo
        CreateAndPostServiceCreditMemo(ServiceContractHeader);

        // [WHEN] Run "Post Prepaid Service Contract Entries" batch job
        PostPrepaidContractEntry(
          ServiceContractHeader."Contract No.", CalcDate('<1Y>', WorkDate()), WorkDate());

        // [THEN] No G/L Entries are created
        Assert.IsTrue(
          NoGLEntriesFound(NonPrepaidContrAccCode, ServiceContractHeader."Contract No."), GLEntriesExistsErr);

        // Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SignLockedServiceContractQuote()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 360817] Sign Service Contract Quote with Status "Locked"

        // [GIVEN] Locked Service Contract Quote
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        LockOpenServContract.LockServContract(ServiceContractHeader);
        ServiceContractHeader.Find();

        // [WHEN] Sign Service Contract Quote
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // [THEN] Service contract created
        ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Contract;
        ServiceContractHeader.Find();
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,CreateContractInvoicesRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure AmountPerPartialPeriodInServiceContractWithExpirationDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 360831] Amount Per Period is equal to Service Invoice Amount when partial quarter period ended on Expiration Date

        // [GIVEN] Service Contract with Prepaid = False, Invoice Period = Quarter
        Initialize();
        CreateServiceContractWithInvPeriod(ServiceContractHeader, ServiceContractHeader."Invoice Period"::Quarter);
        PrepaidFalseInServiceContract(ServiceContractHeader);
        // [GIVEN] Expiration Date 'D' = end of 2nd quarter
        ModifyServiceContractExpirationDate(
          ServiceContractHeader, CalcDate('<2Q>', ServiceContractHeader."Starting Date"));
        SignServContractDoc.SignContract(ServiceContractHeader);
        // [GIVEN] Posted Service Invoice posted in 1st quarter
        CreateContractInvoices(ServiceContractHeader);

        // [WHEN] Post Service Invoice in 2nd quarter with period ended on date 'D' and Service Invoice Amount = 'X'
        CreateContractInvoices(ServiceContractHeader);

        // [THEN] Amount Per Period = 'X'
        Assert.AreEqual(
          GetTotalServLineAmount(ServiceContractHeader."Contract No."), ServiceContractHeader."Amount per Period",
          IncorrectAmountPerPeriodErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,CreateContractInvoicesRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure PostSecondServiceInvoiceFromServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServicePeriod: DateFormula;
    begin
        // [SCENARIO 363400] Service contract is posted and contract invoices Amount is not deducted from following invoices.
        Initialize();

        // [GIVEN] Service Contract with Prepaid = False, Invoice Period = Year and "Line Value" = "X"
        CreateServiceContractWithInvPeriod(ServiceContractHeader, ServiceContractHeader."Invoice Period"::Year);
        PrepaidFalseInServiceContract(ServiceContractHeader);

        // [GIVEN] Service Period in Service Contract = Year
        Evaluate(ServicePeriod, '<1Y>');
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Signed Contract and Created Service Contract Invoice
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [WHEN] Create Contract Invoice "Y"
        CreateContractInvoices(ServiceContractHeader);

        // [THEN] Contract Invoice "Y" has Service Line "Amount" = "X"
        VerifyServiceLineAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,CreateContractInvoicesRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure AmountPerYearPartialPeriodInServiceContractWithExpirationDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 360915.1] Amount Per Period is equal to Service Invoice Amount when partial year period ended on Expiration Date

        // [GIVEN] Service Contract with Prepaid = True, Invoice Period = Year
        Initialize();
        CreateServiceContractWithInvPeriod(ServiceContractHeader, ServiceContractHeader."Invoice Period"::Year);
        // [GIVEN] Expiration Date 'D' = Starting Date + 1Year - X days
        ModifyServiceContractExpirationDate(
          ServiceContractHeader, CalcDate('<1Y-' + Format(LibraryRandom.RandInt(5)) + 'D>', ServiceContractHeader."Starting Date"));
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [WHEN] Post Service Invoice in period ended on date 'D' and Service Invoice Amount = 'X'
        CreateContractInvoices(ServiceContractHeader);

        // [THEN] Amount Per Period = 'X'
        Assert.AreEqual(
          GetTotalServLineAmount(ServiceContractHeader."Contract No."), ServiceContractHeader."Amount per Period",
          IncorrectAmountPerPeriodErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure UT_CalcYearContractAmountWhenExpirationDateEqualPeriodEndDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServContractManagement: Codeunit ServContractManagement;
        ExpirationDateFormula: DateFormula;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 360915.2] Amount Per Period is equal to Service Invoice Amount for period Year when Expiration Date is equal the end of period

        // [GIVEN] Service Contract with Expiration Date 'D' = Starting Date + 1Year - X days
        Initialize();
        Evaluate(ExpirationDateFormula, '<1Y-' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreateAndSignYearServiceContractWithExpirationDate(ServiceContractHeader, ExpirationDateFormula);

        // [WHEN] Calculate contract invoice amount = 'X'
        InvoiceAmount :=
          ServContractManagement.CalcContractAmount(ServiceContractHeader,
            ServiceContractHeader."Next Invoice Period Start", ServiceContractHeader."Next Invoice Period End");

        // [THEN] Amount Per Period = 'X'
        Assert.AreEqual(
          ServiceContractHeader."Amount per Period", InvoiceAmount, IncorrectInvAmountErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure UT_CalcYearContractAmountWhenExpirationDateLaterPeriodEndDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServContractManagement: Codeunit ServContractManagement;
        ExpirationDateFormula: DateFormula;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 360915.3] Amount Per Period is equal to Service Invoice Amount for period Year when Expiration Date is later then then end of period

        // [GIVEN] Service Contract with Expiration Date 'D' = End of Starting Date's month + 1Year + X days
        Initialize();
        Evaluate(ExpirationDateFormula, '<CM+1Y+' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreateAndSignYearServiceContractWithExpirationDate(ServiceContractHeader, ExpirationDateFormula);

        // [WHEN] Calculate contract invoice amount = 'X'
        InvoiceAmount :=
          ServContractManagement.CalcContractAmount(ServiceContractHeader,
            ServiceContractHeader."Next Invoice Period Start", ServiceContractHeader."Next Invoice Period End");

        // [THEN] Amount Per Period = 'X'
        Assert.AreEqual(
          ServiceContractHeader."Amount per Period", InvoiceAmount, IncorrectInvAmountErr);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteLinkMakeLinksToContractAndInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [FEATURE] [Record Link]
        // [SCENARIO 122140] Make Contract in Service Contract Quote page copy links to Service Contract/Service Invoice
        // [GIVEN] Service Contract Quote with random Link added
        Initialize();
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Quote);
        ServiceContractHeader.AddLink(LibraryUtility.GenerateRandomText(10));
        // [WHEN] Sign Service Contract Quote
        SignServContractDoc.SignContractQuote(ServiceContractHeader);
        // [THEN] Created Service Contract has attached Link
        VerifyServiceContractHasLink(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        // [THEN] Created Service Invoice has attached link
        VerifyServiceHeaderHasLink(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPostingDate()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        CurrentWorkDate: Date;
        CreditMemoDate: Date;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 123942] Credit Memo's "Posting Date", "Document Date" filled with values from Service Contract Line's "Credit Memo Date"
        Initialize();

        // [GIVEN] Signed Service Contract with "Invoice Period" = Year
        CreateSignedServiceContractWithInvoicePeriodYear(ServiceContractHeader, ServiceContractLine);

        // [GIVEN] Posted Service Invoice
        InitCurrWorkDateAndPostServiceInvoice(CurrentWorkDate, ServiceContractHeader);

        // [WHEN] Create Credit Memo from Service contract with "Service Contract Line"."Credit Memo Date" = CrMemoDate
        ModifyServiceContractStatus(ServiceContractHeader);
        CreditMemoDate := LibraryRandom.RandDate(-10);
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.", CreditMemoDate);

        // [THEN] Credit Memo "Posting Date", "Document Date" = CrMemoDate
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
        Assert.AreEqual(CreditMemoDate, ServiceHeader."Posting Date", ServiceHeader.FieldCaption("Posting Date"));
        Assert.AreEqual(CreditMemoDate, ServiceHeader."Document Date", ServiceHeader.FieldCaption("Document Date"));

        // TearDown
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure CrMemoAppliedToCorrespondentInvServLedgEntries()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        CurrentWorkDate: Date;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 123942] Credit Memo Service Ledger Entries are applied to correspondent Invoice Service Ledger Entries
        Initialize();

        // [GIVEN] Signed Service Contract with "Invoice Period" = Year
        CreateSignedServiceContractWithInvoicePeriodYear(ServiceContractHeader, ServiceContractLine);

        // [GIVEN] Posted Service Invoice
        InitCurrWorkDateAndPostServiceInvoice(CurrentWorkDate, ServiceContractHeader);

        // [WHEN] Posted Credit Memo
        CreateAndPostServiceCreditMemo(ServiceContractHeader);

        // [THEN] Credit Memo "Service Ledger Entry"."Applies-to Entry No." = Invoice "Service Ledger Entry"."Entry No."
        // [THEN] Credit Memo "Service Ledger Entry"."Posting Date" = Invoice "Service Ledger Entry"."Posting Date"
        // [THEN] Credit Memo "Service Ledger Entry"."Amount (LCY)" = - Invoice "Service Ledger Entry"."Amount (LCY)"
        VerifyCrMemoLinkedToInvServLedgEntries(ServiceContractHeader."Contract No.");

        // TearDown
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure PostPrepaidServiceContractTwiceWithDiffDimension()
    var
        ServiceContractHeader: Record "Service Contract Header";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [FEATURE] [Prepaid Contract] [Post Prepaid Contract Entries] [Dimension]
        // [SCENARIO 363040] Post Prepaid Contract Entries batch job used Dimension Set ID from last Service Ledger Entry

        Initialize();
        // [GIVEN] Service Contract with Dimension "X"
        CreateSignServiceContractWithDimension(ServiceContractHeader);
        // [GIVEN] Posted Service Invoice
        CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader);
        // [GIVEN] Posted Prepaid Contract Entry with dimension "X"
        PostPrepaidContractEntryWithNextInvoiceDate(ServiceContractHeader);
        // [GIVEN] Update of dimension from "X" to "Y" in Service Contract
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        UpdateDimensionInServiceContract(ServiceContractHeader);
        // [GIVEN] Posted Service Invoice
        LockOpenServContract.LockServContract(ServiceContractHeader);
        CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader);

        // [WHEN] Run "Post Prepaid Service Contract Entries" batch job
        PostPrepaidContractEntryWithNextInvoiceDate(ServiceContractHeader);

        // [THEN] G/L Entry posted with Dimension "Y"
        VerifyDimensionInGLEntry(
          GetPrepaidContractAccFromAccGroup(ServiceContractHeader."Serv. Contract Acc. Gr. Code"),
          ServiceContractHeader."Contract No.", ServiceContractHeader."Shortcut Dimension 1 Code");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure OnSignServiceContractWithSmallLineAmount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [FEATURE] [Service Contract]
        // [SCENARIO 363351] Sign Service Contract having Line with Unit Price equals to "Unit-Amount Rounding Precision"/2 + very small decimal
        Initialize();

        // [GIVEN] Service Contract having one Line
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);

        // [GIVEN] Service Contract Line has such Line Amount that Unit Price equals to "Unit-Amount Rounding Precision"/2 + very small decimal
        ServiceContractLine."Line Value" := GetSmallestLineAmount(ServiceContractHeader."Starting Date") + 0.000000000001;
        ServiceContractLine.Modify();
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // [WHEN] Sign Service Contract
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [THEN] Service Contract has been posted successfuly
        ServiceContractLine.Find();
        Assert.AreEqual(
          ServiceContractLine."Contract Status"::Signed,
          ServiceContractLine."Contract Status",
          ServiceContractHeader.FieldCaption(Status));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure PostPrepaidServiceContractTwoInvWithDiffDimension()
    var
        ServiceContractHeader: Record "Service Contract Header";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        ExpectedDimensionCode: array[2] of Code[20];
    begin
        // [FEATURE] [Prepaid Contract] [Post Prepaid Contract Entries] [Dimension]
        // [SCENARIO 363536] Post Prepaid Contract Entries batch job used Dimension Set ID from certain service contract

        Initialize();
        // [GIVEN] Service Contract with Dimension "X"
        CreateSignServiceContractWithDimension(ServiceContractHeader);
        ExpectedDimensionCode[1] := ServiceContractHeader."Shortcut Dimension 1 Code";
        // [GIVEN] Posted Service Invoice
        CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader);
        // [GIVEN] Update of dimension from "X" to "Y" in Service Contract
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        UpdateDimensionInServiceContract(ServiceContractHeader);
        ExpectedDimensionCode[2] := ServiceContractHeader."Shortcut Dimension 1 Code";
        // [GIVEN] Posted Service Invoice
        LockOpenServContract.LockServContract(ServiceContractHeader);
        CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader);

        // [WHEN] Run "Post Prepaid Service Contract Entries" batch job
        PostPrepaidContractEntryWithNextInvoiceDate(ServiceContractHeader);

        // [THEN] Two G/L Entries posted with dimensions "X" and "Y" accordingly
        VerifyDimensionInGLEntries(
          GetPrepaidContractAccFromAccGroup(ServiceContractHeader."Serv. Contract Acc. Gr. Code"),
          ServiceContractHeader."Contract No.", ExpectedDimensionCode);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure SignServiceContractWithServiceItemDescriptionOf50Chars()
    var
        ServContractHeader: Record "Service Contract Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        ExpectedDescPart1: Text;
        ExpectedDescPart2: Text;
    begin
        // [SCENARIO 372111] Sign Service Contract with Service Item Description of 50 characters

        LightInit();
        // [GIVEN] Service Contract with Service Contract Line = "SCL"
        // [GIVEN] LENGTH("SCL".Description) = 50
        CreateServiceContractHeader(ServContractHeader, '');
        CreateServiceContractLineWithDescription(ServContractHeader, ExpectedDescPart1, ExpectedDescPart2);

        // [WHEN] Sign Service Contract
        SignServContractDoc.SignContract(ServContractHeader);

        // [THEN] String of description "Desc" = "SCL"."Service Item No." + ' ' + "SCL".Description
        // [THEN] Two Service Line should be created:
        // [THEN] First Service Line must contains first 50 characters of "Desc"
        // [THEN] Second Service Line must contains characters from 50 to end of "Desc"
        VerifyServiceLineDescription(ExpectedDescPart1, ExpectedDescPart2);
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure UT_SystemAllowZeroLineValueServiceContractLine()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375942] System allows zero value of "Line Value" of "Service Contract Line".

        Initialize();
        // [GIVEN] Service Contract Header with Service Contract Line
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        ServiceContractLine.Init();
        ServiceContractLine."Contract Type" := ServiceContractLine."Contract Type"::Contract;
        ServiceContractLine."Contract No." := ServiceContractHeader."Contract No.";

        // [WHEN] "Line Value" of Service Contract Line is set to zero value
        ServiceContractLine.Validate("Line Value", 0);

        // [THEN] "Line Value" = 0
        ServiceContractLine.TestField("Line Value", 0);
    end;

    [Test]
    [HandlerFunctions('ServContrctTemplateListHandler,SignContractConfirmHandler')]
    [Scope('OnPrem')]
    procedure UT_SystemAllowPositiveLineValueServiceContractLine()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        LineValue: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375942] System allows positive value of "Line Value" of "Service Contract Line".

        Initialize();
        // [GIVEN] Service Contract Header with Service Contract Line
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        ServiceContractLine.Init();
        ServiceContractLine."Contract Type" := ServiceContractLine."Contract Type"::Contract;
        ServiceContractLine."Contract No." := ServiceContractHeader."Contract No.";
        LineValue := LibraryRandom.RandInt(1000);

        // [WHEN] "Line Value" of Service Contract Line is set to positive value = "X"
        ServiceContractLine.Validate("Line Value", LineValue);

        // [THEN] "Line Value" = "X"
        ServiceContractLine.TestField("Line Value", LineValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SystemNotAllowNegativeLineValueServiceContractLine()
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375942] System doesn't allow negative value of "Line Value" of "Service Contract Line".

        Initialize();
        // [GIVEN] Service Contract Line
        ServiceContractLine.Init();

        // [WHEN] "Line Value" of Service Contract Line is set to negative value
        asserterror ServiceContractLine.Validate("Line Value", -LibraryRandom.RandInt(1000));

        // [THEN] Error message of disabling negative value appears
        Assert.ExpectedErrorCode(PositiveValueErrorCodeErr);
        Assert.ExpectedError(StrSubstNo(PositiveValueErrorErr));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,CreateContractServiceOrdersRequestPageHandler,MsgCannotCreateHandler')]
    [Scope('OnPrem')]
    procedure SystemNotAllowCreateServiceOrderWithoutCustomerShipToAddress()
    var
        ContracNo: Code[20];
        CustomerNo: Code[20];
        ShiptoCode: Code[10];
    begin
        // [SCENARIO 379111] System doesn't allow create service contact if Ship-to address from service contract doesn't own customer

        Initialize();
        // [GIVEN] Service Contract Header with not existing Ship-to Code
        CreateUpdateServiceContract(ContracNo, CustomerNo, ShiptoCode);
        LibraryVariableStorage.Enqueue(ContracNo);
        Commit();

        // [WHEN] Run report "Create Contract Service Orders"
        RunCreateContractServiceOrders();

        // [THEN] Message "A service order cannot be created for contract no..." appeared
        Assert.ExpectedMessage(
          StrSubstNo(CannotCreateServiceOrderMsg, ContracNo, CustomerNo, ShiptoCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ZeroOrderCreatedMsg, LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('ServContractConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractCreditLimitWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceContract: TestPage "Service Contract";
    begin
        // [FEATURE] [Credit Limit] [UI]
        // [SCENARIO 379269] Credit limit warning page is shown when validate Customer with overdue balance (reply Yes)
        Initialize();
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with overdue balance
        CreateCustomerWithCreditLimit(Customer);
        CreatePostSalesInvoice(Customer."No.", Customer."Credit Limit (LCY)" + LibraryERM.GetAmountRoundingPrecision());
        // [GIVEN] Open new Service Contract
        ServiceContract.OpenNew();
        // [GIVEN] Validate "Customer No."
        LibraryVariableStorage.Enqueue(Customer."No.");
        ServiceContract."Customer No.".SetValue(Customer."No.");

        // [WHEN] Reply "Yes" on Credit Limit warning page
        // CheckCreditLimit_ReplyYes

        // [THEN] "Customer No." has been validated
        ServiceContract."Customer No.".AssertEquals(Customer."No.");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ServContractConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteCreditLimitWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceContractQuote: TestPage "Service Contract Quote";
    begin
        // [FEATURE] [Credit Limit] [UI] [Quote]
        // [SCENARIO 379269] Credit limit warning page is shown when validate Customer with overdue balance on Service Contract Quote (reply Yes)
        Initialize();
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with overdue balance
        CreateCustomerWithCreditLimit(Customer);
        CreatePostSalesInvoice(Customer."No.", Customer."Credit Limit (LCY)" + LibraryERM.GetAmountRoundingPrecision());
        // [GIVEN] Open new Service Contract Quote
        ServiceContractQuote.OpenNew();
        // [GIVEN] Validate "Customer No."
        LibraryVariableStorage.Enqueue(Customer."No.");
        ServiceContractQuote."Customer No.".SetValue(Customer."No.");

        // [WHEN] Reply "Yes" on Credit Limit warning page
        // CheckCreditLimit_ReplyYes

        // [THEN] "Customer No." has been validated
        ServiceContractQuote."Customer No.".AssertEquals(Customer."No.");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractCreditMemoOK()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 379295] Service Credit Memo posted successfully for Contract with several Items and empty Service Item Nos.
        Initialize();

        // [GIVEN] Signed Service Contract "SC" with Invoice Period = Half Year
        // [GIVEN] Several Service Contract Lines: "Service Item No." empty, "Item No." not empty
        CreateServiceContractForSeveralItemsWithItemNoAndBlankServiceItemNo(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        // [GIVEN] Posted Service Invoice with "Posting Date" = "SC"."Starting Date"
        CreateServiceInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");
        // [GIVEN] Service Credit Memo with "Posting Date" = "SC"."Starting Date" + one month
        CreateServiceCreditMemoForNextMonth(ServiceContractHeader, ServiceContractLine);

        // [WHEN] Posting Service Credit Memo
        PostServiceCreditMemo(ServiceContractHeader);

        // [THEN] No error occurs and Credit Memo Service Ledger entries are linked to that of Service Invoice
        VerifyCrMemoLinkedToInvServLedgEntries(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteWithFullLineDiscount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 380005] Sign-off Service Contract Quote when 100% line discount is applied.

        Initialize();

        // [GIVEN] Create Service Contract Quote with "None" Invoice Period
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Quote);
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, WorkDate(), ServiceContractHeader2."Invoice Period"::None);

        // [WHEN] Apply 100% Line Discount
        UpdateServiceContractLineDiscount(ServiceContractHeader, 100);

        // [THEN] Sing-Off Service Contract Quote
        ServiceContractHeader.Find();
        SignServContractDoc.SignContractQuote(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithFullLineDiscount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 380005] Sign-off Service Contract when 100% line discount is applied.

        Initialize();

        // [GIVEN] Create Service Contract with "None" Invoice Period
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, WorkDate(), ServiceContractHeader."Invoice Period"::None);

        // [WHEN] Apply 100% Line Discount
        UpdateServiceContractLineDiscount(ServiceContractHeader, 100);

        // [THEN] Sing-Off Service Contract
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('ServContractConfHandler')]
    [Scope('OnPrem')]
    procedure OnceConfirmationSignContractQuote()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [UT] [Quote]
        // [SCENARIO 217444] Confirmation message 'Do you want to convert the contract quote into a contract?' appears once when calling SignServContractDoc.SignContractQuote
        Initialize();

        // [GIVEN] Service Contract Header
        CreateServiceContractQuoteSimple(ServiceContractHeader);

        // [WHEN] Invoke SignServContractDoc.SignContractQuote
        LibraryVariableStorage.Enqueue(ConvertMsg);
        LibraryVariableStorage.Enqueue(true);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // [THEN] Replied NO for Confirmation 'Do you want to create the contract using a contract template?'
        // [THEN] Replied YES for Confirmation 'Do you want to convert the contract quote into a contract?'

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ContractTemplateConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure CopyBilltoContactToServiceHeader()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
        ServiceHeaderNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 224033] Fields "Bill-to Contact No." and "Bill-to Contact" must be copied from Service Contract to Service Header by function ServContractManagement.CreateServHeader
        Initialize();

        // [GIVEN] Service Contract with "Bill-to Contact No." = "ContNo" and "Bill-to Contact" = "John Smith"
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        ServiceContractHeader."Bill-to Contact No." :=
          LibraryUtility.GenerateRandomCode(ServiceContractHeader.FieldNo("Bill-to Contact No."), DATABASE::"Service Contract Header");
        ServiceContractHeader."Bill-to Contact" := LibraryUtility.GenerateGUID();
        ServiceContractHeader.Modify();

        // [WHEN] Invoke ServContractManagement.CreateServHeader
        ServiceHeaderNo := ServContractManagement.CreateServHeader(ServiceContractHeader, WorkDate(), true);

        // [THEN] "Service Header"."Bill-to Contact No." = "ContNo"
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceHeaderNo);
        ServiceHeader.TestField("Bill-to Contact No.", ServiceContractHeader."Bill-to Contact No.");

        // [THEN] "Service Header"."Bill-to Contact" = "John Smith"
        ServiceHeader.TestField("Bill-to Contact", ServiceContractHeader."Bill-to Contact");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithSeveralSameLinesCreditMemo()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 230010] Service Credit Memo posted successfully for Contract with several Items with blank ServiceItemNo and ItemNo
        Initialize();

        // [GIVEN] Signed Service Contract "SC" with several Service Contract Lines with blank ServiceItemNo and ItemNo
        CreateServiceContractForSeveralItemsWithBlankServiceItemNo(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Post Service Invoice
        CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader);

        // [GIVEN] Create Service Credit Memo
        CreateServiceCreditMemoForNextMonth(ServiceContractHeader, ServiceContractLine);

        // [WHEN] Post Service Credit Memo
        PostServiceCreditMemo(ServiceContractHeader);

        // [THEN] No error occurs and Credit Memo Service Ledger entries are linked to that of Service Invoice
        VerifyCrMemoLinkedToInvServLedgEntries(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceContractAccountGroupCodeCannotBeBlank()
    var
        ServContractAccountGroups: TestPage "Serv. Contract Account Groups";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235022] You cannot create Service Contract Account Group with blank Code.
        Initialize();

        ServContractAccountGroups.OpenNew();
        asserterror ServContractAccountGroups.Code.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('ServContractConfHandler')]
    [Scope('OnPrem')]
    procedure NoServContractCreatedWhenCancelMakeContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [Quote]
        // [SCENARIO 260931] Service Contract is not created from Service Contract Quote, when Make Contract is cancelled in dialog 'Do you want to convert the contract quote into a contract?'
        Initialize();

        // [GIVEN] Service Contract Quote
        CreateServiceContractQuoteSimple(ServiceContractHeader);

        // [GIVEN] Make Contract
        LibraryVariableStorage.Enqueue(ConvertMsg);
        LibraryVariableStorage.Enqueue(false);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // [WHEN] Cancel Make Contract in Confirm Dialog 'Do you want to convert the contract quote into a contract?'
        // Cancellation is done in ServContractConfHandler

        // [THEN] Service Contract is not created
        VerifyContractNotExists(ServiceContractHeader."Contract No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServContractConfHandler')]
    [Scope('OnPrem')]
    procedure NoServContractCreatedWhenCancelMakeContractNextPlannedServiceDateIsBlank()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Quote]
        // [SCENARIO 260931] Service Contract is not created from Service Contract Quote, when Make Contract is cancelled in dialog:
        // [SCENARIO 260931] 'The "Next Planned Service Date" field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?'
        Initialize();

        // [GIVEN] Service Contract Quote with <blank> "Next Planned Service Date" in Line
        CreateServiceContractQuote(ServiceContractHeader, ServiceContractLine);
        ModifyServiceContractLineNextPlannedServDate(ServiceContractLine, 0D);

        // [GIVEN] Make Contract
        // [GIVEN] Confirm Make Contract in Confirm Dialog 'Do you want to convert the contract quote into a contract?'
        LibraryVariableStorage.Enqueue(ConvertMsg);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(FieldEmptyMsg, ServiceContractLine.FieldCaption("Next Planned Service Date")));
        LibraryVariableStorage.Enqueue(false);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // [WHEN] Cancel Make Contract in Confirm Dialog 'The "Next Planned Service Date" field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?'
        // Cancellation is done in ServContractConfHandler

        // [THEN] Service Contract is not created
        VerifyContractNotExists(ServiceContractHeader."Contract No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServContractConfHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServContractCreatedWhenConfirmMakeContractNextPlannedServiceDateIsBlank()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Quote]
        // [SCENARIO 260931] Service Contract is created from Service Contract Quote, when Make Contract is confirmed in dialog:
        // [SCENARIO 260931] 'The "Next Planned Service Date" field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?'
        Initialize();

        // [GIVEN] Service Contract Quote with <blank> "Next Planned Service Date" in Line
        CreateServiceContractQuote(ServiceContractHeader, ServiceContractLine);
        ModifyServiceContractLineNextPlannedServDate(ServiceContractLine, 0D);

        // [GIVEN] Make Contract
        // [GIVEN] Confirm Make Contract in Confirm Dialog 'Do you want to convert the contract quote into a contract?'
        LibraryVariableStorage.Enqueue(ConvertMsg);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(FieldEmptyMsg, ServiceContractLine.FieldCaption("Next Planned Service Date")));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(InvoiceCreationMsg);
        LibraryVariableStorage.Enqueue(true);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // [WHEN] Confirm Make Contract in Confirm Dialog 'The "Next Planned Service Date" field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?'
        // Confirmation is done in ServContractConfHandler

        // [THEN] Confirm Dialog Opens: 'Do you want to create an invoice for the period...?'

        // [WHEN] Confirm Invoice Creation
        // [THEN] Service Contract is created
        VerifyContractCreationByQuote(ServiceContractHeader."Contract No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceFromServiceOrdersWithDifferentCurrencies()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServContractManagement: Codeunit ServContractManagement;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 263502] Service Invoices for one customer cannot be combined if they are created from Service Contracts with different currencies.
        Initialize();

        // [GIVEN] Two Service Contracts with different currencies, both were created for Customer = "C1".
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateServiceContractWithCurrency(ServiceContractHeader, LibraryERM.CreateCurrencyWithRandomExchRates(), CustomerNo);
        ServiceContractHeader.TestField("Combine Invoices", true);

        Clear(ServiceContractHeader);
        CreateServiceContractWithCurrency(ServiceContractHeader, LibraryERM.CreateCurrencyWithRandomExchRates(), CustomerNo);
        ServiceContractHeader.TestField("Combine Invoices", true);

        // [WHEN] Run CheckMultipleCurrenciesForCustomers function.
        ServiceContractHeader.SetRange("Bill-to Customer No.", CustomerNo);
        asserterror ServContractManagement.CheckMultipleCurrenciesForCustomers(ServiceContractHeader);

        // [THEN] Error "Service Contracts with different currencies cannot be combined on one invoice" occurs.
        Assert.ExpectedError(StrSubstNo('Customer %1 has service contracts with different currency codes', CustomerNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ServContrctTemplateListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceFromServiceOrdersWithTheSameCurrency()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServContractManagement: Codeunit ServContractManagement;
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 263502] Service Invoices for one customer can be combined if they are created from Service Contracts with one and the same currency.
        Initialize();

        // [GIVEN] Two Service Contracts, both were created for Customer = "C1" and both have "Currency Code" = "CUR1".
        CustomerNo := LibrarySales.CreateCustomerNo();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CreateServiceContractWithCurrency(ServiceContractHeader, CurrencyCode, CustomerNo);
        ServiceContractHeader.TestField("Combine Invoices", true);

        Clear(ServiceContractHeader);
        CreateServiceContractWithCurrency(ServiceContractHeader, CurrencyCode, CustomerNo);
        ServiceContractHeader.TestField("Combine Invoices", true);

        // [WHEN] Run CheckMultipleCurrenciesForCustomers function.
        ServiceContractHeader.SetRange("Bill-to Customer No.", CustomerNo);
        ServContractManagement.CheckMultipleCurrenciesForCustomers(ServiceContractHeader);

        // [THEN] Currency check for Service Orders are passed.
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MsgHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceAndCreditMemoForNewServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLine2: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO 447978] Service Credit Memo created for partial amount for first full month of the Prepaid Contract that was invoiced.

        // [GIVEN] Setup: Create Service Item, Service Contract Header, Service Contract Line, and Sign Service Contract.
        Initialize();
        CreateServiceItemAndContract(ServiceContractHeader, ServiceContractLine);

        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Create and Post Service Invoice.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run "Post Prepaid Service Contract Entries" batch job
        PostPrepaidContractEntry(
          ServiceContractHeader."Contract No.", CalcDate('<1Y>', WorkDate()), WorkDate());

        // [THEN] Reopen Service Contract and modify Service Contract Line.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractLine2.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.", ServiceContractLine."Line No.");
        ServiceContractLine2.Validate("Contract Expiration Date", ServiceContractHeader."Starting Date");
        ServiceContractLine2.Validate("Credit Memo Date", ServiceContractHeader."Starting Date");
        ServiceContractLine2.Modify(true);

        // [THEN] Lock Service Contract.
        LockOpenServContract.LockServContract(ServiceContractHeader);

        // [GIVEN] Create Service Credit Memo.
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.", ServiceContractHeader."Starting Date");

        // [THEN] Post Service Credit Memo.
        PostServiceCreditMemo(ServiceContractHeader);

        // [VERIFY] Verify Post Service Invoice and Credit Memo Amount.
        Assert.AreEqual(
          GetPostedServiceInvoiceAmount(ServiceContractHeader."Contract No."), GetPostedServiceCrMemoAmount(ServiceContractHeader."Contract No."), IncorrectCreditMemoAmountErr);
    end;

    [Test]
    [HandlerFunctions('ServiceContractHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure CheckLastInvoicePeriodEndFieldDataWhendeletingRelatedServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceContract: TestPage "Service Contract";
    begin
        // [SCENARIO 560345] Check if the 'Last Invoice Period End' field is empty after deleting the related service invoice.
        Initialize();

        // [GIVEN] Set Work Date.
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [GIVEN] Create a Service Contract Header.
        CreateServiceContractDocument(ServiceContractHeader);

        // [GIVEN] Create Service Contract Line and Service Item.
        CreateServiceContLineWithServiceItem(ServiceContractHeader, ServiceItem, ServiceContractLine);

        // [GIVEN] Sign the Prepaid Contract.
        SignPrepaidContract(ServiceContractHeader);
        LibraryVariableStorage.Clear();
        OpenServiceContractAndCreateInvoice(ServiceContract, ServiceContractHeader);

        // [GIVEN] Change Work Date.
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [GIVEN] Create the second service invoice with a different work date.
        LibraryVariableStorage.Enqueue(true); // Confirm to already create a Prepaid Service Invoice.
        LibraryVariableStorage.Enqueue(true); // Confirm to create a new service invoice.
        ServiceContract.CreateServiceInvoice.Invoke();
        ServiceContract.Close();

        // [WHEN] Delete the second service invoice.
        ServiceHeader.SetRange("Order Date", WorkDate());
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.SetRange("Customer No.", ServiceContractHeader."Customer No.");
        LibraryVariableStorage.Enqueue(true); // Confirm deletion of the service invoice.
        ServiceHeader.FindFirst();
        ServiceHeader.Delete(true);

        // [THEN] Verify that The last invoice date and the last invoice period end date.
        Assert.Equal(ServiceContractHeader."Last Invoice Date", ServiceContractHeader."Starting Date");
        Assert.Equal(ServiceContractHeader."Last Invoice Period End", CalcDate('<1Y>', ServiceContractHeader."Starting Date"));

        // [WHEN] Delete the first service invoice.
        ServiceHeader.Reset();
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.SetRange("Customer No.", ServiceContractHeader."Customer No.");
        ServiceHeader.FindFirst();
        LibraryVariableStorage.Enqueue(true);// Confirm deletion of the service invoice.
        ServiceHeader.Delete(true);

        // [THEN] Verify that The last invoice date and the last invoice period end date should be empty.
        Assert.Equal('', Format(ServiceContractHeader."Last Invoice Date"));
        Assert.Equal('', Format(ServiceContractHeader."Last Invoice Period End"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SignContractConfirmHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerOfTypePeronInServiceContract()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ShiptoAddress: Record "Ship-to Address";
        ServContractManagement: Codeunit ServContractManagement;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 578655] Change Customer No. on Service Contract of Customer type Person.
        Initialize();

        // [GIVEN] Create Contact of type Person.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Open Contact Card and invoke Create Customer.
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard.CreateCustomer.Invoke();

        // [GIVEN] Create Service Contract Header and Service Contract Line.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");

        // [GIVEN] Find Contact Business Relation of the Contact.
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.FindFirst();

        // [GIVEN] Create Ship to Address.
        LibrarySales.CreateShipToAddress(ShiptoAddress, ContactBusinessRelation."No.");

        // [WHEN] Change Customer No. in Service Contract.
        ServContractManagement.ChangeCustNoOnServContract(ShiptoAddress."Customer No.", ShiptoAddress.Code, ServiceContractHeader);

        // [THEN] Check Customer No. is updated.
        CheckChangeCustomerNo(ServiceContractHeader, ContactBusinessRelation."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure PersonContactLinkedViaCompanyValidation()
    var
        Contact: Record Contact;
        CompanyContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 603351] Person contact linked to customer via Company No. should be valid in Service Contract
        Initialize();

        // [GIVEN] Create a Company contact
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Create a customer
        LibrarySales.CreateCustomer(Customer);
        ContactBusinessRelation.Init();
        ContactBusinessRelation."Contact No." := CompanyContact."No.";
        ContactBusinessRelation."Business Relation Code" := 'CUST';
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := Customer."No.";
        ContactBusinessRelation.Insert();

        // [GIVEN] Create a Person contact under the Company
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", CompanyContact."No.");
        Contact.Modify(true);

        // [GIVEN] Create a Service Contract for the customer
        LibraryService.CreateServiceContractHeader(
            ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");

        // [WHEN] Assign the Person contact to the Service Contract
        ServiceContractHeader.Validate("Contact No.", Contact."No.");

        // [THEN] No error should occur and Contact No. should be set
        ServiceContractHeader.TestField("Contact No.", Contact."No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Contracts");
        LightInit();

        LibrarySetupStorage.Restore();
        Clear(LibraryService);
        WorkDate := InitialWorkDate;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Contracts");

        // Setup demonstration data
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateAccountsInServiceContractAccountGroups();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        InitializeServiceContractTemplates();

        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Contracts");
    end;

    local procedure LightInit()
    begin
        LibraryVariableStorage.Clear();
        Clear(SignServContractDoc);
    end;

    local procedure InitializeServiceContractTemplates()
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        ServiceContractTemplate.DeleteAll();
        CreateServiceContractTemplate(
          ServiceContractTemplate, '<3M>', ServiceContractTemplate."Invoice Period"::Month, true, true, false, true);
        Clear(ServiceContractTemplate);
        CreateServiceContractTemplate(
          ServiceContractTemplate, '<3M>', ServiceContractTemplate."Invoice Period"::Month, true, true, true, false);
    end;

    local procedure CopyDefaultHoursFromSetup(ServiceContractNo: Code[20])
    var
        ServiceHour: Record "Service Hour";
    begin
        ServiceHour.SetRange("Service Contract Type", ServiceHour."Service Contract Type"::Quote);
        ServiceHour.SetRange("Service Contract No.", ServiceContractNo);
        ServiceHour.CopyDefaultServiceHours();
    end;

    local procedure CreateSignedServiceContractWithServicePeriod(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServicePeriodOnServiceContractHeader(ServiceContractHeader);
        UpdateAnnualAmountOnServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure CreateAndModifyServiceContract(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; ContractType: Enum "Service Contract Type")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ContractType, CustomerNo);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
    end;

    local procedure CreateAndPostServiceInvoiceByGetShipmentLines(CustomerNo: Code[20]; OrderNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(OrderNo);
        ServiceGetShipment.Run(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Post Ship and Invoice.
    end;

    local procedure CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
        InvoiceNo: Code[20];
    begin
        InvoiceNo := CreateServiceInvoice(ServiceContractHeader);
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, InvoiceNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateAndSignServiceContractWithInvoice(var ServiceLine: Record "Service Line")
    var
        ServiceContractHeader: Record "Service Contract Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        ServiceLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceLine.FindFirst();
    end;

    local procedure CreateAndSignYearServiceContractWithExpirationDate(var ServiceContractHeader: Record "Service Contract Header"; ExpirationDateFormula: DateFormula)
    begin
        CreateServiceContractWithInvPeriod(ServiceContractHeader, ServiceContractHeader."Invoice Period"::Year);
        ModifyServiceContractExpirationDate(
          ServiceContractHeader, CalcDate(ExpirationDateFormula, ServiceContractHeader."Starting Date"));
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Find();
    end;

    local procedure CreateContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        Customer: Record Customer;
    begin
        // Create Service Item and Service Contract Header.
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateDefaultDimension(var DefaultDimension: Record "Default Dimension"; "Code": Code[10])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Service Order Type", Code, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateCommentForServiceQuote(ServiceContractQuoteNo: Code[20])
    var
        ServiceCommentLine: Record "Service Comment Line";
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine."Contract Type" := ServiceContractLine."Contract Type"::Quote;
        ServiceContractLine."Contract No." := ServiceContractQuoteNo;
        LibraryService.CreateCommentLineForServCntrct(ServiceCommentLine, ServiceContractLine, ServiceCommentLine.Type::General);
        ServiceCommentLine.Validate(Date, WorkDate());
        ServiceCommentLine.Modify(true);
    end;

    local procedure CreateMultipleContractLines(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        Counter: Integer;
    begin
        // Use RANDOM for creating Service Item Lines between 1 to 10.
        for Counter := 1 to 1 + LibraryRandom.RandInt(9) do
            CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
    end;

    local procedure CreateServiceContractWithCurrency(var ServiceContractHeader: Record "Service Contract Header"; CurrencyCode: Code[10]; CustomerNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ServiceContractHeader.Validate("Currency Code", CurrencyCode);
        ServiceContractHeader.Modify(true);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
    end;

    local procedure CreateAndSignContractOnToday(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; ServiceContractAccountGroup: Record "Service Contract Account Group")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        CreateContractHeader(ServiceContractHeader);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Next Invoice Date");
        WorkDate := ServiceContractHeader."Next Invoice Date";
        SignServContractDoc.SetHideDialog := true;
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
    end;

    local procedure CreateAndSignServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit(); // To save the changes.
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View"; AccountFilterToSet: Text[200]; StartingDate: Date)
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Account Filter", AccountFilterToSet);
        AnalysisView.Validate("Date Compression", AnalysisView."Date Compression"::Day);
        AnalysisView.Validate("Starting Date", StartingDate);
        AnalysisView.Modify(true);
    end;

    local procedure CreateItemWithUnitPrice(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateContractWithInvPeriodYear(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    begin
        CreateContractHeader(ServiceContractHeader);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Modify(true);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
    end;

    local procedure CreateSignServiceContractWithDimension(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateContractHeader(ServiceContractHeader);
        UpdateDimensionInServiceContract(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeaderWithInvoicePeriod(
          ServiceContractHeader, CalcDate('<-CM>', WorkDate()),
          ServiceContractHeader."Invoice Period"::Quarter);
        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Find();
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; StandardTextCode: Code[20])
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        ServiceContractHeader.Validate("Print Increase Text", true);
        ServiceContractHeader.Validate("Price Inv. Increase Code", StandardTextCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 1000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", 10000000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractLineUpdateAnnualAmount(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(1000));
        ServiceContractLine.Modify(true);
        UpdateAnnualAmountOnServiceContractHeader(ServiceContractHeader);
    end;

    local procedure CreateServiceContractOrder(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
        CreateServOrders: Option;
    begin
        CreateContractServiceOrders.SetTableView(ServiceContractHeader);
        CreateContractServiceOrders.InitializeRequest(WorkDate(), WorkDate(), CreateServOrders);
        CreateContractServiceOrders.UseRequestPage(false);
        CreateContractServiceOrders.Run();
    end;

    local procedure CreateServiceCreditMemo(ContractNo: Code[20]; CreditMemoDate: Date)
    var
        ServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindFirst();
        ServiceContractLine.Validate("Credit Memo Date", CreditMemoDate);
        ServiceContractLine.Modify();
        ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, true);
    end;

    local procedure CreateServiceContractInvoice(var ServiceContractHeader: Record "Service Contract Header")
    begin
        CreateServiceContractInvoice(ServiceContractHeader, ServiceContractHeader."Next Invoice Date", ServiceContractHeader."Next Invoice Date");
    end;

    local procedure CreateServiceContractInvoice(var ServiceContractHeader: Record "Service Contract Header"; NewPostingDate: Date; NewInvoiceDate: Date)
    var
        CreateContractInvoices: Report "Create Contract Invoices";
        CreateInvoice: Option;
    begin
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(NewPostingDate, NewInvoiceDate, CreateInvoice);
        CreateContractInvoices.SetHideDialog(true);
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
    end;

    local procedure CreateServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template"; ServicePeriodTxt: Text; InvoicePeriod: Option; CombineInvoices: Boolean; ContractLinesOnInvoice: Boolean; InvoiceAfterService: Boolean; IsPrepaid: Boolean)
    var
        DefaultServicePeriod: DateFormula;
    begin
        Evaluate(DefaultServicePeriod, ServicePeriodTxt);

        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        ServiceContractTemplate.Validate("Invoice Period", InvoicePeriod);
        ServiceContractTemplate.Validate(Prepaid, IsPrepaid);
        ServiceContractTemplate.Validate("Combine Invoices", CombineInvoices);
        ServiceContractTemplate.Validate("Contract Lines on Invoice", ContractLinesOnInvoice);
        ServiceContractTemplate.Validate("Invoice after Service", InvoiceAfterService);
        ServiceContractTemplate.Modify(true);
    end;

    local procedure CreatePrepaidServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template")
    var
        DefaultServicePeriod: DateFormula;
    begin
        Evaluate(DefaultServicePeriod, '<3M>');
        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        Evaluate(ServiceContractTemplate."Price Update Period", '<6M>');
        ServiceContractTemplate.Validate(Prepaid, true);
        ServiceContractTemplate.Validate("Combine Invoices", true);
        ServiceContractTemplate.Validate("Contract Lines on Invoice", true);
        ServiceContractTemplate.Modify(true);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; ContractType: Enum "Service Contract Type")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ShipToAddress: Record "Ship-to Address";
        CustomerNo: Code[20];
    begin
        // Create Service Item, Service Contract Header, Service Contract Line.
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);

        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ContractType, CustomerNo);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceContractHeader.Modify(true);

        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
    end;

    local procedure CreateServiceContractMultiLines(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; ContractType: Enum "Service Contract Type")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        i: Integer;
        ItemsCount: Integer;
    begin
        // Create Service Item, Service Contract Header, Service Contract Line.
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);

        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ContractType, LibrarySales.CreateCustomerNo());
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
        ItemsCount := LibraryRandom.RandIntInRange(3, 5);
        LibraryVariableStorage.Enqueue(ItemsCount);
        for i := 1 to ItemsCount do
            CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
    end;

    local procedure CreateServiceContractForSeveralItemsWithBlankServiceItemNo(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContractMultiLines(
          ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.FindSet();
        repeat
            UpdateContractLineBlankServiceItemNo(ServiceContractLine);
        until ServiceContractLine.Next() = 0;
        InitServiceContractForSeveralItems(ServiceContractHeader);
    end;

    local procedure CreateServiceContractForSeveralItemsWithItemNoAndBlankServiceItemNo(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContractMultiLines(
          ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.FindSet();
        repeat
            UpdateContractLineBlankServiceItemNo(ServiceContractLine);
            UpdateContractLineItemNo(ServiceContractLine);
        until ServiceContractLine.Next() = 0;
        InitServiceContractForSeveralItems(ServiceContractHeader);
    end;

    local procedure CreateServiceContractQuoteSimple(var ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceTemplateMsg);
        LibraryVariableStorage.Enqueue(false);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, LibrarySales.CreateCustomerNo());
        ServiceContractHeader."Invoice Period" := ServiceContractHeader."Invoice Period"::None;
    end;

    local procedure CreateServiceContractQuote(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ShipToAddress: Record "Ship-to Address";
        ServiceItem: Record "Service Item";
        CustomerNo: Code[20];
    begin
        LibraryVariableStorage.Enqueue(ServiceTemplateMsg);
        LibraryVariableStorage.Enqueue(false);

        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, CustomerNo);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceContractHeader.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(ServItemHasDiffShipToCodeMsg, ServiceItem."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 1000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", 10000000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);

        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
    end;

    local procedure InitServiceContractForSeveralItems(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CY>', WorkDate()));
        ServiceContractHeader.Validate("Combine Invoices", true);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::"Half Year");
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceCreditMemoForNextMonth(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        ServContractManagement: Codeunit ServContractManagement;
        SaveDate: Date;
    begin
        ServiceContractHeader.Find();
        ServiceContractHeader.Validate("Change Status", ServiceContractHeader."Change Status"::Open);
        ServiceContractHeader.Modify(true);
        ServiceContractHeader.Validate("Expiration Date", CalcDate('<1M>', ServiceContractHeader."Starting Date"));
        ServiceContractHeader.Modify(true);

        SaveDate := WorkDate();
        WorkDate := CalcDate('<1M>', ServiceContractHeader."Starting Date");

        ServiceContractLine.Reset();
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.SetRange(Credited, false);
        ServiceContractLine.FindSet();
        repeat
            ServiceContractLine."Credit Memo Date" := WorkDate() - 1;
            ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, true);
        until ServiceContractLine.Next() = 0;

        WorkDate := SaveDate;
    end;

    local procedure CreateServiceContractLineItem(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        RecRef: RecordRef;
    begin
        ServiceContractLine.Init();
        ServiceContractLine.Validate("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.Validate("Contract No.", ServiceContractHeader."Contract No.");
        RecRef.GetTable(ServiceContractLine);
        ServiceContractLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ServiceContractLine.FieldNo("Line No.")));
        ServiceContractLine.Validate("Item No.", CreateItemWithUnitPrice());
        ServiceContractLine.Insert(true);
    end;

    local procedure CreateServiceContractWithExpirationDate(var ServiceContractHeader: Record "Service Contract Header"): Code[20]
    var
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        CreateAndModifyServiceContract(
          ServiceContractHeader, LibrarySales.CreateCustomerNo(), ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.Validate("Expiration Date", CalcDate('<CM+1D>', WorkDate()));
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        exit(ServiceContractLine."Service Item No.");
    end;

    local procedure CreateServiceContractWithInvoicePeriodAndDiscount(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    begin
        CreateContractHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        ServiceContractLine.Modify(true);

        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Next Invoice Date");
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractWithInvPeriod(var ServiceContractHeader: Record "Service Contract Header"; InvoicePeriod: Enum "Service Contract Header Invoice Period")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeaderWithInvoicePeriod(
          ServiceContractHeader, CalcDate('<-CM +' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()),
          InvoicePeriod);
    end;

    local procedure InitServiceInvoiceWithContract(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader."Contract No." := LibraryUtility.GenerateGUID();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
    end;

    local procedure CreateServiceLineForServiceOrder(var ServiceHeader: Record "Service Header"; ContractNumber: Code[20])
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.FindResource(Resource);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Contract No.", ContractNumber);
        ServiceHeader.FindFirst();
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Take Random Quantity.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Take Random Unit Price.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDiscountForQuote(ServiceContractHeader: Record "Service Contract Header")
    var
        ContractServiceDiscount: Record "Contract/Service Discount";
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateContractServiceDiscount(
          ContractServiceDiscount, ServiceContractHeader, ContractServiceDiscount.Type::"Service Item Group", ServiceItemGroup.Code);
    end;

    local procedure CreateServiceInvoice(ServiceContractHeader: Record "Service Contract Header") InvoiceNo: Code[20]
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        InvoiceNo := ServContractManagement.CreateInvoice(ServiceContractHeader);
    end;

    local procedure CreateServiceInvoiceNotApplied(ServiceContractHeader: Record "Service Contract Header"; var ServiceLine: Record "Service Line") InvoiceNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        InvoiceNo := ServContractManagement.CreateServHeader(ServiceContractHeader, WorkDate(), false);
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, InvoiceNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItemWithUnitPrice());
    end;

    local procedure CreateServiceHeaderWithExpirartionDate(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractHeader."Customer No.");
        ServiceHeader.Validate("Order Date", ServiceContractHeader."Expiration Date");
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceContractLineWithDescription(ServContractHeader: Record "Service Contract Header"; var DescPart1: Text; var DescPart2: Text)
    var
        ServContractLine: Record "Service Contract Line";
        Option: Option Capitalized,"Literal and Capitalized";
    begin
        CreateServiceContractLine(ServContractLine, ServContractHeader);
        DescPart1 := LibraryUtility.GenerateRandomAlphabeticText(
            MaxStrLen(ServContractLine.Description) - StrLen(ServContractLine."Service Item No.") - 1, Option::Capitalized);
        DescPart2 := LibraryUtility.GenerateRandomAlphabeticText(
            MaxStrLen(ServContractLine.Description) - StrLen(DescPart1), Option::Capitalized);
        ServContractLine.Validate(Description, CopyStr(DescPart1 + DescPart2, 1, MaxStrLen(ServContractLine.Description)));
        ServContractLine.Modify(true);
        ServContractHeader.CalcFields("Calcd. Annual Amount");
        ServContractHeader.Validate("Annual Amount", ServContractHeader."Calcd. Annual Amount");
        ServContractHeader.Validate("Starting Date", WorkDate());
        ServContractHeader.Modify(true);
        DescPart1 := StrSubstNo('%1 %2', ServContractLine."Service Item No.", DescPart1);
    end;

    local procedure CreateUpdateServiceContract(var ContractNo: Code[20]; var CustomerNo: Code[20]; var ShiptoCode: Code[10])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        ShiptoCode :=
          LibraryUtility.GenerateRandomCode(ServiceContractHeader.FieldNo("Ship-to Code"), DATABASE::"Service Contract Header");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ServiceContractHeader."Change Status" := ServiceContractHeader."Change Status"::Locked;
        ServiceContractHeader.Status := ServiceContractHeader.Status::Signed;
        ServiceContractHeader."Ship-to Code" := ShiptoCode;
        ServiceContractHeader.Modify();
        ContractNo := ServiceContractHeader."Contract No.";
    end;

    local procedure InitServiceLineWithSignedContract(var ServiceLine: Record "Service Line")
    begin
        ServiceLine."Contract No." := LibraryUtility.GenerateGUID();
        ServiceLine.Validate("Appl.-to Service Entry", LibraryRandom.RandIntInRange(2, 5));
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
    end;

    local procedure InitCurrWorkDateAndPostServiceInvoice(var CurrentWorkDate: Date; var ServiceContractHeader: Record "Service Contract Header") InvoiceNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        CurrentWorkDate := WorkDate();
        WorkDate := ServiceContractHeader."Next Invoice Date";
        InvoiceNo := CreateServiceInvoice(ServiceContractHeader);
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceContractHeader.Find();
    end;

    local procedure CreateSignedServiceContractWithInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, CalcDate('<-CM>', WorkDate()),
          ServiceContractHeader."Invoice Period"::Quarter);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure CreateSignedServiceContractWithInvoicePeriodYear(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    begin
        CreateContractWithInvPeriodYear(ServiceContractHeader, ServiceContractLine);
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ModifyServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Service Period");
        SetStartingDateAsNextInvDateAndSignContract(ServiceContractHeader);
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CheckChangeCustomerNo(ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20])
    begin
        // Check that Customer No. is Changed after change Customer.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Customer No.", CustomerNo);
    end;

    local procedure CheckInvoiceQuantity(ContractNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        // Check Invoice for Quantity 1 which is created from Service Contract.
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Contract No.", ContractNo);
        ServiceLine.FindFirst();
        ServiceLine.TestField(Quantity, 1);  // Taking 1 because in every case it generates only 1 quantity.
    end;

    local procedure CheckServiceCreditMemo(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that Customer No. is same after creating Credit Memo from Service Contract.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
        ServiceHeader.TestField("Customer No.", ServiceContractHeader."Customer No.");
        ServiceHeader.TestField("Bill-to Contact No.", ServiceContractHeader."Bill-to Contact No.");
        ServiceHeader.TestField("Bill-to Contact", ServiceContractHeader."Bill-to Contact");
    end;

    local procedure CheckCustomerNoOnInvoice(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Customer No.", ServiceContractHeader."Customer No.");
    end;

    local procedure CheckOrderDate(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
    begin
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        ServiceHeader.TestField("Order Date", ServiceContractHeader."First Service Date");
    end;

    local procedure CheckSrvcCntractQuoteLinValues(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type"::Quote);
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        ServiceContractLine.TestField(Profit, ServiceContractLine."Line Value" - ServiceContractLine."Line Cost");
        ServiceContractLine.TestField("Next Planned Service Date", ServiceContractHeader."First Service Date");
    end;

    local procedure CheckErrorOnCopyDocument(ServiceContractHeader: Record "Service Contract Header")
    var
        CopyServDoc: Report "Copy Service Document";
    begin
        CopyServDoc.SetParameters(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        CopyServDoc.UseRequestPage(false);
        CopyServDoc.Run();
    end;

    local procedure CreateCustomerWithCreditLimit(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Customer.Modify(true);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; ExternalDocumentNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("External Document No.", ExternalDocumentNo);
        GLEntry.FindLast();
    end;

    local procedure NoGLEntriesFound(GLAccountNo: Code[20]; ExternalDocumentNo: Code[20]): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("External Document No.", ExternalDocumentNo);
        exit(GLEntry.IsEmpty);
    end;

    local procedure FindServiceDocumentWithContractNo(DocumentType: Enum "Service Document Type"; ContractNo: Code[20]): Boolean
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        exit(ServiceHeader.FindFirst())
    end;

    local procedure FindServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; ContractNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindLast();
    end;

    local procedure FindServiceHour(var ServiceHour: Record "Service Hour"; ServiceContractNo: Code[20]; Type: Enum "Service Hour Contract Type")
    begin
        ServiceHour.SetRange("Service Contract No.", ServiceContractNo);
        ServiceHour.SetRange("Service Contract Type", Type);
        ServiceHour.FindSet();
    end;

    local procedure FindServiceInvoiceHeader(ContractNo2: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Contract No.", ContractNo2);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure FindServiceCreditHeader(ContractNo2: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Contract No.", ContractNo2);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure FindServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindLast();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure FindServiceLedgerEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractNo: Code[20]; DocumentType: Enum "Service Ledger Entry Document Type"; EntryType: Enum "Service Ledger Entry Entry Type")
    begin
        ServiceLedgerEntry.SetRange("Document Type", DocumentType);
        ServiceLedgerEntry.SetRange("Entry Type", EntryType);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        ServiceLedgerEntry.FindFirst();
    end;

    local procedure FindDifferentStandardText(var StandardText: Record "Standard Text"; StandardTextCode: Code[20])
    var
        RecordRef: RecordRef;
    begin
        StandardText.SetFilter(Code, '<>%1', StandardTextCode);
        RecordRef.GetTable(StandardText);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(StandardText);
    end;

    local procedure FindStandardText(var StandardText: Record "Standard Text")
    var
        RecordRef: RecordRef;
    begin
        StandardText.Init();
        RecordRef.GetTable(StandardText);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(StandardText);
    end;

    local procedure GetAnalysisViewTotalAmount(AnalysisbyDimensions: TestPage "Analysis by Dimensions"; GLAccount: Code[20]): Decimal
    begin
        LibraryVariableStorage.Enqueue(GLAccount);
        AnalysisbyDimensions.ShowOppositeSign.SetValue(false);
        AnalysisbyDimensions.ShowMatrix.Invoke();
        exit(LibraryVariableStorage.DequeueDecimal());
    end;

    local procedure GetExpectedAmount(ServiceContractLine: Record "Service Contract Line"; DiscPostingType: Option) Amount: Decimal
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case DiscPostingType of
            SalesReceivablesSetup."Discount Posting"::"No Discounts", SalesReceivablesSetup."Discount Posting"::"Invoice Discounts":
                Amount := ServiceContractLine."Line Amount";
            SalesReceivablesSetup."Discount Posting"::"Line Discounts", SalesReceivablesSetup."Discount Posting"::"All Discounts":
                Amount := ServiceContractLine."Line Value";
        end;
        exit(Amount);
    end;

    local procedure GetServiceInvoiceCount(): Integer
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        exit(ServiceHeader.Count);
    end;

    local procedure GetPrepaidContractEntry(ServiceHeader: Record "Service Header"; ServiceContractNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        GetPrepaidContractEntries: Report "Get Prepaid Contract Entries";
    begin
        GetPrepaidContractEntries.UseRequestPage(false);
        GetPrepaidContractEntries.Initialize(ServiceHeader);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        GetPrepaidContractEntries.SetTableView(ServiceLedgerEntry);
        GetPrepaidContractEntries.RunModal();
    end;

    local procedure GetNonPerpaidContractAccFromCust(CustNo: Code[20]; ServContrAccGrCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        Customer.Get(CustNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        ServiceContractAccountGroup.Get(ServContrAccGrCode);
        exit(ServiceContractAccountGroup."Non-Prepaid Contract Acc.");
    end;

    local procedure GetPrepaidContractAccFromAccGroup(ServContrAccGroupCode: Code[10]): Code[20]
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        ServiceContractAccountGroup.Get(ServContrAccGroupCode);
        exit(ServiceContractAccountGroup."Prepaid Contract Acc.");
    end;

    local procedure GetTotalServLineAmount(ContractNo: Code[20]): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ContractNo);
        ServiceLine.CalcSums(Amount);
        exit(ServiceLine.Amount);
    end;

    local procedure CreateContractInvoices(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Find();
        Commit();
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Date");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices();
    end;

    local procedure OpenServiceContractPage(ContractNo: Code[20])
    var
        ServiceContract: TestPage "Service Contract";
    begin
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ContractNo);
        ServiceContract.CreateServiceInvoice.Invoke();
        ServiceContract.OK().Invoke();
    end;

    local procedure PostPrepaidContractEntryWithNextInvoiceDate(var ServiceContractHeader: Record "Service Contract Header")
    begin
        PostPrepaidContractEntry(
          ServiceContractHeader."Contract No.",
          CalcDate('<1M>', ServiceContractHeader."Next Invoice Date") - 1,
          WorkDate());
    end;

    local procedure PostPrepaidContractEntry(ContractNo: Code[20]; PostTillDate: Date; PostingDate: Date)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        PostPrepaidContractEntries: Report "Post Prepaid Contract Entries";
        PostPrepaidContractAction: Option "Post Prepaid Transactions","Print Only";
    begin
        Clear(PostPrepaidContractEntries);
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        PostPrepaidContractEntries.SetTableView(ServiceLedgerEntry);
        PostPrepaidContractEntries.InitializeRequest(PostTillDate, PostingDate, PostPrepaidContractAction::"Post Prepaid Transactions");
        PostPrepaidContractEntries.UseRequestPage(false);
        PostPrepaidContractEntries.Run();
    end;

    local procedure PostServiceInvoice(ServiceContractNo: Code[20])
    var
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceHeader: Record "Service Header";
    begin
        // Find the Service Invoice by searching in Service Document Register.
        ServiceDocumentRegister.SetRange("Source Document Type", ServiceDocumentRegister."Source Document Type"::Contract);
        ServiceDocumentRegister.SetRange("Source Document No.", ServiceContractNo);
        ServiceDocumentRegister.SetRange("Destination Document Type", ServiceDocumentRegister."Destination Document Type"::Invoice);
        ServiceDocumentRegister.FindFirst();
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceDocumentRegister."Destination Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure PostServiceInvoiceFromServiceContractWithDiscount(DiscPostingType: Option)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        Amount: Decimal;
    begin
        // Setup: Update Discount Posting in Sales & Receivables Setup
        Initialize();
        LibrarySales.SetDiscountPostingSilent(DiscPostingType);

        // Create Service Contract with Yearly Invoice Period and Line Discount. Sign the Contract.
        CreateServiceContractWithInvoicePeriodAndDiscount(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Create and Post Service Invoices.
        CreateAndPostServiceInvoiceFromServiceContract(ServiceContractHeader);

        // Exercise: Post Prepaid Contract Entries.
        PostPrepaidContractEntry(
          ServiceContractHeader."Contract No.", CalcDate('<1Y>', WorkDate()), WorkDate());

        // Verify: Verify GL Entries after posting Service invoice.
        ServiceContractAccountGroup.Get(ServiceContractHeader."Serv. Contract Acc. Gr. Code");
        Amount := GetExpectedAmount(ServiceContractLine, DiscPostingType);
        VerifyGLEntryForPostPrepaidContract(
          ServiceContractAccountGroup."Non-Prepaid Contract Acc.", ServiceContractHeader."Contract No.", -Amount);
    end;

    local procedure PostServiceInvoiceFromContract(var ExpectedAmount: Decimal; var ExpectedUnitPrice: Decimal; ServiceContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader.SetRange("Contract No.", ServiceContractNo);
        ServiceHeader.FindFirst();

        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindFirst();
        ExpectedAmount := ServiceLine.Amount;
        ExpectedUnitPrice := ServiceLine."Unit Price";

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateAndPostServiceCreditMemo(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ModifyServiceContractStatus(ServiceContractHeader);
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.", WorkDate());
        PostServiceCreditMemo(ServiceContractHeader);
    end;

    local procedure PostServiceCreditMemo(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
    begin
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure PrepaidFalseInServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Validate(Prepaid, false);
        ServiceContractHeader.Modify(true);
    end;

    local procedure SumOfLineAmount(ContractNo: Code[20]) LineAmount: Decimal
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type"::Contract);
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindSet();
        repeat
            LineAmount += ServiceContractLine."Line Amount";
        until ServiceContractLine.Next() = 0;
    end;

    local procedure UpdateAnnualAmountOnServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateBillToCostomerNo(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateContractInvAndLineText(NewInvLineTextCode: Code[20]; NewLineInvTextCode: Code[20])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Contract Inv. Line Text Code", NewInvLineTextCode);
        ServiceMgtSetup.Validate("Contract Line Inv. Text Code", NewLineInvTextCode);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure UpdateContractPeriodTextCode(StandardTextCode: Code[20])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Contract Inv. Period Text Code", StandardTextCode);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure UpdateContractPrice(ServiceContractHeader: Record "Service Contract Header") PricePercentage: Decimal
    var
        UpdateContractPrices: Report "Update Contract Prices";
        PerformUpdate: Option "Update Contract Prices","Print Only";
    begin
        WorkDate := ServiceContractHeader."Next Price Update Date";
        UpdateContractPrices.SetTableView(ServiceContractHeader);
        PricePercentage := 2 * LibraryRandom.RandInt(5);  // To find the Even No.
        UpdateContractPrices.InitializeRequest(WorkDate(), PricePercentage, PerformUpdate::"Update Contract Prices");
        UpdateContractPrices.UseRequestPage(false);
        UpdateContractPrices.Run();
    end;

    local procedure UpdateInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header"; InvoicePeriod: Enum "Service Contract Header Invoice Period")
    begin
        ServiceContractHeader.Validate("Invoice Period", InvoicePeriod);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateContractLineCostAndValue(var ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandDec(1200, 2) * 12);
        ServiceContractLine.Validate("Line Value", ServiceContractLine."Line Cost");
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateContractHeaderPrepaid(var ServiceContractHeader: Record "Service Contract Header"; PrepaidValue: Boolean)
    begin
        ServiceContractHeader.Validate(Prepaid, PrepaidValue);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceOrderType(var ServiceContractHeader: Record "Service Contract Header"; ServiceOrderType: Code[10])
    begin
        ServiceContractHeader.Validate("Service Order Type", ServiceOrderType);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceLineForQtyToInvoice(var ServiceLine: Record "Service Line"; DocumentNo: Code[20]; ContractNo: Code[20])
    begin
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.SetRange("Contract No.", ContractNo);
        ServiceLine.FindFirst();
        ServiceLine.Validate("Qty. to Invoice", ServiceLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(2, 5));
        ServiceLine.Modify(true);
    end;

    local procedure UpdateContractLineBlankServiceItemNo(var ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceContractLine.Validate("Service Item No.", '');
        ServiceContractLine.Validate(
          Description, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceContractLine.Description), 1));
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandInt(5000));
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(5000));
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateContractLineItemNo(var ServiceContractLine: Record "Service Contract Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        ServiceContractLine.Validate("Item No.", Item."No.");
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandInt(5000));
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(5000));
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateDimensionInServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Find();
        ServiceContractHeader.Validate(
          "Shortcut Dimension 1 Code", CreateDimValueForGlobalDimension1Code());
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServContractAccGroup(var ServiceContractAccountGroup: Record "Service Contract Account Group")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", GLAccNo); // make sure Prepaid Contract Acc. <> Non-Prepaid Contract Acc.
        ServiceContractAccountGroup.Modify(true);
    end;

    local procedure UpdateServiceContractLineDiscount(var ServiceContractHeader: Record "Service Contract Header"; LineDiscount: Decimal)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        ServiceContractLine.Validate("Line Discount %", LineDiscount);
        ServiceContractLine.UpdateContractAnnualAmount(false);
        ServiceContractLine.Modify(true);
    end;

    local procedure SetStartingDateAsNextInvDateAndSignContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Next Invoice Date");
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SetHideDialog := true;
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
    end;

    local procedure ModifyServiceContractHeaderWithInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header"; StartingDate: Date; InvoicePeriod: Enum "Service Contract Header Invoice Period")
    begin
        ServiceContractHeader.Validate("Starting Date", StartingDate);
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Invoice Period", InvoicePeriod);
        ServiceContractHeader.Modify(true);
    end;

    local procedure ModifyServiceContractStatus(var ServiceContractHeader: Record "Service Contract Header")
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Find();
        ServiceContractHeader.Validate("Expiration Date", WorkDate());
        ServiceContractHeader.Modify(true);
    end;

    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; PriceUpdatePeriod: DateFormula)
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", PriceUpdatePeriod);
        ServiceContractHeader.Modify(true);
    end;

    local procedure ModifyServiceContractExpirationDate(var ServiceContractHeader: Record "Service Contract Header"; ExpirationDate: Date)
    begin
        ServiceContractHeader.Validate("Expiration Date", ExpirationDate);
        ServiceContractHeader.Modify(true);
    end;

    local procedure ModifyServicePeriodOnServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServicePeriod: DateFormula;
    begin
        ServiceContractHeader.Validate("Starting Date", CalcDate('<CM+1D>', WorkDate()));
        Evaluate(ServicePeriod, StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Validate("Expiration Date", CalcDate('<CM+1D>', WorkDate()));
        ServiceContractHeader.Modify(true);
    end;

    local procedure ModifyServiceContractLineNextPlannedServDate(var ServiceContractLine: Record "Service Contract Line"; NextPlannedServiceDate: Date)
    begin
        ServiceContractLine.Validate("Next Planned Service Date", NextPlannedServiceDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure RoundBasedOnCurrencyPrecision(Value: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.InitRoundingPrecision();
        exit(Round(Value, Currency."Amount Rounding Precision"));
    end;

    local procedure RemoveContractLine(ContractNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        REPORT.RunModal(REPORT::"Remove Lines from Contract", false, true, ServiceContractLine);
    end;

    local procedure RunCreateContractInvoices()
    var
        CreateContractInvoices: Report "Create Contract Invoices";
    begin
        Clear(CreateContractInvoices);
        CreateContractInvoices.Run();
    end;

    local procedure RunCreateContractServiceOrders()
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
    begin
        Clear(CreateContractServiceOrders);
        CreateContractServiceOrders.Run();
    end;

    local procedure GetSmallestLineAmount(StartingDate: Date): Decimal
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        exit((12 * LibraryERM.GetUnitAmountRoundingPrecision()) /
          (2 * ServContractManagement.NoOfMonthsAndMPartsInPeriod(StartingDate, CalcDate('<CM>', StartingDate))));
    end;

    local procedure VerifyAmountOnGLEntry(ContractNo: Code[20]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.CalcFields("Balance (LCY)");
        VerifyInvoicedGLAmt(FindServiceInvoiceHeader(ContractNo), '', -Customer."Balance (LCY)");
    end;

    local procedure VerifyContractCreationByQuote(QuoteNo: Code[20])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, QuoteNo);
        ServiceContractHeader.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", 1);
    end;

    local procedure VerifyContractNotExists(QuoteNo: Code[20])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Contract No.", QuoteNo);
        Assert.RecordCount(ServiceContractHeader, 0);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Quote);
        Assert.RecordCount(ServiceContractHeader, 1);
    end;

    local procedure VerifyGLEntryForPostPrepaidContract(NonPrepaidContractAcc: Code[20]; ContractNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, NonPrepaidContractAcc, ContractNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(GLEntryErr, GLEntry.FieldCaption(Amount)));
    end;

    local procedure VerifyServiceContractLine(ServiceContractLine: Record "Service Contract Line")
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.Get(ServiceContractLine."Service Item No.");
        ServiceContractLine.TestField(Description, ServiceItem.Description);
        ServiceContractLine.TestField("Item No.", ServiceItem."Item No.");
        ServiceContractLine.TestField("Unit of Measure Code", ServiceItem."Unit of Measure Code");
    end;

    local procedure VerifyServiceContractHeader(ServiceContractHeader: Record "Service Contract Header"; LineAmount: Decimal)
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.TestField("Calcd. Annual Amount", LineAmount);
        ServiceContractHeader.TestField("Annual Amount", LineAmount);
    end;

    local procedure VerifyServiceContractHeaderForNoOfUnpostedInvoices(ServiceContractHeader: Record "Service Contract Header"; NoOfPostedInvoices: Integer)
    begin
        ServiceContractHeader.CalcFields("No. of Posted Invoices");
        Assert.AreEqual(
          NoOfPostedInvoices, ServiceContractHeader."No. of Posted Invoices", StrSubstNo(ServiceContractErr, ServiceContractHeader.FieldCaption("No. of Posted Invoices")));
    end;

    local procedure VerifyServiceContractHasLink(ContractType: Enum "Service Contract Type"; ContractNo: Code[20])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.Get(ContractType, ContractNo);
        Assert.IsTrue(ServiceContractHeader.HasLinks, StrSubstNo(ServiceDocLinkNotFoundErr, ServiceContractHeader.TableCaption));
    end;

    local procedure VerifyServiceHeaderHasLink(DocumentType: Enum "Service Document Type"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindFirst();
        Assert.IsTrue(
          ServiceHeader.HasLinks, StrSubstNo(ServiceDocLinkNotFoundErr, ServiceHeader.TableCaption));
    end;

    local procedure VerifyServiceHoursWithSetup(ServiceContractQuoteNo: Code[20])
    var
        ServiceHour: Record "Service Hour";
        ServiceHour2: Record "Service Hour";
    begin
        FindServiceHour(ServiceHour, ServiceContractQuoteNo, ServiceHour2."Service Contract Type"::Quote);
        FindServiceHour(ServiceHour2, '', ServiceHour."Service Contract Type"::" ");  // To find the default Service Hour.
        repeat
            ServiceHour.TestField(Day, ServiceHour2.Day);
            ServiceHour.TestField("Starting Date", ServiceHour2."Starting Date");
            ServiceHour.TestField("Starting Time", ServiceHour2."Starting Time");
            ServiceHour.TestField("Ending Time", ServiceHour2."Ending Time");
            ServiceHour.TestField("Valid on Holidays", ServiceHour2."Valid on Holidays");
            ServiceHour.Next();
        until ServiceHour2.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(ContractNo: Code[20]; DocumentType: Enum "Service Ledger Entry Document Type"; Sign: Integer)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceLedgerEntry2: Record "Service Ledger Entry";
    begin
        FindServiceLedgerEntry(
          ServiceLedgerEntry, ContractNo, ServiceLedgerEntry."Document Type"::Shipment, ServiceLedgerEntry."Entry Type"::Usage);
        FindServiceLedgerEntry(ServiceLedgerEntry2, ContractNo, DocumentType, ServiceLedgerEntry."Entry Type"::Sale);
        ServiceLedgerEntry.TestField(Amount, Sign * ServiceLedgerEntry2.Amount);
        ServiceLedgerEntry.TestField(Quantity, Sign * ServiceLedgerEntry2.Quantity);
        ServiceLedgerEntry.TestField("Unit Cost", ServiceLedgerEntry2."Unit Cost");
    end;

    local procedure VerifyServiceInvoice(ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindFirst();
    end;

    local procedure VerifyServiceLineAmount(ContractNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindFirst();
        FindServiceLine(ServiceLine, ContractNo);
        ServiceLine.FindLast();
        Assert.AreEqual(ServiceContractLine."Line Value", ServiceLine.Amount, ServiceLineAmountErr);
    end;

    local procedure GetServiceLedgerEntryLines(ContractNo: Code[20]): Integer
    var
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLine(ServiceLine, ContractNo);

        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Document No.", ServiceLine."Document No.");
        exit(ServiceLedgerEntry.Count);
    end;

    local procedure VerifyValuesOnServiceInvoice(ServiceContractHeader: Record "Service Contract Header"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Check Service Header for Customer No. and Posting Date which is created from Service Contract.
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        ServiceHeader.TestField("Customer No.", ServiceContractHeader."Customer No.");
        ServiceHeader.TestField("Posting Date", ServiceContractHeader."Next Invoice Date");

        // Check Service Line 4 for Type, No. and Quantity 1 which is created from Service Contract.
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        ServiceLine.FindLast();
        ServiceLine.TestField(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.TestField("No.", No);
        ServiceLine.TestField(Quantity, 1); // Quantity 1 for Type G/L Account.
    end;

    local procedure VerifyLinesOnServiceInvoice(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemsCountVar: Variant;
        i: Integer;
        ItemsCount: Integer;
    begin
        // Check G/L account lines are created after the related text line.
        // G/L Account should follow appropriate Item line.
        LibraryVariableStorage.Dequeue(ItemsCountVar);
        ItemsCount := ItemsCountVar;
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        ServiceLine.Ascending(false);
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        for i := 1 to ItemsCount do begin
            ServiceLine.TestField(Type, ServiceLine.Type::"G/L Account");
            ServiceLine.Next();
            ServiceLine.TestField(Type, ServiceLine.Type::" ");
            ServiceLine.Next();
        end;
    end;

    local procedure VerifyLineDiscountOnServiceInvoice(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemsCountVar: Variant;
        i: Integer;
        ItemsCount: Integer;
    begin
        // Check Service Invoice lines have blank Line Discount values.
        LibraryVariableStorage.Dequeue(ItemsCountVar);
        ItemsCount := ItemsCountVar;
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
        ServiceLine.Ascending(false);
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        for i := 1 to ItemsCount do begin
            ServiceLine.TestField("Line Discount %", 0);
            ServiceLine.Next();
        end;
    end;

    local procedure VerifyValuesOnContractHeader(ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", 2);
        ServiceContractHeader.TestField("Print Increase Text", false);
    end;

    local procedure VerifyAmountServiceLedgerEntry(ContractNo: Code[20]; Amount: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLine(ServiceLine, ContractNo);

        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Cost Amount", -Amount);
            ServiceLedgerEntry.TestField("Amount (LCY)", -Amount);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDimensionSetEntry(DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyUnitCostNotEqualToZeroOnCreditMemoLines(CustomerNo: Code[20]; ServiceItemNo: Code[20]; CreditMemoNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::"Credit Memo");
        ServiceLine.SetRange("Document No.", CreditMemoNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.SetFilter("Customer No.", '<>%1', CustomerNo);
        ServiceLine.SetFilter("Service Item No.", '<>%1', ServiceItemNo);
        ServiceLine.SetFilter("Unit Cost (LCY)", '<>%1', 0);
        if not ServiceLine.IsEmpty() then
            Error(UnitCostErr);
    end;

    local procedure VerifyInvoicedGLAmt(DocNo: Code[20]; GLAccNo: Code[20]; Amt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLAmt: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocNo);
        if GLAccNo <> '' then
            GLEntry.SetRange("G/L Account No.", GLAccNo);
        if Amt > 0 then
            GLEntry.SetFilter(Amount, '>0')
        else
            GLEntry.SetFilter(Amount, '<0');
        if GLEntry.FindSet() then
            repeat
                GLAmt += GLEntry.Amount;
            until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(GLAmt, Amt, LibraryERM.GetAmountRoundingPrecision(), '');
    end;

    local procedure VerifyCrMemoLinkedToInvServLedgEntries(ContractNo: Code[20])
    var
        InvoiceServiceLedgerEntry: Record "Service Ledger Entry";
        CrMemoServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLedgerEntry(CrMemoServiceLedgerEntry, ContractNo, CrMemoServiceLedgerEntry."Document Type"::"Credit Memo", CrMemoServiceLedgerEntry."Entry Type"::Sale);
        CrMemoServiceLedgerEntry.SetFilter("Applies-to Entry No.", '>0');
        repeat
            InvoiceServiceLedgerEntry.Get(CrMemoServiceLedgerEntry."Applies-to Entry No.");
            Assert.AreEqual(-InvoiceServiceLedgerEntry."Amount (LCY)", CrMemoServiceLedgerEntry."Amount (LCY)", CrMemoServiceLedgerEntry.FieldCaption("Amount (LCY)"));
            Assert.AreEqual(InvoiceServiceLedgerEntry."Posting Date", CrMemoServiceLedgerEntry."Posting Date", CrMemoServiceLedgerEntry.FieldCaption("Posting Date"));
        until CrMemoServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDimensionInGLEntry(GLAccountNo: Code[20]; DocNo: Code[20]; ExpectedDimensionCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccountNo, DocNo);
        Assert.AreEqual(
          ExpectedDimensionCode, GLEntry."Global Dimension 1 Code", GLEntry.FieldCaption("Global Dimension 1 Code"));
    end;

    local procedure VerifyDimensionInGLEntries(GLAccountNo: Code[20]; DocNo: Code[20]; ExpectedDimensionCode: array[2] of Code[20])
    var
        GLEntry: Record "G/L Entry";
        i: Integer;
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("External Document No.", DocNo);
        GLEntry.FindSet();
        for i := 1 to ArrayLen(ExpectedDimensionCode) do begin
            Assert.AreEqual(
              ExpectedDimensionCode[i], GLEntry."Global Dimension 1 Code", GLEntry.FieldCaption("Global Dimension 1 Code"));
            GLEntry.Next();
        end;
    end;

    local procedure VerifyServiceLineDescription(ExpectedDescPart1: Text; ExpectedDescPart2: Text)
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Init();
        ServLine.SetRange(Description, ExpectedDescPart1);
        Assert.RecordIsNotEmpty(ServLine);
        ServLine.SetRange(Description, ExpectedDescPart2);
        Assert.RecordIsNotEmpty(ServLine);
    end;

    local procedure VerifyServiceCreditMemoAmountAndUnitPrice(ServiceContractNo: Code[20]; ExpectedAmount: Decimal; ExpectedUnitPrice: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        FindServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractNo);
        ServiceHeader.FindFirst();
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type"::"Credit Memo");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindFirst();
        Assert.AreNearlyEqual(ExpectedAmount, ServiceLine.Amount, 0.01, '');
        Assert.AreNearlyEqual(ExpectedUnitPrice, ServiceLine."Unit Price", 0.01, '');
    end;

    local procedure ChangeCustomerNo(var ServiceContractHeader: Record "Service Contract Header"): Code[20]
    var
        ShiptoAddress: Record "Ship-to Address";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        LibrarySales.CreateShipToAddress(ShiptoAddress, LibrarySales.CreateCustomerNo());
        ServContractManagement.ChangeCustNoOnServContract(ShiptoAddress."Customer No.", ShiptoAddress.Code, ServiceContractHeader);
        exit(ShiptoAddress."Customer No.");
    end;

    local procedure CreateServiceContractDocument(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryVariableStorage.Enqueue(false); // To avoid using the default template.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);

        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        Evaluate(ServiceContractHeader."Service Period", '<1Y>');
        ServiceContractHeader.Validate("Service Period");
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContLineWithServiceItem(ServiceContractHeader: Record "Service Contract Header"; var ServiceItem: Record "Service Item"; var ServiceContractLine: Record "Service Contract Line")
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        ServiceItem.Validate("Default Contract Cost", LibraryRandom.RandDec(1000, 2));
        ServiceItem.Validate("Default Contract Value", LibraryRandom.RandDec(200, 2));
        ServiceItem.Modify(true);

        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Next Planned Service Date", ServiceContractHeader."First Service Date");
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Modify(true);
    end;

    local procedure SignPrepaidContract(ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryVariableStorage.Enqueue(true); // Confirm to create a signed contract. 
        LibraryVariableStorage.Enqueue(false); // Confirm not to create a new service invoice.
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure OpenServiceContractAndCreateInvoice(var ServiceContract: TestPage "Service Contract"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContract.OpenEdit();
        ServiceContract.GoToRecord(ServiceContractHeader);

        LibraryVariableStorage.Enqueue(true); // Confirm to create a new service invoice.
        ServiceContract.CreateServiceInvoice.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ContractTemplateConfirmHandlerFalse(SignContractMessage: Text[1024]; var Result: Boolean)
    begin
        Result := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractLineSelectionHandler(var ContractLineSelection: TestPage "Contract Line Selection")
    begin
        // Verifying that there is no value on the Contract Line Selection page.
        ContractLineSelection."No.".AssertEquals('');
        ContractLineSelection."Customer No.".AssertEquals('');
        ContractLineSelection.Cancel().Invoke();  // Using Cancel to close the page as OK button is disabled.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractServiceOrdersRequestPageHandler(var CreateContractServiceOrders: TestRequestPage "Create Contract Service Orders")
    var
        ContractNumber: Variant;
        CreateServOrder: Option "Create Service Order","Print Only";
    begin
        LibraryVariableStorage.Dequeue(ContractNumber);
        CreateContractServiceOrders.StartingDate.SetValue(Format(WorkDate()));
        CreateContractServiceOrders.EndingDate.SetValue(Format(WorkDate()));
        CreateContractServiceOrders.CreateServiceOrders.SetValue(CreateServOrder::"Create Service Order");
        CreateContractServiceOrders."Service Contract Header".SetFilter("Contract No.", ContractNumber);
        CreateContractServiceOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractInvoicesRequestPageHandler(var CreateContractInvoices: TestRequestPage "Create Contract Invoices")
    var
        InvoiceDate: Variant;
        ContractNumber: Variant;
        CreateInvoices: Option "Create Invoices","Print Only";
    begin
        LibraryVariableStorage.Dequeue(InvoiceDate);
        LibraryVariableStorage.Dequeue(ContractNumber);
        CreateContractInvoices.PostingDate.SetValue(InvoiceDate);
        CreateContractInvoices.InvoiceToDate.SetValue(InvoiceDate);
        CreateContractInvoices.CreateInvoices.SetValue(CreateInvoices::"Create Invoices");
        CreateContractInvoices."Service Contract Header".SetFilter("Contract No.", ContractNumber);
        CreateContractInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesNotEditablePageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    begin
        Assert.IsFalse(DimensionSetEntries."Dimension Code".Editable(), DimensionNonEditableErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesEditablePageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        Assert.IsTrue(EditDimensionSetEntries."Dimension Code".Editable(), DimensionEditableErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FormModalHandler(var ServiceContract: Page "Service Contract"; var Response: Action)
    begin
        ServiceContract.SetRecord(ServiceContractHeader2);
        ServiceContract.CheckRequiredFields();
        Response := ACTION::OK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InvoiceCreationMessageHandler(Message: Text[1024])
    var
        MessageText: Text[1024];
    begin
        // Verify Invoice creation Message.
        MessageText := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(MessageText));
        if (StrPos(Message, MessageText) = 0) and (StrPos(Message, OrderCreationMsg) = 0) then
            Error(MessageText);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        // Confirmation message handler to Sign Service Contract.
        Result := (StrPos(ConfirmMessage, InvoiceCreationMsg) = 0);
    end;

    local procedure InvokeLineDimensionFromServiceInvoice(ServiceLine: Record "Service Line"; ContractNo: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceInvoice.FILTER.SetFilter("Customer No.", ServiceLine."Customer No.");
        ServiceInvoice.ServLines.FILTER.SetFilter("Contract No.", ContractNo);
        ServiceInvoice.ServLines.Dimensions.Invoke();
    end;

    local procedure PrepareServiceContractsForInvoiceGeneration(var ServiceContractHeader: Record "Service Contract Header"; i: Integer; ContractCount: Integer)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        Clear(ServiceContractHeader);
        Clear(ServiceContractLine);
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        if ContractCount = 3 then
            ServiceContractHeader."Invoice after Service" := i = 2 // One contract should be excluded from the invoice generation
        else
            ServiceContractHeader."Invoice after Service" := false;
        ServiceContractHeader."Combine Invoices" := true;
        ServiceContractHeader.Validate("Annual Amount", 1000);
        ServiceContractHeader.Status := ServiceContractHeader.Status::Signed;
        ServiceContractHeader."Change Status" := ServiceContractHeader."Change Status"::Locked;
        ServiceContractHeader.SuspendStatusCheck(true);
    end;

    local procedure CreateServiceItemAndContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ShipToAddress: Record "Ship-to Address";
        ServiceItem: Record "Service Item";
        CustomerNo: Code[20];
    begin
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);

        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Default Contract Cost", LibraryRandom.RandDecInRange(10, 100, 0));
        ServiceItem.Validate("Default Contract Value", LibraryRandom.RandDecInRange(1000, 2000, 0));
        ServiceItem.Validate("Installation Date", CalcDate('<-CM-1D>', WorkDate()));
        ServiceItem.Modify(true);

        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ModifyServiceContractHeaderWithInvoicePeriod(ServiceContractHeader, ServiceItem."Installation Date", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Validate("Ship-to Code", ShipToAddress.Code);
        Evaluate(ServiceContractHeader."Service Period", '<12M>');
        ServiceContractHeader.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ModifyServiceContractExpirationDate(ServiceContractHeader, CalcDate('<11M+CM>', ServiceItem."Installation Date"));
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Modify(true);
    end;

    local procedure GetPostedServiceInvoiceAmount(ContractNo: Code[20]): Decimal
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceNo: Code[20];
    begin
        ServiceInvoiceNo := FindServiceInvoiceHeader(ContractNo);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceNo);
        ServiceInvoiceLine.CalcSums(Amount);
        exit(ServiceInvoiceLine.Amount);
    end;

    local procedure GetPostedServiceCrMemoAmount(ContractNo: Code[20]): Decimal
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceCreditNo: Code[20];
    begin
        ServiceCreditNo := FindServiceCreditHeader(ContractNo);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCreditNo);
        ServiceCrMemoLine.CalcSums(Amount);
        exit(ServiceCrMemoLine.Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostHandler(var ServiceInvoice: TestPage "Service Invoice")
    var
        ContractNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(ContractNumber);
        ServiceInvoice.FILTER.SetFilter("Contract No.", ContractNumber);
        ServiceInvoice.ServLines.Last();
        LibraryVariableStorage.Enqueue(ServiceInvoice.ServLines."Line Amount".AsDecimal());
        ServiceInvoice.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceGetShipmentHandler(var GetServiceShipmentLines: Page "Get Service Shipment Lines"; var Response: Action)
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        OrderNo: Variant;
        InvoiceNo: Code[20];
    begin
        InvoiceNo := LibraryVariableStorage.DequeueText();
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, InvoiceNo);
        ServiceGetShipment.SetServiceHeader(ServiceHeader);

        LibraryVariableStorage.Dequeue(OrderNo);
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindFirst();
        ServiceGetShipment.CreateInvLines(ServiceShipmentLine);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SignContractConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    begin
        // Confirmation message handler to Sign Service Contract.
        Result := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServContrctTemplateListHandler(var ServiceContractTemplateHandler: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServContrListServItemListHandler(var ServContrListServItem: TestPage "Serv. Contr. List (Serv. Item)")
    var
        ContractNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ContractNo);
        ServContrListServItem."Contract No.".AssertEquals(ContractNo);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MessageTest: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServInvoiceHandler(var PostedServInvoice: TestPage "Posted Service Invoice")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisbyDimMatrixPageHandler(var AnalysisByDimensionMatrix: TestPage "Analysis by Dimensions Matrix")
    var
        GLAccount: Text;
        FoundGLAccount: Boolean;
        EndOfRecords: Boolean;
    begin
        FoundGLAccount := false;
        EndOfRecords := false;
        GLAccount := LibraryVariableStorage.DequeueText();

        while not EndOfRecords do begin
            if AnalysisByDimensionMatrix.Code.Value = GLAccount then begin
                FoundGLAccount := true;
                EndOfRecords := true;
                LibraryVariableStorage.Enqueue(AnalysisByDimensionMatrix.TotalAmount.AsDecimal());
            end;
            EndOfRecords := not AnalysisByDimensionMatrix.Next();
        end;
        Assert.AreEqual(true, FoundGLAccount, StrSubstNo('Analysis View G/L Account:%1 is found', GLAccount));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ServContractConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        if ConfirmMessage = ServiceTemplateMsg then
            Result := false
        else
            Result := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandler(var CreateContractInvoices: TestRequestPage "Create Contract Invoices")
    var
        ContractNo: array[3] of Variant;
        ContractCount: Integer;
        i: Integer;
    begin
        CreateContractInvoices.PostingDate.SetValue(WorkDate());
        CreateContractInvoices.InvoiceToDate.SetValue(WorkDate());
        CreateContractInvoices.CreateInvoices.SetValue(0);
        ContractCount := LibraryVariableStorage.DequeueInteger();
        for i := 1 to ContractCount do
            LibraryVariableStorage.Dequeue(ContractNo[i]);
        case ContractCount of
            2:
                CreateContractInvoices."Service Contract Header".SetFilter("Contract No.",
                  StrSubstNo('%1|%2', ContractNo[1], ContractNo[2]));
            3:
                CreateContractInvoices."Service Contract Header".SetFilter("Contract No.",
                  StrSubstNo('%1|%2|%3', ContractNo[1], ContractNo[2], ContractNo[3]));
        end;
        CreateContractInvoices.OK().Invoke();
    end;

    local procedure CreateDimValueForGlobalDimension1Code(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        exit(DimensionValue.Code);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgCannotCreateHandler(MessageTest: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(MessageTest)
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ServContractConfHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Result := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ServiceContractHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    begin
        Result := LibraryVariableStorage.DequeueBoolean();
    end;
}

