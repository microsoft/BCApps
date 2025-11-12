// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;
using System.Utilities;
using System.TestLibraries.Utilities;

codeunit 136150 "Service Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        DoYouWantPostAndPrintTok: Label 'Do you want to post and print';
        ChangeCurrencyConfirmQst: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?';

    [Test]
    [HandlerFunctions('StrMenuHandler,ServiceShipmentReportHandler,ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderPostAndPrint()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Print] [Post] [Order]
        // [SCENARIO 268383] Stan does not see confirmation to close service order card page when document fully shiped and invoiced with printing documents
        Initialize();

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);

        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option

        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder."Post and &Print".Invoke(); // Post and Print

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostAndPrint()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceInvoice: TestPage "Service Invoices";
    begin
        // [FEATURE] [Print] [Post] [Invoice]
        // [SCENARIO 268383] Stan does not see confirmation to close Service Invoices card page when document fully invoiced with printing documents
        Initialize();

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        LibraryVariableStorage.Enqueue(DoYouWantPostAndPrintTok);
        LibraryVariableStorage.Enqueue(true);

        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice."Post and &Print".Invoke(); // Post and Print

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoPostAndPrint()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Print] [Post] [Credit Memo]
        // [SCENARIO 268383] Stan does not see confirmation to close service credit memo card page when document fully invoiced with printing documents
        Initialize();

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");

        LibraryVariableStorage.Enqueue(DoYouWantPostAndPrintTok);
        LibraryVariableStorage.Enqueue(true);

        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo."Post and &Print".Invoke(); // Post and Print

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithValidation')]
    [Scope('OnPrem')]
    procedure ServiceOrderChangeCurrency()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Order]
        // [SCENARIO 308004] Confirmation message to recreate service lines must appear when Stan clears "Currency Code" field on Service Order.
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(LibraryRandom.RandDate(-10), ExchangeRate, ExchangeRate);
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);

        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");

        SetCurrencyCodeOnOrderAndVerify(ServiceOrder, CurrencyCode);
        LibraryVariableStorage.AssertEmpty();

        SetCurrencyCodeOnOrderAndVerify(ServiceOrder, '');
        LibraryVariableStorage.AssertEmpty();

        ServiceOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteFromCustomerCard()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Ship-to Address] [UT]
        // [SCENARIO 387958] It is possible to create Service Quote from Customer's Card having Ship-to Code.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Quote);
        ServiceHeader."Customer No." := Customer."No.";
        ServiceHeader.Validate("Customer No.");
        ServiceHeader.Insert(true);

        ServiceHeader.TestField("No.");
        ServiceHeader.TestField("Ship-to Code", ShipToAddress.Code);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Service Order page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Order page
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceOrder.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Service Order page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Order page
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceOrder."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrdersCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrders: TestPage "Service Orders";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Service Orders page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Orders page
        ServiceOrders.OpenView();
        ServiceOrders.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceOrders.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrdersCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrders: TestPage "Service Orders";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Service Orders page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Orders page
        ServiceOrders.OpenView();
        ServiceOrders.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceOrders."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post on Service Invoice page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoice
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceInvoice.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Print on Service Invoice page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoice
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoice."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Send on Service Invoice page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoice
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoice.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoicesCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoices: TestPage "Service Invoices";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post on Service Invoices page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoices
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoices.OpenView();
        ServiceInvoices.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceInvoices."P&ost".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoicesCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoices: TestPage "Service Invoices";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Print on Service Invoices page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoices
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoices.OpenView();
        ServiceInvoices.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoices."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicesCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoices: TestPage "Service Invoices";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Send on Service Invoices page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoices
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoices.OpenView();
        ServiceInvoices.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoices.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post on Service Credit Memo page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memo
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Print on Service Credit Memo page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memo
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemo."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Send on Service Credit Memo page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memo
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemo.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemos: TestPage "Service Credit Memos";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post on Service Credit Memos page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memos
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceCreditMemos."P&ost".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemos: TestPage "Service Credit Memos";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Print on Service Credit Memos page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memos
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemos."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemos: TestPage "Service Credit Memos";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Send on Service Credit Memos page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memos
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemos.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    procedure ShipToAddressOnServiceInvoiceWhenSetCustomer()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Ship-to Code]
        // [SCENARIO 418143] Ship-to Address fields on Service Invoice page when Customer is set and Ship-to Code is not set.
        Initialize();

        // [GIVEN] Customer with Address and with Ship-to Address, these addresses has different field values.
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationOnCustomer(Customer, Location.Code);
        CreateShipToAddress(ShipToAddress, Customer."No.");

        // [WHEN] Create Service Invoice and set Customer for it. Open Service Invoice page.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] Ship-to Code is blank. Ship-to Address fields are set from Customer.
        VerifyShipToFieldsAreFromCustomer(ServiceInvoice, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromCustomerOnValidate()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Customer] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Service Document must be copied from Customer when the Customer has a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Salesperson Code
        CreateCustomerWithSalesperson(Customer);

        // [WHEN] Validate Cusotmer No. in new Service Document
        ServiceHeader.Validate("Customer No.", Customer."No.");
        ServiceHeader.Insert(true);

        // [THEN] Service Document Salesperson Code is equal to Customer Salesperson Code
        ServiceHeader.TestField("Salesperson Code", Customer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromShiptoCodeOnValidate()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Service Document must be copied from Ship-to Address when the Ship-to Address has a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Ship-to Address with Salesperson Code
        CreateCustomerWithSalesperson(Customer);
        CreateShiptoAddressWithSalesperson(ShipToAddress, Customer."No.");

        // [WHEN] Validate Ship-to Address with a Salesperson Code in new Service Document
        ServiceHeader.Validate("Customer No.", Customer."No.");
        ServiceHeader.Validate("Ship-to Code", ShipToAddress."Code");
        ServiceHeader.Insert(true);

        // [THEN] Service Document Salesperson Code is equal to Ship-to Address Salesperson Code
        ServiceHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromCustomerNoShiptoSalespersonOnValidate()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Service Document must be copied from Customer when the Ship-to Address does not have a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Ship-to Address without Salesperson Code
        CreateCustomerWithSalesperson(Customer);
        CreateShiptoAddressWithoutSalesperson(ShipToAddress, Customer."No.");

        // [WHEN] Validate Ship-to Address without a Salesperson Code in new Service Document
        ServiceHeader.Validate("Customer No.", Customer."No.");
        ServiceHeader.Validate("Ship-to Code", ShipToAddress."Code");
        ServiceHeader.Insert(true);

        // [THEN] Service Document Salesperson Code is equal to Customer Salesperson Code
        ServiceHeader.TestField("Salesperson Code", Customer."Salesperson Code");
    end;

    [Test]
    procedure ShipToAddressOnServiceInvoiceWhenSetShipToCode()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Ship-to Code]
        // [SCENARIO 418143] Ship-to Address fields on Service Invoice page when Ship-to Code is set.
        Initialize();

        // [GIVEN] Customer with Address and with Ship-to Address "A1", these addresses has different field values.
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationOnCustomer(Customer, Location.Code);
        CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Service Invoice with Customer. Opened Service Invoice page.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [WHEN] Set Ship-to Code to "A1".
        ServiceInvoice."Ship-to Code".SetValue(ShipToAddress.Code);

        // [THEN] Ship-to Code is "A1". Ship-to Address fields are set from Ship-to Address record.
        VerifyShipToFieldsAreFromShipToAddress(ServiceInvoice, ShipToAddress);
    end;

    [Test]
    procedure ShipToAddressOnServiceInvoiceWhenClearShipToCode()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Ship-to Code]
        // [SCENARIO 418143] Ship-to Address fields on Service Invoice page when Ship-to Code is set and then cleared.
        Initialize();

        // [GIVEN] Customer with Address and with Ship-to Address "A1", these addresses has different field values.
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationOnCustomer(Customer, Location.Code);
        CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Service Invoice with Customer and with Ship-to Code "A1". Opened Service Invoice page.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        UpdateShipToCodeOnServiceHeader(ServiceHeader, ShipToAddress.Code);
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [WHEN] Clear Ship-to Code.
        ServiceInvoice."Ship-to Code".SetValue('');

        // [THEN] Ship-to Code is blank. Ship-to Address fields are set from Customer.
        VerifyShipToFieldsAreFromCustomer(ServiceInvoice, Customer);
    end;

    [Test]
    [HandlerFunctions('SelectMultiItemsModalPageHandler,ConfirmHandlerYes')]
    procedure SelectMultiItemOnServiceInvoice()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Insert Multiple Items at once]
        // [SCENARIO 426270] Action "Select items" on Invoice subpage adds selected items
        Initialize();
        LibraryVariableStorage.Clear();

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Service Invoice and set Customer for it.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GoToRecord(ServiceHeader);

        // [WHEN] Call action Select Multi Items and select
        ServiceInvoice.ServLines.SelectMultiItems.Invoke();
        ServiceInvoice.Close();

        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);

        // [THEN] Item "X" is added to a Service Invoice
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        Assert.RecordCount(ServiceLine, 1);

        ServiceLine.FindFirst();
        ServiceLine.TestField("No.", ExpectedItemNo);
    end;

    [Test]
    [HandlerFunctions('SelectMultiServiceItemsModalPageHandler,ConfirmHandlerYes,SelectTemplate')]
    procedure SelectMultiItemOnServiceContract()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContract: TestPage "Service Contract";
        ExpectedItemNo: Code[20];
        CreatedServiceContractTemplate: Boolean;
    begin
        // [FEATURE] [Insert Multiple Service Items at once]
        // [SCENARIO 426270] Action "Select service items" on Service Contract subpage adds selected items
        Initialize();
        LibraryVariableStorage.Clear();

        // [GIVEN] Created Customer and several Service Items
        LibrarySales.CreateCustomer(Customer);
        GenerateServiceItemsForCustomer(Customer, LibraryRandom.RandIntInRange(5, 10));

        if ServiceContractTemplate.IsEmpty then begin
            CreateServiceContractTemplate(ServiceContractTemplate, '<3M>', ServiceContractTemplate."Invoice Period"::Month, true, true, false, true);
            CreatedServiceContractTemplate := true;
        end;

        // [GIVEN] Create Service Invoice and set Customer for it.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");

        // [GIVEN] Open Service Contract page
        ServiceContract.OpenEdit();
        ServiceContract.GoToRecord(ServiceContractHeader);

        // [WHEN] Call action Select Multi Items and select
        ServiceContract.ServContractLines.SelectMultiItems.Invoke();
        ServiceContract.Close();

        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);

        // [THEN] Item "X" is added to a Service Contract
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Assert.RecordCount(ServiceContractLine, 1);

        ServiceContractLine.FindFirst();
        ServiceContractLine.TestField("Service Item No.", ExpectedItemNo);

        if CreatedServiceContractTemplate then
            ServiceContractTemplate.Delete();
    end;

    local procedure GenerateServiceItemsForCustomer(var Customer: Record Customer; NoOfItems: Integer)
    var
        ServiceItem: Record "Service Item";
        i: Integer;
    begin
        for i := 1 to NoOfItems do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        end;
    end;

    local procedure CreateServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template"; ServicePeriodTxt: Text; InvoicePeriod: Option; CombineInvoices: Boolean; ContractLinesOnInvoice: Boolean; InvoiceAfterService: Boolean; IsPrepaid: Boolean)
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        DefaultServicePeriod: DateFormula;
    begin
        if ServiceContractAccountGroup.IsEmpty then
            LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);

        Evaluate(DefaultServicePeriod, ServicePeriodTxt);

        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        ServiceContractTemplate.Validate("Invoice Period", InvoicePeriod);
        ServiceContractTemplate.Validate(Prepaid, IsPrepaid);
        ServiceContractTemplate.Validate("Combine Invoices", CombineInvoices);
        ServiceContractTemplate.Validate("Contract Lines on Invoice", ContractLinesOnInvoice);
        ServiceContractTemplate.Validate("Invoice after Service", InvoiceAfterService);
        ServiceContractTemplate.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectTemplate(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Filter.SetFilter("VAT Prod. Posting Group", '<>''''');
        ItemList.Next();
        LibraryVariableStorage.Enqueue(ItemList."No.".Value);
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectMultiServiceItemsModalPageHandler(var ServiceItemList: TestPage "Service Item List")
    begin
        ServiceItemList.Next();
        LibraryVariableStorage.Enqueue(ServiceItemList."No.".Value);
        ServiceItemList.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Pages");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Pages");

        Commit();
        IsInitialized := true;

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryService.SetupServiceMgtNoSeries();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Pages");
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, DocumentType, CustomerNo);
    end;

    local procedure CreateCustomerWithEmptyReceivableAccount(var Customer: Record Customer)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Receivables Account" := '';
        CustomerPostingGroup.Modify();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", FindPaymentMethodWithBalanceAccount());
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateShipToAddress(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        PostCode: Record "Post Code";
        Location: Record Location;
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryWarehouse.CreateLocation(Location);

        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate(Address, LibraryUtility.GenerateGUID());
        ShipToAddress.Validate("Address 2", LibraryUtility.GenerateGUID());
        ShipToAddress.Validate("Location Code", Location.Code);
        ShipToAddress.Validate("Country/Region Code", PostCode."Country/Region Code");
        ShipToAddress.Validate(City, PostCode.City);
        ShipToAddress.Validate("Post Code", PostCode.Code);
        ShipToAddress.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        ShipToAddress.Modify(true);
    end;

    local procedure CreateCustomerWithSalesperson(var Customer: Record Customer)
    var
        Salesperson: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(Salesperson);
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer.Validate("Salesperson Code", Salesperson.Code);
        Customer.Modify(true);
    end;

    local procedure CreateShiptoAddressWithoutSalesperson(var ShiptoAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateShipToAddress(ShiptoAddress, CustomerNo);
        ShiptoAddress.Validate("Salesperson Code", '');
        ShiptoAddress.Modify(true);
    end;

    local procedure CreateShiptoAddressWithSalesperson(var ShiptoAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        Salesperson: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(Salesperson);
        LibrarySales.CreateShipToAddress(ShiptoAddress, CustomerNo);
        ShiptoAddress.Validate("Salesperson Code", Salesperson.Code);
        ShiptoAddress.Modify(true);
    end;

    local procedure FindPaymentMethodWithBalanceAccount(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter("Bal. Account No.", '<>''''');
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure UpdateLocationOnCustomer(var Customer: Record Customer; LocationCode: Code[10])
    begin
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
    end;

    local procedure UpdateShipToCodeOnServiceHeader(var ServiceHeader: Record "Service Header"; ShipToCode: Code[10])
    begin
        ServiceHeader.Validate("Ship-to Code", ShipToCode);
        ServiceHeader.Modify(true);
    end;

    local procedure SetCurrencyCodeOnOrderAndVerify(ServiceOrder: TestPage "Service Order"; CurrencyCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(ChangeCurrencyConfirmQst, ServiceHeader.FieldCaption("Currency Code")));
        LibraryVariableStorage.Enqueue(true);
        ServiceOrder."Currency Code".SetValue(CurrencyCode);
    end;

    local procedure VerifyRecievablesAccountError(Description: Text)
    var
        DummyCustomerPostingGroup: Record "Customer Posting Group";
    begin
        Assert.ExpectedMessage(DummyCustomerPostingGroup.FieldCaption("Receivables Account"), Description);
    end;

    local procedure VerifyShipToFieldsAreFromCustomer(var ServiceInvoice: TestPage "Service Invoice"; Customer: Record Customer)
    begin
        Assert.AreEqual('', ServiceInvoice."Ship-to Code".Value, '');
        Assert.AreEqual(Customer.Address, ServiceInvoice."Ship-to Address".Value, '');
        Assert.AreEqual(Customer."Address 2", ServiceInvoice."Ship-to Address 2".Value, '');
        Assert.AreEqual(Customer."Post Code", ServiceInvoice."Ship-to Post Code".Value, '');
        Assert.AreEqual(Customer.City, ServiceInvoice."Ship-to City".Value, '');
        Assert.AreEqual(Customer."Country/Region Code", ServiceInvoice."Ship-to Country/Region Code".Value, '');
        Assert.AreEqual(Customer."Location Code", ServiceInvoice."Location Code".Value, '');
        Assert.AreEqual(Customer."Phone No.", ServiceInvoice."Ship-to Phone".Value, ServiceInvoice."Ship-to Phone".Caption());
    end;

    local procedure VerifyShipToFieldsAreFromShipToAddress(var ServiceInvoice: TestPage "Service Invoice"; ShipToAddress: Record "Ship-to Address")
    begin
        Assert.AreEqual(ShipToAddress.Code, ServiceInvoice."Ship-to Code".Value, '');
        Assert.AreEqual(ShipToAddress.Address, ServiceInvoice."Ship-to Address".Value, '');
        Assert.AreEqual(ShipToAddress."Address 2", ServiceInvoice."Ship-to Address 2".Value, '');
        Assert.AreEqual(ShipToAddress."Post Code", ServiceInvoice."Ship-to Post Code".Value, '');
        Assert.AreEqual(ShipToAddress.City, ServiceInvoice."Ship-to City".Value, '');
        Assert.AreEqual(ShipToAddress."Country/Region Code", ServiceInvoice."Ship-to Country/Region Code".Value, '');
        Assert.AreEqual(ShipToAddress."Location Code", ServiceInvoice."Location Code".Value, '');
        Assert.AreEqual(ShipToAddress."Phone No.", ServiceInvoice."Ship-to Phone".Value, ServiceInvoice."Ship-to Phone".Caption());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceShipmentReportHandler(var ServiceShipment: Report "Service - Shipment")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportHandler(var ServiceInvoice: Report "Service - Invoice")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoReportHandler(var ServiceCreditMemo: Report "Service - Credit Memo")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithValidation(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationModalPageHandler(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes().Invoke();
    end;
}
