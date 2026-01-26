codeunit 147304 "Make 349 Declaration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        WrongCountryCodeErr: Label 'Wrong Country/Region Code in generated in 349 Declaration.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckReportMake349Declaration()
    var
        Make349Declaration: Report "Make 349 Declaration";
        Vendor: Record Vendor;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        Line: Text;
        FileName: Text[250];
        SearchText: Text[20];
    begin
        // Setup.
        CreateVATPostingSetup(VATPostingSetup);
        CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        CreateItem(Item, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise.
        CreatePostPurchaseInvoice(Vendor."No.", Item."No.");

        // Generate random values for Report Request Page.
        FillValuesForRequestPage();

        // Run Report Make 349 Declaration.
        FileName := GetTempFilePath() + 'make349.txt';
        Make349Declaration.InitializeRequest(FileName);
        Commit();
        Make349Declaration.Run();

        // Verify.
        SearchText := Vendor."Country/Region Code";
        Line := LibraryTextFileValidation.FindLineWithValue(FileName, 76, StrLen(SearchText), SearchText);
        Assert.IsFalse(Line = '', WrongCountryCodeErr);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; VATBusPostingGroup: Code[20])
    var
        VATregNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        VATregNoFormat.SetRange(Format, '###########');
        VATregNoFormat.FindFirst();
        Vendor.Validate("Country/Region Code", VATregNoFormat."Country/Region Code");
        Vendor.Validate(
          "VAT Registration No.",
          '1000000' + Format(LibraryRandom.RandIntInRange(1000, 9999)));
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure CreatePostPurchaseInvoice(VendorNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", LibraryUtility.GenerateRandomDate(20160101D, 20181231D));
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Posting Date");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(5000));
        PurchaseLine.Modify(true);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateItem(var Item: Record Item; VATBusPostingGroup: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATBusPostingGroup);
        Item.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.FindVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount2."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount2."No.");
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure FillValuesForRequestPage()
    var
        CountryRegion: Record "Country/Region";
        Value: Text[20];
    begin
        Value := CopyStr(LibraryUtility.GenerateGUID(), 1, 4);
        LibraryVariableStorage.Enqueue(Value);
        Value := Format(LibraryRandom.RandIntInRange(100000000, 999999999));
        LibraryVariableStorage.Enqueue(Value);
        Value := '100000000' + Format(LibraryRandom.RandIntInRange(1000, 9999));
        LibraryVariableStorage.Enqueue(Value);

        LibraryERM.CreateCountryRegion(CountryRegion);
        Value := CountryRegion.Code;
        LibraryVariableStorage.Enqueue(Value);
    end;

    local procedure GetTempFilePath(): Text
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(DelChr(FileMgt.ServerCreateTempSubDirectory(), '>', '\') + '\');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        PostingDate: Variant;
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        Make349Declaration.FiscalYear.SetValue(Date2DMY(PostingDate, 3));
        Make349Declaration.Period.SetValue(Date2DMY(PostingDate, 2));
        // Contact name.
        LibraryVariableStorage.Dequeue(Value);
        Make349Declaration.ContactName.SetValue(Value);
        // Telephone number.
        LibraryVariableStorage.Dequeue(Value);
        Make349Declaration.TelephoneNumber.SetValue(Value);
        // Declaration number.
        LibraryVariableStorage.Dequeue(Value);
        Make349Declaration.DeclarationNumber.SetValue(Value);
        // Company Country/region code.
        LibraryVariableStorage.Dequeue(Value);
        Make349Declaration.CompanyCountryRegion.SetValue(Value);

        Make349Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

