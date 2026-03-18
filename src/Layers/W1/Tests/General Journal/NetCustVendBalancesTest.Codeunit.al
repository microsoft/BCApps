codeunit 134933 "Net Cust/Vend Balances Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Net Cust/Vend Balances]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        DescriptionMsg: Label 'Net customer/vendor balances %1 %2', Comment = '%1 %2';
        DocNoMustContainNumberErr: Label 'Document No. must contain a number.';
        PostingDateErr: Label 'Please enter the Posting Date.';
        DocumentNoErr: Label 'Please enter the Document No.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        AmountShouldBeEqualErr: Label 'Amount should be equal.';
        DuplicateLineExistsErr: Label 'There is the duplicate journal line in journal template name %2, journal batch name %3, document number %1 applied to %4 %5.',
            Comment = '%1 - document no., %2 - template name, %3 - batch name, %4 - document type, %5 - document no.';

    [Test]
    procedure T001_GetLinkedVendorCustomer()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        // [FEATURE] [UT]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        // [WHEN] run GetLinkedVendor() returns 'V', 
        Assert.AreEqual(Vendor."No.", Customer.GetLinkedVendor(), 'GetLinkedVendor');
        // [WHEN] run GetLinkedCustomer() returns 'C', 
        Assert.AreEqual(Customer."No.", Vendor.GetLinkedCustomer(), 'GetLinkedCustomer');
    end;

    [Test]
    procedure T003_DrillDownBalanceAsVendor()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustomerCard: TestPage "Customer Card";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        InvNo: Code[20];
    begin
        // [FEATURE] [Customer] [UI]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        // [GIVEN] Purchase Invoice 'I' posted for Vendor 'V' for amount 1000
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VendorLedgerEntry.SetRange("Document No.", InvNo);
        VendorLedgerEntry.FindLast();
        // [WHEN] Open customer card for 'C'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer."No.");
        // [THEN] "Balance As Vendor" is 1000, enabled
        Vendor.CalcFields("Balance (LCY)");
        Assert.AreEqual(Vendor."Balance (LCY)", CustomerCard.BalanceAsVendor.AsDecimal(), 'BalanceAsVendor');
        Assert.IsTrue(CustomerCard.BalanceAsVendor.Enabled(), 'BalanceAsVendor.Enabled');
        // [WHEN] drill down "Balance As Vendor"
        VendorLedgerEntries.Trap();
        CustomerCard.BalanceAsVendor.Drilldown();
        // [THEN] shown Vendor Ledger Entry for Invoice 'I'
        Assert.AreEqual(InvNo, VendorLedgerEntries."Document No.".Value(), 'VLE - Document No.');
        Assert.AreEqual(Vendor."No.", VendorLedgerEntries."Vendor No.".Value(), 'VLE - Vendor');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T004_DrillDownBalanceAsCustomer()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorCard: TestPage "Vendor Card";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        InvNo: Code[20];
    begin
        // [FEATURE] [Vendor] [UI]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        // [GIVEN] Sales Invoice 'I' posted for Customer 'C' for amount 1000
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CustLedgerEntry.SetRange("Document No.", InvNo);
        CustLedgerEntry.FindLast();
        // [WHEN] Open vendor card for 'V'
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");
        // [THEN] "Balance As Customer" is 1000, enabled
        Customer.CalcFields("Balance (LCY)");
        Assert.AreEqual(Customer."Balance (LCY)", VendorCard.BalanceAsCustomer.AsDecimal(), 'BalanceAsCustomer');
        Assert.IsTrue(VendorCard.BalanceAsCustomer.Enabled(), 'BalanceAsCustomer.Enabled');
        // [WHEN] drill down "Balance As Customer"
        CustomerLedgerEntries.Trap();
        VendorCard.BalanceAsCustomer.Drilldown();
        // [THEN] shown Cust. Ledger Entry for Invoice 'I'
        Assert.AreEqual(InvNo, CustomerLedgerEntries."Document No.".Value(), 'CLE - Document No.');
        Assert.AreEqual(Customer."No.", CustomerLedgerEntries."Customer No.".Value(), 'CLE - Customer');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T005_DrillDownBalanceAsVendorStatsFactBox()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustomerList: TestPage "Customer List";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        InvNo: Code[20];
    begin
        // [FEATURE] [Customer] [UI]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        // [GIVEN] Purchase Invoice 'I' posted for Vendor 'V' for amount 1000
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VendorLedgerEntry.SetRange("Document No.", InvNo);
        VendorLedgerEntry.FindLast();
        // [WHEN] Open customer card for 'C'
        CustomerList.OpenEdit();
        CustomerList.Filter.SetFilter("No.", Customer."No.");
        // [THEN] "Balance As Vendor" is 1000, enabled
        Vendor.CalcFields("Balance (LCY)");
        Assert.AreEqual(Vendor."Balance (LCY)", CustomerList.CustomerStatisticsFactBox.BalanceAsVendor.AsDecimal(), 'BalanceAsVendor');
        Assert.IsTrue(CustomerList.CustomerStatisticsFactBox.BalanceAsVendor.Enabled(), 'BalanceAsVendor.Enabled');
        // [WHEN] drill down "Balance As Vendor"
        VendorLedgerEntries.Trap();
        CustomerList.CustomerStatisticsFactBox.BalanceAsVendor.Drilldown();
        // [THEN] shown Vendor Ledger Entry for Invoice 'I'
        Assert.AreEqual(InvNo, VendorLedgerEntries."Document No.".Value(), 'VLE - Document No.');
        Assert.AreEqual(Vendor."No.", VendorLedgerEntries."Vendor No.".Value(), 'VLE - Vendor');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T006_DrillDownBalanceAsCustomerStatsFactBox()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorList: TestPage "Vendor List";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        InvNo: Code[20];
    begin
        // [FEATURE] [Vendor] [UI]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        // [GIVEN] Sales Invoice 'I' posted for Customer 'C' for amount 1000
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CustLedgerEntry.SetRange("Document No.", InvNo);
        CustLedgerEntry.FindLast();
        // [WHEN] Open vendor card for 'V'
        VendorList.OpenEdit();
        VendorList.Filter.SetFilter("No.", Vendor."No.");
        // [THEN] "Balance As Customer" is 1000, enabled
        Customer.CalcFields("Balance (LCY)");
        Assert.AreEqual(Customer."Balance (LCY)", VendorList.VendorStatisticsFactBox.BalanceAsCustomer.AsDecimal(), 'BalanceAsCustomer');
        Assert.IsTrue(VendorList.VendorStatisticsFactBox.BalanceAsCustomer.Enabled(), 'BalanceAsCustomer.Enabled');
        // [WHEN] drill down "Balance As Customer"
        CustomerLedgerEntries.Trap();
        VendorList.VendorStatisticsFactBox.BalanceAsCustomer.Drilldown();
        // [THEN] shown Cust. Ledger Entry for Invoice 'I'
        Assert.AreEqual(InvNo, CustomerLedgerEntries."Document No.".Value(), 'CLE - Document No.');
        Assert.AreEqual(Customer."No.", CustomerLedgerEntries."Customer No.".Value(), 'CLE - Customer');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T010_NetBalancesParametersDocumentNoValidation()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] "Document No." must contain a number to be increased.
        Initialize();
        NetBalancesParameters.Validate("Document No.", 'X1');
        NetBalancesParameters.TestField("Document No.", 'X1');

        asserterror NetBalancesParameters.Validate("Document No.", 'X');
        Assert.ExpectedError(DocNoMustContainNumberErr);
    end;

    [Test]
    procedure T011_NetBalancesParametersInitialize()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Initialize() fills Description and "Posting Date".
        Initialize();
        NetBalancesParameters.Initialize();
        NetBalancesParameters.TestField("Posting Date", WorkDate());
        NetBalancesParameters.TestField(Description, DescriptionMsg);
        NetBalancesParameters.TestField("Document No.", '');
    end;

    [Test]
    procedure T012_NetBalancesParametersVerifyDocumentNo()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] "Document No." must be filled.
        Initialize();
        NetBalancesParameters.Validate("Posting Date", Today());
        asserterror NetBalancesParameters.Verify();

        Assert.ExpectedError(DocumentNoErr);
    end;

    [Test]
    procedure T013_NetBalancesParametersVerifyPostingDate()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] "Posting Date" must be filled.
        Initialize();
        NetBalancesParameters.Validate("Document No.", 'X1');
        asserterror NetBalancesParameters.Verify();

        Assert.ExpectedError(PostingDateErr);
    end;

    [Test]
    [HandlerFunctions('NetCustomerVendorBalancesModalHandler')]
    procedure T020_RunNetCustomerVendorBalancesFromPaymentJournal()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [UI]
        Initialize();
        // [GIVEN] Payment Journal page
        KeepOnePaymentTemplate();
        PaymentJournal.OpenEdit();
        // [WHEN] run "Net Customer/Vendor Balances" action
        PaymentJournal.NetCustomerVendorBalances.Invoke();
        // [THEN] modal request page is open, where "Posting Date", "Document No." ...
        Assert.AreEqual(WorkDate(), LibraryVariableStorage.DequeueDate(), 'Posting Date');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Document No.');
        Assert.AreEqual(DescriptionMsg, LibraryVariableStorage.DequeueText(), 'Description');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'Order of suggestion');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'On Hold');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Vendor.GetFilter("No.")');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T021_VendorInvoiceBiggerThanCustomerInvoice()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
    begin
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000
        CompAmount := 1000;
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 2000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -2 * CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V' with "On Hold" 'ABC'
        Vendor.SetRecFilter();
        NetBalancesParameters."On Hold" := 'ABC';
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines with "On Hold" 'ABC':
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -1000
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField(Amount, -CompAmount);
    end;


    [Test]
    procedure T022_VendorInvoiceSmallerThanCustomerInvoice()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
    begin
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 900;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount + 100);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 900
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 900
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -900
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField(Amount, -CompAmount);
    end;

    [Test]
    procedure T023_VendorInvoiceEqualToCustomerInvoice()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
    begin
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -1000
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField(Amount, -CompAmount);
    end;

    [Test]
    procedure T024_2VendorInvoicesToCustomerInvoice()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: array[2] of Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
    begin
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Purchase Invoice 'PI#1' posted for Vendor 'V' for amount 600
        PurchInvNo[1] := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI#2' posted for Vendor 'V' for amount 600
        PurchInvNo[2] := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -0.6 * CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 3 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 3);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI#1', Amount is 600
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo[1]);
        GenJournalLine.TestField(Amount, 0.6 * CompAmount);
        // [THEN] 2nd line, where Account is Vendor, applied to Purch. Invoice 'PI#2', Amount is 400
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo[2]);
        GenJournalLine.TestField(Amount, 0.4 * CompAmount);
        // [THEN] 3rd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -1000
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField(Amount, -CompAmount);
    end;

    [Test]
    procedure T025_VendorInvoiceTo2CustomerInvoices()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        CompAmount: Decimal;
    begin
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI#1' posted for Customer 'C' for amount 600
        SalesInvNo[1] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        // [GIVEN] Sales Invoice 'SI#2' posted for Customer 'C' for amount 600
        SalesInvNo[2] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 3 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 3);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI#1', Amount is -600
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[1]);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
        // [THEN] 3rd line, where Account is Customer, applied to Sales Invoice 'SI#2', Amount is -400
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[2]);
        GenJournalLine.TestField(Amount, -0.4 * CompAmount);
    end;

    [Test]
    procedure T026_VendorInvoiceToCustomerInvoiceAndFinChargeOrderByFinCharge()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        CompAmount: Decimal;
    begin
        // [FEATURE] [Net Cust/Vend Balances Order]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 600
        SalesInvNo[1] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        // [GIVEN] Sales Finance Charge Memo 'FC' posted for Customer 'C' for amount 600
        SalesInvNo[2] :=
            PostDoc(
                WorkDate(), "Gen. Journal Document Type"::"Finance Charge Memo",
                "Gen. Journal Account Type"::Customer, Customer."No.", '', 0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        NetBalancesParameters."Order of Suggestion" := "Net Cust/Vend Balances Order"::"Fin. Ch. Memo First";
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 3 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 3);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Fin. Charge Memo 'FC', Amount is -600
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[2]);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
        // [THEN] 3rd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -400
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[1]);
        GenJournalLine.TestField(Amount, -0.4 * CompAmount);
    end;

    [Test]
    procedure T027_VendorInvoiceToCustomerInvoiceAndFinChargeOrderByInvoice()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        CompAmount: Decimal;
    begin
        // [FEATURE] [Net Cust/Vend Balances Order]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Finance Charge Memo 'FC' posted for Customer 'C' for amount 600
        SalesInvNo[1] :=
            PostDoc(
                WorkDate(), "Gen. Journal Document Type"::"Finance Charge Memo",
                "Gen. Journal Account Type"::Customer, Customer."No.", '', 0.6 * CompAmount);
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 600
        SalesInvNo[2] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        NetBalancesParameters."Order of Suggestion" := "Net Cust/Vend Balances Order"::"Invoices First";
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 3 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 3);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -600
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[2]);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
        // [THEN] 3rd line, where Account is Customer, applied to Sales Fin. Charge Memo 'FC', Amount is -400
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[1]);
        GenJournalLine.TestField(Amount, -0.4 * CompAmount);
    end;

    [Test]
    procedure T028_VendorInvoiceToCustomerInvoiceAndFinChargeOrderByEntryNo()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        CompAmount: Decimal;
    begin
        // [FEATURE] [Net Cust/Vend Balances Order]
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 600
        SalesInvNo[1] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        // [GIVEN] Sales Finance Charge Memo 'FC' posted for Customer 'C' for amount 600
        SalesInvNo[2] :=
            PostDoc(
                WorkDate(), "Gen. Journal Document Type"::"Finance Charge Memo",
                "Gen. Journal Account Type"::Customer, Customer."No.", '', 0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V', order "By Entry No."
        Vendor.SetRecFilter();
        NetBalancesParameters."Order of Suggestion" := "Net Cust/Vend Balances Order"::"By Entry No.";
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 3 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 3);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -600
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[1]);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
        // [THEN] 3rd line, where Account is Customer, applied to Sales Fin. Charge Memo 'FC', Amount is -400
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[2]);
        GenJournalLine.TestField(Amount, -0.4 * CompAmount);
    end;

    [Test]
    procedure T029_VendorInvoiceTo2CustomerInvoices1OnHold()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        CompAmount: Decimal;
    begin
        // [SCENARIO] One of open invoices has an "On Hold" value, so should be skipped
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI#1' posted for Customer 'C' for amount 600
        SalesInvNo[1] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        // [GIVEN] Sales Invoice 'SI#2' posted for Customer 'C' for amount 600, "On Hold" is 'ABC'
        SalesInvNo[2] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", 0.6 * CompAmount);
        CustLedgerEntry.SetRange("Document No.", SalesInvNo[2]);
        CustLedgerEntry.ModifyAll("On Hold", 'ABC');
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V', "On Hold" is 'NET'
        Vendor.SetRecFilter();
        NetBalancesParameters."On Hold" := 'NET';
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 600
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField(Amount, 0.6 * CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI#1', Amount is -600
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[1]);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
        // [THEN] Sales Invoice 'SI#2' is not applied, "On Hold" is still 'ABC'
        CustLedgerEntry.FindLast();
        CustLedgerEntry.TestField("On Hold", 'ABC');
    end;

    [Test]
    procedure T030_VendorInvoiceFCYToCustomerInvoiceLCY()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();
        // [GIVEN] Currency 'USD'
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000 USD
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", CurrencyCode, -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 0 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 0);
    end;

    [Test]
    procedure T031_VendorInvoiceFCYToCustomerInvoiceFCY()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();
        // [GIVEN] Currency 'USD'
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000 USD
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CurrencyCode, CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000 USD
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", CurrencyCode, -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V' with "On Hold" 'ABC'
        Vendor.SetRecFilter();
        NetBalancesParameters."On Hold" := 'ABC';
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines with "On Hold" 'ABC':
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000 USD
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField("Currency Code", CurrencyCode);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -1000 USD
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField("Currency Code", CurrencyCode);
        GenJournalLine.TestField(Amount, -CompAmount);
    end;

    [Test]
    procedure T032_VendorInvoiceLCYFCYToCustomerInvoicesFCYLCY()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: array[2] of Code[20];
        SalesInvNo: array[2] of Code[20];
        CompAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();
        // [GIVEN] Currency 'USD'
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI#1' posted for Customer 'C' for amount 1000
        SalesInvNo[1] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Sales Invoice 'SI#2' posted for Customer 'C' for amount 600 USD
        SalesInvNo[2] := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CurrencyCode, 0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI#1' posted for Vendor 'V' for amount 1000 USD
        PurchInvNo[1] := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", CurrencyCode, -CompAmount);
        // [GIVEN] Purchase Invoice 'PI#2' posted for Vendor 'V' for amount 400
        PurchInvNo[2] := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -0.4 * CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 3 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 4);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI#2', Amount is 400
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo[2]);
        GenJournalLine.TestField(Amount, 0.4 * CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI#1', Amount is -400
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[1]);
        GenJournalLine.TestField(Amount, -0.4 * CompAmount);
        // [THEN] 3rd line, where Account is Vendor, applied to Purch. Invoice 'PI#1', Amount is 600 USD
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo[1]);
        GenJournalLine.TestField(Amount, 0.6 * CompAmount);
        // [THEN] 4th line, where Account is Customer, applied to Sales Invoice 'SI#2', Amount is -600 USD
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo[2]);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
    end;

    [Test]
    procedure T033_VendorInvoiceFCYToCustomerInvoiceFCYOnDiffDates()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();
        // [GIVEN] Currency 'USD'
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        AddExchRate(CurrencyCode, WorkDate() - 2, 1.1);
        AddExchRate(CurrencyCode, WorkDate() - 1, 0.95);
        AddExchRate(CurrencyCode, WorkDate(), 1.03);

        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000 USD, on 09/01
        SalesInvNo := PostInvoice(WorkDate() - 2, "Gen. Journal Account Type"::Customer, Customer."No.", CurrencyCode, CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000 USD, on 10/01
        PurchInvNo := PostInvoice(WorkDate() - 1, "Gen. Journal Account Type"::Vendor, Vendor."No.", CurrencyCode, -CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V' on 11/01
        Vendor.SetRecFilter();
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI', Amount is 1000 USD
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.TestField("Currency Code", CurrencyCode);
        GenJournalLine.TestField(Amount, CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -1000 USD
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField("Currency Code", CurrencyCode);
        GenJournalLine.TestField(Amount, -CompAmount);
        // [WHEN] Post journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] Customer and Vendor ledger entries are closed.
        CustLedgerEntry.SetRange("Document No.", SalesInvNo);
        CustLedgerEntry.FindLast();
        CustLedgerEntry.TestField(Open, false);
        VendorLedgerEntry.SetRange("Document No.", PurchInvNo);
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.TestField(Open, false);
    end;

    [Test]
    procedure T035_2VendorInvoicesDiffPostingDatesToCustomerInvoice()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: array[2] of Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
    begin
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000 on 8/01
        SalesInvNo := PostInvoice(WorkDate() - 2, "Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Purchase Invoice 'PI#1' posted for Vendor 'V' for amount 600 on 10/01
        PurchInvNo[1] := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -0.6 * CompAmount);
        // [GIVEN] Purchase Invoice 'PI#2' posted for Vendor 'V' for amount 600 on 9/01
        PurchInvNo[2] := PostInvoice(WorkDate() - 1, "Gen. Journal Account Type"::Vendor, Vendor."No.", -0.6 * CompAmount);

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V' on 9/01
        Vendor.SetRecFilter();
        NetBalancesParameters.Validate("Posting Date", WorkDate() - 1);
        RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] 2 Journal lines:
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.SetRange("Posting Date", WorkDate() - 1);
        GenJournalLine.SetRange("On Hold", NetBalancesParameters."On Hold");
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] 1st line, where Account is Vendor, applied to Purch. Invoice 'PI#2', Amount is 600 on 9/01
        GenJournalLine.FindSet();
        GenJournalLine.TestField("Account No.", Vendor."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", PurchInvNo[2]);
        GenJournalLine.TestField(Amount, 0.6 * CompAmount);
        // [THEN] 2nd line, where Account is Customer, applied to Sales Invoice 'SI', Amount is -600 on 9/01
        GenJournalLine.Next();
        GenJournalLine.TestField("Account No.", Customer."No.");
        GenJournalLine.TestField("Applies-to Doc. No.", SalesInvNo);
        GenJournalLine.TestField(Amount, -0.6 * CompAmount);
    end;

    [Test]
    procedure T040_DuplicateJournalLineStopsNetting()
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvNo: Code[20];
        SalesInvNo: Code[20];
        CompAmount: Decimal;
    begin
        // [SCENARIO] Existing journal line applied to athe same document stops the process with an error.
        Initialize();
        // [GIVEN] Customer 'C' linked with Vendor 'V' 
        CreateLinkedCustomerVendor(Customer, Vendor);
        CompAmount := 1000;
        // [GIVEN] Sales Invoice 'SI' posted for Customer 'C' for amount 1000
        SalesInvNo := PostInvoice("Gen. Journal Account Type"::Customer, Customer."No.", CompAmount);
        // [GIVEN] Purchase Invoice 'PI' posted for Vendor 'V' for amount 1000
        PurchInvNo := PostInvoice("Gen. Journal Account Type"::Vendor, Vendor."No.", -CompAmount);
        // [GIVEN] Journal line, where Account is Vendor 'V', applied to Purch. Invoice 'PI'
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine."Line No." := 10;
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Account No.", Vendor."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine."Applies-to Doc. No." := PurchInvNo;
        GenJournalLine.Insert();

        // [WHEN] Run "Net Customer/Vendor Balances" for Vendor 'V'
        Vendor.SetRecFilter();
        asserterror RunNetCustVendBalances(Vendor, NetBalancesParameters);
        // [THEN] Error message: "Duplicate journal line applied to .. already exists"
        Assert.ExpectedError(
            StrSubstNo(
                DuplicateLineExistsErr,
                GenJournalLine."Document No.", GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
                GenJournalLine."Applies-to Doc. Type", GenJournalLine."Applies-to Doc. No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T041_StopOnHoldModificationOnVendLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] "On Hold" will not be changed without confirmation.
        Initialize();
        // [GIVEN] Vendor Ledger Entry Invoice 'VI' for Vendor 'V', "On Hold" is 'NET'
        VendorLedgerEntry."Vendor No." := 'V';
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := 'VI';
        VendorLedgerEntry."On Hold" := 'NET';

        //[GIVEN] Journal line for Vendor 'V', applied to Invoice 'VI', "On Hold" is 'NET'
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := LibraryRandom.RandText(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := VendorLedgerEntry."Vendor No.";
        GenJournalLine."Applies-to Doc. Type" := VendorLedgerEntry."Document Type";
        GenJournalLine."Applies-to Doc. No." := VendorLedgerEntry."Document No.";
        GenJournalLine."On Hold" := VendorLedgerEntry."On Hold";
        GenJournalLine.Insert();

        // [WHEN] Blank "On Hold" on Vendor Ledger Entry, don't confirm
        asserterror VendorLedgerEntry.Validate("On Hold", '');

        // [THEN] Silent error, "On Hold" is not changed
        Assert.ExpectedError('');
        VendorLedgerEntry.TestField("On Hold", 'NET');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T042_ConfirmOnHoldModificationOnVendLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] "On Hold" will be changed with confirmation.
        Initialize();
        // [GIVEN] Vendor Ledger Entry Invoice 'VI' for Vendor 'V', "On Hold" is 'NET'
        VendorLedgerEntry."Vendor No." := 'V';
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := 'VI';
        VendorLedgerEntry."On Hold" := 'NET';

        //[GIVEN] Journal line for Vendor 'V', applied to Invoice 'VI', "On Hold" is 'NET'
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := LibraryRandom.RandText(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := VendorLedgerEntry."Vendor No.";
        GenJournalLine."Applies-to Doc. Type" := VendorLedgerEntry."Document Type";
        GenJournalLine."Applies-to Doc. No." := VendorLedgerEntry."Document No.";
        GenJournalLine."On Hold" := VendorLedgerEntry."On Hold";
        GenJournalLine.Insert();

        // [WHEN] Blank "On Hold" on Vendor Ledger Entry, confirmed
        VendorLedgerEntry.Validate("On Hold", '');

        // [THEN] "On Hold" is blank
        VendorLedgerEntry.TestField("On Hold", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T043_StopOnHoldModificationOnCustLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] "On Hold" will not be changed without confirmation.
        Initialize();
        // [GIVEN] Customer Ledger Entry Invoice 'CI' for Customer 'C', "On Hold" is 'NET'
        CustLedgerEntry."Customer No." := 'C';
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := 'CI';
        CustLedgerEntry."On Hold" := 'NET';
        CustLedgerEntry.Open := true;

        //[GIVEN] Journal line for Customer 'C', applied to Invoice 'CI', "On Hold" is 'NET'
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := LibraryRandom.RandText(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := CustLedgerEntry."Customer No.";
        GenJournalLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        GenJournalLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        GenJournalLine."On Hold" := CustLedgerEntry."On Hold";
        GenJournalLine.Insert();

        // [WHEN] Blank "On Hold" on Customer Ledger Entry, don't confirm
        asserterror CustLedgerEntry.Validate("On Hold", '');

        // [THEN] Silent error, "On Hold" is not changed
        Assert.ExpectedError('');
        CustLedgerEntry.TestField("On Hold", 'NET');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T044_ConfirmOnHoldModificationOnCustLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] "On Hold" will be changed with confirmation.
        Initialize();
        // [GIVEN] Customer Ledger Entry Invoice 'CI' for Customer 'C', "On Hold" is 'NET'
        CustLedgerEntry."Customer No." := 'C';
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := 'CI';
        CustLedgerEntry."On Hold" := 'NET';
        CustLedgerEntry.Open := true;

        //[GIVEN] Journal line for Customer 'C', applied to Invoice 'CI', "On Hold" is 'NET'
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := LibraryRandom.RandText(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := CustLedgerEntry."Customer No.";
        GenJournalLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        GenJournalLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        GenJournalLine."On Hold" := CustLedgerEntry."On Hold";
        GenJournalLine.Insert();

        // [WHEN] Blank "On Hold" on Customer Ledger Entry, confirmed
        CustLedgerEntry.Validate("On Hold", '');

        // [THEN] "On Hold" is blank
        CustLedgerEntry.TestField("On Hold", '');
    end;

    [Test]
    [HandlerFunctions('NetCustomerVendorBalancesRequestPageHandler,MessageHandler')]
    procedure VerifyPaymentJournalWhenCustomerWasBlockedAndNetCustomerVendorBalancesUsed()
    var
        Customer: array[3] of Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: array[3] of Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
        CurrentJnlBatchName: Code[10];
        VendorNo: Text;
        CustomerAmount, VendorAmount : Decimal;
        i: Integer;
    begin
        // [SCENARIO 598414] Verify Payment Journal Line When Customer Was Blocked And Net Customer/Vendor Balances Used.
        Initialize();

        // [GIVEN] Create a General Journal Batch.
        CreateJournalBatch(
            GenJournalBatch, LibraryERM.SelectGenJnlTemplate(),
            GenJournalBatch."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] Set Customer and Vendor Amount.
        CustomerAmount := LibraryRandom.RandIntInRange(100, 500);
        VendorAmount := LibraryRandom.RandIntInRange(1000, 2000);

        for i := 1 to 3 do begin
            // [GIVEN] Create Linked Customer and Vendor
            CreateLinkedCustomerVendor(Customer[i], Vendor[i]);

            // [GIVEN] Create General Journal Line for Customer.
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
                GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
                Customer[i]."No.", CustomerAmount);

            // [GIVEN] Create General Journal Line for Vendor.
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
                GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
                Vendor[i]."No.", -VendorAmount);

            // [GIVEN] Set "External Document No.".
            GenJournalLine.Validate("External Document No.",
                LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("External Document No."), Database::"Gen. Journal Line"));
            GenJournalLine.Modify(true);
        end;

        // [GIVEN] Post General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Enqueue Vendor No.
        VendorNo := Vendor[1]."No." + '|' + Vendor[2]."No." + '|' + Vendor[3]."No.";
        LibraryVariableStorage.Enqueue(VendorNo);

        // [GIVEN] Open Payment Journal.
        OpenPaymentJournal(PaymentJournal);

        // [WHEN] Run "Net Customer/Vendor Balances" action
        PaymentJournal.NetCustomerVendorBalances.Invoke();

        // [THEN] Store Current Journal Batch Name.
        CurrentJnlBatchName := PaymentJournal.CurrentJnlBatchName.Value;
        PaymentJournal.OK().Invoke();

        // [THEN] Verify Amount in payment journal.
        VerifyAmountInGeneralJournalLine(GenJournalLine, CurrentJnlBatchName, Vendor[1]."No.", CustomerAmount, VendorAmount);

        // [GIVEN] Block the Customer 2.
        Customer[2].Validate(Blocked, Customer[2].Blocked::All);
        Customer[2].Modify(true);

        // [GIVEN] Delete the existing General Journal Lines. 
        DeleteGeneralJournalLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);

        // [GIVEN] Open Payment Journal.
        OpenPaymentJournal(PaymentJournal);

        // [WHEN] Run "Net Customer/Vendor Balances" action
        PaymentJournal.NetCustomerVendorBalances.Invoke();

        // [THEN] Verify Amount in General Journal Line.
        VerifyAmountInGeneralJournalLine(GenJournalLine, CurrentJnlBatchName, Vendor[3]."No.", CustomerAmount, VendorAmount);

        // [THEN] Post General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Net Cust/Vend Balances Test");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Net Cust/Vend Balances Test");

        LibraryERM.SetEnableDataCheck(false);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Net Cust/Vend Balances Test");
    end;

    local procedure CreateLinkedCustomerVendor(var Customer: Record Customer; var Vendor: Record Vendor)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        LibrarySales.CreateCustomer(Customer);
        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(ContactBusinessRelation, Contact."No.", Customer."No.");
        LibraryPurchase.CreateVendor(Vendor);
        LibraryMarketing.CreateBusinessRelationBetweenContactAndVendor(ContactBusinessRelation, Contact."No.", Vendor."No.");
    end;

    local procedure CreateGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure PostInvoice(AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20];
    begin
        exit(PostInvoice(WorkDate(), AccountType, AccountNo, '', Amount));
    end;

    local procedure PostInvoice(PostingDate: Date; AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20];
    begin
        exit(PostInvoice(PostingDate, AccountType, AccountNo, '', Amount));
    end;

    local procedure PostInvoice(AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20];
    begin
        exit(PostInvoice(WorkDate(), AccountType, AccountNo, CurrencyCode, Amount));
    end;

    local procedure PostInvoice(PostingDate: Date; AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20];
    begin
        exit(PostDoc(PostingDate, "Gen. Journal Document Type"::Invoice, AccountType, AccountNo, CurrencyCode, Amount));
    end;

    local procedure PostDoc(PostingDate: Date; DocType: Enum "Gen. Journal Document Type"; AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20];
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            DocType, AccountType, AccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure RunNetCustVendBalances(var Vendor: Record Vendor; var NetBalancesParameters: Record "Net Balances Parameters")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        NetCustVendBalancesMgt: Codeunit "Net Cust/Vend Balances Mgt.";
    begin
        NetBalancesParameters.Initialize();
        NetBalancesParameters.Validate("Document No.", 'NET001');
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        NetBalancesParameters.Validate("Journal Template Name", GenJournalTemplate.Name);
        NetBalancesParameters.Validate("Journal Batch Name", GenJournalBatch.Name);
        NetCustVendBalancesMgt.NetCustVendBalances(Vendor, NetBalancesParameters);
    end;

    local procedure AddExchRate(var CurrencyCode: Code[10]; StartingDate: Date; Multiplier: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindLast();
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" * Multiplier);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Starting Date", StartingDate);
        CurrencyExchangeRate.Insert();
    end;

    local procedure KeepOnePaymentTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, "Gen. Journal Template Type"::Payments);
        if GenJournalTemplate.FindFirst() then begin
            GenJournalTemplate.SetFilter(Name, '<>%1', GenJournalTemplate.Name);
            GenJournalTemplate.DeleteAll();
        end;
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.ModifyAll("No. Series", '');
        Commit();
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure OpenPaymentJournal(var PaymentJournal: TestPage "Payment Journal")
    begin
        KeepOnePaymentTemplate();
        PaymentJournal.OpenEdit();
    end;

    local procedure VerifyAmountInGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrentJnlBatchName: Code[10]; VendorNo: Code[20]; CustomerAmount: Decimal; VendorAmount: Decimal)
    begin
        GenJournalLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
        if CustomerAmount > VendorAmount then
            Assert.AreEqual(GenJournalLine.Amount, ABS(VendorAmount), AmountShouldBeEqualErr)
        else
            Assert.AreEqual(GenJournalLine.Amount, ABS(CustomerAmount), AmountShouldBeEqualErr);
    end;

    local procedure DeleteGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.DeleteAll(true);
    end;

    [RequestPageHandler]
    procedure NetCustomerVendorBalancesModalHandler(var NetCustomerVendorBalances: TestRequestPage "Net Customer/Vendor Balances")
    begin
        Assert.IsTrue(NetCustomerVendorBalances."Posting Date".Editable(), '"Posting Date".Editable');
        LibraryVariableStorage.Enqueue(NetCustomerVendorBalances."Posting Date".AsDate());
        Assert.IsTrue(NetCustomerVendorBalances."Document No.".Editable(), '"Document No.".Editable');
        LibraryVariableStorage.Enqueue(NetCustomerVendorBalances."Document No.".Value());
        Assert.IsTrue(NetCustomerVendorBalances.Description.Editable(), 'Description.Editable');
        LibraryVariableStorage.Enqueue(NetCustomerVendorBalances.Description.Value());
        Assert.IsTrue(NetCustomerVendorBalances."Order of suggestion".Editable(), '"Order of suggestion".Editable');
        LibraryVariableStorage.Enqueue(NetCustomerVendorBalances."Order of suggestion".AsInteger());
        Assert.IsTrue(NetCustomerVendorBalances."On Hold".Editable(), '"On Hold".Editable');
        LibraryVariableStorage.Enqueue(NetCustomerVendorBalances."On Hold".Value());
        LibraryVariableStorage.Enqueue(NetCustomerVendorBalances.Vendor.GetFilter("No."));
    end;

    [RequestPageHandler]
    procedure NetCustomerVendorBalancesRequestPageHandler(var NetCustomerVendorBalances: TestRequestPage "Net Customer/Vendor Balances")
    var
        VendorNo: Variant;
    begin
        VendorNo := LibraryVariableStorage.DequeueText();
        NetCustomerVendorBalances."Posting Date".SetValue(WorkDate());
        NetCustomerVendorBalances."Document No.".SetValue('TEST-001');
        NetCustomerVendorBalances.Vendor.SetFilter("No.", VendorNo);
        NetCustomerVendorBalances.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; Var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; Var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}