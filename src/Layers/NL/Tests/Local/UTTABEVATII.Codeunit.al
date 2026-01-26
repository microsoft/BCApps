codeunit 144046 "UT TAB EVAT II"
{
    // Test for feature EVAT - Electronic VAT Declaration.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CurrentQuarterTxt: Label '<+CQ>', Locked = true;
        DialogErr: Label 'Dialog';
        DeclarationConfirmation: Label 'A declaration for %1 %2 already exists. Do you wish to continue?';
        InitialOurReferenceTxt: Label 'OB-';
        TableErr: Label 'NCLCSRTS:TableErrorStr';
        ValueMustNotExistMsg: Label 'Value must not exist.';
        ValueMustExistMsg: Label 'Value must exist.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateOurRefInitialCharElecTaxDeclHeaderError()
    begin
        // Purpose of the test is to validate Our Reference - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Test to verify error, Our Reference must start with 'OB-' in Elec. Tax Declaration Header Declaration Type='VAT Declaration',No.=''.
        Initialize();
        OnValidateOurReferenceElecTaxDeclarationHeader(LibraryUTUtility.GetNewCode10(), TableErr);  // Our Reference - with random code.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateOurRefSpecialCharElecTaxDeclHeaderError()
    begin
        // Purpose of the test is to validate Our Reference - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Test to verify error, Our Reference can only contain letters, digits and dashes in Elec. Tax Declaration Header Declaration Type='VAT Declaration',No.=''.
        Initialize();
        OnValidateOurReferenceElecTaxDeclarationHeader(InitialOurReferenceTxt + '@', TableErr);  // Our Reference - with special character.
    end;

    local procedure OnValidateOurReferenceElecTaxDeclarationHeader(OurReference: Code[20]; ExpectedErrorCode: Text[1024])
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Exercise.
        asserterror ElecTaxDeclarationHeader.Validate("Our Reference", OurReference);

        // Verify: Verify Expected error code, related to Our Reference.
        Assert.ExpectedErrorCode(ExpectedErrorCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclarationTypeICPElecTaxDeclHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Type - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        // Setup.
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");

        // Exercise.
        asserterror ElecTaxDeclarationHeader.Validate("Declaration Type", ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");

        // Verify: Verify Expected error code, Actual error: You cannot change Declaration Type once a No. is assigned to a Elec. Tax Declaration Header.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclarationYearAfterTodayElecTaxDeclHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Year - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        // Setup.
        Initialize();
        ElecTaxDeclarationHeader."Declaration Type" := ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration";
        ElecTaxDeclarationHeader."No." := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationHeader."Declaration Period" := ElecTaxDeclarationHeader."Declaration Period"::December;  // Used Declaration Period as last month of the year.

        // Exercise.
        asserterror ElecTaxDeclarationHeader.Validate("Declaration Year", Date2DMY(Today, 3));  // 3 for Year

        // Verify: Verify Expected error code, Actual error: It is not allowed to send a declaration with a period that ends after today.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateUniqueOurRefElecTaxDeclarationHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationHeader2: Record "Elec. Tax Declaration Header";
    begin
        // Setup: Create Electronic Tax Declaration Header with different Declaration type with same Our Reference.
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, LibraryRandom.RandIntInRange(0, 1));  // ElecTaxDeclarationHeader Declaration Type - VAT Declaration and ICP Declaration.
        ElecTaxDeclarationHeader.Validate("Our Reference", InitialOurReferenceTxt +
          LibraryUtility.GenerateRandomXMLText(
            LibraryUtility.GetFieldLength(DATABASE::"Elec. Tax Declaration Header",
              ElecTaxDeclarationHeader.FieldNo("Our Reference")) - StrLen(InitialOurReferenceTxt)));  // Our Reference must be of 20 digits.
        ElecTaxDeclarationHeader.Modify();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader2, ElecTaxDeclarationHeader2."Declaration Type"::"VAT Declaration");

        // Exercise.
        asserterror ElecTaxDeclarationHeader2.Validate("Our Reference", ElecTaxDeclarationHeader."Our Reference");

        // Verify: Verify Expected error code, Actual error: The value in Our Reference must be unique.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('DeclarationConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSameDeclarationYearElecTaxDeclHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationHeader2: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Year - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Create two Electronic Tax Declaration Headers with same Declaration Period and Declaration Year.
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
        UpdateDeclarationPeriodElecTaxDeclarationHeader(ElecTaxDeclarationHeader, "Elec. Tax Declaration Period".FromInteger(LibraryRandom.RandIntInRange(1, 12)));  // Declaration Period - January to December.
        ElecTaxDeclarationHeader."Declaration Year" := Date2DMY(Today, 3) - 1;  // Declaration Year on the basis of Declaration Year - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        ElecTaxDeclarationHeader.Modify();

        // Create second Electronic Tax Declaration Header with same Declaration Period and Declaration Year.
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader2, ElecTaxDeclarationHeader2."Declaration Type"::"ICP Declaration");
        UpdateDeclarationPeriodElecTaxDeclarationHeader(ElecTaxDeclarationHeader2, ElecTaxDeclarationHeader."Declaration Period");
        LibraryVariableStorage.Enqueue(ElecTaxDeclarationHeader."Declaration Period");  // Required inside DeclarationConfirmHandler.

        // Exercise.
        ElecTaxDeclarationHeader2.Validate("Declaration Year", ElecTaxDeclarationHeader."Declaration Year");

        // Verify: Verification is done inside DeclarationConfirmHandler: A Declaration for Declaration Period "current year" already exist. Do you wish to continue?
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclarationYearBeforeSepElecTaxDeclHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Year - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Create Electronic Tax Declaration Header.
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        UpdateDeclarationPeriodElecTaxDeclarationHeader(ElecTaxDeclarationHeader, "Elec. Tax Declaration Period".FromInteger(LibraryRandom.RandIntInRange(1, 12)));  // Declaration Period - January to December.

        // Exercise.
        asserterror ElecTaxDeclarationHeader.Validate("Declaration Year", Date2DMY(Today, 3) - LibraryRandom.RandIntInRange(2, 10));  // Declaration Year on the basis of Declaration Year - OnValidate Trigger Elec. Tax Declaration Header.

        // Verify: Verify Expected error code, Actual error: Declarations from Declaration Year "current year -1" should be processed before September "current year".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteElecTaxDeclarationHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        // Setup.
        Initialize();
        ElecTaxDeclarationHeader.Status := ElecTaxDeclarationHeader.Status::Submitted;

        // Exercise.
        asserterror ElecTaxDeclarationHeader.Delete(true);

        // Verify: Verify Expected error code, Actual error: You cannot delete a Elec. Tax Declaration Header if Status is Submitted.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteElecTaxDeclarationHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        ElecTaxDeclErrorLog: Record "Elec. Tax Decl. Error Log";
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Create Electronic Tax Declaration Header, Electronic Tax Declaration Line, Electronic Tax Declaration Error Log and Electronic Tax Declaration Response Message.
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        CreateElecTaxDeclarationLine(ElecTaxDeclarationLine, ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.");
        CreateElecTaxDeclErrorLog(ElecTaxDeclErrorLog, ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.");
        CreateElecTaxDeclResponseMsg(ElecTaxDeclResponseMsg, ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.");

        // Exercise.
        ElecTaxDeclarationHeader.Delete(true);

        // Verify: Verify Electronic Tax Declaration Header, Elec. Tax Declaration Line and Elec. Tax Decl. Error Log and Electronic Tax Declaration Response Message deleted.
        Assert.IsFalse(
          ElecTaxDeclarationHeader.Get(ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No."), ValueMustNotExistMsg);
        Assert.IsFalse(
          ElecTaxDeclarationLine.Get(
            ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.", ElecTaxDeclarationLine."Line No."),
          ValueMustNotExistMsg);
        Assert.IsFalse(
          ElecTaxDeclErrorLog.Get(ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.", ElecTaxDeclErrorLog."No."),
          ValueMustNotExistMsg);
        Assert.IsFalse(ElecTaxDeclResponseMsg.Get(ElecTaxDeclResponseMsg."No."), ValueMustNotExistMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreExportElecTaxDeclarationHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        // Purpose of the test is to validate OnPreExport function of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Create Electronic Tax Declaration Header and Electronic Tax Declaration Line
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
        CreateElecTaxDeclarationLine(
          ElecTaxDeclarationLine, ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationLine."Declaration No.");

        // Exercise.
        asserterror ElecTaxDeclarationHeader.OnPreExport();

        // Verify: Verify Expected error code, Actual error: You cannot export a Elec. Tax Declaration Header of Declaration Type ICP Declaration if there was no relevant economic activity during the declaration period.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertLineElecTaxDeclarationHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        Name: Text[20];
    begin
        // Purpose of the test is to validate InsertLine function of Table ID - 11409 Elec. Tax Declaration Header.
        // Setup.
        Initialize();
        CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        Name := LibraryUTUtility.GetNewCode();

        // Exercise.
        ElecTaxDeclarationHeader.InsertLine(ElecTaxDeclarationLine."Line Type"::Element, 0, Name, Name);  // Indentation Level - 0, Name and Data.

        // Verify: Verify Elec. Tax Declaration Line created.
        Assert.IsTrue(
          ElecTaxDeclarationLine.Get(ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.", 10000),
          ValueMustExistMsg);  // Line No - 10000, from OnInsert Trigger of Elec. Tax Declaration Line.
        ElecTaxDeclarationLine.TestField(Name, Name);
        ElecTaxDeclarationLine.TestField(Data, Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestNoSeriesVATElecTaxDeclarationHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate TestNoSeries function of Table ID - 11409 Elec. Tax Declaration Header.

        // Test to verify error, VAT Declaration Nos. must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty.
        TestNoSeriesElecTaxDeclarationHeader(ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestNoSeriesICPElecTaxDeclarationHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate TestNoSeries function of Table ID - 11409 Elec. Tax Declaration Header.

        // Test to verify error, ICP Declaration Nos. must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty.
        TestNoSeriesElecTaxDeclarationHeader(ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
    end;

    local procedure TestNoSeriesElecTaxDeclarationHeader(DeclarationType: Option)
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate TestNoSeries function of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Update VAT Declaration Nos. and ICP Declaration Nos. on Elec. Tax Declaration Setup.
        Initialize();
        UpdateElecTaxDeclarationSetup(ElecTaxDeclarationSetup, LibraryUTUtility.GetNewCode10(), LibraryUTUtility.GetNewCode10());  // VAT Declaration Nos and ICP Declaration Nos.
        ElecTaxDeclarationHeader."Declaration Type" := DeclarationType;

        // Exercise.
        asserterror ElecTaxDeclarationHeader.TestNoSeries();

        // Verify: Verify Expected error code, Actual error: VAT Declaration Nos. or ICP Declaration Nos. must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodBiMonthlyElecTaxDeclHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        // Setup.
        Initialize();
        ElecTaxDeclarationHeader."Declaration Type" := ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration";

        // Exercise.
        asserterror ElecTaxDeclarationHeader.Validate(
            "Declaration Period", ElecTaxDeclarationHeader."Declaration Period"::"January-February");

        // Verify: Verify Expected error code, Actual error: Declaration Period must not be bi-monthly if Declaration Type is VAT Declaration.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodJanElecTaxDeclarationHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header for Declaration Period January.

        // Calculation of Declaration Period From Date for Declaration Period - January and Declaration Period To Date on - Current Month.
        OnValidateDeclPeriodElecTaxDeclarationHeader(
          ElecTaxDeclarationHeader."Declaration Period"::January, ElecTaxDeclarationHeader."Declaration Period"::January.AsInteger(), '<+CM>');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodFirstQuarterElecTaxDeclHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header for Declaration Period First Quarter.

        // Calculation of Declaration Period From Date for Declaration Period - First Quarter and Declaration Period To Date on - Current Quarter.
        OnValidateDeclPeriodElecTaxDeclarationHeader(ElecTaxDeclarationHeader."Declaration Period"::"First Quarter", 1, CurrentQuarterTxt);  // 1 - January.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodSecondQuarterElecTaxDeclHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header for Declaration Period Second Quarter.

        // Calculation of Declaration Period From Date for Declaration Period - Second Quarter and Declaration Period To Date on - Current Quarter.
        OnValidateDeclPeriodElecTaxDeclarationHeader(
          ElecTaxDeclarationHeader."Declaration Period"::"Second Quarter", 4, CurrentQuarterTxt);  // 4 - April.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodThirdQuarterElecTaxDeclHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header for Declaration Period Third Quarter.

        // Calculation of Declaration Period From Date for Declaration Period - Third Quarter and Declaration Period To Date on - Current Quarter.
        OnValidateDeclPeriodElecTaxDeclarationHeader(ElecTaxDeclarationHeader."Declaration Period"::"Third Quarter", 7, CurrentQuarterTxt);  // 7 - July.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodFourthQuarterElecTaxDeclHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header for Declaration Period Fourth Quarter.

        // Calculation of Declaration Period From Date for Declaration Period - Fourth Quarter and Declaration Period To Date on - Current Quarter.
        OnValidateDeclPeriodElecTaxDeclarationHeader(
          ElecTaxDeclarationHeader."Declaration Period"::"Fourth Quarter", 10, CurrentQuarterTxt);  // 10 - October.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDeclPeriodYearToDateElecTaxDeclHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate Declaration Period - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header for Declaration Period Year.

        // Calculation of Declaration Period From Date for Declaration Period - Year and Declaration Period To Date on - Current Year.
        OnValidateDeclPeriodElecTaxDeclarationHeader(ElecTaxDeclarationHeader."Declaration Period"::Year, 1, '<+CY>');
    end;

    local procedure OnValidateDeclPeriodElecTaxDeclarationHeader(DeclarationPeriod: Enum "Elec. Tax Declaration Period"; ExpectedMonth: Integer; DateExpression: Text[5])
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        DeclarationDateExpression: DateFormula;
    begin
        // Setup.
        Initialize();
        ElecTaxDeclarationHeader."Declaration Type" := ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration";
        ElecTaxDeclarationHeader."Declaration Year" := Date2DMY(Today, 3) - 1;  // Declaration Year on the basis of Declaration Year - OnValidate Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        Evaluate(DeclarationDateExpression, DateExpression);

        // Exercise.
        ElecTaxDeclarationHeader.Validate("Declaration Period", DeclarationPeriod);

        // Verify: Verify Declaration Period From Date and Declaration Period To Date on Elec. Tax Declaration Header.
        ElecTaxDeclarationHeader.TestField(
          "Declaration Period From Date", DMY2Date(1, ExpectedMonth, ElecTaxDeclarationHeader."Declaration Year"));
        ElecTaxDeclarationHeader.TestField(
          "Declaration Period To Date", CalcDate(DeclarationDateExpression, ElecTaxDeclarationHeader."Declaration Period From Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenameElecTaxDeclarationLineError()
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        // Purpose of the test is to validate OnRename Trigger of Table ID - 11410 Elec. Tax Declaration Line.
        // Setup.
        Initialize();
        CreateElecTaxDeclarationLine(
          ElecTaxDeclarationLine, ElecTaxDeclarationLine."Declaration Type"::"VAT Declaration", LibraryUTUtility.GetNewCode());  // Using Random code for Elec. Tax Declaration Line - Declaration No.

        // Exercise.
        asserterror ElecTaxDeclarationLine.Rename(
            ElecTaxDeclarationLine."Declaration Type", ElecTaxDeclarationLine."Declaration No.",
            ElecTaxDeclarationLine."Line No." + LibraryRandom.RandInt(10));  // Adding Random value in Line Number to rename.

        // Verify: Verify expected error code, Actual error: You cannot rename a Elec. Tax Declaration Line.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertElecTaxDeclResponseMsg()
    var
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 11413 Elec. Tax Decl. Response Msg.

        // Setup: Create Electronic Tax Declaration Response Msg with Number - 0.
        Initialize();
        ElecTaxDeclResponseMsg.DeleteAll();  // Required to delete all Elec. Tax Decl. Response Msg.
        ElecTaxDeclResponseMsg."No." := 0;

        // Exercise.
        ElecTaxDeclResponseMsg.Insert(true);

        // Verify: Verify Elec. Tax Decl. Response Msg. is incremented to 1.
        ElecTaxDeclResponseMsg.TestField("No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertDeclarationTypeElecTaxDeclarationHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        StartingNo: Code[20];
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 11409 Elec. Tax Declaration Header.
        // Setup.
        Initialize();
        StartingNo := CreateElecTaxDeclarationHeaderWithNoSeries(ElecTaxDeclarationHeader, CreateNoSeries(true));  // Manual Nos - TRUE.

        // Exercise: Validate OnInsert Trigger of Elec. Tax Declaration Header with Manual Nos - TRUE.
        ElecTaxDeclarationHeader.Insert(true);

        // Verify: Verify Elec. Tax Declaration Header Number automatically updated from No. Series attached on VAT Declaration Nos or ICP Declaration Nos of Elec. Tax Declaration Setup.
        Assert.IsTrue(ElecTaxDeclarationHeader.Get(ElecTaxDeclarationHeader."Declaration Type", StartingNo), ValueMustExistMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenameNoManualTrueElecTaxDeclarationHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        No: Code[20];
    begin
        // Purpose of the test is to validate OnRename Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Create No. Series with Manual and Default as TRUE.
        Initialize();
        ElecTaxDeclarationHeader."No." := CreateNoSeriesLine(CreateNoSeries(true));
        ElecTaxDeclarationHeader.Insert();
        No := LibraryUTUtility.GetNewCode10();

        // Exercise.
        ElecTaxDeclarationHeader.Rename(ElecTaxDeclarationHeader."Declaration Type", No);

        // Verify: Verify Elec. Tax Declaration Header Number can be updated manually.
        Assert.IsTrue(ElecTaxDeclarationHeader.Get(ElecTaxDeclarationHeader."Declaration Type", No), ValueMustExistMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNoManualFalseElecTaxDeclarationHeaderError()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of the test is to validate OnValidate - No Trigger of Table ID - 11409 Elec. Tax Declaration Header.

        // Setup: Create No. Series with Manual - False.
        Initialize();
        CreateElecTaxDeclarationHeaderWithNoSeries(ElecTaxDeclarationHeader, CreateNoSeries(false));  // Manual Nos - FALSE.
        ElecTaxDeclarationHeader.Insert();

        // Exercise.
        asserterror ElecTaxDeclarationHeader.Validate("No.", LibraryUTUtility.GetNewCode());

        // Verify: Verify expected error code, actual error: You may not enter numbers manually. If you want to enter numbers manually, please activate Manual Nos. in No. Series.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateFiscalEntityNoCompanyInformationError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate OnValidate - Fiscal Entity No Trigger of Table ID - 79 Company Information.
        // Setup.
        Initialize();

        // Exercise.
        asserterror CompanyInformation.Validate("Fiscal Entity No.", LibraryUTUtility.GetNewCode());

        // Verify: Verify expected error code, actual error: The entered VAT Registration number is not in agreement with the format specified for Country/Region Code NL.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTConvertOptionDeclarationPeriodToEnum()
    var
        DeclarationPeriodOption: Option ,January,February,March,April,May,June,July,August,September,October,November,December,,,,,,,,,"First Quarter",,,"Second Quarter",,,"Third Quarter",,,"Fourth Quarter",,,,,,,,,,Year,"January-February","April-May","July-August","October-November";
        DeclarationPeriodEnum: Enum "Elec. Tax Declaration Period";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 317453] Check convert Option Declaration Period to Enum
        VerifyEnumValue(DeclarationPeriodOption::January, DeclarationPeriodEnum::January);
        VerifyEnumValue(DeclarationPeriodOption::February, DeclarationPeriodEnum::February);
        VerifyEnumValue(DeclarationPeriodOption::March, DeclarationPeriodEnum::March);
        VerifyEnumValue(DeclarationPeriodOption::April, DeclarationPeriodEnum::April);
        VerifyEnumValue(DeclarationPeriodOption::May, DeclarationPeriodEnum::May);
        VerifyEnumValue(DeclarationPeriodOption::June, DeclarationPeriodEnum::June);
        VerifyEnumValue(DeclarationPeriodOption::July, DeclarationPeriodEnum::July);
        VerifyEnumValue(DeclarationPeriodOption::August, DeclarationPeriodEnum::August);
        VerifyEnumValue(DeclarationPeriodOption::September, DeclarationPeriodEnum::September);
        VerifyEnumValue(DeclarationPeriodOption::October, DeclarationPeriodEnum::October);
        VerifyEnumValue(DeclarationPeriodOption::November, DeclarationPeriodEnum::November);
        VerifyEnumValue(DeclarationPeriodOption::December, DeclarationPeriodEnum::December);
        VerifyEnumValue(DeclarationPeriodOption::"First Quarter", DeclarationPeriodEnum::"First Quarter");
        VerifyEnumValue(DeclarationPeriodOption::"Second Quarter", DeclarationPeriodEnum::"Second Quarter");
        VerifyEnumValue(DeclarationPeriodOption::"Third Quarter", DeclarationPeriodEnum::"Third Quarter");
        VerifyEnumValue(DeclarationPeriodOption::"Fourth Quarter", DeclarationPeriodEnum::"Fourth Quarter");
        VerifyEnumValue(DeclarationPeriodOption::"January-February", DeclarationPeriodEnum::"January-February");
        VerifyEnumValue(DeclarationPeriodOption::"April-May", DeclarationPeriodEnum::"April-May");
        VerifyEnumValue(DeclarationPeriodOption::"July-August", DeclarationPeriodEnum::"July-August");
        VerifyEnumValue(DeclarationPeriodOption::"October-November", DeclarationPeriodEnum::"October-November");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT TAB EVAT II");
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateElecTaxDeclarationHeader(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header"; DeclarationType: Option)
    begin
        ElecTaxDeclarationHeader."Declaration Type" := DeclarationType;
        ElecTaxDeclarationHeader."No." := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationHeader.Insert();
    end;

    local procedure CreateElecTaxDeclarationLine(var ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line"; DeclarationType: Option; DeclarationNo: Code[20])
    begin
        ElecTaxDeclarationLine."Declaration Type" := DeclarationType;
        ElecTaxDeclarationLine."Declaration No." := DeclarationNo;
        ElecTaxDeclarationLine."Line No." := LibraryRandom.RandInt(10);
        ElecTaxDeclarationLine."Line Type" := ElecTaxDeclarationLine."Line Type"::Element;
        ElecTaxDeclarationLine.Insert();
    end;

    local procedure CreateElecTaxDeclErrorLog(var ElecTaxDeclErrorLog: Record "Elec. Tax Decl. Error Log"; DeclarationType: Option; DeclarationNo: Code[20])
    begin
        ElecTaxDeclErrorLog."Declaration Type" := DeclarationType;
        ElecTaxDeclErrorLog."Declaration No." := DeclarationNo;
        ElecTaxDeclErrorLog."No." := LibraryRandom.RandInt(10);
        ElecTaxDeclErrorLog.Insert();
    end;

    local procedure CreateElecTaxDeclResponseMsg(var ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg."; DeclarationType: Option; DeclarationNo: Code[20])
    begin
        ElecTaxDeclResponseMsg.Init();
        ElecTaxDeclResponseMsg."Declaration Type" := DeclarationType;
        ElecTaxDeclResponseMsg."Declaration No." := DeclarationNo;
        ElecTaxDeclResponseMsg.Insert(true);
    end;

    local procedure CreateNoSeries(ManualNos: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := ManualNos;
        NoSeries.Insert();
        exit(NoSeries.Code)
    end;

    local procedure CreateNoSeriesLine(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Starting No." := LibraryUTUtility.GetNewCode();
        NoSeriesLine.Insert();
        exit(NoSeriesLine."Starting No.");
    end;

    local procedure CreateElecTaxDeclarationHeaderWithNoSeries(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header"; NoSeriesCode: Code[20]) StartingNo: Code[20]
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        StartingNo := CreateNoSeriesLine(NoSeriesCode);
        UpdateElecTaxDeclarationSetup(ElecTaxDeclarationSetup, NoSeriesCode, NoSeriesCode);  // VAT Declaration Nos and ICP Declaration Nos from No Series.
        ElecTaxDeclarationHeader."Declaration Type" := LibraryRandom.RandIntInRange(0, 1);  // Elec. Tax Declaration Header Declaration Type - VAT Declaration and ICP Declaration.
    end;

    local procedure UpdateElecTaxDeclarationSetup(var ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup"; VATDeclarationNos: Code[20]; ICPDeclarationNos: Code[20])
    begin
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."VAT Declaration Nos." := VATDeclarationNos;
        ElecTaxDeclarationSetup."ICP Declaration Nos." := ICPDeclarationNos;
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure UpdateDeclarationPeriodElecTaxDeclarationHeader(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header"; DeclarationPeriod: Enum "Elec. Tax Declaration Period")
    begin
        ElecTaxDeclarationHeader."Declaration Period" := DeclarationPeriod;
        ElecTaxDeclarationHeader.Modify();
    end;

    local procedure VerifyEnumValue(DeclarationPeriodOption: Option; DeclarationPeriodEnum: Enum "Elec. Tax Declaration Period")
    begin
        Assert.AreEqual(DeclarationPeriodOption, DeclarationPeriodEnum.AsInteger(), 'Invalid value');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DeclarationConfirmHandler(Question: Text; var Reply: Boolean)
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        ElecTaxDeclarationHeader."Declaration Period" := "Elec. Tax Declaration Period".FromInteger(LibraryVariableStorage.DequeueInteger());
        Assert.IsTrue(
          StrPos(Question, StrSubstNo(DeclarationConfirmation, ElecTaxDeclarationHeader."Declaration Period", Format(Date2DMY(Today, 3) - 1))) >
          0, Question);
        Reply := true;
    end;
}

