codeunit 144020 "UT TAB Post Code - II"
{
    // Test for feature Post Code.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustNotExistMsg: Label '%1 must not exist.';
        ValueMustExistMsg: Label '%1 must exist.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressPurchaseQuote()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Quote Header, open Purchase Quote Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", CreatePurchaseHeader(PurchaseHeader."Document Type"));

        // Exercise: Set value on Ship-to Address field of Page - Purchase Quote.
        PurchaseQuote."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Purchase Quote.
        PurchaseQuote."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseQuote."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseQuote."Ship-to City".AssertEquals(PostCodeRange.City);
        PurchaseQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressPurchaseOrder()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Order Header, open Purchase Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", CreatePurchaseHeader(PurchaseHeader."Document Type"::Order));

        // Exercise: Set value on Ship-to Address field of Page - Purchase Order.
        PurchaseOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Purchase Order.
        PurchaseOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        PurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressPurchaseInvoice()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Invoice Header, open Purchase Invoice Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice));

        // Exercise: Set value on Ship-to Address field of Page - Purchase Invoice.
        PurchaseInvoice."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Purchase Invoice.
        PurchaseInvoice."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseInvoice."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseInvoice."Ship-to City".AssertEquals(PostCodeRange.City);
        PurchaseInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressPurchaseReturnOrder()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Return Order Header, open Purchase Return Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order"));

        // Exercise: Set value on Ship-to Address field of Page - Purchase Return Order.
        PurchaseReturnOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Purchase Return Order.
        PurchaseReturnOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseReturnOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseReturnOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        PurchaseReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressCustomer()
    var
        PostCodeRange: Record "Post Code Range";
        CustomerCard: TestPage "Customer Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 18 Customer.

        // Setup: Create Post Code Range and Customer.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", CreateCustomer());

        // Exercise: Set value on Address field of Page - Customer Card.
        CustomerCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Customer Card.
        CustomerCard.Address.AssertEquals(PostCodeRange."Street Name");
        CustomerCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        CustomerCard.City.AssertEquals(PostCodeRange.City);
        CustomerCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressEmployee()
    var
        Employee: Record Employee;
        PostCodeRange: Record "Post Code Range";
        EmployeeCard: TestPage "Employee Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5200 Employee.

        // Setup: Create Post Code Range and Employee, open Employee Card.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        Employee."No." := LibraryUTUtility.GetNewCode();
        Employee.Insert();
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");

        // Exercise: Set value on Address field of Employee Card.
        EmployeeCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on Employee Card.
        EmployeeCard.Address.AssertEquals(PostCodeRange."Street Name");
        EmployeeCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        EmployeeCard.City.AssertEquals(PostCodeRange.City);
        EmployeeCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressUnion()
    var
        Union: Record Union;
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5209 Union.

        // Setup: Create Post Code Range and Union.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        Union.Code := LibraryUTUtility.GetNewCode10();
        Union.Insert();

        // Exercise: Validate Address field of table - Union.
        Union.Validate(Address, DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City field of table - Union.
        Union.TestField(Address, PostCodeRange."Street Name");
        Union.TestField("Post Code", PostCodeRange."Post Code");
        Union.TestField(City, PostCodeRange.City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressWorkCenter()
    var
        PostCodeRange: Record "Post Code Range";
        WorkCenter: Record "Work Center";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID -  99000754 - Work Center.

        // Setup: Create Post Code Range and Work Center.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        WorkCenter."No." := LibraryUTUtility.GetNewCode();
        WorkCenter.Insert();

        // Exercise: Validate Address field on table - Work Center.
        WorkCenter.Validate(Address, DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City field of table - Work Center.
        WorkCenter.TestField(Address, PostCodeRange."Street Name");
        WorkCenter.TestField("Post Code", PostCodeRange."Post Code");
        WorkCenter.TestField(City, PostCodeRange.City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressMachineCenter()
    var
        PostCodeRange: Record "Post Code Range";
        MachineCenter: Record "Machine Center";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID -  99000758 - Machine Center.

        // Setup: Create Post Code Range and Machine Center.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.
        MachineCenter."No." := LibraryUTUtility.GetNewCode();
        MachineCenter.Insert();

        // Exercise: Validate Address field of table - Machine Center.
        MachineCenter.Validate(Address, DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City filed of table - Machine Center.
        MachineCenter.TestField(Address, PostCodeRange."Street Name");
        MachineCenter.TestField("Post Code", PostCodeRange."Post Code");
        MachineCenter.TestField(City, PostCodeRange.City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePostCodeRange()
    var
        PostCode: Record "Post Code";
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 11406 Post Code Range.

        // Setup: Create Post Code Range.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - option Range 0 to 4, Random value for From Number.

        // Exercise: Validate OnDelete Trigger of table - Post Code Range.
        PostCodeRange.Delete(true);

        // Verify: Verify Post Code Range and Post Code is deleted.
        Assert.IsFalse(
          PostCodeRange.Get(PostCodeRange."Post Code", PostCodeRange.City, PostCodeRange.Type, PostCodeRange."From No."),
          StrSubstNo(ValueMustNotExistMsg, PostCodeRange.TableCaption()));
        Assert.IsFalse(
          PostCode.Get(PostCodeRange."Post Code", PostCodeRange.City), StrSubstNo(ValueMustNotExistMsg, PostCode.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPostCodeRange()
    var
        PostCode: Record "Post Code";
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 11406 Post Code Range.

        // Setup: Initialize Post Code Range.
        PostCodeRange."Post Code" := LibraryUTUtility.GetNewCode();
        PostCodeRange.City := LibraryUTUtility.GetNewCode();

        // Exercise: Validate OnInsert Trigger of table - Post Code Range.
        PostCodeRange.Insert(true);

        // Verify: Verify Post Code Range with corresponding Post Code is Inserted.
        Assert.IsTrue(PostCode.Get(PostCodeRange."Post Code", PostCodeRange.City), StrSubstNo(ValueMustExistMsg, PostCode.TableCaption()));
        Assert.IsTrue(
          PostCodeRange.Get(PostCodeRange."Post Code", PostCodeRange.City, PostCodeRange.Type, PostCodeRange."From No."),
          StrSubstNo(ValueMustExistMsg, PostCodeRange.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTypeBlankCodePostRange()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate Type - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateTypePostCodeRange(PostCodeRange.Type);  // Default value of Type is blank.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTypeHouseBoatPostCodeRange()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate Type - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateTypePostCodeRange(PostCodeRange.Type::"House Boat");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTypeHouseTrailerPostCodeRange()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate Type - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateTypePostCodeRange(PostCodeRange.Type::"House Trailer");
    end;

    local procedure OnValidateTypePostCodeRange(Type: Option)
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Setup: Create Post Code Range.
        CreatePostCodeRange(PostCodeRange, Type, LibraryRandom.RandInt(10));  // Random value for From Number.

        // Exercise: Validate Type - OnValidate Trigger of table - Post Code Range.
        PostCodeRange.Validate(Type);

        // Verify: Verify updated From Number and To Number with zero on table - Post Code Range.
        PostCodeRange.TestField("From No.", 0);
        PostCodeRange.TestField("To No.", 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateFromNoTypeBlankPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate From No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateFromNoTypePostCodeRange(PostCodeRange.Type, LibraryRandom.RandInt(10));  // Default value of Type is blank, Random value for From Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateFromNoTypeHouseBoatPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate From No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateFromNoTypePostCodeRange(PostCodeRange.Type::"House Boat", LibraryRandom.RandInt(10));  // Random value for From Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateFromNoTypeHouseTrailerPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate From No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateFromNoTypePostCodeRange(PostCodeRange.Type::"House Trailer", LibraryRandom.RandInt(10));  // Random value for From Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateFromNoTypeOddPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate From No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateFromNoTypePostCodeRange(PostCodeRange.Type::Odd, 2 * LibraryRandom.RandInt(10));  // Even value for From Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateFromNoTypeEvenPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate From No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateFromNoTypePostCodeRange(PostCodeRange.Type::Even, 2 * LibraryRandom.RandInt(10) + 1);   // Odd value for From Number.
    end;

    local procedure OnValidateFromNoTypePostCodeRange(Type: Option; FromNumber: Integer)
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Setup: Create Post Code Range.
        CreatePostCodeRange(PostCodeRange, Type, FromNumber);

        // Exercise: Validate From No. - OnValidate Trigger of table - Post Code Range.
        asserterror PostCodeRange.Validate("From No.");

        // Verify: Verify the Error Code, Actual Error - From No. must be 0 if Type is blank or House Boat or House Trailer in Post Code Range or From No. must be odd if Type is Odd in Post Code Range
        // or From No. must be even if Type is Even in Post Code Range.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToNoTypeBlankPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate To No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateToNoTypePostCodeRange(PostCodeRange.Type, LibraryRandom.RandInt(10));  // Default value of Type is blank, Random value for To Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToNoTypeHouseBoatPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate To No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateToNoTypePostCodeRange(PostCodeRange.Type::"House Boat", LibraryRandom.RandInt(10));  // Random value for To Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToNoTypeHouseTrailerPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate To No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateToNoTypePostCodeRange(PostCodeRange.Type::"House Trailer", LibraryRandom.RandInt(10));  // Random value for To Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToNoTypeOddPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate To No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateToNoTypePostCodeRange(PostCodeRange.Type::Odd, 2 * LibraryRandom.RandInt(10));  // Even value for To Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToNoTypeEvenPostCodeRangeError()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate To No. - OnValidate Trigger of Table ID - 11406 Post Code Range.
        OnValidateToNoTypePostCodeRange(PostCodeRange.Type::Even, 2 * LibraryRandom.RandInt(10) + 1);   // Odd value for To Number.
    end;

    local procedure OnValidateToNoTypePostCodeRange(Type: Option; ToNo: Integer)
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Setup: Create Post Code Range.
        CreatePostCodeRange(PostCodeRange, Type, LibraryRandom.RandInt(10));  // Random value for From Number.
        PostCodeRange."To No." := ToNo;
        PostCodeRange.Modify();

        // Exercise: Validate To No. - OnValidate Trigger of table - Post Code Range.
        asserterror PostCodeRange.Validate("To No.");

        // Verify: Verify the Error Code, Actual Error - To No. must be 0 if Type is blank or House Boat or House Trailer in Post Code Range or To No. must be odd if Type is Odd in Post Code Range
        // or To No. must be even if Type is Even in Post Code Range.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountHolderPostCodeBankAccount()
    var
        BankAccount: Record "Bank Account";
        PostCode: Record "Post Code";
    begin
        // Purpose of the test is to validate Account Holder Post Code - OnValidate Trigger of Table ID - 270 Bank Account.

        // Setup: Create Post Code and Bank Account.
        CreatePostCode(PostCode);
        CreateBankAccount(BankAccount, PostCode.Code, '');  // Blank value for Account Holder City.

        // Exercise: Validate Account Holder Post Code - OnValidate Trigger of table - Bank Account.
        BankAccount.Validate("Account Holder Post Code");

        // Verify: Verify updated Account Holder City and Acc. Hold. Country Region Code with City and Country Region Code of Post Code table.
        BankAccount.TestField("Account Holder City", PostCode.City);
        BankAccount.TestField("Acc. Hold. Country/Region Code", PostCode."Country/Region Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountHolderCityBankAccount()
    var
        BankAccount: Record "Bank Account";
        PostCode: Record "Post Code";
    begin
        // Purpose of the test is to validate Account Holder City - OnValidate Trigger of Table ID - 270 Bank Account.

        // Setup: Create Post Code and Bank Account.
        CreatePostCode(PostCode);
        CreateBankAccount(BankAccount, '', PostCode."Search City");  // Blank value for Account Holder Post Code.

        // Exercise: Validate Account Holder City - OnValidate Trigger of table - Bank Account.
        BankAccount.Validate("Account Holder City");

        // Verify: Verify updated Account Holder Post Code and Acc. Hold. Country Region Code with Code and Country Region Code of Post Code table.
        BankAccount.TestField("Account Holder Post Code", PostCode.Code);
        BankAccount.TestField("Acc. Hold. Country/Region Code", PostCode."Country/Region Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToAddressBlanketSalesOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // Purpose of the test is to validate Sell-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Blanket Sales Order, open Blanket Sales Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenBlanketSalesOrder(BlanketSalesOrder, CreateSalesHeader(SalesHeader."Document Type"::"Blanket Order"));

        // Exercise: Set value on Sell-to Address field of Page - Blanket Sales Order.
        BlanketSalesOrder."Sell-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Sell-to Address, Sell-to Post Code and Sell-to City on Page - Blanket Sales Order.
        BlanketSalesOrder."Sell-to Address".AssertEquals(PostCodeRange."Street Name");
        BlanketSalesOrder."Sell-to Post Code".AssertEquals(PostCodeRange."Post Code");
        BlanketSalesOrder."Sell-to City".AssertEquals(PostCodeRange.City);
        BlanketSalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToAddressSalesReturnOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Purpose of the test is to validate Sell-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Return Order, open Sales Return Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenSalesReturnOrder(SalesReturnOrder, CreateSalesHeader(SalesHeader."Document Type"::"Return Order"));

        // Exercise: Set value on Sell-to Address field of Page - Sales Return Order.
        SalesReturnOrder."Sell-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Sell-to Address, Sell-to Post Code and Sell-to City on Page - Sales Return Order.
        SalesReturnOrder."Sell-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesReturnOrder."Sell-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesReturnOrder."Sell-to City".AssertEquals(PostCodeRange.City);
        SalesReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressBlanketSalesOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Blanket Sales Order, open Blanket Sales Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenBlanketSalesOrder(BlanketSalesOrder, CreateSalesHeader(SalesHeader."Document Type"::"Blanket Order"));

        // Exercise: Set value on Bill-to Address field of Page - Blanket Sales Order.
        BlanketSalesOrder."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on Page - Blanket Sales Order.
        BlanketSalesOrder."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        BlanketSalesOrder."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        BlanketSalesOrder."Bill-to City".AssertEquals(PostCodeRange.City);
        BlanketSalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressSalesReturnOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Return Order, open Sales Return Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenSalesReturnOrder(SalesReturnOrder, CreateSalesHeader(SalesHeader."Document Type"::"Return Order"));

        // Exercise: Set value on Bill-to Address field of Page - Sales Return Order.
        SalesReturnOrder."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on Page - Sales Return Order.
        SalesReturnOrder."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesReturnOrder."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesReturnOrder."Bill-to City".AssertEquals(PostCodeRange.City);
        SalesReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressBlanketSalesOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Blanket Sales Order, open Blanket Sales Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenBlanketSalesOrder(BlanketSalesOrder, CreateSalesHeader(SalesHeader."Document Type"::"Blanket Order"));

        // Exercise: Set value on Ship-to Address field of Page - Blanket Sales Order.
        BlanketSalesOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on Page - Blanket Sales Order.
        BlanketSalesOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        BlanketSalesOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        BlanketSalesOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        BlanketSalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressSalesReturnOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Return Order, open Sales Return Order Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenSalesReturnOrder(SalesReturnOrder, CreateSalesHeader(SalesHeader."Document Type"::"Return Order"));

        // Exercise: Set value on Ship-to Address field of Page - Sales Return Order.
        SalesReturnOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on Page - Sales Return Order.
        SalesReturnOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesReturnOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesReturnOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        SalesReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressCustomerBankAccount()
    var
        PostCodeRange: Record "Post Code Range";
        CustomerBankAccountCard: TestPage "Customer Bank Account Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 287 Customer Bank Account.

        // Setup: Create Post Code Range and Customer Bank Account, open Customer Bank Account Card.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenCustomerBankAccountCard(CustomerBankAccountCard);

        // Exercise: Set value on Address field of Page - Customer Bank Account Card.
        CustomerBankAccountCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on Page - Customer Bank Account Card.
        CustomerBankAccountCard.Address.AssertEquals(PostCodeRange."Street Name");
        CustomerBankAccountCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        CustomerBankAccountCard.City.AssertEquals(PostCodeRange.City);
        CustomerBankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountHolderAddressCustomerBankAccount()
    var
        PostCodeRange: Record "Post Code Range";
        CustomerBankAccountCard: TestPage "Customer Bank Account Card";
    begin
        // Purpose of the test is to validate Account Holder Address - OnValidate Trigger of Table ID - 287 Customer Bank Account.

        // Setup: Create Post Code Range and Customer Bank Account, open Customer Bank Account Card.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        OpenCustomerBankAccountCard(CustomerBankAccountCard);

        // Exercise: Set value on Account Holder Address field of Page - Customer Bank Account Card.
        CustomerBankAccountCard."Account Holder Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Account Holder Address, Account Holder Post Code and Account Holder City on Page - Customer Bank Account Card.
        CustomerBankAccountCard."Account Holder Address".AssertEquals(PostCodeRange."Street Name");
        CustomerBankAccountCard."Account Holder Post Code".AssertEquals(PostCodeRange."Post Code");
        CustomerBankAccountCard."Account Holder City".AssertEquals(PostCodeRange.City);
        CustomerBankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressShipToAddress()
    var
        PostCodeRange: Record "Post Code Range";
        ShipToAddress: Record "Ship-to Address";
        ShipToAddressPage: TestPage "Ship-to Address";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 222 Ship-to Address.

        // Setup: Create Post Code Range and Ship To Address, open Ship-to Address Page.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        ShipToAddress.Code := LibraryUTUtility.GetNewCode10();
        ShipToAddress.Insert();
        ShipToAddressPage.OpenEdit();
        ShipToAddressPage.FILTER.SetFilter(Code, ShipToAddress.Code);

        // Exercise: Set value on Address field of Page - Ship-to Address.
        ShipToAddressPage.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Ship-to Address.
        ShipToAddressPage.Address.AssertEquals(PostCodeRange."Street Name");
        ShipToAddressPage."Post Code".AssertEquals(PostCodeRange."Post Code");
        ShipToAddressPage.City.AssertEquals(PostCodeRange.City);
        ShipToAddressPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressAlternativeAddress()
    var
        AlternativeAddress: Record "Alternative Address";
        PostCodeRange: Record "Post Code Range";
        AlternativeAddressCard: TestPage "Alternative Address Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5201 Alternative Address.

        // Setup: Create Post Code Range and Alternative Address, open Alternative Address Card.
        CreatePostCodeRange(PostCodeRange, LibraryRandom.RandIntInRange(0, 4), LibraryRandom.RandInt(10));  // Type - Option Range 0 to 4, Random value for - From Number field.
        AlternativeAddress.Code := LibraryUTUtility.GetNewCode10();
        AlternativeAddress.Insert();
        AlternativeAddressCard.OpenEdit();
        AlternativeAddressCard.FILTER.SetFilter(Code, AlternativeAddress.Code);

        // Exercise: Set value on Address field of Page - Alternative Address Card.
        AlternativeAddressCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Alternative Address Card.
        AlternativeAddressCard.Address.AssertEquals(PostCodeRange."Street Name");
        AlternativeAddressCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        AlternativeAddressCard.City.AssertEquals(PostCodeRange.City);
        AlternativeAddressCard.Close();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; AccountHolderPostCode: Code[20]; AccountHolderCity: Text[30])
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Account Holder Post Code" := AccountHolderPostCode;
        BankAccount."Account Holder City" := AccountHolderCity;
        BankAccount.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.Code := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount.Insert();
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code")
    begin
        PostCode.Code := Format(LibraryRandom.RandIntInRange(1000, 9999)) + ' ' + 'ZZ';  // Code should contain 4 digit following space and two upper case alphabet.
        PostCode.City := LibraryUTUtility.GetNewCode();
        PostCode."Search City" := PostCode.City;
        PostCode."Country/Region Code" := LibraryUTUtility.GetNewCode10();
        PostCode.Insert();
    end;

    local procedure CreatePostCodeRange(var PostCodeRange: Record "Post Code Range"; Type: Option; FromNo: Integer)
    var
        PostCode: Record "Post Code";
    begin
        CreatePostCode(PostCode);
        PostCodeRange."Post Code" := PostCode.Code;
        PostCodeRange.City := PostCode.City;
        PostCodeRange.Type := Type;
        PostCodeRange."From No." := FromNo;
        PostCodeRange."To No." := PostCodeRange."From No.";
        PostCodeRange."Street Name" := LibraryUTUtility.GetNewCode();
        PostCodeRange.Insert();
    end;

    local procedure CreatePurchaseHeader(DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader.Insert();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSalesHeader(DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Insert();
        exit(SalesHeader."No.");
    end;

    local procedure OpenBlanketSalesOrder(var BlanketSalesOrder: TestPage "Blanket Sales Order"; No: Code[20])
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenCustomerBankAccountCard(var CustomerBankAccountCard: TestPage "Customer Bank Account Card")
    begin
        CustomerBankAccountCard.OpenEdit();
        CustomerBankAccountCard.FILTER.SetFilter(Code, CreateCustomerBankAccount());
    end;

    local procedure OpenSalesReturnOrder(var SalesReturnOrder: TestPage "Sales Return Order"; No: Code[20])
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
    end;
}

