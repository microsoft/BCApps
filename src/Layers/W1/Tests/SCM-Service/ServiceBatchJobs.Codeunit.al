// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;

codeunit 136122 "Service Batch Jobs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service]
        IsInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        OrderNo: Code[20];
        ExistError: Label '%1 for %2 must not exist.';
        ServiceError: Label 'Invoiced Service Order must not exist.';
        FromDateError: Label 'You must fill in the From Date field.';
        ToDateError: Label 'You must fill in the To Date field.';
        DateError: Label 'Date field must not be blank.';
        ServiceItemError: Label 'Service Item log entries must not exist.';
        ServiceLedgerEntryError: Label '%1 must not exist.';
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Batch Jobs");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Batch Jobs");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Batch Jobs");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerShipmentLine')]
    [Scope('OnPrem')]
    procedure InvoiceServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        CustomerNo: Code[20];
    begin
        // Covers document number TC-PP-RE-9 - refer to TFS ID 128082.
        // Test Service Order Invoiced after posting Service Invoice created through Get Shipment Lines.

        // 1. Setup: Create and Post Service Order with Service Line of Type Item.
        Initialize();
        CreateAndPostServiceOrder(ServiceHeader);
        CustomerNo := ServiceHeader."Customer No.";

        // Set Global Variable for Form Handler.
        OrderNo := ServiceHeader."No.";

        // 2. Exercise: Create Service Invoice from Get Shipment Lines and Post it.
        Clear(ServiceHeader);
        CreateInvoiceFromGetShipment(ServiceHeader, CustomerNo);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify Service Line update for Service Order.
        VerifyServiceLines(OrderNo);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerShipmentLine')]
    [Scope('OnPrem')]
    procedure DeleteInvoicedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        CustomerNo: Code[20];
    begin
        // Covers document number TC-PP-RE-9 - refer to TFS ID 128082.
        // Test Invoiced Service Order Deleted after run Delete Invoiced Service Order Batch Job.

        // 1. Setup: Create and Post Service Order with Service Line of Type Item, Create Service Invoice from Get Shipment Lines and
        // Post it.
        Initialize();
        CreateAndPostServiceOrder(ServiceHeader);
        CustomerNo := ServiceHeader."Customer No.";

        // Set Global Variable for Form Handler.
        OrderNo := ServiceHeader."No.";

        Clear(ServiceHeader);
        CreateInvoiceFromGetShipment(ServiceHeader, CustomerNo);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 2. Exercise: Run Delete Invoiced Service Orders Batch Report.
        RunDeleteInvoicedServiceOrders(OrderNo);

        // 3. Verify: Verify Service Order Deleted.
        Assert.IsFalse(
          ServiceHeader.Get(ServiceHeader."Document Type"::Order, OrderNo), StrSubstNo(ExistError, ServiceHeader.TableCaption(), OrderNo));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerShipmentLine')]
    [Scope('OnPrem')]
    procedure DeleteInvoicedServiceOrderWithComments()
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
        CustomerNo: Code[20];
        CommentText: Text[80];
    begin
        // [FEATURE] [Service Order] [Comments]
        // [SCENARIO 257848] REP5914 "Delete Invoiced Service Orders" removes comments for Service Order only.
        Initialize();

        // [GIVEN] Service Order "SO" posted with Shipped flag only.
        CreateAndPostServiceOrder(ServiceHeader);
        OrderNo := ServiceHeader."No.";
        CustomerNo := ServiceHeader."Customer No.";
        CommentText := LibraryUtility.GenerateGUID();

        // [GIVEN] "SO" has comment "SO-TXT".
        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          ServiceHeader."Document Type".AsInteger(), OrderNo, ServiceCommentLine.Type::General, 0);
        ServiceCommentLine.Comment := CommentText;
        ServiceCommentLine.Modify();

        // [GIVEN] Service Quote "SQ" with comment "SQ-TXT".
        MockServiceHeaderWithCommentLine(ServiceHeader."Document Type"::Quote, OrderNo, CommentText);

        // [GIVEN] Service Invoice "SI" created for "SO" and posted.
        Clear(ServiceHeader);
        CreateInvoiceFromGetShipment(ServiceHeader, CustomerNo);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [WHEN] REP5914 "Delete Invoiced Service Orders" is called to remove "SO" as "SI" is posted.
        RunDeleteInvoicedServiceOrders(OrderNo);

        // [THEN] "SO" is posted.
        Assert.IsFalse(
          ServiceHeader.Get(ServiceHeader."Document Type"::Order, OrderNo), StrSubstNo(ExistError, ServiceHeader.TableCaption(), OrderNo));

        // [THEN] "SO-TXT" is removed.
        VerifyServiceCommentLineNotExists(ServiceHeader."Document Type"::Order.AsInteger(), CommentText);

        // [THEN] "SQ-TXT" is still exists.
        VerifyServiceCommentLineExists(ServiceHeader."Document Type"::Quote.AsInteger(), CommentText);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostServiceInvoices()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        BatchPostServiceInvoices: Report "Batch Post Service Invoices";
    begin
        // Covers document number TC-PP-RE-10 - refer to TFS ID 128082.
        // Test Service Invoice Posted after run Post Service Invoices Batch Job.

        // 1. Setup: Create Customer, Create Service Invoice with Service Lines of Type Item, Resource, Cost and G/L Account,
        // Save Service Lines in Temporary Table.
        Initialize();
        CreateCustomerInvoiceDiscount(CustInvoiceDisc);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustInvoiceDisc.Code);
        GetServiceLines(ServiceLine, ServiceHeader);
        CopyServiceLines(TempServiceLine, ServiceLine);

        // 2. Exercise: Run Batch Post Service Invoices Report.
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        Clear(BatchPostServiceInvoices);
        BatchPostServiceInvoices.SetTableView(ServiceHeader);
        BatchPostServiceInvoices.UseRequestPage(false);
        BatchPostServiceInvoices.InitializeRequest(WorkDate(), true, true, true);
        BatchPostServiceInvoices.Run();

        // 3. Verify: Verify Service Invoice Line after run Batch Job.
        VerifyServiceInvoiceLine(TempServiceLine, ServiceHeader."No.", CustInvoiceDisc."Discount %");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemos()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        BatchPostServiceCrMemos: Report "Batch Post Service Cr. Memos";
    begin
        // Covers document number TC-PP-RE-11 - refer to TFS ID 128082.
        // Test Service Credit Memo Posted after run Post Service Credit Memos Batch Job.

        // 1. Setup: Create Customer, Customer Invoice Discount, Create Service Credit Memo with Service Lines of Type Item, Resource,
        // Cost and G/L Account, Save Service Lines in Temporary Table.
        Initialize();
        CreateCustomerInvoiceDiscount(CustInvoiceDisc);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustInvoiceDisc.Code);
        GetServiceLines(ServiceLine, ServiceHeader);
        CopyServiceLines(TempServiceLine, ServiceLine);

        // 2. Exercise: Run Batch Post Service Invoices Report.
        ExecuteConfirmHandlerInvoiceES();
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        Clear(BatchPostServiceCrMemos);
        BatchPostServiceCrMemos.SetTableView(ServiceHeader);
        BatchPostServiceCrMemos.UseRequestPage(false);
        BatchPostServiceCrMemos.InitializeRequest(WorkDate(), true, true, true);
        BatchPostServiceCrMemos.Run();

        // 3. Verify: Verify Service Credit Memo Line after run Batch Job.
        VerifyServiceCreditMemoLine(TempServiceLine, ServiceHeader."No.", CustInvoiceDisc."Discount %");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemLog()
    var
        ServiceItem: Record "Service Item";
    begin
        // Covers document number TC128951 TFS_TC_ID=13385.
        // Test Service Item Log Entries after running Service Item Log Delete report.

        // 1.Setup: Creating a Service Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');

        // 2.Exercise: Run the report for deleting the Service Item Log Entries.
        DeleteServiceItemLogEntries(ServiceItem."No.");

        // 3.Verify: Verify that the Service Item Log Entries must not exist.
        VerifyServiceItemLog(ServiceItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC129092 TFS_TC_ID=13528.
        // [SCENARIO] Test Invoiced Service Order after running the Delete Invoiced Service Orders report.
        Initialize();

        // [GIVEN] Create and post Service Order with multiple service lines and invoice rounding.
        LibraryERM.SetInvRoundingPrecisionLCY(0.5);
        CreateServiceOrder(ServiceHeader, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Delete Service Lines.
        DeleteServiceLine(ServiceLine, ServiceHeader);

        // [WHEN] Run the report to delete the invoiced Service Order.
        DeleteInvoiceServiceOrders(ServiceHeader."No.");

        // [THEN] Invoiced Service Order does not exist.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), ServiceError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FaultResolRelationFromDate()
    var
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
    begin
        // Covers document number TC129099 TFS_TC_ID=13535.
        // Test the error messages after running Insert Fault/Resolution Relationships without From Date.

        // 1. Setup: Create Fault Resolution Relationship code.
        Initialize();
        CreateFaultResolCodesRlship(FaultResolCodRelationship);

        // 2.Exercise: Run the report for Insert Fault Resolution Relationship Code without From Date.
        asserterror InsertFaultResolRelation(0D, WorkDate(), true, true);

        // 3.Verify: Verify the Fault Resolution Code Relationship Report.
        Assert.AreEqual(StrSubstNo(FromDateError), StrSubstNo(GetLastErrorText), DateError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FaultResolRelationManually()
    var
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
    begin
        // Covers document number TC129099 TFS_TC_ID=13535.
        // Test Fault/Resolution Relationships created manually after creating it.

        // 1. Setup.
        Initialize();

        // 2.Exercise: Creating Fault Resolution Code Relationship.
        CreateFaultResolCodesRlship(FaultResolCodRelationship);

        // 3.Verify: The Fault Resolution Code Relationship must be created manually.
        FaultResolCodRelationship.TestField("Created Manually", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FaultResolRelationToDate()
    var
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
    begin
        // Covers document number TC129099 TFS_TC_ID=13535.
        // Test the error messages after running Insert Fault/Resolution Relationships without To Date.

        // 1. Setup: Create Fault Resolution Relationship code.
        Initialize();
        CreateFaultResolCodesRlship(FaultResolCodRelationship);

        // 2.Exercise: Run the report for Insert Fault Resolution Relationship Code without To Date.
        asserterror InsertFaultResolRelation(WorkDate(), 0D, true, true);

        // 3.Verify: Verify the Fault Resolution Code Relationship report.
        Assert.AreEqual(StrSubstNo(ToDateError), StrSubstNo(GetLastErrorText), DateError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContractTemplateListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPrepaidServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC129100 TFS_TC_ID=13536.
        // Test Service Ledger Entries after running the Post Prepaid Service Contract Entries report.

        // 1.Setup: Creating a Service Contract, create Service Account Group Code, modify Service Contract,
        // sign Service Contract, post Service Invoice, create Contract Credit Memo and post Credit Memo.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoiceCreditMemo(ServiceContractHeader."Contract No.", ServiceHeader."Document Type"::Invoice);
        ServiceContractHeader.Find();
        ModifyServiceContract(ServiceContractHeader);

        CreateContractCreditMemo(ServiceContractHeader);
        PostServiceInvoiceCreditMemo(ServiceContractHeader."Contract No.", ServiceHeader."Document Type"::"Credit Memo");

        // 2.Exercise: Run the report for Post Prepaid Contract Entries.
        PostPrepaidContractEntry(ServiceContractHeader."Contract No.");

        // 3.Verify: Verify the Service Ledger Entries.
        VerifyPostPrepaidContractEntry(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContractTemplateListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateServiceContractDiscount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        DiscountPercent: Decimal;
    begin
        // Covers document number TC129103 TFS_TC_ID=13539.
        // Test Service Contract Quote Line Discount percent after running the Update Discount percent On Contract report.

        // 1.Setup: Creating a Service Contract Quote.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote);

        // 2.Exercise: Run the report for Updating the Line Discount Percent.
        DiscountPercent := UpdateDiscPercentOnContract(ServiceContractHeader."Contract No.");

        // 3.Verify: Verify the Service Contract Line Discount Percent.
        VerifyDiscountPercentContract(ServiceContractHeader, DiscountPercent);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContractTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerWithShipCode()
    begin
        // Covers document number TC129104 TFS_TC_ID=13541.
        // Test Change Customer with Ship to Code after running the Change Customer in Contract report.

        ChangeCustomer(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContractTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerWithoutShipCode()
    begin
        // Covers document number TC129104 TFS_TC_ID=13541.
        // Test Change Customer without Ship to Code after running the Change Customer in Contract report.

        ChangeCustomer(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContractTemplateListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPrepaidMultipleServiceContractsWithLastContractCreditMemo()
    var
        ServiceContractHeader: array[2] of Record "Service Contract Header";
        i: Integer;
        OldWorkDate: Date;
    begin
        // [SCENARIO 263758] Service Ledger Entries posts by batch job "Post Prepaid Service Contract Entries" with filter of multiple Service Contracts when last one has posted Credit Memo

        // [GIVEN] Two service contracts "A" and "B" with posted service invoices
        Initialize();
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<-CY>', WorkDate());
        for i := 1 to ArrayLen(ServiceContractHeader) do
            SignServiceContractAndPostInvoice(ServiceContractHeader[i]);

        // [GIVEN] Posted Credit Memo for service contract "B"
        SetWorkDateOnContractExpirationDateAndPostCrMemo(ServiceContractHeader[2]);

        // [WHEN] Run batch job "Post Prepaid Contract Entries" with filter "A|B"
        PostPrepaidMultipleContractEntries(ServiceContractHeader[1]."Contract No.", ServiceContractHeader[2]."Contract No.");

        // [THEN] One G/L Entry with "Non-Prepaid Contract Acc." created for contact "A" since balance of contract "B" is zero because of Credit Memo
        VerifyNonPrepaidGLEntry(ServiceContractHeader[1]."Contract No.", true);
        VerifyNonPrepaidGLEntry(ServiceContractHeader[2]."Contract No.", false);

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContractTemplateListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPrepaidMultipleServiceContractsWithCreditMemoForContractBeforeLast()
    var
        ServiceContractHeader: array[3] of Record "Service Contract Header";
        i: Integer;
        OldWorkDate: Date;
    begin
        // [SCENARIO 265239] Service Ledger Entries posts by batch job "Post Prepaid Service Contract Entries" with filter of multiple Service Contracts when there is posted Credit Memo for contract before last

        // [GIVEN] Three service contracts "A", "B" and "C" with posted service invoices
        Initialize();
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<-CY>', WorkDate());
        for i := 1 to ArrayLen(ServiceContractHeader) do
            SignServiceContractAndPostInvoice(ServiceContractHeader[i]);

        // [GIVEN] Posted Credit Memo for service contract "B"
        SetWorkDateOnContractExpirationDateAndPostCrMemo(ServiceContractHeader[2]);

        // [WHEN] Run batch job "Post Prepaid Contract Entries" with filter "A|C"
        PostPrepaidMultipleContractEntries(ServiceContractHeader[1]."Contract No.", ServiceContractHeader[3]."Contract No.");

        // [THEN] One G/L Entry with "Non-Prepaid Contract Acc." created for contacts "A" and "C" since balance of contract "B" is zero because of Credit Memo
        VerifyNonPrepaidGLEntry(ServiceContractHeader[1]."Contract No.", true);
        VerifyNonPrepaidGLEntry(ServiceContractHeader[2]."Contract No.", false);
        VerifyNonPrepaidGLEntry(ServiceContractHeader[3]."Contract No.", true);

        // Tear down
        WorkDate := OldWorkDate;
    end;

    local procedure ChangeCustomer(WithShiptoCode: Boolean)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ShipToAddress: Record "Ship-to Address";
        ShipToCode: Code[10];
    begin
        // 1.Setup: Creating a Service Contract and selecting a Ship To Address.
        Initialize();
        ShipToCode := '';
        CreateServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract);
        SelectShipToAddress(ShipToAddress);
        if WithShiptoCode then
            ShipToCode := ShipToAddress.Code;

        // 2.Exercise: Run the report for change the Customer and Ship To Code in Service Contract.
        UpdateCustomerInContract(ServiceContractHeader, ShipToAddress."Customer No.", ShipToCode);

        // 3.Verify: Verify the Customer and Ship To Code of Service Contract Header.
        VerifyChangeCustomer(ServiceContractHeader."Contract No.", ShipToAddress."Customer No.", ShipToCode);
    end;

    local procedure CreateAndPostServiceOrder(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create Customer, Service Header, Service Item Line, Service Line with Type Item and Post Service Order as Ship.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithItem(ServiceHeader, ServiceItemLine."Line No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure CreateCustomerInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));  // Use Random because value is not important.
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateContractCreditMemo(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        LibraryService.CreateContractLineCreditMemo(ServiceContractLine, false);
    end;

    local procedure CreateFaultResolCodesRlship(var FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship")
    var
        FaultArea: Record "Fault Area";
        ResolutionCode: Record "Resolution Code";
        SymptomCode: Record "Symptom Code";
        ServiceItemGroupCode: Record "Service Item Group";
        FaultCode: Record "Fault Code";
    begin
        // Finding Fault Area Code, Symptom Code, Resolution Code,Service Item Group Code and creating Fault Code.
        LibraryService.CreateFaultArea(FaultArea);
        LibraryService.CreateSymptomCode(SymptomCode);
        LibraryService.CreateResolutionCode(ResolutionCode);
        LibraryService.CreateServiceItemGroup(ServiceItemGroupCode);
        LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);
        LibraryService.CreateFaultResolCodesRlship(FaultResolCodRelationship, FaultCode, ResolutionCode.Code, ServiceItemGroupCode.Code);
    end;

    local procedure CreateInvoiceFromGetShipment(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceInvoiceSubform: Page "Service Invoice Subform";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        Clear(ServiceInvoiceSubform);
        ServiceInvoiceSubform.SetTableView(ServiceLine);
        ServiceInvoiceSubform.SetRecord(ServiceLine);
        ServiceInvoiceSubform.GetShipment();
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractType: Enum "Service Contract Type")
    var
        Customer: Record Customer;
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractType, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Use Random to update values in Line Value and Line Cost fields.
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(200));
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandInt(200));
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractWithAccGroup(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractType: Enum "Service Contract Type")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        Customer: Record Customer;
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceContractAccountGroup.Modify(true);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractType, Customer."No.");
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Use Random to update values in Line Value and Line Cost fields.
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(200));
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandInt(200));
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        // Service Header of Specified Document Type, Service Line with Type Item, Resource, Cost and G/L Account.
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Cost, SelectServiceCost());
        CreateServiceLine(ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        Commit();
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; LineType: Enum "Service Line Type"; No: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, LineType, No);
        ServiceLine.Validate("Allow Invoice Disc.", true);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Use Random because value is not important.
        ServiceLine.Validate("VAT %", 0);  // Use 0 to avoid VAT Calculation.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLines(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
        Counter: Integer;
    begin
        // To Create new Service Lines.
        LibraryInventory.CreateItem(Item);
        // Use Random to generate between 1 to 10 service lines.
        for Counter := 1 to 1 + LibraryRandom.RandInt(9) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
            ServiceLine.Validate("Service Item No.", ServiceItemNo);
            // Use Random for Quantity and Unit Price.
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
            ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(200));
            // For updating the field Qty. to Ship by 0.
            if Counter > 1 then
                ServiceLine.Validate("Qty. to Ship", 0);
            ServiceLine.Modify(true);
            Item.Next();
        end;
    end;

    local procedure CreateServiceLineWithItem(ServiceHeader: Record "Service Header"; ServiceItemLineLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // To Create a new Service Header, Service Item Line and Service Lines.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLines(ServiceLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure SignServiceContractAndPostInvoice(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        CreateServiceContractWithAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Find();
        PostServiceInvoice(ServiceContractHeader);
    end;

    local procedure CopyServiceLines(var TempServiceLine: Record "Service Line" temporary; var FromServiceLine: Record "Service Line")
    begin
        FromServiceLine.FindSet();
        repeat
            TempServiceLine := FromServiceLine;
            TempServiceLine.Insert();
        until FromServiceLine.Next() = 0;
    end;

    local procedure DeleteInvoiceServiceOrders(ServiceOrderNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        DeleteInvoicedServiceOrders: Report "Delete Invoiced Service Orders";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("No.", ServiceOrderNo);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        Clear(DeleteInvoicedServiceOrders);
        DeleteInvoicedServiceOrders.SetTableView(ServiceHeader);
        DeleteInvoicedServiceOrders.UseRequestPage(false);
        DeleteInvoicedServiceOrders.Run();
    end;

    local procedure DeleteServiceItemLogEntries(ServiceItemNo: Code[20])
    var
        ServiceItemLog: Record "Service Item Log";
        DeleteServiceItemLog: Report "Delete Service Item Log";
    begin
        ServiceItemLog.SetRange("Service Item No.", ServiceItemNo);
        ServiceItemLog.FindFirst();
        Clear(DeleteServiceItemLog);
        DeleteServiceItemLog.SetTableView(ServiceItemLog);
        DeleteServiceItemLog.UseRequestPage(false);
        DeleteServiceItemLog.Run();
    end;

    local procedure DeleteServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        ServiceLine.SetFilter("Line No.", '<> %1', ServiceLine."Line No.");
        ServiceLine.DeleteAll(true);
    end;

    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure FilterServiceCommentLine(var ServiceCommentLine: Record "Service Comment Line"; TableSubtype: Option; CommentText: Text[80])
    begin
        ServiceCommentLine.SetRange("No.", OrderNo);
        ServiceCommentLine.SetRange(Type, ServiceCommentLine.Type::General);
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("Table Subtype", TableSubtype);
        ServiceCommentLine.SetRange(Comment, CommentText);
    end;

    local procedure GetServiceLines(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure InsertFaultResolRelation(FromDate: Date; ToDate: Date; BasedOnServItemGr: Boolean; RetainManuallyInserted: Boolean)
    var
        InsertFaultResolRelations: Report "Insert Fault/Resol. Relations";
    begin
        Clear(InsertFaultResolRelations);
        InsertFaultResolRelations.InitializeRequest(FromDate, ToDate, BasedOnServItemGr, RetainManuallyInserted);
        InsertFaultResolRelations.UseRequestPage(false);
        InsertFaultResolRelations.Run();
    end;

    local procedure MockServiceHeaderWithCommentLine(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; CommentText: Text[80])
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := DocumentNo;
        ServiceHeader.Insert();

        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          DocumentType.AsInteger(), DocumentNo, ServiceCommentLine.Type::General, 0);
        ServiceCommentLine.Comment := CommentText;
        ServiceCommentLine.Modify();
    end;

    local procedure ModifyServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Find();
        ServiceContractHeader.Validate("Expiration Date", WorkDate());
        ServiceContractHeader.Modify(true);
        LockOpenServContract.LockServContract(ServiceContractHeader);
    end;

    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure PostServiceInvoiceCreditMemo(ContractNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindFirst();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
    end;

    local procedure PostPrepaidContractEntry(ContractNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        PostPrepaidContractServContractReport(ServiceLedgerEntry);
    end;

    local procedure PostPrepaidMultipleContractEntries(ContractNo: Code[20]; ContractNo2: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo, ContractNo2);
        PostPrepaidContractServContractReport(ServiceLedgerEntry);
    end;

    local procedure PostPrepaidContractServContractReport(var ServiceLedgerEntry: Record "Service Ledger Entry")
    var
        PostPrepaidContractEntries: Report "Post Prepaid Contract Entries";
        PostPrepaidContractAction: Option "Post Prepaid Transactions","Print Only";
    begin
        Clear(PostPrepaidContractEntries);
        PostPrepaidContractEntries.SetTableView(ServiceLedgerEntry);
        PostPrepaidContractEntries.InitializeRequest(WorkDate(), WorkDate(), PostPrepaidContractAction::"Post Prepaid Transactions");
        PostPrepaidContractEntries.UseRequestPage(false);
        PostPrepaidContractEntries.Run();
    end;

    local procedure PostServiceInvoice(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        PostServiceInvoiceCreditMemo(ServiceContractHeader."Contract No.", ServiceHeader."Document Type"::Invoice);
    end;

    local procedure PostServiceCrMemo(ServiceContractLine: Record "Service Contract Line")
    var
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, false);
        PostServiceInvoiceCreditMemo(ServiceContractLine."Contract No.", ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure RunDeleteInvoicedServiceOrders(DocumentNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        DeleteInvoicedServiceOrders: Report "Delete Invoiced Service Orders";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, DocumentNo);
        Clear(DeleteInvoicedServiceOrders);
        DeleteInvoicedServiceOrders.SetTableView(ServiceHeader);
        DeleteInvoicedServiceOrders.UseRequestPage(false);
        DeleteInvoicedServiceOrders.Run();
    end;

    local procedure SelectServiceCost(): Code[10]
    var
        ServiceCost: Record "Service Cost";
    begin
        ServiceCost.SetFilter("Account No.", '<>''''');
        ServiceCost.SetRange("Service Zone Code", '');
        ServiceCost.FindFirst();
        exit(ServiceCost.Code);
    end;

    local procedure SelectShipToAddress(var ShipToAddress: Record "Ship-to Address")
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, LibrarySales.CreateCustomerNo());
    end;

    local procedure SetWorkDateOnContractExpirationDateAndPostCrMemo(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        LibraryService.FindServiceContractLine(
          ServiceContractLine, ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractLine.Validate("Contract Expiration Date", WorkDate());
        ServiceContractLine.Modify(true);
        PostServiceCrMemo(ServiceContractLine);
    end;

    local procedure UpdateCustomerInContract(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; ShipToCode: Code[10])
    var
        ChangeCustomerInContract: Report "Change Customer in Contract";
    begin
        Clear(ChangeCustomerInContract);
        ChangeCustomerInContract.SetRecord(ServiceContractHeader."Contract No.");
        ChangeCustomerInContract.InitializeRequest(CustomerNo, ShipToCode);
        ChangeCustomerInContract.UseRequestPage(false);
        ChangeCustomerInContract.Run();
    end;

    local procedure UpdateDiscPercentOnContract(ContractNo: Code[20]) DiscountPercent: Decimal
    var
        ServiceContractLine: Record "Service Contract Line";
        UpdDiscPctOnContract: Report "Upd. Disc.% on Contract";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type"::Quote);
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindFirst();
        Clear(UpdDiscPctOnContract);
        UpdDiscPctOnContract.SetTableView(ServiceContractLine);
        UpdDiscPctOnContract.UseRequestPage(false);

        // Use Random for Discount percent.
        DiscountPercent := LibraryRandom.RandInt(100);
        UpdDiscPctOnContract.InitializeRequest(DiscountPercent);
        UpdDiscPctOnContract.Run();
    end;

    local procedure VerifyChangeCustomer(ContractNo: Code[20]; CustomerNo: Code[20]; ShipToCode: Code[10])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ContractNo);
        ServiceContractHeader.TestField("Customer No.", CustomerNo);
        ServiceContractHeader.TestField("Ship-to Code", ShipToCode);
    end;

    local procedure VerifyDiscountPercentContract(ServiceContractHeader: Record "Service Contract Header"; DiscountPercent: Decimal)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        ServiceContractLine.TestField("Line Discount %", DiscountPercent);
    end;

    local procedure VerifyServiceCommentLineExists(TableSubtype: Option; CommentText: Text[80])
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        FilterServiceCommentLine(ServiceCommentLine, TableSubtype, CommentText);
        Assert.RecordIsNotEmpty(ServiceCommentLine);
    end;

    local procedure VerifyServiceCommentLineNotExists(TableSubtype: Option; CommentText: Text[80])
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        FilterServiceCommentLine(ServiceCommentLine, TableSubtype, CommentText);
        Assert.RecordIsEmpty(ServiceCommentLine);
    end;

    local procedure VerifyServiceCreditMemoLine(var TempServiceLine: Record "Service Line" temporary; PreAssignedNo: Code[20]; Discount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        GeneralLedgerSetup.Get();
        TempServiceLine.FindSet();
        repeat
            ServiceCrMemoLine.Get(ServiceCrMemoHeader."No.", TempServiceLine."Line No.");
            ServiceCrMemoLine.TestField("No.", TempServiceLine."No.");
            Assert.AreNearlyEqual(
              TempServiceLine.Amount * Discount / 100,
              ServiceCrMemoLine."Inv. Discount Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)", '');
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceInvoiceLine(var TempServiceLine: Record "Service Line" temporary; PreAssignedNo: Code[20]; Discount: Decimal)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
        GeneralLedgerSetup.Get();
        TempServiceLine.FindSet();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", TempServiceLine."Line No.");
            ServiceInvoiceLine.TestField("No.", TempServiceLine."No.");
            Assert.AreNearlyEqual(
              TempServiceLine.Amount * Discount / 100,
              ServiceInvoiceLine."Inv. Discount Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)", '');
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceItemLog(ServiceItemNo: Code[20])
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        ServiceItemLog.SetRange("Service Item No.", ServiceItemNo);
        Assert.IsFalse(ServiceItemLog.FindFirst(), ServiceItemError);
    end;

    local procedure VerifyServiceLines(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();

        // Use 0 for Fully Ship and Invoice.
        ServiceLine.TestField("Qty. to Ship", 0);
        ServiceLine.TestField("Qty. to Invoice", 0);
        ServiceLine.TestField("Quantity Invoiced", ServiceLine.Quantity);
    end;

    local procedure VerifyPostPrepaidContractEntry(ContractNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Moved from Prepaid Acc.", false);
        ServiceLedgerEntry.SetRange(Open, false);
        Assert.IsFalse(ServiceLedgerEntry.FindFirst(), StrSubstNo(ServiceLedgerEntryError, ServiceLedgerEntry.TableCaption()))
    end;

    local procedure VerifyNonPrepaidGLEntry(ContractNo: Code[20]; Exists: Boolean)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        GLEntry: Record "G/L Entry";
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ContractNo);
        ServiceContractAccountGroup.Get(ServiceContractHeader."Serv. Contract Acc. Gr. Code");
        GLEntry.SetRange("G/L Account No.", ServiceContractAccountGroup."Non-Prepaid Contract Acc.");
        GLEntry.SetRange("External Document No.", ContractNo);
        Assert.AreEqual(Exists, not GLEntry.IsEmpty, '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerShipmentLine(var GetServiceShipmentLines: Page "Get Service Shipment Lines"; var Response: Action)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindFirst();

        GetServiceShipmentLines.SetRecord(ServiceShipmentLine);
        GetServiceShipmentLines.GetShipmentLines();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;
}

