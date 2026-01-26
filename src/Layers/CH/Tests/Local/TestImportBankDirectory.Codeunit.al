codeunit 144016 "Test Import Bank Directory"
{
    // // [FEATURE] [Import Bank Directory]
    // Bank clearing numbers are used to identify each banking agency with a unique number. This information is a base requirement for electronic payment.
    // You can import the bank clearing number file, and customer and vendor bank information has clearing has clearing number information.
    // When you import the bank clearing number file, the data is imported to the bank clearing number table, and existing data is overwritten.
    // After importing the data, when you create bank information for a new customer, you can enter the clearing number in the customer bank card.
    // All relevant data is retrieved from the clearing number table to populate the form with information such as the bank name and address.
    // There is a table relation between the Bank Branch No. field and the clearing number table ("Bank Directory").

    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        FileNameForHandler: Text;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectory()
    var
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        NumberOfImportedRows: Integer;
        UpdateClearingNumbers: Boolean;
    begin
        // Setup
        Initialize();

        UpdateClearingNumbers := false;
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);

        CreateBankDirectoryImportFile();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // Exercise
        REPORT.Run(REPORT::"Import Bank Directory", true, false);

        NumberOfImportedRows := 12;

        // Verify
        VerifyImportedRecords(NumberOfImportedRows);

        VerifyBankDirectoryRecords();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportBankDirectoryCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelImportBankDirectory()
    var
        BankDirectory: Record "Bank Directory";
        BankDirectoryPage: TestPage "Bank Directory";
    begin
        // Setup
        Initialize();

        // Exercise
        BankDirectoryPage.OpenView();
        BankDirectoryPage."Import Bank Directory".Invoke();
        BankDirectoryPage.Close();

        // Verify
        Assert.AreEqual(0, BankDirectory.Count,
          'No bank directory entries should have been created when cancelling.');
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryUpdatingCustomerBankAccountClearingNumbers()
    begin
        // test import and updating the customer bank account clearing branch numbers
        ImportBankDirectoryWithCustomerBankAccount(true);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryNotUpdatingCustomerBankAccountClearingNumbers()
    begin
        // test import without updating the customer bank account clearing branch numbers
        ImportBankDirectoryWithCustomerBankAccount(false);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryUpdatingVendorBankAccountClearingNumbers()
    begin
        // test import and updating the vendor bank account clearing branch numbers
        ImportBankDirectoryWithVendorBankAccount(true);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryNotUpdatingVendorBankAccountClearingNumbers()
    begin
        // test import without updating the vendor bank account clearing branch numbers
        ImportBankDirectoryWithVendorBankAccount(false);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryEncodingUT()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        UpdateClearingNumbers: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 166131] NAV imports bank directory file containing country specific symbols with correct encoding
        Initialize();

        // [GIVEN] Bank directory file which has address with country specific symbols
        UpdateClearingNumbers := false;
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);
        CreateBankDirectoryImportFile();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Run report Import Bank Directory
        REPORT.Run(REPORT::"Import Bank Directory", true, false);

        // [THEN] Imported record contains country specific symbols in correct encoding
        BankDirectory.Get('100');
        BankDirectory.TestField(Address, 'ÄäÜüöÖß');
    end;

    local procedure Initialize()
    var
        BankDirectory: Record "Bank Directory";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryVariableStorage.Clear();
        BankDirectory.DeleteAll();
        Commit();
    end;

    procedure SetFileName(FileName: Text)
    begin
        FileNameForHandler := FileName;
    end;

    local procedure ImportBankDirectoryWithCustomerBankAccount(UpdateClearingNumbers: Boolean)
    var
        CustomerBankAccount1: Record "Customer Bank Account";
        CustomerBankAccount2: Record "Customer Bank Account";
        CustomerBankAccount3: Record "Customer Bank Account";
        BranchNo1: Code[5];
        BranchNo2: Code[5];
        BranchNo3: Code[5];
    begin
        // Setup
        Initialize();

        CreateCustomerBankAccount(CustomerBankAccount1);
        CreateCustomerBankAccount(CustomerBankAccount2);
        CreateCustomerBankAccount(CustomerBankAccount3);

        BranchNo1 := CustomerBankAccount1."Bank Branch No.";
        BranchNo2 := CustomerBankAccount2."Bank Branch No.";
        BranchNo3 := CustomerBankAccount3."Bank Branch No.";

        // Set the request page options
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);

        ImportBankDirectoryWithClearingNumbers(BranchNo1, BranchNo2, BranchNo3);

        // Verify
        CustomerBankAccount1.Find();
        CustomerBankAccount2.Find();
        CustomerBankAccount3.Find();

        // Verify that the customer bank account branch number is updated when there is a new clearing number in the imported directory
        if UpdateClearingNumbers then
            Assert.AreEqual(BranchNo2, CustomerBankAccount1."Bank Branch No.", 'Customer 1 Bank Branch No should be modified')
        else
            Assert.AreEqual(BranchNo1, CustomerBankAccount1."Bank Branch No.", 'Customer 1 Bank Branch No should be modified');

        // Verify that that other accounts are not updated
        Assert.AreEqual(BranchNo2, CustomerBankAccount2."Bank Branch No.", 'Bank Branch No should not be modified');
        Assert.AreEqual(BranchNo3, CustomerBankAccount3."Bank Branch No.", 'Bank Branch No should not be modified');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ImportBankDirectoryWithVendorBankAccount(UpdateClearingNumbers: Boolean)
    var
        VendorBankAccount1: Record "Vendor Bank Account";
        VendorBankAccount2: Record "Vendor Bank Account";
        VendorBankAccount3: Record "Vendor Bank Account";
        NewVendorBankAccount: Record "Vendor Bank Account";
        BranchNo1: Code[5];
        BranchNo2: Code[5];
        BranchNo3: Code[5];
    begin
        // Setup
        Initialize();

        CreateVendorBankAccount(VendorBankAccount1);
        CreateVendorBankAccount(VendorBankAccount2);
        CreateVendorBankAccount(VendorBankAccount3);

        BranchNo1 := VendorBankAccount1."Clearing No.";
        BranchNo2 := VendorBankAccount2."Clearing No.";
        BranchNo3 := VendorBankAccount3."Clearing No.";

        // Set the request page options
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);

        ImportBankDirectoryWithClearingNumbers(BranchNo1, BranchNo2, BranchNo3);

        VendorBankAccount1.Find();
        VendorBankAccount2.Find();
        VendorBankAccount3.Find();

        // Verify that the original Vendor bank account 1 is not modified
        Assert.AreEqual(BranchNo1, VendorBankAccount1."Clearing No.", 'Vendor Bank Account 1 Branch No should be modified');

        // Verify that the a new Vendor bank account is created when there is a new clearing number in the imported directory
        NewVendorBankAccount.SetRange("Vendor No.", VendorBankAccount1."Vendor No.");
        NewVendorBankAccount.SetRange("Clearing No.", BranchNo2);
        Assert.AreEqual(UpdateClearingNumbers, not NewVendorBankAccount.IsEmpty, 'Vendor bank account with New Clearing No.');

        // Verify that that other accounts are not updated
        Assert.AreEqual(BranchNo2, VendorBankAccount2."Clearing No.", 'Vendor Bank Account 2 Clearing No should not be modified');
        Assert.AreEqual(BranchNo3, VendorBankAccount3."Clearing No.", 'Vendor Bank Account 3 Clearing No should not be modified');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ImportBankDirectoryWithClearingNumbers(BranchNo1: Code[5]; BranchNo2: Code[5]; BranchNo3: Code[5])
    var
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        NumberOfImportedRows: Integer;
    begin
        NumberOfImportedRows := WriteBankDirectoryFile(BranchNo1, BranchNo2, BranchNo3, BranchNo2);
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // run the report
        REPORT.Run(REPORT::"Import Bank Directory", true, false);

        // Verify the rows were imported
        VerifyImportedRecords(NumberOfImportedRows);
    end;

    local procedure VerifyImportedRecords(ExpectedRecordCount: Integer)
    var
        BankDirectory: Record "Bank Directory";
        ElementValue: Variant;
        ImportedRecords: Text;
    begin
        // Verify records imported in the report dataset
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          'No rows in the dataset.');

        // Verify the Imported record count from the dataset
        LibraryReportDataset.GetElementValueInCurrentRow('ReadRec', ElementValue);
        ImportedRecords := CopyStr(ElementValue, 1, StrPos(ElementValue, ' ') - 1);
        Assert.AreEqual(Format(ExpectedRecordCount), ImportedRecords,
          'The number of imported records in the dataset should match the number of rows in the file.');

        // Verify records imported in the Bank Directory Table
        Assert.RecordCount(BankDirectory, ExpectedRecordCount);
    end;

    local procedure VerifyBankDirectoryRecords()
    begin
        // Verify the records imported from the file created by WriteFileContent function
        AssertBankDirectoryRecord('100', '8022', '100');
        AssertBankDirectoryRecord('110', '3003', '100');
        AssertBankDirectoryRecord('115', '3003', '100');
        AssertBankDirectoryRecord('140', '1211', '100');
        AssertBankDirectoryRecord('193', '60486', '193');
        AssertBankDirectoryRecord('294', '3940', '230');
        AssertBankDirectoryRecord('298', '8098', '230');
        AssertBankDirectoryRecord('4003', '5001', '4835');
        AssertBankDirectoryRecord('4209', '8820', '4836');
        AssertBankDirectoryRecord('4570', '8808', '4837');
        AssertBankDirectoryRecord('4823', '6301', '4838');
        AssertBankDirectoryRecord('4835', '8070', '4839');
    end;

    local procedure AssertBankDirectoryRecord(ClearingNo: Code[5]; PostCode: Text[20]; ClearingMainOffice: Code[5])
    var
        BankDirectory: Record "Bank Directory";
    begin
        Assert.IsTrue(BankDirectory.Get(ClearingNo), 'Clearing No. was not imported correctly.');
        Assert.AreEqual(PostCode, BankDirectory."Post Code", 'Wrong post code');
        Assert.AreEqual(ClearingMainOffice, BankDirectory."Clearing Main Office", 'Clearing Main Office');
    end;

    local procedure CreateBankDirectoryImportFile()
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('txt');
        WriteFileContent(FileNameForHandler);
    end;

    local procedure WriteFileContent(FileName: Text)
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileHdl.Create(FileName, TEXTENCODING::Windows);
        FileHdl.CreateOutStream(TmpStream);
        WriteLine(TmpStream, '01100  0000     001008100  120060324131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'ÄäÜüöÖß                            Postfach 2800                      ' +
          '8022      Zürich                             044 631 31 11                              30-5-5      SNBZCHZZXXX   ');
        WriteLine(TmpStream, '01110  0000     001100100  220071109131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'Bundesplatz 1                      Postfach                           ' +
          '3003      Bern                               031 327 02 21                              *30-5-5     SNBZCHZZXXX   ');
        WriteLine(TmpStream, '01115  0000     001158100  220060324131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'Bundesverw. / Bundesplatz 1        Postfach                           ' +
          '3003      Bern                               044 631 31 30     044 631 39 34            *30-5-5     SNBZCHZZXXX   ');
        WriteLine(TmpStream, '01140  0000     001403100  220060324132BNS            ' +
          'Banque nationale suisse                                     ' +
          'Rue Diday 8                        Case postale 5355                  ' +
          '1211      Genève 11                          022 311 86 11                              *30-5-5     SNBZCHZZXXX   ');
        WriteLine(TmpStream, '08193  0000     001933193  120020829031SECB           ' +
          'SECB Swiss Euro Clearing Bank                               ' +
          'Solmsstrasse 18                                                       ' +
          '60486     Frankfurt am Main                  69 97 98 98 0     69 97 98 98 98    ++49 DE            SECGDEFFXXX   ');
        WriteLine(TmpStream, '02294  0001     002940230  320050623111UBS            ' +
          'UBS AG                                                      ' +
          'Haus Metropol / Bahnhofstrasse 21  Postfach                           ' +
          '3940      Steg VS                            027 933 93 11                              *80-2-2                   ');
        WriteLine(TmpStream, '02298  0000     002982230  220050305111UBS            ' +
          'UBS AG                                                      ' +
          'Bahnhofstrasse 45                  Corporate Center                   ' +
          '8098      Zürich                             044 234 11 11                              *80-2-2     UBSWCHZH80A   ');
        WriteLine(TmpStream, '044003 00004835 0400354835 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Bahnhofstrasse 20                  Postfach 2503                      ' +
          '5001      Aarau                              062 836 31 31     062 836 33 00            *30-3200-1  CRESCHZZ50A   ');
        WriteLine(TmpStream, '044209 00004835 0420954836 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Friedbergstrasse 9                 Postfach 350                       ' +
          '8820      Wädenswil                          044 783 31 11     044 783 33 11            *80-500-4   CRESCHZZ88H   ');
        WriteLine(TmpStream, '044570 00004835 0457034837 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Schindellegistrasse 3              Postfach 59                        ' +
          '8808      Pfäffikon SZ                       055 416 01 01     055 416 02 02            *80-500-4   CRESCHZZ88F   ');
        WriteLine(TmpStream, '044823 00004835 0482374838 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Bahnhofstrasse 17                  Postfach 357                       ' +
          '6301      Zug                                041 727 99 22     041 727 99 43            *30-3200-1  CRESCHZZ63A   ');
        WriteLine(TmpStream, '044835 0000     0483584839 120050424111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Paradeplatz 8                      Postfach 100                       ' +
          '8070      Zürich                             044 333 99 11     044 332 55 55            80-500-4    CRESCHZZ80A   ');

        FileHdl.Close();
    end;

    local procedure WriteLine(TmpStream: OutStream; Text: Text)
    begin
        TmpStream.WriteText(Text);
        TmpStream.WriteText();
    end;

    local procedure WriteBankDirectoryFile(ClearingBranchNo1: Code[5]; ClearingBranchNo2: Code[5]; ClearingBranchNo3: Code[5]; NewClearingBranchNo1: Code[5]) RecordCount: Integer
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('txt');
        FileHdl.Create(FileNameForHandler);
        FileHdl.CreateOutStream(TmpStream);
        WriteLine(TmpStream, '04' + PadStr(ClearingBranchNo1, 5) +
          '0000' + PadStr(NewClearingBranchNo1, 5) + '0400354835 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Bahnhofstrasse 20                  Postfach 2503                      ' +
          '5001      Aarau                              062 836 31 31     062 836 33 00            *30-3200-1  CRESCHZZ50A   ');
        WriteLine(TmpStream, '04' + PadStr(ClearingBranchNo2, 5) +
          '0000     0483584839 120050424111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Paradeplatz 8                      Postfach 100                       ' +
          '8070      Zürich                             044 333 99 11     044 332 55 55            80-500-4    CRESCHZZ80A   ');
        WriteLine(TmpStream, '01' + PadStr(ClearingBranchNo3, 5) +
          '0000     001008100  120060324131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'Börsenstrasse 15                   Postfach 2800                      ' +
          '8022      Zürich                             044 631 31 11                              30-5-5      SNBZCHZZXXX   ');

        FileHdl.Close();
        RecordCount := 3;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportHandler(var ImportBankDirectory: TestRequestPage "Import Bank Directory")
    var
        UpdateClearingNumbers: Variant;
    begin
        LibraryVariableStorage.Dequeue(UpdateClearingNumbers);
        ImportBankDirectory.AutoUpdate.SetValue(UpdateClearingNumbers);
        ImportBankDirectory.FileName.AssistEdit();

        ImportBankDirectory.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCancelRequestPageHandler(var ImportBankDirectoryRequestPage: TestRequestPage "Import Bank Directory")
    begin
        ImportBankDirectoryRequestPage.Cancel().Invoke();
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account")
    var
        Customer: Record Customer;
    begin
        // Create a customer with Bank Account
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount."Bank Branch No." := Format(LibraryRandom.RandIntInRange(11111, 99999));
        CustomerBankAccount.Modify(true);
        Commit();
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        // Create a vendor with Bank Account
        LibraryPurchase.CreateVendor(Vendor);
        VendorBankAccount.Init();
        VendorBankAccount.Validate("Vendor No.", Vendor."No.");
        VendorBankAccount.Validate(Code, CopyStr(LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account"), 1, 5));
        VendorBankAccount."Clearing No." := Format(LibraryRandom.RandIntInRange(11111, 99999));
        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Bank Payment Domestic";
        VendorBankAccount.Insert(true);
        Commit();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Import Bank Directory", 'OnImportFile', '', false, false)]
    procedure OnImportFile(var TempBlob: Codeunit "Temp Blob"; var FileName: Text; var IsHandled: Boolean);
    var
        FileManagement: Codeunit "File Management";
    begin
        FileName := FileNameForHandler;
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        IsHandled := true;
    end;

}

