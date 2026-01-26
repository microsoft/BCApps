codeunit 144088 "Decl. of Intent Export Test"
{
    // // [FEATURE] [Declaration of Intent] [Purchase]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        FlatFileManagement: Codeunit "Flat File Management";
        TextFile: BigText;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDeclOfIntent()
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
        Vendor: Record Vendor;
        VATExemption: Record "VAT Exemption";
        SigningCompanyOfficials: Record "Company Officials";
        DeclarationOfIntentExport: Codeunit "Declaration of Intent Export";
        FileName: Text;
        AmountToDeclare: Decimal;
        ExportFlags: array[6] of Boolean;
        Index: Integer;
    begin
        // [SCENARIO] Export the Declaration of Intent and validate its content
        Setup(CompanyInformation, VendorTaxRepresentative);

        // [GIVEN] CompanyInformation."Name" = "CRONUS Italia S.p.A.", "Fiscal Code" = "11111111111", "VAT Registration No." = "22222222222"
        // [GIVEN] Vendor with "Name" = "London Postmaster", "Fiscal Code" = "33333333333", "VAT Registration No." = "44444444444"
        // [GIVEN] A VAT Exemption for a Vendor
        CreateVendor(Vendor, false);
        CreateVATExemption(VATExemption, Vendor);

        // [GIVEN] A Company Official to sign the declaration
        CreateCompanyOfficial(SigningCompanyOfficials);

        // [GIVEN] An Amount to declare
        AmountToDeclare := 1234.56;

        // [WHEN] The Declaration of Intent is exported
        FileName := TemporaryPath + LibraryUtility.GenerateGUID() + '.ivi';
        ExportFlags[1] := false;
        ExportFlags[2] := false;
        ExportFlags[3] := false;
        ExportFlags[4] := false;
        ExportFlags[5] := false;
        ExportFlags[6] := false;
        DeclarationOfIntentExport.SetServerFileName(FileName);
        DeclarationOfIntentExport.Export(
          VATExemption, 'Description of Goods', SigningCompanyOfficials."No.", AmountToDeclare, 0, ExportFlags, false, '', '');

        // [THEN] The content reflects the data in NAV
        // [THEN] Record B fields 11, 12 are blanked, 13 = "CRONUS Italia S.p.A.", 14 = "22222222222" (TFS 296019)
        // [THEN] Record B fields 41 and 42 = "44444444444", 45 = "London Postmaster" (TFS 296019)
        // [THEN] Record B fields 38, 39 (pos 670, 686) are blanked from February 2021 (TFS 381364)
        // [THEN] Record B fields: B-30 = '1', B-31 = '0', B-40 = '0' (TFS 472473)
        LoadFile(FileName);

        // Verify line structure
        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do
            LibrarySpesometro.VerifyLine(TextFile, Index);

        // Verify content
        VerifyHeader(1);
        VerifyBRecord(2, Vendor, SigningCompanyOfficials, AmountToDeclare, VATExemption, VendorTaxRepresentative);
        VerifyFooter(3);
    end;

    [Test]
    [HandlerFunctions('DeclOfIntentReportHandler')]
    [Scope('OnPrem')]
    procedure ExportAndPrintDeclOfIntent()
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
        Vendor: Record Vendor;
        VATExemption: Record "VAT Exemption";
        SigningCompanyOfficials: Record "Company Officials";
        DeclarationOfIntentReport: Report "Declaration of Intent Report";
        AmountToDeclare: Decimal;
        ExportFlags: array[6] of Boolean;
    begin
        // [SCENARIO] Run the Declaration of Intent Report and validate its content
        Setup(CompanyInformation, VendorTaxRepresentative);

        // [GIVEN] CompanyInformation."Name" = "CRONUS Italia S.p.A."
        // [GIVEN] A VAT Exemption for a Vendor
        CreateVendor(Vendor, false);
        CreateVATExemption(VATExemption, Vendor);

        // [GIVEN] A Company Official to sign the declaration
        CreateCompanyOfficial(SigningCompanyOfficials);

        // [GIVEN] An Amount to declare
        AmountToDeclare := 1234.56;

        // [WHEN] The Declaration of Intent is exported
        ExportFlags[1] := false;
        ExportFlags[2] := false;
        ExportFlags[3] := false;
        ExportFlags[4] := false;
        ExportFlags[5] := false;
        ExportFlags[6] := false;

        DeclarationOfIntentReport.Initialize(
          'Description of Goods', SigningCompanyOfficials."No.", AmountToDeclare, 0, ExportFlags, false, '', '');
        DeclarationOfIntentReport.SetTableView(VATExemption);
        Commit();
        DeclarationOfIntentReport.Run();

        // [THEN] The content of report reflects the data in NAV, 'CustomAuthorityFlagValue' = '', Recipient data is printed for the vendor. (TFS 477441)
        // [THEN] Section "Declaration Data" field "Surname or company's name" = "CRONUS Italia S.p.A." (TFS 296019)
        VerifyDeclOfIntentReport(VATExemption, Vendor, VendorTaxRepresentative, SigningCompanyOfficials, AmountToDeclare);
        VerifyReportParameters(ExportFlags, false, '', '');
    end;

    [Test]
    [HandlerFunctions('DeclOfIntentReportHandler')]
    [Scope('OnPrem')]
    procedure ExportDeclOfIntentFromDeclOfIntentExpPageWhenUseMultipleVendors()
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
        Vendor: array[2] of Record Vendor;
        VATExemption: array[2] of Record "VAT Exemption";
        SigningCompanyOfficials: Record "Company Officials";
        VendorCard: TestPage "Vendor Card";
        VATExemptions: TestPage "VAT Exemptions";
        DeclarationOfIntentExport: TestPage "Declaration of Intent Export";
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 378206] Correct VAT Exemption used when export Declaration of Intent from "Declaration of Intent" page when use multiple vendors

        Setup(CompanyInformation, VendorTaxRepresentative);

        // [GIVEN] Vendor "A" with VAT Exemption ("Int. Registry No." = "X") and Vendor "B" with VAT Exemption ("Int. Registry No." = "Y")
        for i := 1 to ArrayLen(Vendor) do begin
            CreateVendor(Vendor[i], false);
            CreateVATExemption(VATExemption[i], Vendor[i]);
        end;
        CreateCompanyOfficial(SigningCompanyOfficials);

        // [GIVEN] "Declaration Of Intent Export" page is open with VAT Exemption for Vendor "B"
        VendorCard.OpenView();
        VendorCard.GotoRecord(Vendor[2]);
        VATExemptions.Trap();
        VendorCard."VAT E&xemption".Invoke();
        DeclarationOfIntentExport.Trap();
        VATExemptions."Export Decl. of Intent".Invoke();
        DeclarationOfIntentExport."Signing Company Officials".SetValue(SigningCompanyOfficials."No.");
        DeclarationOfIntentExport."Amount To Declare".SetValue(1234.56);
        Commit();

        // [WHEN] Export file and Print Report "Declaration Of Intent Export"
        DeclarationOfIntentExport.ExportFileAndPrintReport.Invoke();

        // [THEN] "VAT Exemption Int. Registry No." printed in report is "Y"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATExemptIntRegistryNo_Value', VATExemption[2]."VAT Exempt. Int. Registry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDeclOfIntentForCustomAuthorityVendor()
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
        Vendor: Record Vendor;
        VATExemption: Record "VAT Exemption";
        SigningCompanyOfficials: Record "Company Officials";
        DeclarationOfIntentExport: Codeunit "Declaration of Intent Export";
        FileName: Text;
        AmountToDeclare: Decimal;
        ExportFlags: array[6] of Boolean;
        Index: Integer;
    begin
        // [SCENARIO 476267] Export the Declaration of Intent for custom authority vendor
        Setup(CompanyInformation, VendorTaxRepresentative);

        // [GIVEN] CompanyInformation."Name" = "CRONUS Italia S.p.A.", "Fiscal Code" = "11111111111", "VAT Registration No." = "22222222222"
        // [GIVEN] Vendor with "Name" = "London Postmaster", "Fiscal Code" = "33333333333", "VAT Registration No." = "44444444444"
        // [GIVEN] Vendor as a Custom Authority,a VAT Exemption for a Vendor
        CreateVendor(Vendor, false);
        CreateVATExemption(VATExemption, Vendor);
        CreateCustomAuthorityVendor(Vendor."No.");

        // [GIVEN] A Company Official to sign the declaration
        CreateCompanyOfficial(SigningCompanyOfficials);

        // [GIVEN] An Amount to declare
        AmountToDeclare := 1234.56;

        // [WHEN] The Declaration of Intent is exported
        FileName := TemporaryPath + LibraryUtility.GenerateGUID() + '.ivi';
        ExportFlags[1] := false;
        ExportFlags[2] := false;
        ExportFlags[3] := false;
        ExportFlags[4] := false;
        ExportFlags[5] := false;
        ExportFlags[6] := false;
        DeclarationOfIntentExport.SetServerFileName(FileName);
        DeclarationOfIntentExport.Export(
          VATExemption, 'Description of Goods', SigningCompanyOfficials."No.", AmountToDeclare, 0, ExportFlags, false, '', '');

        // [THEN] File is exported
        // [THEN] Record B fields: B-30 = '', B-31 = '1', B-40 = '1'
        LoadFile(FileName);
        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do
            LibrarySpesometro.VerifyLine(TextFile, Index);
        VerifyHeader(1);
        VerifyBRecord(2, Vendor, SigningCompanyOfficials, AmountToDeclare, VATExemption, VendorTaxRepresentative);
        VerifyFooter(3);
    end;

    [Test]
    [HandlerFunctions('DeclOfIntentReportHandler')]
    [Scope('OnPrem')]
    procedure PrintDeclOfIntentForCustomAuthorityVendor()
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
        Vendor: Record Vendor;
        VATExemption: Record "VAT Exemption";
        SigningCompanyOfficials: Record "Company Officials";
        DeclarationOfIntentReport: Report "Declaration of Intent Report";
        AmountToDeclare: Decimal;
        ExportFlags: array[6] of Boolean;
    begin
        // [SCENARIO 477441] Print the Declaration of Intent Report for custom authority vendor
        Setup(CompanyInformation, VendorTaxRepresentative);

        // [GIVEN] CompanyInformation."Name" = "CRONUS Italia S.p.A."
        // [GIVEN] Vendor as a Custom Authority, a VAT Exemption for a Vendor
        CreateVendor(Vendor, false);
        CreateVATExemption(VATExemption, Vendor);
        CreateCustomAuthorityVendor(Vendor."No.");

        // [GIVEN] A Company Official to sign the declaration
        CreateCompanyOfficial(SigningCompanyOfficials);

        // [GIVEN] An Amount to declare
        AmountToDeclare := 1234.56;

        // [WHEN] The Declaration of Intent is printed
        ExportFlags[1] := false;
        ExportFlags[2] := false;
        ExportFlags[3] := false;
        ExportFlags[4] := false;
        ExportFlags[5] := false;
        ExportFlags[6] := false;

        DeclarationOfIntentReport.Initialize(
          'Description of Goods', SigningCompanyOfficials."No.", AmountToDeclare, 0, ExportFlags, false, '', '');
        DeclarationOfIntentReport.SetTableView(VATExemption);
        Commit();
        DeclarationOfIntentReport.Run();

        // [THEN] The dataset of then report contains 'CustomAuthorityFlagValue' = 'X'; Recipient data is empty.
        VerifyDeclOfIntentReport(VATExemption, Vendor, VendorTaxRepresentative, SigningCompanyOfficials, AmountToDeclare);
        VerifyReportParameters(ExportFlags, false, '', '');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure ExportDeclOfIntentSuggetsDeclarationAmount()
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
        Vendor: Record Vendor;
        VATExemption: Record "VAT Exemption";
        VendorCard: TestPage "Vendor Card";
        VATExemptions: TestPage "VAT Exemptions";
        DeclarationOfIntentExport: TestPage "Declaration of Intent Export";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 483095] When Exporting Declaration of Intent, the "Amount To Declare" field is prefilled with "Tax Exempt Amount"

        // [GIVEN] Initial setup of Company Information and Vendor Tax Representative
        Setup(CompanyInformation, VendorTaxRepresentative);

        // [GIVEN] Vendor "A" with VAT Exemption ("Int. Registry No." = "X")
        CreateVendor(Vendor, false);
        CreateVATExemption(VATExemption, Vendor);

        // [GIVEN] Vendor has a "Tax Exempt Amount" = XXX
        UpdateTaxExemptAmount(Vendor, LibraryRandom.RandDec(1000, 2));

        // [GIVEN] "VAT Exemptions" page is open for Vendor "B"
        VendorCard.OpenView();
        VendorCard.GotoRecord(Vendor);
        VATExemptions.Trap();
        VendorCard."VAT E&xemption".Invoke();

        // [WHEN] "Export Decl. of Intent" on "VAT Exemptions" page is invoked
        DeclarationOfIntentExport.Trap();
        VATExemptions."Export Decl. of Intent".Invoke();

        // [THEN] "Amount To Declare" is prefilled with "Tax Exempt Amount"
        DeclarationOfIntentExport."Amount To Declare".AssertEquals(Vendor."Tax Exempt Amount (LCY)");
    end;

    local procedure VerifyHeader(LineNo: Integer)
    var
        CompanyInformation: Record "Company Information";
        VendorTaxRepresentative: Record Vendor;
    begin
        CompanyInformation.Get();
        LibrarySpesometro.VerifyValue(TextFile, 'A', LineNo, 1, 1, ConstFormat::AN); // A-1
        LibrarySpesometro.VerifyValue(TextFile, PadStr(' ', 14), LineNo, 2, 14, ConstFormat::AN); // A-2
        LibrarySpesometro.VerifyValue(TextFile, 'IVI15', LineNo, 16, 5, ConstFormat::AN); // A-3

        if CompanyInformation."Tax Representative No." <> '' then begin
            VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.");
            LibrarySpesometro.VerifyValue(TextFile, '10', LineNo, 21, 2, ConstFormat::NU); // A-4
            LibrarySpesometro.VerifyValue(TextFile, VendorTaxRepresentative."Fiscal Code", LineNo, 23, 16, ConstFormat::AN);  // A-5
        end else begin
            LibrarySpesometro.VerifyValue(TextFile, '01', LineNo, 21, 2, ConstFormat::NU); // A-4
                                                                                           // Assuming the Fiscal Code is set:
            LibrarySpesometro.VerifyValue(TextFile, CompanyInformation."Fiscal Code", LineNo, 23, 16, ConstFormat::AN); // A-5
        end;

        LibrarySpesometro.VerifyValue(TextFile, PadStr(' ', 483), LineNo, 39, 483, ConstFormat::AN); // A-6
        LibrarySpesometro.VerifyValue(TextFile, PadStr(' ', 4), LineNo, 522, 4, ConstFormat::AN); // A-7
        LibrarySpesometro.VerifyValue(TextFile, PadStr(' ', 4), LineNo, 526, 4, ConstFormat::AN); // A-8
        LibrarySpesometro.VerifyValue(TextFile, PadStr(' ', 100), LineNo, 530, 100, ConstFormat::AN); // A-9
        LibrarySpesometro.VerifyValue(TextFile, PadStr(' ', 200), LineNo, 1698, 200, ConstFormat::AN); // A-11
        LibrarySpesometro.VerifyValue(TextFile, 'A', LineNo, 1898, 1, ConstFormat::AN); // A-12
    end;

    local procedure VerifyBRecord(LineNo: Integer; Vendor: Record Vendor; SigningCompanyOfficials: Record "Company Officials"; AmountToDeclare: Decimal; VATExemption: Record "VAT Exemption"; VendorTaxRepresentative: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
        B30, B31, B40 : Text[10];
    begin
        CompanyInformation.Get();
        GetCustomAuthorityValues(B30, B31, B40, Vendor.IsCustomAuthorityVendor());
        LibrarySpesometro.VerifyValue(TextFile, 'B', LineNo, 1, 1, ConstFormat::AN); // B-1
        // Assuming the Fiscal Code is set on Company Information:
        LibrarySpesometro.VerifyValue(TextFile, CompanyInformation."Fiscal Code", LineNo, 2, 16, ConstFormat::CF); // B-2
        LibrarySpesometro.VerifyValue(TextFile, '1', LineNo, 18, 8, ConstFormat::NUp); // B-3
        LibrarySpesometro.VerifyValue(TextFile, '08106710158', LineNo, 74, 16, ConstFormat::AN); // B-7
        // Assuming this is not a Supplementary Return:
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 90, 1, ConstFormat::CB); // B-8
        LibrarySpesometro.VerifyValue(TextFile, '00000000000000000', LineNo, 91, 17, ConstFormat::NU); // B-9
        LibrarySpesometro.VerifyValue(TextFile, '000000', LineNo, 108, 6, ConstFormat::NU); // B-10
        // Assuming this is not an individual person and the vendor has no Fiscal Code:
        LibrarySpesometro.VerifyValue(TextFile, CompanyInformation.Name, LineNo, 158, 60, ConstFormat::AN); // B-13
        LibrarySpesometro.VerifyValue(TextFile, CompanyInformation."VAT Registration No.", LineNo, 218, 11, ConstFormat::PI); // B-14
        LibrarySpesometro.VerifyValue(TextFile, SigningCompanyOfficials."Fiscal Code", LineNo, 280, 16, ConstFormat::CF); // B-19
        LibrarySpesometro.VerifyValue(TextFile, CompanyInformation."Fiscal Code", LineNo, 296, 11, ConstFormat::CN); // B-20
        LibrarySpesometro.VerifyValue(TextFile, SigningCompanyOfficials."Appointment Code", LineNo, 307, 2, ConstFormat::NU); // B-21
        LibrarySpesometro.VerifyValue(TextFile, SigningCompanyOfficials."Last Name", LineNo, 309, 24, ConstFormat::AN); // B-22
        LibrarySpesometro.VerifyValue(TextFile, SigningCompanyOfficials."First Name", LineNo, 333, 20, ConstFormat::AN); // B-23
        LibrarySpesometro.VerifyValue(TextFile, 'M', LineNo, 353, 1, ConstFormat::AN); // B-24
        LibrarySpesometro.VerifyValue(TextFile, SigningCompanyOfficials."Birth City", LineNo, 362, 40, ConstFormat::AN); // B-25
        LibrarySpesometro.VerifyValue(TextFile, SigningCompanyOfficials."Birth County", LineNo, 402, 2, ConstFormat::PR); // B-26
        if CompanyInformation."Phone No." = '' then
            LibrarySpesometro.VerifyValue(TextFile, '000000000000', LineNo, 404, 12, ConstFormat::AN) // B-28
        else
            LibrarySpesometro.VerifyValue(TextFile, FlatFileManagement.CleanPhoneNumber(CompanyInformation."Phone No."),
              LineNo, 404, 12, ConstFormat::AN); // B-28
        LibrarySpesometro.VerifyValue(TextFile, CompanyInformation."E-Mail", LineNo, 416, 100, ConstFormat::AN); // B-29
        LibrarySpesometro.VerifyValue(TextFile, B30, LineNo, 516, 1, ConstFormat::CB); // B-30
        LibrarySpesometro.VerifyValue(TextFile, B31, LineNo, 517, 1, ConstFormat::CB); // B-31
        LibrarySpesometro.VerifyValue(TextFile,
          Format(Date2DMY(VATExemption."VAT Exempt. Starting Date", 3)), LineNo, 518, 4, ConstFormat::NU); // B-32
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 522, 16, ConstFormat::VP); // B-33
        LibrarySpesometro.VerifyValue(
          TextFile, FlatFileManagement.FormatNum(AmountToDeclare, ConstFormat::VP), LineNo, 538, 16, ConstFormat::VP); // B-34
        LibrarySpesometro.VerifyValue(TextFile, '', LineNo, 554, 8, ConstFormat::DT); // B-35
        LibrarySpesometro.VerifyValue(TextFile, '', LineNo, 562, 8, ConstFormat::DT); // B-36
        LibrarySpesometro.VerifyValue(TextFile, 'DESCRIPTION OF GOODS', LineNo, 570, 100, ConstFormat::AN); // B-36
        LibrarySpesometro.VerifyValue(TextFile, '', LineNo, 670, 16, ConstFormat::AN); // B-38
        LibrarySpesometro.VerifyValue(TextFile, '', LineNo, 686, 4, ConstFormat::AN); // B-39
        LibrarySpesometro.VerifyValue(TextFile, B40, LineNo, 690, 1, ConstFormat::CB); // B-40
        LibrarySpesometro.VerifyValue(TextFile, Vendor."VAT Registration No.", LineNo, 691, 16, ConstFormat::CF); // B-41
        LibrarySpesometro.VerifyValue(TextFile, Vendor."VAT Registration No.", LineNo, 707, 11, ConstFormat::PI); // B-42
        LibrarySpesometro.VerifyValue(TextFile, Vendor.Name, LineNo, 762, 60, ConstFormat::AN); // B-45
        LibrarySpesometro.VerifyValue(TextFile, '1', LineNo, 823, 1, ConstFormat::CB); // B-47
        LibrarySpesometro.VerifyValue(TextFile, '1', LineNo, 824, 1, ConstFormat::NU); // B-48
        // Assuming no export flags are set:
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 825, 1, ConstFormat::CB); // B-49
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 826, 1, ConstFormat::CB); // B-50
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 827, 1, ConstFormat::CB); // B-51
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 828, 1, ConstFormat::CB); // B-52
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 829, 1, ConstFormat::CB); // B-53
        LibrarySpesometro.VerifyValue(TextFile, '0', LineNo, 830, 1, ConstFormat::CB); // B-54
        LibrarySpesometro.VerifyValue(TextFile, VendorTaxRepresentative."Fiscal Code", LineNo, 891, 16, ConstFormat::CF); // B-57
        LibrarySpesometro.VerifyValue(TextFile, FlatFileManagement.FormatDate(Today, ConstFormat::DT), LineNo, 907, 8, ConstFormat::DT); // B-58
        LibrarySpesometro.VerifyValue(TextFile, '1', LineNo, 915, 1, ConstFormat::NU); // B-59
    end;

    local procedure VerifyFooter(LineNo: Integer)
    var
        Index: Integer;
        RecordCount: array[7] of Integer;
        RecordType: Option ,A,B,C,D,E,H,Z;
        Type: Text;
    begin
        LibrarySpesometro.VerifyValue(TextFile, 'Z', LineNo, 1, 1, ConstFormat::AN);

        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do begin
            Type := '';
            Type := LibrarySpesometro.ReadValue(TextFile, Index, 1, 1);
            if Type <> '' then begin
                Evaluate(RecordType, Type);
                RecordCount[RecordType] += 1;
            end;
        end;

        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatNumber(Format(RecordCount[2]), 9), LineNo, 16, 9, ConstFormat::NU);
    end;

    local procedure Setup(var CompanyInformation: Record "Company Information"; var VendorTaxRepresentative: Record Vendor)
    begin
        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := '19988771001';
        CompanyInformation."VAT Registration No." := '19988771002';
        CompanyInformation.Name := 'CRONUS Italia S.p.A.';
        CompanyInformation.City := 'Rome';
        CompanyInformation.County := 'AG';

        LibraryPurchase.CreateVendor(VendorTaxRepresentative);
        VendorTaxRepresentative."Fiscal Code" := '1231592749271424';
        VendorTaxRepresentative."VAT Registration No." := '19283749201';
        VendorTaxRepresentative.Modify();
        CompanyInformation.Validate("Tax Representative No.", VendorTaxRepresentative."No.");
        CompanyInformation.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; IndividualPerson: Boolean)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("Individual Person", IndividualPerson);

        if IndividualPerson then begin
            Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor); // Validation of Fiscal Code is not important.
            Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
            Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
            Vendor.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
            Vendor.Validate("Birth City", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth City"), DATABASE::Vendor));
        end else
            Vendor.Validate(
              "VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor));

        Vendor.Modify(true);
    end;

    local procedure CreateVATExemption(var VATExemption: Record "VAT Exemption"; Vendor: Record Vendor)
    begin
        VATExemption.Type := VATExemption.Type::Vendor;
        VATExemption."No." := Vendor."No.";
        VATExemption."VAT Exempt. Starting Date" := WorkDate();
        VATExemption."VAT Exempt. Ending Date" := CalcDate('<+1D>', WorkDate());
        VATExemption."VAT Exempt. Int. Registry No." :=
          LibraryUtility.GenerateRandomCode(VATExemption.FieldNo("VAT Exempt. Int. Registry No."), DATABASE::"VAT Exemption");
        VATExemption."VAT Exempt. No." :=
          LibraryUtility.GenerateRandomCode(VATExemption.FieldNo("VAT Exempt. No."), DATABASE::"VAT Exemption");
        VATExemption.Insert();
    end;

    local procedure CreateCustomAuthorityVendor(VendorNo: Code[20])
    var
        CustomsAuthorityVendor: Record "Customs Authority Vendor";
    begin
        CustomsAuthorityVendor.Init();
        CustomsAuthorityVendor.Validate("Vendor No.", VendorNo);
        CustomsAuthorityVendor.Insert(true);
    end;

    local procedure GetCustomAuthorityValues(var B30: Text[10]; var B31: Text[10]; var B40: Text[10]; IsCustomAuthority: Boolean)
    begin
        if IsCustomAuthority then begin
            B30 := '';
            B31 := '1';
            B40 := '1';
        end else begin
            B30 := '1';
            B31 := '0';
            B40 := '0';
        end;
    end;

    local procedure CreateCompanyOfficial(var CompanyOfficials: Record "Company Officials")
    begin
        CompanyOfficials.Init();
        CompanyOfficials."No." := LibraryUtility.GenerateGUID();
        CompanyOfficials."First Name" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("First Name"), DATABASE::"Company Officials");
        CompanyOfficials."Last Name" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Last Name"), DATABASE::"Company Officials");
        CompanyOfficials."Fiscal Code" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Fiscal Code"), DATABASE::"Company Officials");
        CompanyOfficials."Appointment Code" := '06';
        CompanyOfficials."Date of Birth" := CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>');
        CompanyOfficials."Birth City" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Birth City"), DATABASE::"Company Officials");
        CompanyOfficials."Birth Post Code" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Birth Post Code"), DATABASE::"Company Officials");
        CompanyOfficials."Birth County" := 'RO';
        CompanyOfficials."Birth Country/Region Code" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Birth Country/Region Code"), DATABASE::"Company Officials");
        CompanyOfficials.Gender := CompanyOfficials.Gender::Male;
        CompanyOfficials.Insert();
    end;

    local procedure LoadFile(FileName: Text)
    var
        File: File;
        InStr: InStream;
    begin
        File.Open(FileName);
        File.CreateInStream(InStr);
        TextFile.Read(InStr);
    end;

    local procedure VerifyDeclOfIntentReport(VATExemption: Record "VAT Exemption"; Vendor: Record Vendor; VendorTaxRepresentative: Record Vendor; SigningCompanyOfficials: Record "Company Officials"; AmountToDeclare: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();

        VerifyDates(VATExemption);
        VerifyCompanyInfo();
        VerifyVendor(Vendor);
        VerifyVendorTaxRepresentative(VendorTaxRepresentative);
        VerifySigningCompanyOfficials(SigningCompanyOfficials);
        VerifyAmountToDeclare(AmountToDeclare);
    end;

    local procedure VerifyCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        CompanyFiscalCode: Code[20];
    begin
        CompanyInformation.Get();
        if CompanyInformation."Fiscal Code" <> '' then
            CompanyFiscalCode := CompanyInformation."Fiscal Code" // B-2
        else
            if CompanyInformation."VAT Registration No." <> '' then
                CompanyFiscalCode := CompanyInformation."VAT Registration No."; // B-2

        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoName', CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists('FiscalCode_Value', CompanyFiscalCode);
        LibraryReportDataset.AssertElementWithValueExists('VATRegNo_Value', CompanyInformation."VAT Registration No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoPhoneNo_Value', CompanyInformation."Phone No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEmail_Value', CompanyInformation."E-Mail");
    end;

    local procedure VerifyDates(VATExemption: Record "VAT Exemption")
    begin
        LibraryReportDataset.AssertElementWithValueExists(
          'VATExemptStartingDate_Year_Value', Date2DMY(VATExemption."VAT Exempt. Starting Date", 3));
    end;

    local procedure VerifyReportParameters(ExportFlagsValue: array[6] of Boolean; SupplementaryReturnValue: Boolean; TaxAuthorityReceiptsNoValue: Text[17]; TaxAuthorityDocNoValue: Text[6])
    begin
        LibraryReportDataset.AssertElementWithValueExists('AnnualVATSubmitted', ExportFlagsValue[1]);
        LibraryReportDataset.AssertElementWithValueExists('Exports', ExportFlagsValue[2]);
        LibraryReportDataset.AssertElementWithValueExists('IntraCommunitydisposals', ExportFlagsValue[3]);
        LibraryReportDataset.AssertElementWithValueExists('DisposalsSanMarino', ExportFlagsValue[4]);
        LibraryReportDataset.AssertElementWithValueExists('AssimilatedOperations', ExportFlagsValue[5]);
        LibraryReportDataset.AssertElementWithValueExists('ExtraordinaryOperations', ExportFlagsValue[6]);
        LibraryReportDataset.AssertElementWithValueExists('SupplementaryReturn_Value', SupplementaryReturnValue);
        LibraryReportDataset.AssertElementWithValueExists('TaxAuthorityReceiptsNo_Value', TaxAuthorityReceiptsNoValue);
        LibraryReportDataset.AssertElementWithValueExists('TaxAuthorityDocNo_Value', TaxAuthorityDocNoValue);
    end;

    local procedure VerifySigningCompanyOfficials(SigningCompanyOfficials: Record "Company Officials")
    begin
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsDateofBirth_Day_Value',
          Date2DMY(SigningCompanyOfficials."Date of Birth", 1));
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsDateofBirth_Month_Value',
          Date2DMY(SigningCompanyOfficials."Date of Birth", 2));
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsDateofBirth_Year_Value',
          Date2DMY(SigningCompanyOfficials."Date of Birth", 3));
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsFiscalCode_Value',
          SigningCompanyOfficials."Fiscal Code");
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsAppointmentCode_Value',
          SigningCompanyOfficials."Appointment Code");
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsBirthCity_Value',
          SigningCompanyOfficials."Birth City");
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsBirthCounty_Value',
          CopyStr(SigningCompanyOfficials."Birth County", 1, 3));
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsLastName_Value',
          SigningCompanyOfficials."Last Name");
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsFirstName_Value',
          SigningCompanyOfficials."First Name");
        LibraryReportDataset.AssertElementWithValueExists('SigningCompanyOfficialsGender_Value',
          CopyStr(Format(SigningCompanyOfficials.Gender), 1, 1));
    end;

    local procedure VerifyAmountToDeclare(AmountToDeclare: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists('AmountToDeclare_Value', AmountToDeclare);
    end;

    local procedure VerifyVendor(Vendor: Record Vendor)
    var
        VendorFiscalCode: Code[20];
        VendorName: Text;
        VendorFirstName: Text;
        VendorGender: Code[1];
        VendorCustomAuthorityFlag: Text[10];
        VendorVATRegNo: Text[20];
    begin
        if not Vendor.IsCustomAuthorityVendor() then
            if Vendor."Fiscal Code" <> '' then
                VendorFiscalCode := Vendor."Fiscal Code" // B-41
            else
                if Vendor."VAT Registration No." <> '' then
                    VendorFiscalCode := Vendor."VAT Registration No."; // B-41

        if not Vendor.IsCustomAuthorityVendor() and (Vendor."Last Name" <> '') then begin
            VendorFirstName := Vendor."First Name";
            VendorName := Vendor."Last Name";
            VendorGender := GetVendorGender(Vendor);
        end else begin
            VendorName := Vendor.Name;
            VendorFirstName := '';
            VendorGender := '';
        end;

        if Vendor.IsCustomAuthorityVendor() then begin
            VendorCustomAuthorityFlag := 'X';
            VendorVATRegNo := '';
        end else begin
            VendorCustomAuthorityFlag := '';
            VendorVATRegNo := Vendor."VAT Registration No.";
        end;

        LibraryReportDataset.AssertElementWithValueExists('VendorFiscalCode_Value', VendorFiscalCode);
        LibraryReportDataset.AssertElementWithValueExists('VendorGender_Value', VendorGender);
        LibraryReportDataset.AssertElementWithValueExists('VendorLastName', VendorName);
        LibraryReportDataset.AssertElementWithValueExists('VendorFirstName', VendorFirstName);
        LibraryReportDataset.AssertElementWithValueExists('VendoRVATRegNo_Value', VendorVATRegNo);
        LibraryReportDataset.AssertElementWithValueExists('CustomAuthorityFlagValue', VendorCustomAuthorityFlag);
    end;

    local procedure VerifyVendorTaxRepresentative(VendorTaxRepresentative: Record Vendor)
    var
        VendorTaxRepresentativeVATRegNo: Code[20];
    begin
        if VendorTaxRepresentative."Fiscal Code" <> '' then
            VendorTaxRepresentativeVATRegNo := VendorTaxRepresentative."Fiscal Code" // B-57
        else
            if VendorTaxRepresentative."VAT Registration No." <> '' then
                VendorTaxRepresentativeVATRegNo := VendorTaxRepresentative."VAT Registration No."; // B-57

        LibraryReportDataset.AssertElementWithValueExists('VendorTaxRepresentativeVATRegNo_Value', VendorTaxRepresentativeVATRegNo);
    end;

    local procedure UpdateTaxExemptAmount(var Vendor: Record Vendor; Amount: Decimal)
    begin
        Vendor.Validate("Tax Exempt Amount (LCY)", Amount);
        Vendor.Modify(true);
    end;

    local procedure GetVendorGender(Vendor: Record Vendor): Code[1]
    begin
        if Vendor.Gender = Vendor.Gender::Male then
            exit('M'); // B-46

        exit('F'); // B-46
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeclOfIntentReportHandler(var DeclarationOfIntentRequestPage: TestRequestPage "Declaration of Intent Report")
    begin
        DeclarationOfIntentRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

