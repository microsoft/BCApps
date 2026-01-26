codeunit 144014 "ERM Make 349 Declaration Disc"
{
    // Test For Report - Make 349 Declaration.
    // 1. Test to verify Amount on Report 10710 - Make 349 Declaration for multiple Sales Invoice.
    // 
    // Covers Test Cases for WI - 351137.
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ----------------------------------------------------------------------------------------------
    // Make349DeclarationReportWithMultipleSalesInvoice                                       343572

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        FileNameTxt: Label '%1.txt';
        FormatTxt: Label '###########';
        PositionTxt: Label '142';
        ValueNotFoundMsg: Label 'Value not found.';

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,MessageHandler,CustomerVendorWarnings349ModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithMultipleSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        Position: Integer;
        FileName: Text[250];
    begin
        // Test to verify Amount on Report 10710 - Make 349 Declaration for multiple Sales Invoice.

        // Setup: Create and Post multiple Sales Invoice.
        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        Amount := CreateAndPostSalesInvoice(CustomerNo, ItemNo);
        Amount := Amount + CreateAndPostSalesInvoice(CustomerNo, ItemNo);
        FileName := TemporaryPath + StrSubstNo(FileNameTxt, LibraryUtility.GenerateGUID());  // Generate - File Name.

        // Exercise.
        RunMake349DeclarationReport(FileName);  // Open handlers - Make349DeclarationRequestPageHandler, CustomerVendorWarnings349ModalPageHandler.

        // Verify: Verify Amount in Text File, Using Hardcoded values for Known Starting Position.
        Evaluate(Position, PositionTxt);
        VerifyAmountOnGeneratedTextFile(FileName, Position, DelChr(Format(Amount), '=', ','));
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,MessageHandler,CustomerVendorWarnings349ModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithSalesInvoiceThe58positionIsEmpty()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        Position: Integer;
        FileName: Text[250];
        FirstLine: Text;
    begin
        // [SCENARIO 360639] Verify that the 58th symbol of first line is empty on Report 10710 - Make 349 Declaration for Sales Invoice

        // [GIVEN] Create and Post Sales Invoice.
        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        CreateAndPostSalesInvoice(CustomerNo, ItemNo);

        // [GIVEN] Generated File Name.
        FileName := TemporaryPath + StrSubstNo(FileNameTxt, LibraryUtility.GenerateGUID());
        Position := 58;

        // [WHEN] Run report 10710 - "Make 349 Declaration"
        RunMake349DeclarationReport(FileName);

        // [THEN] Symbol at position 58 of first line is equal to ' '
        FirstLine := LibraryTextFileValidation.ReadLine(FileName, 1);
        Assert.AreEqual(FirstLine[Position], ' ', ' ');
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; ItemNo: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(2, 5));  // Random - Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        exit(SalesLine.Amount);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        VATregNoFormat: Record "VAT Registration No. Format";
    begin
        VATregNoFormat.SetRange(Format, FormatTxt);
        VATregNoFormat.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Country/Region Code", VATregNoFormat."Country/Region Code");
        Customer.Validate("VAT Registration No.", GenerateRandomCode(11));  // VAT Registration Number required length of 11.
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) DeclarationNumber: Text[1024]
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            DeclarationNumber := InsStr(DeclarationNumber, Format(LibraryRandom.RandInt(9)), Counter);
    end;

    local procedure RunMake349DeclarationReport(FileName: Text)
    var
        Make349Declaration: Report "Make 349 Declaration";
    begin
        Commit(); // Commit Required;
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure VerifyAmountOnGeneratedTextFile(ExportFileName: Text; StartingPosition: Integer; ExpectedValue: Text)
    var
        FieldValue: Text[1024];
    begin
        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(
              ExportFileName, StartingPosition, StrLen(ExpectedValue), ExpectedValue), StartingPosition, StrLen(ExpectedValue));
        Assert.AreEqual(ExpectedValue, FieldValue, ValueNotFoundMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349ModalPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationRequestPageHandler(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        CountryRegion: Record "Country/Region";
        DeclarationMediaType: Option "Physical support",Telematic;
    begin
        CountryRegion.FindFirst();
        Make349Declaration.FiscalYear.SetValue(Date2DMY(WorkDate(), 3));
        Make349Declaration.Period.SetValue(Date2DMY(WorkDate(), 2));
        Make349Declaration.ContactName.SetValue(DeclarationMediaType::Telematic);
        Make349Declaration.TelephoneNumber.SetValue(GenerateRandomCode(9));  // Telephone Number required of length 9.
        Make349Declaration.DeclarationNumber.SetValue(GenerateRandomCode(13));  // Declaration Number required of length 13.
        Make349Declaration.CompanyCountryRegion.SetValue(CountryRegion.Code);
        Make349Declaration.DeclarationMediaType.SetValue(DeclarationMediaType::"Physical support");
        Make349Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

