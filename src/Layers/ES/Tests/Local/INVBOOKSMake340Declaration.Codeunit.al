codeunit 147302 "INVBOOKS - Make340 Declaration"
{
    // Test for Report Make 340 Declaration:
    //   1. Run Make 340 Declaration Report with Fiscal Year.
    //   2. Validate Deponent Company VAT Number Field in Make 340 Declaration.
    //   3. Run Make 340 Declaration Report without Contact Name.
    //   4. Run Make 340 Declaration Report without Declaration Number.
    //   5. Run Make 340 Declaration Report without Electronic Code.
    //   6. Run Make 340 Declaration Report without Fiscal Year.
    //   7. Run Make 340 Declaration Report without Company VAT Registration No.
    //   8. Run Make 340 Declaration Report when both month and quarter are filled in.
    //   9. Run Make 340 Declaration Report when 'Replacement Declaration' is true and 'Previous Declaration No' is <blank>.
    //  10. Run Make 340 Declaration Report with Declaration Media Type = Telematic.
    //  11. Run Make 340 Declaration Report with Declaration Media Type = CD-R.
    //  12. Run Make 340 Declaration Report when incomplete Electronic Code is filled in.
    //  13. Run Make 340 Declaration Report when Telephone Number is less than 9 digits.
    //  14. Run make 340 Declaration Report with Record Type 2.
    //  15. Run make 340 Declaration Report with Electronic Code.
    //  16. Run make 340 Declaration Report with foreign customer.
    //  17. Run make 340 Declaration Report with domestic customer.
    //  18. Run make 340 Declaration Report with domestic customer for resident country code.
    //  19. Run make 340 Declaration Report with domestic vendor for resident country code.
    //  20. Run make 340 Declaration Report with EU vendor for resident country code.
    //  21. Run make 340 Declaration Report with Non-EU vendor for resident country code.
    //  22. Run make 340 Declaration Report with Vendor for Book Type Code.
    //  23. Run make 340 Declaration Report with Customer for Book Type Code.
    //  24. Run make 340 Declaration Report with Sales Credit Memo for Operation Code.
    //  25. Run make 340 Declaration Report with Customer for Equivalence Charge Amount.
    //  26. Run make 340 Declaration Report with Multiple Purchase Receipt for Operation Date.
    //  27. Run make 340 Declaration Report with Purchase Invoice for VAT Base Amount.
    //  28. Run make 340 Declaration Report with Special Characters in Company Name.
    //  29. Run make 340 Declaration Report with Corrected Invoice in Sales Credit Memo.
    //  30. Run make 340 Declaration Report with Sales Credit Memo for Operation Code.
    //  31. Run make 340 Declaration Report for VAT Number With Customer Country Code as ES.
    //  32. Run make 340 Declaration Report for VAT Number with Vendor Country Code as ES.
    //  33. Run make 340 Declaration Report for Permanent VAT Number with Customer Country Code as ES.
    // 
    // Covers Test Cases for ES - 154810,154832,154779,154781,154783,154776,154784,154790,154793,154805,154783,154789,154838,154858,155082,154891,154908,
    // 154911,154945,154946,154947,154954,154967,154981,155056,155079,155081,155083,155085,154901,154930,154936.
    //   --------------------------------------------------------------------------------
    //   Test Function Name                                                          TFS ID
    //   --------------------------------------------------------------------------------
    //   RunMake340DeclarationReportForFiscalYear                                    154810
    //   RunMake340DeclarationReportWithVATRegistrationNo                            154832
    //   RunMake340DeclarationReportWithoutContactName                               154779
    //   RunMake340DeclarationReportWithoutDeclarationNumber                         154781
    //   RunMake340DeclarationReportWithoutElectronicCode                            154783
    //   RunMake340DeclarationReportWithoutFiscalYear                                154776
    //   RunMake340DeclarationReportWithoutVATRegistrationNumber                     154784
    //   RunMake340DeclarationReportWithBothMonthAndQuarter                          154790,154793
    //   RunMake340DeclarationReportWithBlankPreviousDeclarationNo                   154805
    //   RunMake340DeclarationReportWithDeclarationTypeTelematic                     154838
    //   RunMake340DeclarationReportWithDeclarationTypeCDR                           154858
    //   RunMake340DeclarationReportWithIncompleteElectronicCode                     154783
    //   RunMake340DeclarationReportWithInvalidTelephoneNumber                       154789
    //   RunMake340DeclarationReportWithRecordType2                                  155082
    //   RunMake340DeclarationReportWithElectronicCode                               154891
    //   RunMake340DeclarationReportWithForeignCustomer                              154908
    //   RunMake340DeclarationReportWithDomesticCustomer                             154911
    //   RunMake340DeclarationReportWithDomesticCustomerGetResidentCountryCode       154911
    //   RunMake340DeclarationReportWithDomesticVendorGetResidentCountryCode         154945
    //   RunMake340DeclarationReportWithForeignEUVendorGetResidentCountryCode        154946
    //   RunMake340DeclarationReportWithNonEUVendorGetResidentCountryCode            154947
    //   RunMake340DeclarationReportWithVendorGetBookTypeCode                        154954
    //   RunMake340DeclarationReportWithCustomerGetBookTypeCode                      154954
    //   RunMake340DeclarationReportWithSalesCrMemoGetOperationCode                  154967
    //   RunMake340DeclarationReportWithCustomerGetEquivalenceChargeAmount           154981
    //   RunMake340DeclarationReportWithMultiplePurchaseReceipts                     155056
    //   RunMake340DeclarationReportWithForeignEUVendorGetBaseAmount                 155079
    //   RunMake340DeclarationReportWithSpecialCharacter                             155081
    //   RunMake340DeclarationReportWithSalesCrMemoGetCorrectedInvoiceIdentification 155083
    //   RunMake340DeclarationReportWithPurchaseCrMemoGetOperationCode               155085
    //   RunMake340DeclarationReportForVATNumberWithCustomerCountryCodeAsES          154901
    //   RunMake340DeclarationReportForVATNumberWithVendorCountryCodeAsES            154936
    //   RunMake340DeclarationReportForPermanentVATNumberWithCustomerCountryCodeAsES 154930

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false
    end;

    var
        Assert: Codeunit Assert;
        ES: Label 'ES';
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        ContactPerson: Label 'Contact Person';
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMake340Declaration: Codeunit "Library - Make 340 Declaration";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        FieldsAreNotEqual: Label 'Actual value %2 is not equal to the expected value, which is %1.';
        TelephoneNumber: Label '123456789';
        DeclarationNo: Label '1234';
        IncompleteElectronicCodeError: Label 'Electronic Code must be 16 digits without spaces or special characters.';
        InvalidTelephoneNumberError: Label 'Contact Telephone must be %1 digits without spaces or special characters.';
        MissingContactNameError: Label 'Contact Name must be entered.';
        MissingDeclarationNoError: Label 'Declaration Number must be entered.';
        MissingElectronicCodeError: Label 'Electronic Code must be entered.';
        MissingVATRegistrationNoError: Label 'Please specify the VAT Registration No. of your Company in the Company Information window.';
        PreviousDeclarationNoBlankError: Label 'Please specify the Previous Declaration No. if this is a replacement declaration.';
        ExpectedCountryName: Label 'CRONUS ESPAÐA S A';
        UpdatedCountryName: Label 'CróNUS España S&A';

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportForFiscalYear()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        ReferenceDate: Date;
    begin
        // Verify Fiscal Year in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();
        ReferenceDate := GetBasisOfCalcForPostingDate();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0,
            FindCountryRegionCode(), GenerateIntegerCode(16), ReferenceDate);

        // Verify: Verify Fiscal Year.
        VerifyFieldRecordType1(5, 4, ExportFileName, Format(Date2DMY(ReferenceDate, 3)), 1);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportGetVATRegNo()
    var
        CompanyInformation: Record "Company Information";
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // Verify VAT Registration Number in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify VAT Registration Number.
        CompanyInformation.Get();
        VerifyFieldRecordType1(9, 9, ExportFileName, CompanyInformation."VAT Registration No.", 1);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithoutContactName()
    begin
        // Verify whether system throws error message when Contact Name is not filled in.
        RunMake340DeclarationReportWithInvalidFilters('', DeclarationNo, GenerateIntegerCode(16),
          MissingContactNameError, TelephoneNumber, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithoutDeclarationNumber()
    begin
        // Verify whether system throws error message when Declaration Number is not filled in.
        RunMake340DeclarationReportWithInvalidFilters(ContactPerson, '', GenerateIntegerCode(16),
          MissingDeclarationNoError, TelephoneNumber, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithoutElectronicCode()
    begin
        // Verify whether system throws error message when Electronic Code is not filled in.
        RunMake340DeclarationReportWithInvalidFilters(ContactPerson, DeclarationNo, '',
          MissingElectronicCodeError, TelephoneNumber, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithoutVATRegistrationNumber()
    var
        Make340Declaration: Report "Make 340 Declaration";
        FiscalYear: Text[4];
        VATRegistrationNo: Text[20];
    begin
        // Verify whether system throws error message when Company VAT Registration No is not filled in.
        // Setup: Update Country/Region in Company Information.
        Initialize();  // Setup Demo Data.
        VATRegistrationNo := UpdateCompanyVATRegistrationNo('');

        // Exercise: Run Report Make 340 Declaration.
        FiscalYear := Format(Date2DMY(WorkDate(), 3));
        Clear(Make340Declaration);
        Make340Declaration.UseRequestPage(false);
        Make340Declaration.InitializeRequest(
          FiscalYear, Date2DMY(WorkDate(), 2),
          ContactPerson, TelephoneNumber, DeclarationNo,
          CopyStr(CreateGuid(), 1, 16),
          0, false, '',
          TemporaryPath + 'ES340.txt'
          , '', 0.0);
        asserterror Make340Declaration.RunModal();

        // Verify: Verify the error message.
        Assert.ExpectedError(MissingVATRegistrationNoError);

        // Tear Down.
        UpdateCompanyVATRegistrationNo(VATRegistrationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithBlankPreviousDeclarationNo()
    begin
        // Verify whether system throws error message when 'Replacement Declaration' is true and 'Previous Declaration No' is <blank>.
        RunMake340DeclarationReportWithInvalidFilters(ContactPerson, DeclarationNo,
          GenerateIntegerCode(16), PreviousDeclarationNoBlankError, TelephoneNumber, true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithDeclarationTypeTelematic()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // Verify Telematic code in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify Telematic code.
        VerifyFieldRecordType1(58, 1, ExportFileName, 'T', 1);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithDeclarationTypeCDR()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // Verify CD-R Code in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 1, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify CD-R code.
        VerifyFieldRecordType1(58, 1, ExportFileName, 'C', 1);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithIncompleteElectronicCode()
    var
        Make340Declaration: Report "Make 340 Declaration";
    begin
        // Verify whether system throws error message when incomplete Electronic Code is filled in.
        // Setup: Update Country/Region in Company Information.
        Initialize();  // Setup Demo Data.

        // Exercise: Run Report Make 340 Declaration.
        Make340Declaration.UseRequestPage(true);
        asserterror Make340Declaration.RunModal();

        // Verify: Verify the error message.
        Assert.ExpectedError(IncompleteElectronicCodeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithInvalidTelephoneNumber()
    begin
        // Verify whether system throws error message when Telephone Number is less than 9 digits.
        RunMake340DeclarationReportWithInvalidFilters(ContactPerson, DeclarationNo, GenerateIntegerCode(16),
          StrSubstNo(InvalidTelephoneNumberError, 9), GenerateIntegerCode(8), false);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithRecordType2()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Record Type 2 in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify Record Type 2.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 1, 1, '2');

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithElectronicCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        ElectronicCode: Code[16];
    begin
        // Verify Electronic Code in Make 340 Declaration text file.
        // Setup: Generate 16 digit Electronic Code.
        Initialize();
        ElectronicCode := CopyStr(GenerateIntegerCode(16), 1, 16);

        // Exercise: Run Report Make 340 Declaration and export text file.
        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0,
            FindCountryRegionCode(), ElectronicCode, GetBasisOfCalcForPostingDate());

        // Verify: Verify Electronic Code.
        VerifyFieldRecordType1(400, 16, ExportFileName, ElectronicCode, 1);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithForeignCustomer()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify VAT Registration No. for Foreign Customer in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindForeignCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify VAT Registration Number of foreign customer.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 18, 9, '         ');  // VAT Registration Number is blank for foreign customer.

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithDomesticCustomer()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        VATRegNo: Text[20];
        Line: Text[1024];
    begin
        // Verify VAT Registration No. for Domestic Customer in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify VAT Registration Number of domestic customer.
        // Required different value for every test case to get different VAT Registration Code in the export file.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        CustomerNo := GetCustomerFromSalesInvHeader(DocumentNo);
        Customer.Get(CustomerNo);
        VATRegNo := CopyStr(Customer."VAT Registration No.", 1, 9);
        VerifyFieldRecordType2(Line, 18, 9, VATRegNo);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithDomesticCustomerGetResidentCountryCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Resident Country Code for Domestic Customer in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify Resident Country Code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 78, 1, '1');

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithDomesticVendorGetResidentCountryCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Resident Country Code for Domestic Vendor in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportForPurchaseWithFilters(DocumentNo,
            FindCountryRegionCode(), GetBasisOfCalcForPostingDate());

        // Verify: Verify Resident Country Code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 78, 1, '1');

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithForeignEUVendorGetResidentCountryCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Resident Country Code for EU Vendor in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportForPurchaseWithFilters(DocumentNo,
            FindForeignCountryRegionCode(), GetBasisOfCalcForPostingDate());

        // Verify: Verify Resident Country Code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 78, 1, '2');

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithNonEUVendorGetResidentCountryCode()
    var
        DocumentNo: Code[20];
        NonEUCountryCode: Code[10];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Resident Country Code for Non-EU Vendor in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        NonEUCountryCode := FindNonEUCountryRegionCode();
        ExportFileName := RunMake340DeclarationReportForPurchaseWithFilters(DocumentNo,
            NonEUCountryCode, GetBasisOfCalcForPostingDate());

        // Verify: Verify Resident Country Code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 76, 2, NonEUCountryCode);

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithVendorGetBookTypeCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Book Type Code for Vendor in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportForPurchaseWithFilters(DocumentNo,
            FindCountryRegionCode(), GetBasisOfCalcForPostingDate());

        // Verify: Verify Book Type Code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 99, 1, 'R');

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithCustomerGetBookTypeCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Book Type Code for Customer in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify Book Type code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 99, 1, 'E');

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithSalesCrMemoGetOperationCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Operation Code for Sales Credit Memo in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportSalesCrMemoWithFilters(DocumentNo, false);

        // Verify: Verify Operation Code.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 100, 1, 'D');

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesCrMemoHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithCustomerGetEquivalenceChargeAmount()
    var
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Equivalence Charge Amount for Customer in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify Equivalence Charge Amount.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 372, 13, CalculateEquivalenceChargeAmt(VATEntry, DocumentNo));

        // Tear Down: Remove EC % from VAT Posting Setup and VAT Registration No. from Customer.
        UpdateVATPostingSetup(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group", 0);
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithMultiplePurchaseReceipts()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
        OperationDate: Text[8];
        ReferenceDate: Date;
    begin
        // Verify Operation Date for multiple Purchase Receipt in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();
        ReferenceDate := GetBasisOfCalcForPostingDate();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithPurchaseReceiptWithFilters(DocumentNo, ReferenceDate);

        // Verify: Verify Operation Date for multiple receipts.
        OperationDate := GetDateAsNumber(ReferenceDate);
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 109, 8, OperationDate);

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithForeignEUVendorGetBaseAmount()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Base Amount for Purchase in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportForPurchaseWithFilters(DocumentNo,
            FindForeignCountryRegionCode(), GetBasisOfCalcForPostingDate());

        // Verify: Verify Base Amount for Purchase Invoice.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 123, 13, GetVATEntryBase(DocumentNo));

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithSpecialCharacter()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        PreviousCompanyName: Text[1024];
    begin
        // Verify Special Characters in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();
        PreviousCompanyName := UpdateCompanyName(UpdatedCountryName);
        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0, FindCountryRegionCode(),
            GenerateIntegerCode(16), GetBasisOfCalcForPostingDate());

        // Verify: Verify Special Characters in company name.
        VerifyFieldRecordType1(18, 17, ExportFileName, ExpectedCountryName, 1);  // Expected Value is different from input value for the following reason:
        // i)All characters will be exported in Capital Letters.
        // ii)'&' and 'ñ' will be replaced with SPACE.

        // Tear Down: Set initial Company Name in Company Information.
        UpdateCompanyName(PreviousCompanyName);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesInvHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithSalesCrMemoGetCorrectedInvoiceIdentification()
    var
        DocumentNo: Code[20];
        CorrectedInvNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Corrected Invoice Identification for Sales Credit Memo in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportSalesCrMemoWithFilters(DocumentNo, true);

        // Verify: Verify Corrected Invoice Identification.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        CorrectedInvNo := GetCorrectedInvNo(DocumentNo);
        VerifyFieldRecordType2(Line, 326, StrLen(CorrectedInvNo), CorrectedInvNo);

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(GetCustomerFromSalesCrMemoHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithPurchaseCrMemoGetOperationCode()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        Line: Text[1024];
    begin
        // Verify Operation Code for Purchase Credit Memo in Make 340 Declaration text file.
        // Exercise: Run Report Make 340 Declaration and export text file.
        Initialize();

        // Required different value for every test case to get different VAT Registration Code in the export file.
        ExportFileName := RunMake340DeclarationReportPurchaseCrMemoWithFilters(DocumentNo);

        // Verify: Verify Operation Code for Purchase Credit Memo.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 100, 1, 'D');

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(GetVendorFromPurchaseCrMemoHeader(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportForVATNumberWithCustomerCountryCodeAsES()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
        Line: Text[1024];
        ActualValue: Text[9];
        ExpectedValue: Text[9];
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ReferenceDate: Date;
    begin
        // Verify Customer VAT Number field in the 340 Declaration file, when 340 Declaration Report is run with Customer Country Code = ES.
        // Setup & Exercise: Post a Sales Invoice with Customer Country Code = ES and run report Make 340 Declaration.
        Initialize();
        ReferenceDate := GetBasisOfCalcForPostingDate();
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0,
            FindCountryRegionCode(), GenerateIntegerCode(16), ReferenceDate);
        CustomerNo := GetCustomerFromSalesInvHeader(DocumentNo);
        Customer.Get(CustomerNo);

        // Verify: Verify customer VAT Registration No. in the exported file.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        ActualValue := LibraryMake340Declaration.ReadSpanishCustVATNo(Line);
        ExpectedValue := CopyStr(Customer."VAT Registration No.", 1, 9);
        Assert.AreEqual(ExpectedValue, ActualValue, StrSubstNo(FieldsAreNotEqual, ExpectedValue, ActualValue));

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportForVATNumberWithVendorCountryCodeAsES()
    var
        Vendor: Record Vendor;
        ExportFileName: Text[1024];
        Line: Text[1024];
        ActualValue: Text[9];
        ExpectedValue: Text[9];
        DocumentNo: Code[20];
        VendorNo: Code[20];
        ReferenceDate: Date;
    begin
        // Verify Vendor VAT Number field in the 340 Declaration file, when 340 Declaration Report is run with Vendor Country Code = ES.
        // Setup & Exercise: Post a Purchase Invoice with Vendor Country Code = ES and run report Make 340 Declaration.
        Initialize();
        ReferenceDate := GetBasisOfCalcForPostingDate();
        ExportFileName := RunMake340DeclarationReportForPurchaseWithFilters(DocumentNo, FindCountryRegionCode(), ReferenceDate);
        VendorNo := GetVendorFromPurchaseInvHeader(DocumentNo);
        Vendor.Get(VendorNo);

        // Verify: Verify vendor VAT Registration No. in the exported file.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 218, StrLen(DocumentNo), DocumentNo);
        ActualValue := LibraryMake340Declaration.ReadSpanishCustVATNo(Line);
        ExpectedValue := CopyStr(Vendor."VAT Registration No.", 1, 9);
        Assert.AreEqual(ExpectedValue, ActualValue, StrSubstNo(FieldsAreNotEqual, ExpectedValue, ActualValue));

        // Tear Down: Remove VAT Registration No from Vendor.
        RemoveVendorVATRegNo(VendorNo);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportForPermanentVATNumberWithCustomerCountryCodeAsES()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
        Line: Text[1024];
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ReferenceDate: Date;
    begin
        // Verify VAT Number in the Permanenet Residence Country field in the 340 Declaration file, when report is run with Customer Country Code = ES.
        // Setup & Exercise: Post a Sales Invoice with Customer Country Code = ES and run report Make 340 Declaration.
        Initialize();
        ReferenceDate := GetBasisOfCalcForPostingDate();
        ExportFileName := RunMake340DeclarationReportWithFilters(DocumentNo, 0,
            FindCountryRegionCode(), GenerateIntegerCode(16), ReferenceDate);
        CustomerNo := GetCustomerFromSalesInvHeader(DocumentNo);
        Customer.Get(CustomerNo);

        // Verify: Verify customer VAT Registration No. in the exported file.
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 178, StrLen(DocumentNo), DocumentNo);
        VerifyFieldRecordType2(Line, 79, 20, PadStr('', 20, ' '));

        // Tear Down: Remove VAT Registration No from Customer.
        RemoveCustomerVATRegNo(CustomerNo);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        UpdateCompanyInformation(ES);  // Update Country/Region code as ES.

        IsInitialized := true;
        Commit();
    end;

    local procedure CalculateEquivalenceChargeAmt(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]): Text[1024]
    var
        CalculatedAmt: Integer;
        EquivalenceChargeAmt: Text[1024];
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        CalculatedAmt := 100 * Abs(Round(VATEntry.Base * VATEntry."EC %" / 100, 0.01));  // Value in text file is always considered with 2 decimal places.
        EquivalenceChargeAmt := Format(CalculatedAmt);
        // Add '0' to the left of Equivalence Charge Amount to make the field to 13 digit.
        EquivalenceChargeAmt := PadStr('', 13 - StrLen(EquivalenceChargeAmt), '0') + EquivalenceChargeAmt;
        exit(EquivalenceChargeAmt);
    end;

    local procedure CreateCustomer(CountryRegion: Code[10]): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        VATRegNo: Text[20];
    begin
        // Create new customer.
        VATRegNo := LibraryERM.GenerateVATRegistrationNo(CountryRegion);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Country/Region Code", CountryRegion);
        Customer.Validate("VAT Registration No.", VATRegNo);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CountryRegion: Code[10]; PurchaseDocumentType: Enum "Purchase Document Type"; PostingDate: Date)
    begin
        // Create Purchase Invoice to generate transaction data.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseDocumentType, CreateVendor(CountryRegion));
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(), LibraryRandom.RandInt(10))
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesDocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date)
    begin
        // Create Sales Invoice to generate transaction data.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateVendor(CountryRegion: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATRegNo: Text[20];
    begin
        // Create new Vendor.
        VATRegNo := LibraryERM.GenerateVATRegistrationNo(CountryRegion);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Country/Region Code", CountryRegion);
        Vendor.Validate("VAT Registration No.", VATRegNo);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetBasisOfCalcForPostingDate(): Date
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("Posting Date");
        GLRegister.FindLast();
        exit(DMY2Date(Date2DMY(WorkDate(), 1), Date2DMY(WorkDate(), 2), 1 + Date2DMY(GLRegister."Posting Date", 3)));
    end;

    local procedure GetCustomerFromSalesInvHeader(DocumentNo: Code[20]) CustomerNo: Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.Get(DocumentNo);
        CustomerNo := SalesInvHeader."Sell-to Customer No.";
    end;

    local procedure GetCustomerFromSalesCrMemoHeader(DocumentNo: Code[20]) CustomerNo: Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        CustomerNo := SalesCrMemoHeader."Sell-to Customer No.";
    end;

    local procedure GetCorrectedInvNo(DocumentNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        exit(SalesCrMemoHeader."Corrected Invoice No.");
    end;

    local procedure GetDateAsNumber(Date: Date) DateAsNumber: Text[8]
    var
        Year: Text[4];
        Month: Text[2];
        Day: Text[2];
    begin
        Year := Format(Date2DMY(Date, 3));
        Month := Format(Date2DMY(Date, 2));
        Day := Format(Date2DMY(Date, 1));
        if StrLen(Month) < 2 then
            Month := '0' + Month;
        if StrLen(Day) < 2 then
            Day := '0' + Day;
        DateAsNumber := Year + Month + Day;
    end;

    local procedure GetVendorFromPurchaseInvHeader(DocumentNo: Code[20]) VendorNo: Code[20]
    var
        PurchaseInvHeader: Record "Purch. Inv. Header";
    begin
        PurchaseInvHeader.Get(DocumentNo);
        VendorNo := PurchaseInvHeader."Buy-from Vendor No.";
    end;

    local procedure GetVendorFromPurchaseCrMemoHeader(DocumentNo: Code[20]) VendorNo: Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Get(DocumentNo);
        VendorNo := PurchCrMemoHdr."Buy-from Vendor No.";
    end;

    local procedure GenerateIntegerCode(NumberOfDigit: Integer) IntegerCode: Text[16]
    var
        i: Integer;
    begin
        for i := 1 to NumberOfDigit do
            IntegerCode := InsStr(IntegerCode, Format(LibraryRandom.RandInt(9)), i);
    end;

    local procedure GetVATEntryBase(DocumentNo: Code[20]) VATBaseAmt: Text[20]
    var
        VATEntry: Record "VAT Entry";
        CalculatedVATBase: Integer;
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        CalculatedVATBase := 100 * Abs(VATEntry.Base);  // Value in text file is always considered with 2 decimal places.
        VATBaseAmt := Format(CalculatedVATBase);  // Add '0' to the left of Equivalence Charge Amount
        // to make the field to 13 digit.
        VATBaseAmt := PadStr('', 13 - StrLen(VATBaseAmt), '0') + VATBaseAmt;
    end;

    local procedure FindCountryRegionCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code");
    end;

    local procedure FindForeignCountryRegionCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure FindNonEUCountryRegionCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetRange("EU Country/Region Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure RemoveCustomerVATRegNo(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Registration No.", '');
        Customer.Modify(true);
    end;

    local procedure RemoveVendorVATRegNo(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Modify(true);
    end;

    local procedure RunMake340DeclarationReportWithFilters(var DocumentNo: Code[20]; DeclarationMediaType: Option; CountryRegion: Code[10]; ElectronicCode: Code[16]; PostingDate: Date) ExportFileName: Text[1024]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        CustomerNo := CreateCustomer(CountryRegion);
        Customer.Get(CustomerNo);
        ItemNo := CreateItem();
        Item.Get(ItemNo);
        UpdateVATPostingSetup(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group", LibraryRandom.RandDec(99, 2));
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        RunMake340DeclarationReport(Date2DMY(PostingDate, 2), DeclarationMediaType, ExportFileName,
          ElectronicCode, Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure RunMake340DeclarationReportWithInvalidFilters(ContactPerson: Text[30]; DeclarationNo: Text[4]; ElectronicCode: Code[16]; ExpectedErrorMessage: Text[1024]; TelephoneNumber: Code[9]; ReplacementDeclaration: Boolean)
    var
        Make340Declaration: Report "Make 340 Declaration";
        FiscalYear: Text[4];
    begin
        // Setup: Update Country/Region in Company Information.
        Initialize();  // Setup Demo Data.

        // Exercise: Run Report Make 340 Declaration.
        FiscalYear := Format(Date2DMY(WorkDate(), 3));
        Clear(Make340Declaration);
        Make340Declaration.UseRequestPage(false);
        Make340Declaration.InitializeRequest(
          FiscalYear, Date2DMY(WorkDate(), 2), ContactPerson,
          TelephoneNumber, DeclarationNo, ElectronicCode,
          0, ReplacementDeclaration, '',
          TemporaryPath + 'ES340.txt', '', 0.0);
        asserterror Make340Declaration.RunModal();

        // Verify: Verify the error message.
        Assert.ExpectedError(ExpectedErrorMessage);
    end;

    local procedure RunMake340DeclarationReportForPurchaseWithFilters(var DocumentNo: Code[20]; CountryRegion: Code[10]; PostingDate: Date) ExportFileName: Text[1024]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CountryRegion, PurchaseHeader."Document Type"::Invoice, PostingDate);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        RunMake340DeclarationReport(Date2DMY(PostingDate, 2), 0, ExportFileName, GenerateIntegerCode(16),
          Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure RunMake340DeclarationReportSalesCrMemoWithFilters(var DocumentNo: Code[20]; CorrectedInvoice: Boolean) ExportFileName: Text[1024]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvNo: Code[20];
        CustomerNo: Code[20];
        CountryRegion: Code[10];
        ReferenceDate: Date;
    begin
        CountryRegion := FindCountryRegionCode();
        ReferenceDate := GetBasisOfCalcForPostingDate();
        if CorrectedInvoice then begin
            CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer(CountryRegion),
              CreateItem(), ReferenceDate);
            CustomerNo := SalesHeader."Sell-to Customer No.";
            SalesInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true)
        end else
            CustomerNo := CreateCustomer(CountryRegion);

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CustomerNo, CreateItem(), ReferenceDate);
        SalesHeader.Validate("Corrected Invoice No.", SalesInvNo);
        SalesHeader.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        RunMake340DeclarationReport(Date2DMY(ReferenceDate, 2), 0, ExportFileName, GenerateIntegerCode(16),
          Format(Date2DMY(ReferenceDate, 3)));
    end;

    local procedure RunMake340DeclarationReportPurchaseCrMemoWithFilters(var DocumentNo: Code[20]) ExportFileName: Text[1024]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostingDate: Date;
    begin
        PostingDate := GetBasisOfCalcForPostingDate();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, FindCountryRegionCode(), PurchaseHeader."Document Type"::"Credit Memo", PostingDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");  // Document No. is used as Vendor Cr. Memo No. is not important.
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        RunMake340DeclarationReport(Date2DMY(PostingDate, 2), 0, ExportFileName, GenerateIntegerCode(16), Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure RunMake340DeclarationReportWithPurchaseReceiptWithFilters(var DocumentNo: Code[20]; PostingDate: Date) ExportFileName: Text[1024]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, FindCountryRegionCode(), PurchaseHeader."Document Type"::Order, PostingDate);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);  // Entering Qty. to recieve less than Quantity.
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseHeader.Validate("Posting Date", PostingDate + 1);  // Posting the second receipt and invoice with a different posting date.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        RunMake340DeclarationReport(Date2DMY(PostingDate, 2), 0, ExportFileName, GenerateIntegerCode(16),
          Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure RunMake340DeclarationReport(Month: Option; DeclarationMediaType: Option; var ExportFileName: Text[1024]; ElectronicCode: Code[16]; FiscalYear: Text[4]): Text[1024]
    begin
        RunMake340DeclarationReportSaveTxt(Month, DeclarationMediaType, ExportFileName, ElectronicCode, FiscalYear);
    end;

    local procedure RunMake340DeclarationReportSaveTxt(Month: Option; DeclarationMedia: Option; var ExportedFileName: Text[1024]; ElectronicCode: Code[16]; FiscalYear: Text[4])
    var
        Make340Declaration: Report "Make 340 Declaration";
    begin
        ExportedFileName := TemporaryPath + 'ES340.txt';
        if Exists(ExportedFileName) then
            Erase(ExportedFileName);

        // Run Report Make 340 Declaration with filters.
        Clear(Make340Declaration);
        Make340Declaration.UseRequestPage(false);
        // Contact Name,Telephone Number,Electronic Code defined as Text Constant as they are always fixed.
        Make340Declaration.InitializeRequest(
          FiscalYear, Month,
          ContactPerson, TelephoneNumber, DeclarationNo,
          ElectronicCode,
          DeclarationMedia, false, '',
          ExportedFileName, '', 0.0);
        Make340Declaration.RunModal();
    end;

    local procedure UpdateCompanyInformation(CountryRegionCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        // Setup Country/Region code in Company Information.
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", CountryRegionCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCompanyName(Name: Text[1024]) PreviousName: Text[1024]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        PreviousName := CompanyInformation.Name;
        CompanyInformation.Validate(Name, Name);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCompanyVATRegistrationNo(VATRegistrationNo: Text[20]) PreviousVATRegistrationNo: Text[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        PreviousVATRegistrationNo := CompanyInformation."VAT Registration No.";
        CompanyInformation."VAT Registration No." := VATRegistrationNo;  // Validation of VAT Registration No is out of scope for this feature.
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; ECPercentage: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("EC %", ECPercentage);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyFieldRecordType1(StartingPosition: Integer; FieldLength: Integer; ExportFileName: Text[1024]; ExpectedValue: Text[1024]; FileLineNumber: Integer)
    var
        FieldValue: Text[1024];
    begin
        FieldValue := LibraryTextFileValidation.ReadValueFromLine(ExportFileName, FileLineNumber, StartingPosition, FieldLength);
        Assert.AreEqual(ExpectedValue, FieldValue, StrSubstNo(FieldsAreNotEqual, ExpectedValue, FieldValue));
    end;

    local procedure VerifyFieldRecordType2(Line: Text[1024]; StartingPosition: Integer; Length: Integer; ExpectedValue: Text[1024])
    var
        FieldValue: Text[1024];
    begin
        FieldValue := LibraryTextFileValidation.ReadValue(Line, StartingPosition, Length);
        Assert.AreEqual(ExpectedValue, FieldValue, StrSubstNo(FieldsAreNotEqual, ExpectedValue, FieldValue));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make340DeclarationHandler(var Make340Declaration: TestRequestPage "Make 340 Declaration")
    begin
        Make340Declaration.ElectronicCode.Value := GenerateIntegerCode(15);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeclarationLinesPageHandler(var PageName: Page "340 Declaration Lines"; var ReplyAction: Action)
    begin
        ReplyAction := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportedSuccessfullyMessageHandler(Message: Text[1024])
    begin
    end;
}

