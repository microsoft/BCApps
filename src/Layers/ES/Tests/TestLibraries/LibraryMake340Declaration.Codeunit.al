codeunit 143303 "Library - Make 340 Declaration"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateCountryVATRegistration(var CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        CreateCountryRegion(CountryRegion);
        CountryRegionCode := CountryRegion.Code;
        CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegionCode);
    end;

    [Scope('OnPrem')]
    procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        CountryRegion.Init();
        CountryRegion.Validate(Code, CopyStr(LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Country/Region", CountryRegion.FieldNo(Code))));
        CountryRegion.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerVATRegistration(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
        CountryRegionCode: Code[10];
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCountryVATRegistration(CountryRegionCode);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Validate("VAT Registration No.", GetUniqueCustomerVATRegNo());
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateOperationCode(var OperationCode: Record "Operation Code"; "Code": Code[1])
    begin
        OperationCode.Init();
        OperationCode.Validate(Code, Code);
        OperationCode.Validate(
          Description, CopyStr(LibraryUtility.GenerateRandomCode(OperationCode.FieldNo(Description), DATABASE::"Operation Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Operation Code", OperationCode.FieldNo(Description))));
        OperationCode.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATRegistrationNoFormat(var VATRegistrationNoFormat: Record "VAT Registration No. Format"; CountryRegionCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        VATRegistrationNoFormat.Init();
        VATRegistrationNoFormat.Validate("Country/Region Code", CountryRegionCode);
        RecRef.GetTable(VATRegistrationNoFormat);
        VATRegistrationNoFormat.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, VATRegistrationNoFormat.FieldNo("Line No.")));
        VATRegistrationNoFormat.Validate("Check VAT Registration No.", false);
        VATRegistrationNoFormat.Insert(true)
    end;

    [Scope('OnPrem')]
    procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercentage: Decimal; ECPercentage: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercentage);
        VATPostingSetup.Validate("EC %", ECPercentage);
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendorVATRegistration(var Vendor: Record Vendor)
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        LibraryPurchase: Codeunit "Library - Purchase";
        CountryRegionCode: Code[10];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        CreateCountryVATRegistration(CountryRegionCode);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("VAT Registration No.", GetUniqueVendorVATRegNo());
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Modify(true);
        Commit();
    end;

    local procedure GetUniqueCustomerVATRegNo(): Text[20]
    var
        Customer: Record Customer;
        VATRegistrationNo: Integer;
    begin
        VATRegistrationNo := LibraryRandom.RandIntInRange(10000000, 49999000);
        repeat
            VATRegistrationNo += 1;
            Customer.SetRange("VAT Registration No.", Format(VATRegistrationNo));
        until Customer.IsEmpty;
        exit(Format(VATRegistrationNo));
    end;

    local procedure GetUniqueVendorVATRegNo(): Text[20]
    var
        Vendor: Record Vendor;
        VATRegistrationNo: Integer;
    begin
        VATRegistrationNo := LibraryRandom.RandIntInRange(10000000, 49999000);
        repeat
            VATRegistrationNo += 1;
            Vendor.SetRange("VAT Registration No.", Format(VATRegistrationNo));
        until Vendor.IsEmpty;
        exit(Format(VATRegistrationNo));
    end;

    [Scope('OnPrem')]
    procedure ReadCashCollectableAmountInteger(Line: Text[1024]): Text[15]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 411, 15), 1, 15));
    end;

    [Scope('OnPrem')]
    procedure ReadCashCollectableAmountFraction(Line: Text[1024]): Text[2]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 424, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure ReadCashCollectablesAsAbsolute(Line: Text[1024]): Decimal
    var
        IntegerPart: Integer;
        FractionPart: Integer;
    begin
        Evaluate(IntegerPart, CopyStr(LibraryTextFileValidation.ReadValue(Line, 411, 13), 1, 13));
        Evaluate(FractionPart, CopyStr(LibraryTextFileValidation.ReadValue(Line, 424, 2), 1, 2));
        exit(IntegerPart + (FractionPart / 100));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerLine(FileName: Text[1024]; CustName: Code[20]): Text[1024]
    begin
        exit(LibraryTextFileValidation.FindLineWithValue(FileName, 36, StrLen(CustName), CustName));
    end;

    [Scope('OnPrem')]
    procedure ReadLegalRepresentativeVATNo(Line: Text[1024]): Text[9]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 27, 9), 1, 9));
    end;

    [Scope('OnPrem')]
    procedure ReadNumericExercise(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 426, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadNumericExerciseLine(FileName: Text[1024]; NumericExercise: Text[4]): Text[1024]
    begin
        exit(LibraryTextFileValidation.FindLineWithValue(FileName, 426, 4, NumericExercise));
    end;

    [Scope('OnPrem')]
    procedure ReadNoOfRegisters(Line: Text[1024]): Text[9]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 138, 9), 1, 9));
    end;

    [Scope('OnPrem')]
    procedure ReadOperationCode(Line: Text[1024]): Code[1]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 100, 1), 1, 1));
    end;

    [Scope('OnPrem')]
    procedure ReadOperationalCodeFromFile(FileName: Text[1024]; InvoiceNo: Code[20]; OperationCodePosition: Integer; ReportFieldLength: Integer; StartingPosition: Integer; OccuranceNo: Integer): Code[1]
    var
        LineNo: Integer;
    begin
        LineNo :=
          LibraryTextFileValidation.FindLineNoWithValue(
            FileName, OperationCodePosition, StrLen(Format(InvoiceNo)), Format(InvoiceNo), OccuranceNo);
        if LineNo <> 0 then
            exit(LibraryTextFileValidation.ReadValueFromLine(FileName, LineNo, StartingPosition, ReportFieldLength));

        exit('');
    end;

    [Scope('OnPrem')]
    procedure ReadPresenterIDCompanyVATNo(Line: Text[1024]): Text[9]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 9, 9), 1, 9));
    end;

    [Scope('OnPrem')]
    procedure ReadPropertyLocation(Line: Text[1024]): Text[1]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 385, 1), 1, 1))
    end;

    [Scope('OnPrem')]
    procedure ReadPropertyTaxAccNo(Line: Text[1024]): Text[25]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 386, 25), 1, 25));
    end;

    [Scope('OnPrem')]
    procedure ReadSpanishCustVATNo(Line: Text[1024]): Text[9]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 18, 9), 1, 9));
    end;

    [Scope('OnPrem')]
    procedure ReadType1RecordLine(FileName: Text[1024]): Text[1024]
    begin
        exit(LibraryTextFileValidation.ReadLine(FileName, 1))
    end;

    [Scope('OnPrem')]
    procedure ReadVendorLine(FileName: Text[1024]; VendName: Code[20]): Text[1024]
    begin
        exit(LibraryTextFileValidation.FindLineWithValue(FileName, 36, StrLen(VendName), VendName));
    end;

    [Scope('OnPrem')]
    procedure ReadYearLine(FileName: Text[1024]; Year: Text[4]): Text[1024]
    begin
        exit(LibraryTextFileValidation.FindLineWithValue(FileName, 109, 4, Year));
    end;

    [Scope('OnPrem')]
    procedure RunMake340DeclarationReport(FiscalYear: Integer; GLAcc: Text[20]; Month: Option; MinPaymentAmount: Decimal) FileName: Text[1024]
    var
        Make340Declaration: Report "Make 340 Declaration";
    begin
        FileName := TemporaryPath + 'ES340.txt';
        if Exists(FileName) then
            Erase(FileName);

        Clear(Make340Declaration);
        Make340Declaration.InitializeRequest(
          Format(FiscalYear), Month,
          CopyStr(LibraryUtility.GenerateGUID(), 1, 30),
          Format(LibraryRandom.RandIntInRange(111111111, 999999999)),
          Format(LibraryRandom.RandIntInRange(1111, 9999)),
          CopyStr(LibraryUtility.GenerateGUID(), 1, 16),
          0, true, '1111000000000',
          FileName, GLAcc, MinPaymentAmount);

        Make340Declaration.UseRequestPage(false);
        Make340Declaration.RunModal();
        Make340Declaration.GetServerFileName(FileName);
    end;
}

