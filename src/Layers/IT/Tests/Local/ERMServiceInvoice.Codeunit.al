codeunit 144130 "ERM Service Invoice"
{
    // 1. Test to verify field Bank Account is available on Service Invoice window.
    // 2. Test to verify field Cumulative Bank Receipts is available on Service Invoice window.
    // 3. Test to verify that service invoice is posted successfully with Bank Account and Cumulative Bank Receipts.
    // 4. Test to verify that service invoice is posted successfully with Bank Account and Cumulative Bank Receipts as FALSE.
    // 5. Test to verify that service invoice is posted successfully without Bank Account and Cumulative Bank Receipts as TRUE.
    // 6. Test to verify that service invoice is posted successfully without Bank Account and Cumulative Bank Receipts as FALSE.
    // 
    // Covers Test Cases for WI - 345269
    // --------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                               TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------------
    // BankAccountFieldOnServiceInvoice,CumulativeBankReceiptsFieldOnServiceInvoice                                     202749,202750
    // PostedServiceInvWithCumulativeBankRcptsTrue                                                                      202751,202755
    // PostedServiceInvWithCumulativeBankRcptsFalse                                                                     202754,202756
    // PostedServiceInvWithCumulativeBankRcptsAndBlankBankAcc                                                            202752,202758
    // PostedServiceInvWithoutCumulativeBankRcptsAndBankAcc                                                           202753,202757,202759

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountFieldOnServiceInvoice()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // Test to verify field Bank Account is available on Service Invoice window.
        // Setup.
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CreateCustomer());

        // Exercise & Verify.
        ServiceInvoiceWithLocalizedFields(CustomerBankAccount."Customer No.", CustomerBankAccount.Code, false);  // Using FALSE for Cumulative Bank Receipts.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CumulativeBankReceiptsFieldOnServiceInvoice()
    begin
        // Test to verify field Cumulative Bank Receipts is available on Service Invoice window.
        // Exercise & Verify.
        ServiceInvoiceWithLocalizedFields(CreateCustomer(), '', true);  // Using blank for Bank Account and TRUE for Cumulative Bank Receipts.
    end;

    local procedure ServiceInvoiceWithLocalizedFields(CustomerNo: Code[20]; BankAccount: Code[20]; CumulativeBankReceipts: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Exercise.
        CreateServiceDocument(ServiceHeader, CustomerNo, BankAccount, CumulativeBankReceipts);

        // Verify: Verify values on Service Invoice page.
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        ServiceInvoice.OpenView();
        ServiceInvoice.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceInvoice."Bank Account".AssertEquals(UpperCase(BankAccount));
        ServiceInvoice."Cumulative Bank Receipts".AssertEquals(CumulativeBankReceipts);
        ServiceInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvWithCumulativeBankRcptsTrue()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // Test to verify that service invoice is posted successfully with Bank Account and Cumulative Bank Receipts.
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CreateCustomer());
        CreateAndPostServInvWithBankAccAndCumulativeBankRcpts(CustomerBankAccount."Customer No.", CustomerBankAccount.Code, true);  // Using TRUE for Cumulative Bank Receipts.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvWithCumulativeBankRcptsFalse()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // Test to verify that service invoice is posted successfully with Bank Account and Cumulative Bank Receipts as FALSE.
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CreateCustomer());
        CreateAndPostServInvWithBankAccAndCumulativeBankRcpts(CustomerBankAccount."Customer No.", CustomerBankAccount.Code, false);  // Using FALSE for Cumulative Bank Receipts.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvWithCumulativeBankRcptsAndBlankBankAcc()
    begin
        // Test to verify if service invoice is posted successfully without Bank Account and Cumulative Bank Receipts as TRUE.
        CreateAndPostServInvWithBankAccAndCumulativeBankRcpts(CreateCustomer(), '', true);  // Using blank for Bank Account and TRUE for Cumulative Bank Receipts.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvWithoutCumulativeBankRcptsAndBankAcc()
    begin
        // Test to verify if service invoice is posted successfully without Bank Account and Cumulative Bank Receipts as FALSE.
        CreateAndPostServInvWithBankAccAndCumulativeBankRcpts(CreateCustomer(), '', false);  // Using blank for Bank Account and FALSE for Cumulative Bank Receipts.
    end;

    local procedure CreateAndPostServInvWithBankAccAndCumulativeBankRcpts(CustomerNo: Code[20]; BankAccount: Code[20]; CumulativeBankReceipts: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // Setup.
        CreateServiceDocument(ServiceHeader, CustomerNo, BankAccount, CumulativeBankReceipts);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.

        // Verify: Verify Bank Account and Cumulative Bank Receipts on Posted Service Invoice.
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Bank Account", BankAccount);
        ServiceInvoiceHeader.TestField("Cumulative Bank Receipts", CumulativeBankReceipts);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; BankAccount: Code[20]; CumulativeBankReceipts: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader.Validate("Bank Account", BankAccount);
        ServiceHeader.Validate("Cumulative Bank Receipts", CumulativeBankReceipts);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        ServiceLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Bill-to Customer No.", Customer."No.");
        Customer.Modify(true);
        exit(Customer."No.");
    end;
}

