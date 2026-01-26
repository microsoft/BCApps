codeunit 144021 "IT - CU 2015 Unit Test"
{
    // // [FEATURE] [CU2015] [Export] [Withholding Tax]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileMgt: Codeunit "File Management";
        TextFile: BigText;
        CommunicationNumber: Integer;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        WrongRecordFoundErr: Label 'Wrong record found.';
        EmptyFieldErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        BaseExcludedAmountTotalErr: Label 'Base - Excluded Amount total on lines for Withholding Tax Entry No. = %1 must be equal to Base - Excluded Amount on the Withholding Tax card for that entry (%2).', Comment = '%1=Entry number,%2=Amount.';
        IsInitialized: Boolean;
        CURTxt: Label 'CUR%1', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithoutSigningOfficial()
    var
        VendorNo: Code[20];
    begin
        Initialize();

        VendorNo := CreateVendor();

        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        asserterror Export('');

        Assert.ExpectedError('You need to specify a Signing Company Official');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportEmptyTable()
    var
        SigningCompanyOfficialNo: Code[20];
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(
          StrSubstNo('There were no Withholding Tax entries for the year %1.', Format(Date2DMY(WorkDate(), 3))));
        SigningCompanyOfficialNo := CreateCompanyOfficial();
        Export(SigningCompanyOfficialNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleEntry()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
        EntryNo: Integer;
        NonTaxableAmountByTreaty: Decimal;
    begin
        // [SCENARIO 228176] Export Withholding Tax should correctly fill all fields
        Initialize();

        // [GIVEN] Vendor "V"
        VendorNo := CreateVendor();

        // [GIVEN] Withholding Tax "WT" for "V"
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();

        // [GIVEN] Set non-zero "WT"."Non Taxable Amount By Treaty"
        NonTaxableAmountByTreaty := LibraryRandom.RandDec(100, 2);
        SetWithholdingTaxNonTaxableAmountByTreaty(EntryNo, NonTaxableAmountByTreaty);

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] All fields are filled
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
        ValidateBlockValue(4, 'AU001005', ConstFormat::VP, NonTaxableAmountByTreaty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleEntryNonResidentVendor()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
        EntryNo: Integer;
        NonTaxableAmountByTreaty: Decimal;
    begin
        // [SCENARIO 228176] Export Withholding Tax with Non-Resident Vendor should not write "Non Taxable Amount By Treaty" in the 'AU001005' field
        Initialize();

        // [GIVEN] Vendor "V" with Resident = "Non-Resident"
        VendorNo := CreateNonResidentVendorNo();

        // [GIVEN] Withholding Tax for "V" with "Non Taxable Amount By Treaty"
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();

        // [GIVEN] Set non-zero "WT"."Non Taxable Amount By Treaty"
        NonTaxableAmountByTreaty := LibraryRandom.RandDec(100, 2);
        SetWithholdingTaxNonTaxableAmountByTreaty(EntryNo, NonTaxableAmountByTreaty);

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] No 'AU001005' field in the exported file
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
        ValidateBlockValue(4, 'AU001005', ConstFormat::VP, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesWithSameReason()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        Initialize();

        VendorNo := CreateVendor();

        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();
        Filename := Export(SigningCompanyOfficialNo);

        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntiesWithDifferentReason()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        Initialize();

        VendorNo := CreateVendor();

        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::B, 0, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();
        Filename := Export(SigningCompanyOfficialNo);

        LoadFile(Filename);
        // Bug id 438543: A "0" char must be exported on the 527 position for the header's line
        ValidateHeader(SigningCompanyOfficialNo);
        ValidateRecordDAndH(VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::A, 3, '', WithholdingTax."Non-Taxable Income Type"::"1", 1);
        ValidateRecordDAndH(VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::B, 5, '', WithholdingTax."Non-Taxable Income Type"::"1", 2);
        ValidateFooter(7, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithTaxRepresentative()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        Initialize();

        VendorNo := CreateVendor();

        CreateTaxRepresentative();
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();
        Filename := Export(SigningCompanyOfficialNo);

        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ErrorPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesDiffPeriodsWithEmptyReason()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        WHTEntryNo: Integer;
    begin
        // [SCENARIO 376054] Export Withholdind Tax in current and previous periods with empty Reason should generate an error for the current period only
        Initialize();
        VendorNo := CreateVendor();

        // [GIVEN] Withholding Tax for current and previous periods with Reason = ""
        WHTEntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::" ", 0, WorkDate(), WorkDate());
        // Make sure Confirm is raised 
        WithholdingTax.Get(CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::" ", -1, WorkDate(), WorkDate()));
        if WithholdingTax."Withholding Tax Amount" <= WithholdingTax."Taxable Base" + 1 then begin
            WithholdingTax."Withholding Tax Amount" := WithholdingTax."Taxable Base" + 2;
            WithholdingTax.Modify();
        end;

        SigningCompanyOfficialNo := CreateCompanyOfficial();

        // [WHEN] Run Withholding Tax Export
        LibraryVariableStorage.Enqueue(WHTEntryNo);
        LibraryVariableStorage.Enqueue(WithholdingTax.FieldCaption(Reason));
        Export(SigningCompanyOfficialNo);

        // [THEN] Error log shows Error Message for empty Reason for current period
        // [THEN] No error shown for previous period
        // verification is done inside ErrorPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesPreviousPeriodWithEmptyReason()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 376054] Export Withholdind Tax in current period and previous period with empty Reason
        Initialize();
        VendorNo := CreateVendor();

        // [GIVEN] Withholding Tax for current period with Reason = "A" and previous period with Reason Code = ""
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::" ", -1, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] File exported with record for current period with Reason "A"
        // [THEN] Footer shows 1 record as total count
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesDiffPeriodsDiffReason()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 376054] Export Withholdind Tax in current and previous periods with different Reason
        Initialize();
        VendorNo := CreateVendor();

        // [GIVEN] Withholding Tax for current period with Reason Code = "A" and previous period with Reason Code = "B"
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::B, -1, WorkDate(), WorkDate());
        SigningCompanyOfficialNo := CreateCompanyOfficial();

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] File exported with record for current period with Reason "A"
        // [THEN] Footer shows 1 record as total count
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPreviousYearEntries()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
        EntryNo: Integer;
    begin
        // [SCENARIO 380480] If Related Date of withholding tax entries is not equal to the year specified in Certificazione Unica declatation export, then these entries should not be included in AU001018 and AU001019 parameters of line H

        Initialize();

        // [GIVEN] Withholding tax entry with Related Date in current year (e.g. the year 2018)
        VendorNo := CreateVendor();
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());

        // [GIVEN] Withholding tax entry with Related Date in previous year (e.g. the year 2017)
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), CalcDate('<-1Y>', WorkDate()));
        WithholdingTax.Get(EntryNo);

        SigningCompanyOfficialNo := CreateCompanyOfficial();

        // [WHEN] Export Certificazione Unica declatation
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] Exported file does not contain the value in AU001018 and AU001019 of H-line
        LoadFile(Filename);
        asserterror ValidateBlockValue(4, 'AU001018', ConstFormat::VP, Format(WithholdingTax."Taxable Base")); // Check AU001018 in H-line
        Assert.ExpectedError(
          StrSubstNo('Assert.AreEqual failed. Expected:<%1> (Text). Actual:<> (Text).', WithholdingTax."Taxable Base"));

        ValidateBlockValue(4, 'AU001019', ConstFormat::VP, ''); // Check AU001019 in H-line
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReplaceAU001019ByTaxableBase()
    var
        WithholdingTax: Record "Withholding Tax";
        Filename: Text;
    begin
        // [SCENARIO 380698] If "Withholding Tax Amount" > TempWithholdingTaxPrevYears."Taxable Base" + 1 in Withholding Tax record and user accepts replacement, then AU001019 should contain "Taxable Base"

        Initialize();

        // [GIVEN] Withholding tax entry 1 with Related Date in current year (e.g. the year 2018)
        // [GIVEN] Withholding tax entry 2 with Related Date in previous year (e.g. the year 2017)
        // [GIVEN] Withholding tax entry 2 has "Withholding Tax Amount" bigger than WithholdingTax."Taxable Base" + 1
        CreateWithholdingTaxInCurrentAndPreviousYears(WithholdingTax);

        // [GIVEN] Export Certificazione Unica declatation
        // [WHEN] Reply "Yes" to "Do you want to replace the witholding tax amount with the maximum allowed?"
        Filename := ExportCertificazioneUnica(); // Meets ConfirmHandlerYes

        // [THEN] Exported file contains the value of Withholding tax entry 2 "Taxable Base" in AU001019 of H-line
        LoadFile(Filename);
        ValidateBlockValue(4, 'AU001019', ConstFormat::VP, WithholdingTax."Taxable Base"); // Check AU001019 in H-line
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure FillAU001019ByWithholdingTaxAmount()
    var
        WithholdingTax: Record "Withholding Tax";
        Filename: Text;
    begin
        // [SCENARIO 380698] If "Withholding Tax Amount" > TempWithholdingTaxPrevYears."Taxable Base" + 1 in Withholding Tax record and user does not accept replacement, then AU001019 should contain "Withholding Tax Amount"

        Initialize();

        // [GIVEN] Withholding tax entry 1 with Related Date in current year (e.g. the year 2018)
        // [GIVEN] Withholding tax entry 2 with Related Date in previous year (e.g. the year 2017)
        // [GIVEN] Withholding tax entry 2 has "Withholding Tax Amount" bigger than WithholdingTax."Taxable Base" + 1
        CreateWithholdingTaxInCurrentAndPreviousYears(WithholdingTax);

        // [GIVEN] Export Certificazione Unica declatation
        // [WHEN] Reply "No" to "Do you want to replace the witholding tax amount with the maximum allowed?"
        Filename := ExportCertificazioneUnica(); // Meets ConfirmHandlerNo

        // [THEN] Exported file contains the value of Withholding tax entry 2 "Withholding Tax Amount" in AU001019 of H-line
        LoadFile(Filename);
        ValidateBlockValue(4, 'AU001019', ConstFormat::VP, WithholdingTax."Withholding Tax Amount"); // Check AU001019 in H-line
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxReasonCodeOptionZO()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        WithholdingTax: Record "Withholding Tax";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 219573] WithholdingTax."Reason" option has value "ZO"

        // TAB 12113 "Tmp Withholding Contribution"
        TmpWithholdingContribution.Init();
        TmpWithholdingContribution.Validate(Reason, TmpWithholdingContribution.Reason::ZO);
        Assert.AreEqual('ZO', Format(TmpWithholdingContribution.Reason), '');

        // TAB 12116 "Withholding Tax"
        WithholdingTax.Init();
        WithholdingTax.Validate(Reason, WithholdingTax.Reason::ZO);
        Assert.AreEqual('ZO', Format(WithholdingTax.Reason), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxReasonCodeOptionGHI()
    var
        WithholdingTax: Record "Withholding Tax";
        VendorNo: Code[20];
        SigningCompanyOfficialNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 223885] Record H in exported file contains field AU001002 only for reasons "G", "H", "I". Value of field AU001002 must be less then the year of the declaration.
        // [SCENARIO 233814] Export file with 4 different values of AU001006
        Initialize();

        // [GIVEN] Withholding tax entry with Reason = "G" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 1 in Withholding Tax
        VendorNo := CreateVendor();
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, "Withholding Tax Reason"::G, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"1");

        // [GIVEN] Withholding tax entry with Reason = "H" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 2 in Withholding Tax
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, "Withholding Tax Reason"::H, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"2");

        // [GIVEN] Withholding tax entry with Reason = "I" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 5 in Withholding Tax
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, "Withholding Tax Reason"::I, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"5");

        // [GIVEN] Withholding tax entry with Reason = "ZO" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 6 in Withholding Tax
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, "Withholding Tax Reason"::ZO, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"6");

        // [WHEN] Export withholding taxes
        SigningCompanyOfficialNo := CreateCompanyOfficial();
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] File contains Records H
        LoadFile(Filename);
        ValidateHeader(SigningCompanyOfficialNo);

        // [THEN] Record with "AU001001" = "G", field "AU001002" = 2016, "AU001006" = 1
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::G, 3, Format(Date2DMY(WorkDate(), 3) - 1),
          WithholdingTax."Non-Taxable Income Type"::"1", 1);

        // [THEN] Record with "AU001001" = "H", field "AU001002" = 2016, "AU001006" = 2
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::H, 5, Format(Date2DMY(WorkDate(), 3) - 1),
          WithholdingTax."Non-Taxable Income Type"::"2", 2);

        // [THEN] Record with "AU001001" = "I", field "AU001002" = 2016, "AU001006" = 5
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::I, 7, Format(Date2DMY(WorkDate(), 3) - 1),
          WithholdingTax."Non-Taxable Income Type"::"5", 3);

        // [THEN] Record with "AU001001" = "ZO", without field "AU001002", "AU001006" = 6
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::ZO, 9, '', WithholdingTax."Non-Taxable Income Type"::"6", 4);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenExportWithholdingTaxWithEmptyNonTaxableIncomeType()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        WHTEntryNo: Integer;
    begin
        // [SCENARIO 233814] Error when export file with empty "Non-Taxable Income Type" in "Withholding Tax"
        Initialize();

        // [GIVEN] Withholding tax entry with Non-Taxable Income Type" = " "
        VendorNo := CreateVendor();
        WHTEntryNo :=
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" ");

        // [WHEN] Export withholding taxes
        SigningCompanyOfficialNo := CreateCompanyOfficial();
        LibraryVariableStorage.Enqueue(WHTEntryNo);
        LibraryVariableStorage.Enqueue(WithholdingTax.FieldCaption("Non-Taxable Income Type"));
        Export(SigningCompanyOfficialNo);

        // [THEN] Error log shows Error Message for empty Non-Taxable Income Type
        // Verification is done inside ErrorPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithholdingTaxWithSplitBaseExcludedValue()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: array[2] of Record "Withholding Tax Line";
        FileName: Text;
        LineNo: Integer;
    begin
        // [SCENARIO 350177] Base - Excluded amount split in two lines with different Non-taxable income type is correctly exported in two separate lines
        Initialize();

        // [GIVEN] Withholding tax entry with Non-Taxable Income Type" = " " and Base - Excluded amount = "X+Y"
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        WithholdingTax."Base - Excluded Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Non Taxable Amount By Treaty" := 0;
        WithholdingTax.Modify();

        // [GIVEN] Created Withholding tax lines for entry. Line 1 = Amount X and Non-taxable income type 1
        // [GIVEN] Line 2 = Amount Y and Non-taxable income type 2
        CreateBaseExcludedSplit(WithholdingTaxLine, WithholdingTax."Entry No.");

        // [WHEN] Run "Withholding tax export" codeunit
        FileName := Export(CreateCompanyOfficial());

        // [THEN] In the report there are 2 RecordH lines corresponding to Withholding Tax Entry, we skip 3 header lines
        LoadFile(FileName);
        LineNo := 4;

        // [THEN] First line has Total Amount = Withholding Tax Entry Total amount, Base Excluded Amount = X + WHT Entry Non-Taxable Amount and Non-taxable income type 1
        ValidateAmountsInRecordH(WithholdingTaxLine[1], WithholdingTax."Total Amount", WithholdingTax."Non Taxable Amount", LineNo);

        // [THEN] Second line has Total Amount = 0, Base Excluded Amount = Y and Non-Taxable income type 2
        // TFS ID 430480: Withholding taxes with different non taxable income type has a single D record and multiple H records
        ValidateAmountsInRecordH(WithholdingTaxLine[2], 0, 0, LineNo + 1);

        // Cleanup
        WithholdingTaxLine[1].Delete();
        WithholdingTaxLine[2].Delete();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ErrorPageHandlerWithExpectedErrorMessage')]
    [Scope('OnPrem')]
    procedure ExportWithholdingTaxWithSplitBaseExcludedValueErrorOnWrongAmount()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: array[2] of Record "Withholding Tax Line";
    begin
        // [SCENARIO 350177] Base - Excluded amount split in two lines with different Non-taxable income type is correctly exported in two separate lines
        Initialize();

        // [GIVEN] Withholding tax entry with Non-Taxable Income Type" = " " and Base - Excluded amount = "X+Y"
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Created Withholding tax lines for entry. Line 1 = Amount X and Non-taxable income type 1
        // [GIVEN] Line 2 = Amount Y + 50 and Non-taxable income type 2
        WithholdingTax."Base - Excluded Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Non Taxable Amount By Treaty" := 0;
        WithholdingTax.Modify();

        CreateBaseExcludedSplit(WithholdingTaxLine, WithholdingTax."Entry No.");
        WithholdingTaxLine[2]."Base - Excluded Amount" := WithholdingTaxLine[2]."Base - Excluded Amount" + LibraryRandom.RandDec(50, 2);
        WithholdingTaxLine[2].Modify();

        // [WHEN] Run "Withholding tax export" codeunit
        LibraryVariableStorage.Enqueue(StrSubstNo(
            BaseExcludedAmountTotalErr, WithholdingTax."Entry No.", WithholdingTax."Base - Excluded Amount"));
        Export(CreateCompanyOfficial());

        // [THEN] Error for Base - Excluded Amount is shown.
        // Validated in ErrorPageHandlerWithExpectedErrorMessage
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        WithholdingTaxLine[1].Delete();
        WithholdingTaxLine[2].Delete();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxDrilldownOpensWithholdingTaxLines()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page opens on Base - Excluded Amount drilldown in Withholding Tax Card
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User clicks on "Base - Excluded amount" drilldown
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // UI Handled by WithholdingTaxLinesModalPageHandler

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WithholdingTaxDrilldownConfirmYesOnNonEmptyNonTaxableIncomeType()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] If Non-taxable income type is not empty, confirm will pop up on Base - Excluded Amount drilldown in Withholding Tax Card
        // User presses Yes - Withholding tax lines page opens
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"7"));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User clicks on "Base - Excluded amount" drilldown
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // UI Handled by WithholdingTaxLinesModalPageHandler

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure WithholdingTaxDrilldownConfirmNoOnNonEmptyNonTaxableIncomeType()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] If Non-taxable income type is not empty, confirm will pop up on Base - Excluded Amount drilldown in Withholding Tax Card
        // User presses No - Withholding tax lines page opens
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"7"));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User clicks on "Base - Excluded amount" drilldown
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page doesn't open

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithCheckTotal')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesDisplaysWithholdingTaxTotal()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page displays correct Withholding Tax Card total
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty and Base - ExcludedAmount = X
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // Total amount validated in WithholdingTaxLinesModalPageHandlerWithCheckTotal handler
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithLineEntry,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesWarningOnClosingWithWrongTotal()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page will warn user that amount total is not correct when closing page
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty and Base - ExcludedAmount = X
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount" + LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(WithholdingTax."Non-Taxable Income Type"::"6");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [WHEN] Withholding tax lines page opens Line is entered with a non-taxable income type and amount = X + 100
        // UI is handled by WithholdingTaxLinesModalPageHandlerWithLineEntry
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Closing Withholding tax page a confirm pops up with warning
        // UI is handled by ConfirmHandlerYes

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithCorrectSplit')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesSplitInTwoLinesWithCorrectTotal()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: Record "Withholding Tax Line";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page will successfully close and create lines when split total correctly
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty and Base ExcludedAmount = X
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        WithholdingTax."Base - Excluded Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Non Taxable Amount By Treaty" := 0;
        WithholdingTax.Modify();

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [WHEN] Withholding tax lines page opens. User splits the total amount of X correctly into two lines
        // UI is handled by WithholdingTaxLinesModalPageHandlerWithCorrectSplit
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Page closes with no warning. Two lines are created.
        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", WithholdingTax."Entry No.");
        Assert.RecordCount(WithholdingTaxLine, 2);

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    procedure ExceptionalEventFieldNotMandatory()
    var
        WithholdingTaxExport: Codeunit "Withholding Tax Export";
        Filename: Text;
        Date: Date;
    begin
        // [SCENARIO 413573] "Exceptional Event" field is not mandatory when Export function is run from Withholding Tax Export codeunit.
        Initialize();

        // [GIVEN] Withholding Tax for 2021 year.
        Date := DMY2Date(1, 1, LibraryRandom.RandIntInRange(2020, 2030));
        CreateWithholdingTaxAndContributionEntry(CreateVendor(), "Withholding Tax Reason"::A, 0, Date, Date);

        // [WHEN] Run Export function of Withholding Tax Export codeunit with blank "Exceptional Event" field.
        Filename := FileMgt.ServerTempFileName('.dcm');
        WithholdingTaxExport.SetServerFileName(Filename);
        WithholdingTaxExport.Export(Date2DMY(Date, 3), CreateCompanyOfficial(), 1, 0, '');

        // [THEN] File is created. Record B Field 17 = "  " (two spaces).
        LoadFile(Filename);
        Assert.AreEqual('  ', LibrarySpesometro.ReadValue(TextFile, 2, 309, 2), '');
    end;

    [Test]
    procedure ForeignIndividualMaleVendor()
    var
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        WithholdingTaxExport: Codeunit "Withholding Tax Export";
        Date: Date;
        ExceptionalEventCode: Code[10];
        Filename: Text;
    BEGIN
        // [SCENARIO 397347] Foreign individual male vendor export
        Initialize();

        // [GIVEN] Foreign individual male person vendor with ISO country code = "123"
        Vendor.Get(CreateVendor());
        Vendor.TestField(Gender, Vendor.Gender::Male);
        CountryRegion.Get(Vendor."Country/Region Code");
        CountryRegion.TestField("ISO Numeric Code");

        // [GIVEN] Withholding Tax for 2021 year
        Date := DMY2Date(1, 1, LibraryRandom.RandIntInRange(2020, 2030));
        CreateWithholdingTaxAndContributionEntry(Vendor."No.", "Withholding Tax Reason"::A, 0, Date, Date);

        // [WHEN] Export Withholding Tax using Year = "2021", Exceptional Event = "12"
        ExceptionalEventCode := Format(LibraryRandom.RandIntInRange(10, 20));
        Filename := TemporaryPath() + LibraryUtility.GenerateGUID() + '.dcm';
        WithholdingTaxExport.SetServerFileName(Filename);
        WithholdingTaxExport.Export(Date2DMY(Date, 3), CreateCompanyOfficial(), 1, 0, ExceptionalEventCode);

        // [THEN] Record A Field 3 = "CUR22"
        // [THEN] Record B Field 17 = "12"
        // [THEN] Record B Field 24 = "1"
        // [THEN] Record D Field DA002004 = "M"
        // [THEN] Record D Field DA002011 = "123"
        LoadFile(Filename);
        ValidateTextFileValue(1, 16, 5, StrSubstNo(CURTxt, Date2DMY(Date, 3) mod 100 + 1));
        ValidateTextFileValue(2, 309, 2, ExceptionalEventCode);
        ValidateTextFileValue(2, 402, 8, '00000001');
        ValidateBlockValue(3, 'DA002004', ConstFormat::AN, 'M');
        ValidateBlockValue(3, 'DA002011', ConstFormat::AN, CountryRegion."ISO Numeric Code");
    end;

    [Test]
    procedure ForeignIndividualFemaleVendor()
    var
        Vendor: Record Vendor;
    BEGIN
        // [SCENARIO 397347] Foreign individual female vendor export
        Initialize();

        // [GIVEN] Foreign individual female person vendor
        Vendor.Get(CreateVendor());
        Vendor.Validate(Gender, Vendor.Gender::Female);
        Vendor.Modify(true);

        // [GIVEN] Withholding Tax
        CreateWithholdingTaxAndContributionEntry(Vendor."No.", "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());

        // [WHEN] Export Withholding Tax
        LoadFile(Export(CreateCompanyOfficial()));

        // [THEN] Record D Field DA002004 = "F"
        ValidateBlockValue(3, 'DA002004', ConstFormat::AN, 'F');
    end;

    [Test]
    procedure DomesticCompanyVendor()
    var
        Vendor: Record Vendor;
    BEGIN
        // [SCENARIO 397347] Domestic company vendor export
        Initialize();

        // [GIVEN] Domestic vendor with "Individual Person" = False
        Vendor.Get(LibrarySpesometro.CreateVendor(false, Vendor.Resident::Resident, false, true));
        Vendor.Validate("Country/Region Code", '');
        Vendor.Modify();

        CreateWithholdingTaxAndContributionEntry(Vendor."No.", "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());

        // [WHEN] Export Withholding Tax
        LoadFile(Export(CreateCompanyOfficial()));

        // [THEN] Record D Field DA002004 is not exported
        // [THEN] Record D Field DA002011 is not exported
        ValidateBlockValue(3, 'DA002004', ConstFormat::AN, '');
        ValidateBlockValue(3, 'DA002011', ConstFormat::AN, '');
    end;

    [Test]
    procedure WithholdingTaxExportGroupsEmptyNonTaxableIncomeTypeWithFirstNonEmpty()
    var
        WithholdingTax: Record "Withholding Tax";
        VendorNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 416538] Withholding tax export groups empty non-taxable income type entries with the first non-empty one
        Initialize();

        // [GIVEN] Vendor
        VendorNo := CreateVendor();

        // [GIVEN] Withholding tax entry 1 with "Non-Taxable Income Type" = " "
        CreateWithholdingTaxWithAU001006WithEmptyNonTaxable(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());

        // [GIVEN] Withholding tax entry 2 with "Non-Taxable Income Type" = 2
        CreateWithholdingTaxWithAU001006(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::"2");

        // [GIVEN] Withholding Tax entry 3 with "Non-Taxable Income Type" = " "
        CreateWithholdingTaxWithAU001006WithEmptyNonTaxable(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());

        // [WHEN] Export withholding taxes
        Filename := Export(CreateCompanyOfficial());

        // [THEN] File contains Records H
        LoadFile(Filename);

        // [THEN] All three records are grouped into one, so footer has number of D records = 1
        ValidateFooter(5, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxExportGroupTotalsInTheFirstHRecord()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: array[3] of Record "Withholding Tax Line";
        VendorNo: Code[20];
        Filename: Text;
        TotalAmount: Decimal;
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
        CombinedNonTaxableAmount: Decimal;
        CombinedNonTaxAmtByTreaty: Decimal;
        i: Integer;
    begin
        // [SCENARIO 430480] The first H record in the withholding tax export contains the totals of the "Total Amount", "Taxable Base" and "Withholding Tax Amount" of all the withholding taxes exported

        Initialize();

        // [GIVEN] Vendor
        VendorNo := CreateVendor();

        // [GIVEN] Two withholding tax with a single line that has "Non-Taxable Income Type" = "24"
        // [GIVEN] First line has "Total Amount" = 110, "Taxable Base" = 100, "Non-Taxable Amount" = 10, "Non-Taxable Amount By Treaty" = 5, "Withholding Tax Amount" = 1
        // [GIVEN] Second line has "Total Amount" = 220, "Taxable Base" = 200, "Non-Taxable Amount" = 20, "Non-Taxable Amount By Treaty" = 10, "Withholding Tax Amount" = 2
        for i := 1 to ArrayLen(WithholdingTaxLine) - 1 do begin
            WithholdingTax.Get(
              CreateWithholdingTaxWithAU001006AndContributionEntry(
                VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));
            WithholdingTax."Base - Excluded Amount" := LibraryRandom.RandDec(100, 2);
            WithholdingTax.Modify();

            CreateWithholdingTaxLine(
              WithholdingTaxLine[i], WithholdingTax."Entry No.", i * 10000,
              WithholdingTax."Base - Excluded Amount", WithholdingTax."Non-Taxable Income Type"::"24");
            TotalAmount += WithholdingTax."Total Amount";
            TaxableBase += WithholdingTax."Taxable Base";
            WithholdingTaxAmount += WithholdingTax."Withholding Tax Amount";
            CombinedNonTaxableAmount += WithholdingTax."Non Taxable Amount";
            CombinedNonTaxAmtByTreaty += WithholdingTax."Non Taxable Amount By Treaty";
        end;

        // [GIVEN] Third withholding tax with a single line that has "Non-Taxable Income Type" = "6", "Total Amount" = 330, "Taxable Base" = 300,
        // [GIVEN] "Non-Taxable Amount" = 30, "Non-Taxable Amount By Treaty" = 15, "Withholding Tax Amount" = 3
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" "));

        WithholdingTax."Base - Excluded Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax.Modify();

        CreateWithholdingTaxLine(
          WithholdingTaxLine[3], WithholdingTax."Entry No.", 30000,
          WithholdingTax."Base - Excluded Amount", WithholdingTax."Non-Taxable Income Type"::"6");
        TotalAmount += WithholdingTax."Total Amount";
        TaxableBase += WithholdingTax."Taxable Base";
        WithholdingTaxAmount += WithholdingTax."Withholding Tax Amount";

        // [WHEN] Export withholding taxes
        Filename := Export(CreateCompanyOfficial());

        // [THEN] File contains Records H
        LoadFile(Filename);

        // [THEN] The exported file has in total one D record and two H records
        ValidateFooterOfDAndHRecords(6, 2, 1);

        // [THEN] First H line has AU001004 equals the total Amount of all lines (660), AU001005 equals "Non-Taxable Amount By Treaty" of the third withholding tax line (15)
        // [THEN] AU001006 equals "Non-Taxable Income Type" of the third withholding tax line (6)
        // [THEN] AU001007 equals the the amount and non-taxable amount of the third withholding tax line (300 + 30 = 330)
        // [THEN] AU001008 equals the total base of all lines (600)
        // [THEN] AU001008 equals the total withholding tax amount of all lines (6)
        ValidateBlockValueOfStrictPosition(4, 'AU001004', ConstFormat::VP, TotalAmount, 114);
        ValidateBlockValueOfStrictPosition(4, 'AU001005', ConstFormat::VP, WithholdingTax."Non Taxable Amount By Treaty", 138);
        ValidateBlockValueOfStrictPosition(4, 'AU001006', ConstFormat::NP, Format(WithholdingTaxLine[3].GetNonTaxableIncomeTypeNumber()), 162);
        ValidateBlockValueOfStrictPosition(
          4, 'AU001007', ConstFormat::VP, WithholdingTaxLine[3]."Base - Excluded Amount" + WithholdingTax."Non Taxable Amount", 186);
        ValidateBlockValueOfStrictPosition(4, 'AU001008', ConstFormat::VP, TaxableBase, 210);
        ValidateBlockValueOfStrictPosition(4, 'AU001009', ConstFormat::VP, WithholdingTaxAmount, 234);

        // [THEN] Second H line has no AU001004, AU001008 and AU001009
        // [THEN] AU001005 equals the total non-taxable amount by treaty of the first and second lines (5 + 10 = 15)
        // [THEN] AU001006 equals the sum of the total amount and non-taxable amount (300 + 30 = 330)
        ValidateBlockAbsence(5, 'AU001004');
        // Tfs Id 457147: A record does not contain blank reason and total amount values
        ValidateBlockValueOfStrictPosition(5, 'AU001005', ConstFormat::VP, CombinedNonTaxAmtByTreaty, 90);
        ValidateBlockValueOfStrictPosition(5, 'AU001006', ConstFormat::NP, Format(WithholdingTaxLine[1].GetNonTaxableIncomeTypeNumber()), 114);
        ValidateBlockValueOfStrictPosition(
          5, 'AU001007', ConstFormat::VP,
          WithholdingTaxLine[1]."Base - Excluded Amount" + WithholdingTaxLine[2]."Base - Excluded Amount" +
          CombinedNonTaxableAmount, 138);
        ValidateBlockAbsence(5, 'AU001008');
        ValidateBlockAbsence(5, 'AU001009');
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithCheckTotal')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesDisplaysWithholdingTaxTotalForNextRec()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
        WithHoldENtryNo: array[2] of Decimal;
        NewDate: Date;
        VednorNo: Code[20];
    begin
        // [SCENARIO 441140] The Total Base - Excluded Amount Header field of the Withholding Tax Card always takes the amount from the first withholding tax card inserted in the Italian version.
        Initialize();

        // [GIVEN] Create Vendor and set Date
        VednorNo := CreateVendor();
        NewDate := CalcDate('1M', WorkDate());

        //[GIVEN] Create 2 WithHold Tax entry with Lines.
        WithHoldENtryNo[1] := CreateWithholdingTaxWithAU001006AndContributionEntry(
            VednorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate(), WithholdingTax."Non-Taxable Income Type"::" ");
        WithHoldENtryNo[2] := CreateWithholdingTaxWithAU001006AndContributionEntry(
            VednorNo, "Withholding Tax Reason"::A, 0, NewDate, NewDate, WithholdingTax."Non-Taxable Income Type"::" ");

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(WithHoldENtryNo[2]);

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // [VERIFY] Total amount validated in WithholdingTaxLinesModalPageHandlerWithCheckTotal handler
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    local procedure Initialize()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: Record "Withholding Tax Line";
        Contributions: Record Contributions;
    begin
        WithholdingTax.DeleteAll();
        WithholdingTaxLine.DeleteAll();
        Contributions.DeleteAll();
        CommunicationNumber := LibraryRandom.RandIntInRange(1, 99999999);

        if IsInitialized then
            exit;

        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := LibraryUtility.GenerateGUID();
        CompanyInformation.County := LibraryUtility.GenerateGUID();
        CompanyInformation."Office Code" := 'abc';
        CompanyInformation.Modify();
        Commit();

        IsInitialized := true;
    end;

    local procedure CreateBaseExcludedSplit(var WithholdingTaxLine: array[2] of Record "Withholding Tax Line"; WHTEntryNo: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.Get(WHTEntryNo);
        CreateWithholdingTaxLine(
          WithholdingTaxLine[1], WHTEntryNo, 10000,
          Round(WithholdingTax."Base - Excluded Amount" / 3), WithholdingTax."Non-Taxable Income Type"::"5");
        CreateWithholdingTaxLine(
          WithholdingTaxLine[2], WHTEntryNo, 20000,
          WithholdingTax."Base - Excluded Amount" - WithholdingTaxLine[1]."Base - Excluded Amount",
          WithholdingTax."Non-Taxable Income Type"::"7");
    end;

    local procedure CalculateContributions(var WithholdingTax: Record "Withholding Tax"; EntryNo: Integer; var TempContributions: Record Contributions temporary)
    var
        Contributions: Record Contributions;
    begin
        Contributions.SetRange("External Document No.", WithholdingTax."External Document No.");
        if not TempContributions.Get(EntryNo) then begin
            TempContributions.Init();
            TempContributions."Entry No." := EntryNo;
            TempContributions.Insert();
        end;

        if Contributions.FindSet() then
            repeat
                TempContributions."Company Amount" += Contributions."Company Amount";
                TempContributions."Free-Lance Amount" += Contributions."Free-Lance Amount";
            until Contributions.Next() = 0;
        TempContributions.Modify();
    end;

    local procedure CreateWithholdingTaxLine(var WithholdingTaxLine: Record "Withholding Tax Line"; WithholdingTaxEntryNo: Integer; WithholdingTaxLineNo: Integer; BaseExcludedAmount: Decimal; NonTaxableIncomeType: Enum "Non-Taxable Income Type")
    begin
        WithholdingTaxLine.Init();
        WithholdingTaxLine."Base - Excluded Amount" := BaseExcludedAmount;
        WithholdingTaxLine."Non-Taxable Income Type" := NonTaxableIncomeType;
        WithholdingTaxLine."Withholding Tax Entry No." := WithholdingTaxEntryNo;
        WithholdingTaxLine."Line No." := WithholdingTaxLineNo;
        if WithholdingTaxLine.Insert() then;
    end;

    local procedure CreateCompanyOfficial(): Code[20]
    var
        CompanyOfficials: Record "Company Officials";
    begin
        if CompanyOfficials.FindFirst() then;
        CompanyOfficials."No." += LibraryUtility.GenerateGUID();
        CompanyOfficials."Fiscal Code" := LibraryUtility.GenerateGUID();
        CompanyOfficials."Appointment Code" := GetAppointmentCode();
        CompanyOfficials."First Name" := LibraryUtility.GenerateGUID();
        CompanyOfficials."Last Name" := LibraryUtility.GenerateGUID();

        CompanyOfficials.Insert();
        exit(CompanyOfficials."No.");
    end;

    local procedure CreateContributions()
    var
        Contributions: Record Contributions;
    begin
        if Contributions.FindLast() then;
        Contributions."Entry No." += 1;
        Contributions.Init();

        Contributions."Company Amount" := LibraryRandom.RandDec(100, 2);
        Contributions."Free-Lance Amount" := LibraryRandom.RandDec(100, 2);

        Contributions.Insert();
    end;

    local procedure CreateTaxRepresentative()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."Intermediary Date" := WorkDate();
        VATReportSetup.Modify();

        CompanyInformation.Validate("Tax Representative No.", CreateVendor());
        CompanyInformation.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        exit(LibrarySpesometro.CreateVendor(true, Vendor.Resident::Resident, false, true));
    end;

    local procedure CreateNonResidentVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        exit(LibrarySpesometro.CreateVendor(true, Vendor.Resident::"Non-Resident", false, true));
    end;

    local procedure CreateWithholdingTaxAndContributionEntry(VendorNo: Code[20]; WithholdingTaxReason: Enum "Withholding Tax Reason"; CalcYear: Integer; Date: Date; RelatedDate: Date): Integer
    var
        WithholdingTax: Record "Withholding Tax";
        WHTEntryNo: Integer;
    begin
        WHTEntryNo :=
          CreateWithholdingTaxWithAU001006(
            VendorNo, WithholdingTaxReason, CalcYear, Date, RelatedDate, WithholdingTax."Non-Taxable Income Type"::"1");
        CreateContributions();

        exit(WHTEntryNo);
    end;

    local procedure CreateWithholdingTaxWithAU001006AndContributionEntry(VendorNo: Code[20]; WithholdingTaxReason: Enum "Withholding Tax Reason"; CalcYear: Integer; Date: Date; RelatedDate: Date; NonTaxableIncomeType: Enum "Non-Taxable Income Type"): Integer
    var
        WHTEntryNo: Integer;
    begin
        WHTEntryNo := CreateWithholdingTaxWithAU001006(VendorNo, WithholdingTaxReason, CalcYear, Date, RelatedDate, NonTaxableIncomeType);
        CreateContributions();

        exit(WHTEntryNo);
    end;

    local procedure CreateWithholdingTaxInCurrentAndPreviousYears(var WithholdingTax: Record "Withholding Tax")
    var
        VendorNo: Code[20];
        EntryNo: Integer;
    begin
        VendorNo := CreateVendor();
        CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, WorkDate(), WorkDate());
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, "Withholding Tax Reason"::A, 0, CalcDate('<-1Y>', WorkDate()), WorkDate());
        WithholdingTax.Get(EntryNo);
        WithholdingTax.Validate("Withholding Tax Amount", WithholdingTax."Taxable Base" + 2);
        WithholdingTax.Modify(true);
    end;

    local procedure CreateWithholdingTaxWithAU001006(VendorNo: Code[20]; WithholdingTaxReason: Enum "Withholding Tax Reason"; CalcYear: Integer; Date: Date; RelatedDate: Date; NonTaxableIncomeType: Enum "Non-Taxable Income Type"): Integer
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.Get(CreateWithholdingTaxWithAU001006WithEmptyNonTaxable(VendorNo, WithholdingTaxReason, CalcYear, Date, RelatedDate));
        WithholdingTax."Non Taxable Amount By Treaty" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Non-Taxable Income Type" := NonTaxableIncomeType;
        WithholdingTax.Modify();

        exit(WithholdingTax."Entry No.");
    end;

    local procedure CreateWithholdingTaxWithAU001006WithEmptyNonTaxable(VendorNo: Code[20]; WithholdingTaxReason: Enum "Withholding Tax Reason"; CalcYear: Integer; Date: Date; RelatedDate: Date): Integer
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        if WithholdingTax.FindLast() then;
        WithholdingTax."Entry No." += 1;
        WithholdingTax.Init();

        WithholdingTax."Vendor No." := VendorNo;
        WithholdingTax.Reason := WithholdingTaxReason;

        WithholdingTax."Total Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Non Taxable Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Taxable Base" := LibraryRandom.RandDec(100, 2);
        WithholdingTax."Withholding Tax Amount" := LibraryRandom.RandDec(100, 2);
        WithholdingTax.Year := Date2DMY(Date, 3) + CalcYear;
        WithholdingTax."Related Date" := RelatedDate;
        WithholdingTax."Non-Taxable Income Type" := WithholdingTax."Non-Taxable Income Type"::" ";
        WithholdingTax.Insert();

        exit(WithholdingTax."Entry No.");
    end;

    local procedure SetWithholdingTaxNonTaxableAmountByTreaty(EntryNo: Integer; NonTaxableAmountByTreaty: Decimal)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.Get(EntryNo);
        WithholdingTax."Non Taxable Amount By Treaty" := NonTaxableAmountByTreaty;
        WithholdingTax.Modify();
    end;

    local procedure GetAppointmentCode(): Code[2];
    var
        AppointmentCode: Record "Appointment Code";
    BEGIN
        if AppointmentCode.FindFirst() then
            exit(AppointmentCode.Code);
        exit(LibrarySpesometro.CreateAppointmentCode());
    end;

    local procedure Export(SigningCompanyOfficialNo: Code[20]) Filename: Text
    var
        WithholdingTaxExport: Codeunit "Withholding Tax Export";
    begin
        Filename := TemporaryPath + LibraryUtility.GenerateGUID() + '.dcm';
        WithholdingTaxExport.SetServerFileName(Filename);
        WithholdingTaxExport.Export(Date2DMY(WorkDate(), 3), SigningCompanyOfficialNo, 1, CommunicationNumber, '1');
    end;

    local procedure ExportCertificazioneUnica(): Text
    var
        WithholdingTaxExport: Codeunit "Withholding Tax Export";
        Filename: Text;
        SigningCompanyOfficialNo: Code[20];
    begin
        SigningCompanyOfficialNo := CreateCompanyOfficial();

        Filename := TemporaryPath + LibraryUtility.GenerateGUID() + '.dcm';
        WithholdingTaxExport.SetServerFileName(Filename);
        WithholdingTaxExport.Export(Date2DMY(WorkDate(), 3), SigningCompanyOfficialNo, 1, CommunicationNumber, '1');

        exit(Filename);
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

    local procedure FormatToLength(Value: Variant; Length: Integer): Text
    begin
        exit(PadStr('', Length - StrLen(Format(Value)), '0') + Format(Value));
    end;

    local procedure ValidateAmountsInRecordH(WithholdingTaxLine: Record "Withholding Tax Line"; TotalAmount: Decimal; NonTaxableAmount: Decimal; LineNumber: Integer)
    begin
        if TotalAmount <> 0 then
            ValidateBlockValue(LineNumber, 'AU001004', ConstFormat::VP, TotalAmount);
        ValidateBlockValue(LineNumber, 'AU001006', ConstFormat::NP, Format(WithholdingTaxLine.GetNonTaxableIncomeTypeNumber()));
        ValidateBlockValue(LineNumber, 'AU001007', ConstFormat::VP, WithholdingTaxLine."Base - Excluded Amount" + NonTaxableAmount);
    end;

    local procedure ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo: Code[20]; VendorNo: Code[20]; Filename: Text)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        LoadFile(Filename);
        ValidateHeader(SigningCompanyOfficialNo);
        ValidateRecordDAndH(VendorNo, SigningCompanyOfficialNo, "Withholding Tax Reason"::A, 3, '', WithholdingTax."Non-Taxable Income Type"::"1", 1);
        ValidateFooter(5, 1);
    end;

    local procedure ValidateBlockValueOfStrictPosition(LineNumber: Integer; FieldName: Text; Type: Option; ExpectedValue: Variant; ExpectedPosition: Integer)
    begin
        ValidateTextFileValue(LineNumber, ExpectedPosition, StrLen(FieldName), FieldName);
        ValidateBlockValue(LineNumber, FieldName, Type, ExpectedValue);
    end;

    local procedure ValidateBlockValue(LineNumber: Integer; FieldName: Text; Type: Option; ExpectedValue: Variant)
    var
        FlatFileManagement: Codeunit "Flat File Management";
        Expected: Text;
    begin
        if ExpectedValue.IsInteger or ExpectedValue.IsDecimal then
            Expected := FlatFileManagement.FormatNum(ExpectedValue, Type)
        else
            Expected := ExpectedValue;

        if Type = ConstFormat::AN then
            Expected := UpperCase(Expected);

        Assert.AreEqual(Expected, DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNumber, FieldName), '<>', ' '), '');
    end;

    local procedure ValidateBlockAbsence(LineNumber: Integer; FieldName: Text)
    begin
        Assert.AreEqual('', LibrarySpesometro.ReadBlockValue(TextFile, LineNumber, FieldName), '');
    end;

    local procedure ValidateSpecialCategoryBlockValue(LineNumber: Integer; FieldName: Text; ExpectedValue: Option)
    var
        Vendor: Record Vendor;
        Expected: Text;
    begin
        Vendor."Special Category" := ExpectedValue;
        if ExpectedValue = Vendor."Special Category"::" " then
            Expected := ''
        else
            Expected := UpperCase(Format(Vendor."Special Category"));
        Assert.AreEqual(Expected, DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNumber, FieldName), '<>', ' '), '');
    end;

    local procedure ValidateTextFileValue(LineNumber: Integer; Position: Integer; Length: Integer; Expected: Text)
    begin
        Assert.AreEqual(Expected, DelChr(LibrarySpesometro.ReadValue(TextFile, LineNumber, Position, Length), '<>', ' '), '');
    end;

    local procedure ValidateRecordDAndH(VendorNo: Code[20]; SigningCompanyOfficialNo: Code[20]; WithholdingTaxReason: Enum "Withholding Tax Reason"; LineNumber: Integer; Year: Text; NonTaxableIncomeType: Enum "Non-Taxable Income Type"; RecordHEntryNumber: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
        TempWithholdingTax: Record "Withholding Tax" temporary;
        Vendor: Record Vendor;
        TempContributions: Record Contributions temporary;
        SigningCompanyOfficials: Record "Company Officials";
    begin
        Vendor.Get(VendorNo);
        SigningCompanyOfficials.Get(SigningCompanyOfficialNo);
        TempWithholdingTax.Init();
        WithholdingTax.SetRange("Vendor No.", VendorNo);
        WithholdingTax.SetRange(Reason, WithholdingTaxReason);
        WithholdingTax.SetRange("Non-Taxable Income Type", NonTaxableIncomeType);
        WithholdingTax.FindSet();
        repeat
            TempWithholdingTax."Total Amount" += WithholdingTax."Total Amount";
            TempWithholdingTax."Non Taxable Amount By Treaty" += WithholdingTax."Non Taxable Amount By Treaty";
            TempWithholdingTax."Base - Excluded Amount" += WithholdingTax."Base - Excluded Amount";
            TempWithholdingTax."Non Taxable Amount" += WithholdingTax."Non Taxable Amount";
            TempWithholdingTax."Taxable Base" += WithholdingTax."Taxable Base";
            TempWithholdingTax."Withholding Tax Amount" += WithholdingTax."Withholding Tax Amount";
            CalculateContributions(WithholdingTax, 1, TempContributions);
        until WithholdingTax.Next() = 0;
        TempWithholdingTax.Insert();

        // Validate D-Record
        ValidateTextFileValue(LineNumber, 1, 1, 'D');
        ValidateTextFileValue(LineNumber, 2, 16, CompanyInformation."Fiscal Code");
        ValidateTextFileValue(LineNumber, 18, 8, '00000001'); // We only export a single file
        ValidateTextFileValue(LineNumber, 26, 16, Vendor."Fiscal Code");

        ValidateBlockValue(LineNumber, 'DA001001', 0, CompanyInformation."Fiscal Code");

        ValidateBlockValue(LineNumber, 'DA001002', ConstFormat::AN, CompanyInformation.Name);
        ValidateBlockValue(LineNumber, 'DA001004', ConstFormat::AN, CompanyInformation.City);
        ValidateBlockValue(LineNumber, 'DA001005', ConstFormat::PR, CompanyInformation.County);
        ValidateBlockValue(LineNumber, 'DA001006', ConstFormat::AN, CompanyInformation."Post Code");
        ValidateBlockValue(LineNumber, 'DA001007', ConstFormat::AN, CompanyInformation.Address);
        ValidateBlockValue(LineNumber, 'DA001009', ConstFormat::AN, CompanyInformation."E-Mail");
        ValidateBlockValue(LineNumber, 'DA001011', ConstFormat::AN, CompanyInformation."Office Code");

        // Bug id 468097: DA002001 tag must contain the fiscal code of the vendor
        ValidateBlockValue(LineNumber, 'DA002001', ConstFormat::CF, Vendor."Fiscal Code");
        ValidateBlockValue(LineNumber, 'DA002002', ConstFormat::AN, Vendor."Last Name");
        ValidateBlockValue(LineNumber, 'DA002003', ConstFormat::AN, Vendor."First Name");
        ValidateBlockValue(LineNumber, 'DA002006', ConstFormat::AN, Vendor."Birth City");
        ValidateBlockValue(LineNumber, 'DA002007', ConstFormat::PN, Vendor."Birth County");
        ValidateSpecialCategoryBlockValue(LineNumber, 'DA002008', Vendor."Special Category");

        ValidateBlockValue(LineNumber, 'DA002030', ConstFormat::AN, '');

        ValidateBlockValue(LineNumber, 'DA003002', ConstFormat::CB, '1');

        // Validate H-Record
        ValidateTextFileValue(LineNumber + 1, 1, 1, 'H');
        ValidateTextFileValue(LineNumber + 1, 2, 16, CompanyInformation."Fiscal Code");
        // Bug id 468097: H record must contain the progressive entry number
        ValidateTextFileValue(LineNumber + 1, 18, 8, '0000000' + Format(RecordHEntryNumber)); // We only export a single file
        ValidateTextFileValue(LineNumber + 1, 26, 16, Vendor."Fiscal Code");

        ValidateBlockValue(LineNumber + 1, 'AU001001', 0, Format(WithholdingTax.Reason));
        ValidateBlockValue(LineNumber + 1, 'AU001002', 0, Year);
        ValidateBlockValue(LineNumber + 1, 'AU001004', ConstFormat::VP, TempWithholdingTax."Total Amount");
        ValidateBlockValue(LineNumber + 1, 'AU001006', ConstFormat::NP, Format(WithholdingTax."Non-Taxable Income Type".Names().Get(NonTaxableIncomeType.AsInteger() + 1)));
        ValidateBlockValue(LineNumber + 1, 'AU001007', ConstFormat::VP,
          TempWithholdingTax."Non Taxable Amount" + TempWithholdingTax."Base - Excluded Amount");
        ValidateBlockValue(LineNumber + 1, 'AU001008', ConstFormat::VP, TempWithholdingTax."Taxable Base");
        ValidateBlockValue(LineNumber + 1, 'AU001010', ConstFormat::VP, '');

        ValidateBlockValue(LineNumber + 1, 'AU001020', ConstFormat::VP, TempContributions."Company Amount");
        ValidateBlockValue(LineNumber + 1, 'AU001021', ConstFormat::VP, TempContributions."Free-Lance Amount");
    end;

    local procedure ValidateHeader(SigningCompanyOfficialNo: Code[20])
    var
        SigningCompanyOfficials: Record "Company Officials";
        VendorTaxRepresentative: Record Vendor;
    begin
        SigningCompanyOfficials.Get(SigningCompanyOfficialNo);

        // Validate A-Record
        ValidateTextFileValue(1, 1, 1, 'A');

        ValidateTextFileValue(1, 16, 5, StrSubstNo(CURTxt, Date2DMY(WorkDate(), 3) mod 100 + 1)); // TFS 397347

        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then begin
            ValidateTextFileValue(1, 21, 2, '10');
            ValidateTextFileValue(1, 23, 16, VendorTaxRepresentative."Fiscal Code")
        end else begin
            ValidateTextFileValue(1, 21, 2, '01');
            ValidateTextFileValue(1, 23, 16, CompanyInformation."Fiscal Code")
        end;

        // Validate B-Record
        ValidateTextFileValue(2, 1, 1, 'B');
        ValidateTextFileValue(2, 2, 16, CompanyInformation."Fiscal Code");

        ValidateTextFileValue(2, 309, 2, '1'); // TFS 390620
        ValidateTextFileValue(2, 311, 16, SigningCompanyOfficials."Fiscal Code");
        ValidateTextFileValue(2, 327, 2, SigningCompanyOfficials."Appointment Code");
        ValidateTextFileValue(2, 329, 24, SigningCompanyOfficials."Last Name");
        ValidateTextFileValue(2, 353, 20, SigningCompanyOfficials."First Name");
        ValidateTextFileValue(2, 373, 11, FormatToLength(CompanyInformation."Fiscal Code", 11));
        ValidateTextFileValue(2, 384, 18, '000000000000000000'); // TFS 390620
        ValidateTextFileValue(2, 402, 8, FormatToLength(CommunicationNumber, 8));
        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then
            ValidateTextFileValue(2, 412, 16, VendorTaxRepresentative."Fiscal Code");
        ValidateTextFileValue(2, 527, 1, '0');
    end;

    local procedure ValidateFooter(LineNo: Integer; NumHRecords: Integer)
    begin
        ValidateTextFileValue(LineNo, 1, 1, 'Z');

        ValidateTextFileValue(LineNo, 16, 9, '000000001'); // Number of B-Records
        ValidateTextFileValue(LineNo, 25, 9, '000000000'); // Number of C-Records
        ValidateTextFileValue(LineNo, 34, 9, '00000000' + Format(NumHRecords, 0, 1)); // Number of D-Records
        ValidateTextFileValue(LineNo, 43, 9, '000000000'); // Number of G-Records
        ValidateTextFileValue(LineNo, 52, 9, '00000000' + Format(NumHRecords, 0, 1)); // Number of H-Records
    end;

    local procedure ValidateFooterOfDAndHRecords(LineNo: Integer; NumHRecords: Integer; NumDRecords: Integer)
    begin
        ValidateTextFileValue(LineNo, 1, 1, 'Z');

        ValidateTextFileValue(LineNo, 16, 9, '000000001'); // Number of B-Records
        ValidateTextFileValue(LineNo, 25, 9, '000000000'); // Number of C-Records
        ValidateTextFileValue(LineNo, 34, 9, '00000000' + Format(NumDRecords, 0, 1)); // Number of D-Records
        ValidateTextFileValue(LineNo, 43, 9, '000000000'); // Number of G-Records
        ValidateTextFileValue(LineNo, 52, 9, '00000000' + Format(NumHRecords, 0, 1)); // Number of H-Records
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedMessage, Message, '');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Msg: Text)
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorPageHandler(var ErrorMessages: TestPage "Error Messages")
    var
        WithholdingTax: Record "Withholding Tax";
        RecRef: RecordRef;
    begin
        WithholdingTax.Get(LibraryVariableStorage.DequeueInteger());
        RecRef.GetTable(WithholdingTax);
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(EmptyFieldErr, LibraryVariableStorage.DequeueText(), RecRef.RecordId));
        Assert.IsFalse(ErrorMessages.Next(), WrongRecordFoundErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorPageHandlerWithExpectedErrorMessage(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.Description.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(ErrorMessages.Next(), WrongRecordFoundErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandler(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    begin
        WithholdingTaxLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandlerWithLineEntry(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    begin
        WithholdingTaxLines."Base - Excluded Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        WithholdingTaxLines."Non-Taxable Income Type".SetValue(LibraryVariableStorage.DequeueInteger());
        WithholdingTaxLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandlerWithCheckTotal(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    begin
        WithholdingTaxLines."Total Base - Excluded Amount".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        WithholdingTaxLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandlerWithCorrectSplit(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    var
        WithholdingTaxLine: Record "Withholding Tax Line";
        FirstLineAmount: Decimal;
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryVariableStorage.DequeueDecimal();
        FirstLineAmount := Round(TotalAmount / 2);
        WithholdingTaxLines."Base - Excluded Amount".SetValue(FirstLineAmount);
        WithholdingTaxLines."Non-Taxable Income Type".SetValue(WithholdingTaxLine."Non-Taxable Income Type"::"2");
        WithholdingTaxLines.Next();
        WithholdingTaxLines."Base - Excluded Amount".SetValue(TotalAmount - FirstLineAmount);
        WithholdingTaxLines."Non-Taxable Income Type".SetValue(WithholdingTaxLine."Non-Taxable Income Type"::"6");
        WithholdingTaxLines.OK().Invoke();
    end;
}

