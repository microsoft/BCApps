codeunit 144050 "UT TAB EVAT"
{
    //  1. Purpose of this test is to validate Agent Contact Type Tax Payer and Agent Contact ID for Electronic Tax Declaration Setup Table.
    //  2. Purpose of this test is to validate Agent Contact Type Agent and Agent Contact ID for Electronic Tax Declaration Setup Table.
    //  3. Purpose of this test is to validate Agent Contact Type Agent and Agent Contact ID for BECON ID function for Electronic Tax Declaration Setup Table.
    //  4. Purpose of this test is to validate Agent Contact Type Agent and Sign Method function for Electronic Tax Declaration Setup Table.
    //  5. Purpose of this test is to validate Agent Contact Type Agent and Part of Fiscal Entity function for Electronic Tax Declaration Setup Table.
    //  6 -10. Purpose of the test is to validate Category on Table 11411(Elec. Tax Decl. VAT Category) with "By Us (Domestic)", "To Us (Domestic)", "By Us (Foreign)", "To Us (Foreign)", Calculation
    // 11. Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
    //     Verify error "Category must be equal to '1. By Us (Domestic)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
    // 12. Purpose of the test is to validate "To Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
    //     Verify error "Category must be equal to '2. To Us (Domestic)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
    // 13. Purpose of the test is to validate "By Us (Foreign)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
    //     Verify error "Category must be equal to '3. By Us (Foreign)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
    // 14. Purpose of the test is to validate "To Us (Foreign)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
    //     Verify error "Category must be equal to '4. To Us (Foreign)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
    // 15. Purpose of the test is to validate Calculation on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
    //     Verify "Category must be equal to '5. Calculation'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
    // 16. Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
    //     Verify error "Elec. Tax Decl. VAT Category 1A-1 already uses this category and subcategory.".
    // 17. Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
    //     Verify error "Elec. Tax Decl. VAT Category 2A-1 already uses this category and subcategory.".
    // 18. Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
    //     Verify error "Elec. Tax Decl. VAT Category 3A already uses this category and subcategory.".
    // 19. Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
    //     Verify error "Elec. Tax Decl. VAT Category 4A-1 already uses this category and subcategory.".
    // 20. Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
    //     Verify error "Elec. Tax Decl. VAT Category 5A already uses this category and subcategory.".
    // 21. Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 1. By Us (Domestic) and subcategory 1 could not be found"
    //     when Category is set to "1. By Us (Domestic)" with random subcategory.
    // 22. Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 2. To Us (Domestic) and subcategory 1 could not be found"
    //     when Category is set to "2. To Us (Domestic)" with random subcategory.
    // 23. Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 3. To Us (Foreign) and subcategory 1 could not be found"
    //     when Category is set to "3. By Us (Foreign)" with random subcategory.
    // 24. Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 4. To Us (Foreign) and subcategory 1 could not be found"
    //     when Category is set to "4. To Us (Foreign)" with random subcategory.
    // 25. Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 5. Calculation and subcategory 1 could not be found"
    //     when Category is set to "5. Calculation" with random subcategory.
    // 26. Purpose of the test is to verify error "Invalid category" with random Category and subcategory.
    // 27. Purpose of the test is to validate error "Elec. Tax Decl. VAT Category cannot be deleted; one or more VAT statement lines refer to it" on Delete trigger for Table 11411(Elec. Tax Decl. VAT Category).
    // 28. Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for Country/Region Code NL.
    //     The following formats are acceptable: NL#########B##, #########B##" when VAT Registration No. on Company Information is in different format.
    // 29. Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
    //     The VAT Registration number is not valid according to the Modulus-11 checksum algorithm." when VAT Registration No. on Company Information does not fulfill modulus-11 check.
    // 30. Purpose of this test is to verify error "he entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
    //     The last two characters of the VAT Registration number must be digits, but not equal to ''00''". when last two characters of VAT Registration No. on Company Information are equal to 0.
    // 31. Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for Country/Region Code NL.
    //     The following formats are acceptable: NL#########B##, #########B##" when  Fiscal Entity No. on Company Information is in different format.
    // 32. Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
    //     The VAT Registration number is not valid according to the Modulus-11 checksum algorithm." when Fiscal Entity No. on Company Information does not fulfill modulus-11 check.
    // 33. Purpose of this test is to verify error "he entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
    //     The last two characters of the VAT Registration number must be digits, but not equal to ''00''". when last two characters of Fiscal Entity No. on Company Information are equal to 0.
    // 
    // Covers Test Cases for WI - 343069
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                    TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // OnValidateAgentContactIDWithVATContactTypeTaxPayerErr, OnValidateAgentContactIDWithVATContactTypeAgentErr             171594,171560
    // OnValidateAgentContactIDCheckBECONIDErr, OnValidateSignMethodErr, OnValidatePartOfFiscalEntityErr                     171558, 171559
    // 
    // Covers Test Cases for WI - 343295
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                    TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // OnValidateCategoryByUsDomesticElecTaxDeclVATCategory, OnValidateCategoryToUsDomesticElecTaxDeclVATCategory
    // OnValidateCategoryByUsForeignElecTaxDeclVATCategory, OnValidateCategoryToUsForeignElecTaxDeclVATCategory
    // OnValidateCategoryCalculationElecTaxDeclVATCategory, OnValidateByUsDomesticElecTaxDeclVATCategoryError
    // OnValidateToUsDomesticElecTaxDeclVATCategoryError, OnValidateByUsForeignElecTaxDeclVATCategoryError
    // OnValidateToUsForeignElecTaxDeclVATCategoryError, OnValidateCalculationElecTaxDeclVATCategoryError
    // OnValidateByUsDomesticCatElecTaxDeclVATCatError, OnValidateToUsDomesticCatElecTaxDeclVATCatError
    // OnValidateByUsForeignCatElecTaxDeclVATCatError, OnValidateToUsForeignCatElecTaxDeclVATCatError
    // OnValidateCalculationCatElecTaxDeclVATCatError, GetCategoryCodeByUsDomesticError                                       171551
    // GetCategoryCodeToUsDomesticError, GetCategoryCodeByUsForeignError                                                      171590
    // GetCategoryCodeToUsForeignError, GetCategoryCodeCalculationError                                                       171550
    // GetCategoryCodeInvalidCategoryError                                                                                    171592
    // OnDeleteElecTaxDeclVATCategoryError                                                                                    171591
    // VATRegistrationNoError                                                                                                 171552
    // VATRegistrationNoModulusChecksumError                                                                                171599
    // VATRegistrationNoTwoDigitsError                                                                                        171601
    // FiscalEntityNoError                                                                                                    171593
    // FiscalEntityNoModulusChecksum Error                                                                                  171600
    // FiscalEntityNoTwoDigitsError                                                                                           171602

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        DialogCap: Label 'Dialog';
        TestFieldCap: Label 'TestField';
        VatLengthErr: Label 'The VAT registration number must be 14 characters long.';
        VatLastTwoCharsErr: Label 'The last two characters of the VAT Registration number must be digits, but not equal to ''''00''''.';
        VatMod11NotAllowedCharErr: Label 'The VAT registration number must have the format NLdddddddddBdd where d is a digit.';
        VatMod97NotAllowedCharErr: Label 'The VAT registration number for a natural person must have the format NLXXXXXXXXXXdd where d is a digit, and x can be a digit, an uppercase letter, ''+'', or ''*''.';
        VatMod11Err: Label 'The VAT registration number is not valid according to the Modulus-11 checksum algorithm.';
        VatMod97Err: Label 'The VAT registration number is not valid according to the Modulus-97 checksum algorithm.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAgentContactIDWithVATContactTypeTaxPayerErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Agent Contact Type Tax Payer, Agent Contact ID and
        // verify error code, actual error is "Agent Contact ID must be blank if VAT Contact Type and ICP Contact Type are Tax Payer." for Electronic Tax Declaration Setup Table.
        AgentContactIDError(ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer", LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAgentContactIDWithVATContactTypeAgentErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Agent Contact Type Agent, Agent Contact ID and
        // verify error code "Length of Agent Contact ID must be exactly 6 characters if VAT Contact Type or ICP Contact Type is Agent." for Electronic Tax Declaration Setup Table.
        AgentContactIDError(ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAgentContactIDCheckBECONIDErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Agent Contact Type Agent, Agent Contact ID for BECON ID and verify error code "195620 is not a valid BECON ID." function for Electronic Tax Declaration Setup Table.
        AgentContactIDError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, Format(LibraryRandom.RandIntInRange(100000, 200000)));  // Take Random Value.
    end;

    local procedure AgentContactIDError(VATContactType: Option; AgentContactID: Code[10])
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Setup: Create Electronic Tax Delcaration Setup.
        Initialize();
        CreateElectronicTaxDeclarationSetup(ElecTaxDeclarationSetup, VATContactType);

        // Exercise.
        asserterror ElecTaxDeclarationSetup.Validate("Agent Contact ID", AgentContactID);

        // Verify: Verify error code.
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePartOfFiscalEntityErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Agent Contact Type Agent and Part of Fiscal Entity function for Electronic Tax Declaration Setup Table.

        // Setup: Create Electronic Tax Delcaration Setup.
        Initialize();
        CreateElectronicTaxDeclarationSetup(ElecTaxDeclarationSetup, ElecTaxDeclarationSetup."VAT Contact Type"::Agent);
        ElecTaxDeclarationSetup."Agent Contact ID" := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationSetup."Part of Fiscal Entity" := false;

        // Exercise.
        asserterror ElecTaxDeclarationSetup.Validate("Part of Fiscal Entity", true);

        // Verify: Verify error code, actual error is "You cannot change Part of Fiscal Entity when you have Elec. Tax Declaration Header with Status Submitted.".
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCategoryByUsDomesticElecTaxDeclVATCategory()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate Category on Table 11411(Elec. Tax Decl. VAT Category) with "By Us (Domestic)".
        // Setup.
        Initialize();

        // Exercise.
        ElecTaxDeclVATCategory.Validate(Category, ElecTaxDeclVATCategory.Category::"5. Calculation");

        // Verify: Verify "By Us (Domestic)" is blank after Category Validation.
        ElecTaxDeclVATCategory.TestField("By Us (Domestic)", ElecTaxDeclVATCategory."By Us (Domestic)"::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCategoryToUsDomesticElecTaxDeclVATCategory()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate Category on Table 11411(Elec. Tax Decl. VAT Category) with "To Us (Domestic)".
        // Setup.
        Initialize();

        // Exercise.
        ElecTaxDeclVATCategory.Validate(Category, ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)");

        // Verify: Verify "To Us (Domestic)" is blank after Category Validation.
        ElecTaxDeclVATCategory.TestField("To Us (Domestic)", ElecTaxDeclVATCategory."To Us (Domestic)"::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCategoryByUsForeignElecTaxDeclVATCategory()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate Category on Table 11411(Elec. Tax Decl. VAT Category) with "By Us (Foreign)".
        // Setup.
        Initialize();

        // Exercise.
        ElecTaxDeclVATCategory.Validate(Category, ElecTaxDeclVATCategory.Category::"2. To Us (Domestic)");

        // Verify: Verify "By Us (Foreign)" is blank after Category Validation.
        ElecTaxDeclVATCategory.TestField("By Us (Foreign)", ElecTaxDeclVATCategory."By Us (Foreign)"::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCategoryToUsForeignElecTaxDeclVATCategory()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate Category on Table 11411(Elec. Tax Decl. VAT Category) with "To Us (Foreign)".
        // Setup.
        Initialize();

        // Exercise.
        ElecTaxDeclVATCategory.Validate(Category, ElecTaxDeclVATCategory.Category::"3. By Us (Foreign)");

        // Verify: Verify "To Us (Foreign)" is blank after Category Validation.
        ElecTaxDeclVATCategory.TestField("To Us (Foreign)", ElecTaxDeclVATCategory."To Us (Foreign)"::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCategoryCalculationElecTaxDeclVATCategory()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate Category on Table 11411(Elec. Tax Decl. VAT Category) with Calculation.
        // Setup.
        Initialize();

        // Exercise.
        ElecTaxDeclVATCategory.Validate(Category, ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)");

        // Verify: Verify Calculation is blank after Category Validation.
        ElecTaxDeclVATCategory.TestField(Calculation, ElecTaxDeclVATCategory.Calculation::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateByUsDomesticElecTaxDeclVATCategoryError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
        // Verify error "Category must be equal to '1. By Us (Domestic)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
        // Setup.
        Initialize();

        // Exercise & verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::" ", ElecTaxDeclVATCategory.FieldNo("By Us (Domestic)"),
          ElecTaxDeclVATCategory."By Us (Domestic)"::"1a. Sales Amount (High Rate)", TestFieldCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToUsDomesticElecTaxDeclVATCategoryError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "To Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
        // Verify error "Category must be equal to '2. To Us (Domestic)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
        // Setup.
        Initialize();

        // Exercise & verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::" ", ElecTaxDeclVATCategory.FieldNo("To Us (Domestic)"),
          ElecTaxDeclVATCategory."To Us (Domestic)"::"2a. Sales Amount (Tax Withheld)", TestFieldCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateByUsForeignElecTaxDeclVATCategoryError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Foreign)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
        // Verify error "Category must be equal to '3. By Us (Foreign)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
        // Setup.
        Initialize();

        // Exercise & verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::" ", ElecTaxDeclVATCategory.FieldNo("By Us (Foreign)"),
          ElecTaxDeclVATCategory."By Us (Foreign)"::"3a. Sales Amount (Non-EU)", TestFieldCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToUsForeignElecTaxDeclVATCategoryError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "To Us (Foreign)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
        // Verify error "Category must be equal to '4. To Us (Foreign)'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
        // Setup.
        Initialize();

        // Exercise & verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::" ", ElecTaxDeclVATCategory.FieldNo("To Us (Foreign)"),
          ElecTaxDeclVATCategory."To Us (Foreign)"::"4a. Purchase Amount (Non-EU)", TestFieldCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCalculationElecTaxDeclVATCategoryError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate Calculation on Table 11411(Elec. Tax Decl. VAT Category) when Category is set to blank and
        // Verify "Category must be equal to '5. Calculation'  in Elec. Tax Decl. VAT Category: Code=. Current value is ' '".
        // Setup.
        Initialize();

        // Exercise & verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::" ", ElecTaxDeclVATCategory.FieldNo(Calculation),
          ElecTaxDeclVATCategory."By Us (Domestic)"::"1a. Sales Amount (High Rate)", TestFieldCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateByUsDomesticCatElecTaxDeclVATCatError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
        // Verify error "Elec. Tax Decl. VAT Category 1A-1 already uses this category and subcategory.".
        // Setup.
        Initialize();
        CreateElectronicTaxDeclarationVATCategory(
          ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)", ElecTaxDeclVATCategory.FieldNo("By Us (Domestic)"),
          ElecTaxDeclVATCategory."By Us (Domestic)"::"1a. Sales Amount (High Rate)");

        // Exercise & Verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)", ElecTaxDeclVATCategory.FieldNo("By Us (Domestic)"),
          ElecTaxDeclVATCategory."By Us (Domestic)"::"1a. Sales Amount (High Rate)", DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToUsDomesticCatElecTaxDeclVATCatError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
        // Verify error "Elec. Tax Decl. VAT Category 2A-1 already uses this category and subcategory.".
        // Setup.
        Initialize();
        CreateElectronicTaxDeclarationVATCategory(ElecTaxDeclVATCategory.Category::"2. To Us (Domestic)",
          ElecTaxDeclVATCategory.FieldNo("To Us (Domestic)"),
          ElecTaxDeclVATCategory."To Us (Domestic)"::"2a. Sales Amount (Tax Withheld)");

        // Exercise & Verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::"2. To Us (Domestic)", ElecTaxDeclVATCategory.FieldNo("To Us (Domestic)"),
          ElecTaxDeclVATCategory."To Us (Domestic)"::"2a. Sales Amount (Tax Withheld)", DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateByUsForeignCatElecTaxDeclVATCatError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
        // Verify error "Elec. Tax Decl. VAT Category 3A already uses this category and subcategory.".
        // Setup.
        Initialize();
        CreateElectronicTaxDeclarationVATCategory(
          ElecTaxDeclVATCategory.Category::"3. By Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("By Us (Foreign)"),
          ElecTaxDeclVATCategory."By Us (Foreign)"::"3a. Sales Amount (Non-EU)");

        // Exercise & Verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::"3. By Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("By Us (Foreign)"),
          ElecTaxDeclVATCategory."By Us (Foreign)"::"3a. Sales Amount (Non-EU)", DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateToUsForeignCatElecTaxDeclVATCatError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
        // Verify error "Elec. Tax Decl. VAT Category 4A-1 already uses this category and subcategory.".
        // Setup.
        Initialize();
        CreateElectronicTaxDeclarationVATCategory(
          ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("To Us (Foreign)"),
          ElecTaxDeclVATCategory."To Us (Foreign)"::"4a. Purchase Amount (Non-EU)");

        // Exercise & Verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("To Us (Foreign)"),
          ElecTaxDeclVATCategory."To Us (Foreign)"::"4a. Purchase Amount (Non-EU)", DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCalculationCatElecTaxDeclVATCatError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate "By Us (Domestic)" on Table 11411(Elec. Tax Decl. VAT Category) when Category is not equal to blank and
        // Verify error "Elec. Tax Decl. VAT Category 5A already uses this category and subcategory.".
        // Setup.
        Initialize();
        CreateElectronicTaxDeclarationVATCategory(
          ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("To Us (Foreign)"),
          ElecTaxDeclVATCategory."To Us (Foreign)"::"4a. Purchase Amount (Non-EU)");

        // Exercise & Verify.
        ElectronicTaxDeclarationVATCategoryError(
          ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("To Us (Foreign)"),
          ElecTaxDeclVATCategory."To Us (Foreign)"::"4a. Purchase Amount (Non-EU)", DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCategoryCodeByUsDomesticError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 1. By Us (Domestic) and subcategory 1 could not be found"
        // when Category is set to "1. By Us (Domestic)" with random subcategory.
        GetCategoryCode(ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCategoryCodeToUsDomesticError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 2. To Us (Domestic) and subcategory 1 could not be found"
        // when Category is set to "2. To Us (Domestic)" with random subcategory.
        GetCategoryCode(ElecTaxDeclVATCategory.Category::"2. To Us (Domestic)");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCategoryCodeByUsForeignError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 3. To Us (Foreign) and subcategory 1 could not be found"
        // when Category is set to "3. By Us (Foreign)" with random subcategory.
        GetCategoryCode(ElecTaxDeclVATCategory.Category::"3. By Us (Foreign)");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCategoryCodeToUsForeignError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 4. To Us (Foreign) and subcategory 1 could not be found"
        // when Category is set to "4. To Us (Foreign)" with random subcategory.
        GetCategoryCode(ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCategoryCodeCalculationError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to verify error "An Elec. Tax Decl. VAT Category with category 5. Calculation and subcategory 1 could not be found"
        // when Category is set to "5. Calculation" with random subcategory.
        GetCategoryCode(ElecTaxDeclVATCategory.Category::"5. Calculation");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCategoryCodeInvalidCategoryError()
    begin
        // Purpose of the test is to verify error "Invalid category" with random Category and subcategory.
        GetCategoryCode(LibraryRandom.RandInt(5));  // Taken random for Category.
    end;

    local procedure GetCategoryCode(Category: Option)
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Setup.
        Initialize();

        // Exercise.
        asserterror ElecTaxDeclVATCategory.GetCategoryCode(Category, LibraryRandom.RandInt(5));  // Taken random value for Sub Category.

        // Verify.
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteElecTaxDeclVATCategoryError()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        // Purpose of the test is to validate error "Elec. Tax Decl. VAT Category cannot be deleted; one or more VAT statement lines refer to it" on Delete trigger for Table 11411(Elec. Tax Decl. VAT Category).

        // Setup.
        Initialize();
        CreateElectronicTaxDeclarationVATCategory(
          ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)", ElecTaxDeclVATCategory.FieldNo("To Us (Foreign)"),
          ElecTaxDeclVATCategory."To Us (Foreign)"::"4a. Purchase Amount (Non-EU)");

        // Exercise.
        asserterror ElecTaxDeclVATCategory.Delete(true);

        // Verify: Verify error Elec. Tax Decl. VAT Category cannot be deleted; one or more VAT statement lines refer to it.
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegistrationNoError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for Country/Region Code NL.
        // The following formats are acceptable: NL#########B##, #########B##" when VAT Registration No. on Company Information is in different format.
        CompanyInfoVATRegistrationNoError(CompanyInformation.FieldNo("VAT Registration No."), LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegistrationNoModulusChecksumError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
        // The VAT Registration number is not valid according to the Modulus-11 checksum algorithm." when VAT Registration No. on Company Information does not fulfill modulus-11 check.
        CompanyInfoVATRegistrationNoError(CompanyInformation.FieldNo("VAT Registration No."), '123456789B12');  // Taken hard coded value as VAT Registration No. requires modulus operation.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegistrationNoTwoDigitsError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of this test is to verify error "he entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
        // The last two characters of the VAT Registration number must be digits, but not equal to ''00''". when last two characters of VAT Registration No. on Company Information are equal to 0.
        CompanyInfoVATRegistrationNoError(CompanyInformation.FieldNo("VAT Registration No."), '123456789B00');  // Taken hard coded value as VAT Registration No. is in fixed format.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FiscalEntityNoError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for Country/Region Code NL.
        // The following formats are acceptable: NL#########B##, #########B##" when  Fiscal Entity No. on Company Information is in different format.
        CompanyInfoVATRegistrationNoError(CompanyInformation.FieldNo("Fiscal Entity No."), LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FiscalEntityNoModulusChecksumError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of this test is to verify error "The entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
        // The VAT Registration number is not valid according to the Modulus-11 checksum algorithm." when Fiscal Entity No. on Company Information does not fulfill modulus-11 check.
        CompanyInfoVATRegistrationNoError(CompanyInformation.FieldNo("Fiscal Entity No."), '123456789B12');  // Taken hard coded vallue as VAT Registration No. requires modulus operation.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FiscalEntityNoTwoDigitsError()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of this test is to verify error "he entered VAT Registration number is not in agreement with the format specified for electronic tax declaration:
        // The last two characters of the VAT Registration number must be digits, but not equal to ''00''". when last two characters of Fiscal Entity No. on Company Information are equal to 0.
        CompanyInfoVATRegistrationNoError(CompanyInformation.FieldNo("Fiscal Entity No."), '123456789B00');  // Taken hard coded vallue as VAT Registration No. is in fixed format.
    end;

    local procedure CompanyInfoVATRegistrationNoError(FieldNo: Integer; Fieldvalue: Code[20])
    var
        CompanyInformation: Record "Company Information";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();
        RecRef.GetTable(CompanyInformation);
        FieldRef := RecRef.Field(FieldNo);

        // Exercise.
        asserterror FieldRef.Validate(Fieldvalue);

        // Verify.
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    procedure RunCheckCompanyInfoOnVatWithIncorrectLength()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number with length <> 14.
        Initialize();

        // [GIVEN] VAT Registration number of length 15.
        VATRegNo := 'NL1234567891B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about incorrect VAT length is thrown.
        Assert.ExpectedError(VatLengthErr);
        Assert.ExpectedErrorCode('Dialog');

        // [GIVEN] VAT Registration number of length 13.
        VATRegNo := 'NL12345678B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about incorrect VAT length is thrown.
        Assert.ExpectedError(VatLengthErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure RunCheckCompanyInfoOnNonNLVatInNonNLCompany()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        CountryRegion: Record "Country/Region";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number with first chars "AB".
        Initialize();

        // [GIVEN] Company Information with Country/Region Code "KM"
        // [GIVEN] VAT Registration number with first two chars "AB".
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateCountryRegionOnCompany(CountryRegion.Code);
        VATRegNo := 'AB123456789B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.

        // [GIVEN] Company Information with Country/Region Code "NL"
        // [GIVEN] VAT Registration number with first two chars "AB".
        UpdateCountryRegionOnCompany('NL');
        VATRegNo := 'AB123456789B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.
    end;

    [Test]
    procedure RunCheckCompanyInfoOnVatWithIncorrectLastTwoChars()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number with last two chars "1A" or "00".
        Initialize();

        // [GIVEN] VAT Registration number with last two chars "1A".
        VATRegNo := 'NL123456789B1A';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about incorrect last two characters of VAT is thrown.
        Assert.ExpectedError(VatLastTwoCharsErr);
        Assert.ExpectedErrorCode('Dialog');

        // [GIVEN] VAT Registration number with last two chars "00".
        VATRegNo := 'NL123456789B00';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about incorrect last two characters of VAT is thrown.
        Assert.ExpectedError(VatLastTwoCharsErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure RunCheckCompanyInfoOnVatWithLowercaseLetters()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number with lowercase letters.
        Initialize();

        // [GIVEN] VAT Registration number with lowercase letter between NL and B.
        VATRegNo := 'NL1234m6789B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about incorrect characters in VAT is thrown.
        Assert.ExpectedError(VatMod97NotAllowedCharErr);
        Assert.ExpectedErrorCode('Dialog');

        // [GIVEN] VAT Registration number with special character between NL and B.
        VATRegNo := 'NL12345&789B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about incorrect characters in VAT is thrown.
        Assert.ExpectedError(VatMod97NotAllowedCharErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure RunCheckCompanyInfoOnNotValidMod97Vat()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number that is not valid according to Modulus-97 algorithm.
        Initialize();

        // [GIVEN] VAT Registration number that is not valid according to Modulus-97 algorithm.
        VATRegNo := 'NL123456789B12';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about invalid VAT according to Mod-97 is thrown.
        Assert.ExpectedError(VatMod97Err);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure RunCheckCompanyInfoOnValidMod97Vat()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number that is valid according to Modulus-97 algorithm.
        Initialize();

        // [GIVEN] VAT Registration number that is valid according to Modulus-97 algorithm.
        VATRegNo := 'NL123456789B13';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.

        // [GIVEN] VAT Registration number that is valid according to Modulus-97 algorithm.
        VATRegNo := 'NL003714803B30';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.
    end;

    [Test]
    procedure RunCheckCompanyInfoOnValidMod97VatWithLetterOrPlusOrAsterisk()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number that is valid according to Modulus-97 algorithm.
        Initialize();

        // [GIVEN] VAT Registration number with uppercase letter between NL anb B and which is valid according to Modulus-97 algorithm.
        VATRegNo := 'NL0023K2672B25';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.

        // [GIVEN] VAT Registration number with '+' sign between NL and B and which is valid according to Modulus-97 algorithm.
        VATRegNo := 'NL0023+2672B87';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.

        // [GIVEN] VAT Registration number with '*' sign between NL and B and which is valid according to Modulus-97 algorithm.
        VATRegNo := 'NL0023*2672B06';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.
    end;

    [Test]
    procedure RunCheckCompanyInfoOnNotValidMod97Mod11Vat()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
        ErrorText: Text;
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number that is not valid according to Modulus-11 and Modulus-97 algorithm.
        Initialize();

        // [GIVEN] VAT Registration number with uppercase letter between NL anb B and which is not valid according to Mod-11 and Mod-97 algorithm.
        VATRegNo := 'NL0023K2672B24';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        asserterror VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] Error about not allowed characters in VAT according to Mod-11 and about invalid VAT according to Mod-97 is thrown.
        ErrorText := GetLastErrorText();
        Assert.ExpectedMessage(VatMod11NotAllowedCharErr, ErrorText);
        Assert.ExpectedMessage(VatMod97Err, ErrorText);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure RunCheckCompanyInfoOnValidMod11Vat()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Run CheckCompanyInfo function of table VAT Registration No. Format on VAT number that is valid according to Modulus-11 algorithm.
        Initialize();

        // [GIVEN] VAT Registration number which is valid according to Modulus-11 algorithm.
        VATRegNo := 'NL777777770B77';

        // [WHEN] Run CheckCompanyInfo function of VAT Registration No. Format table on this VAT number.
        VATRegistrationNoFormat.CheckCompanyInfo(VATRegNo);

        // [THEN] No errors are thrown.
    end;

    [Test]
    procedure SetValidMod97VatOnCompanyInfoPage()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Set VAT number which is valid according to Mod-97 algorithm to "VAT Registration No." field of page "Company Information".
        Initialize();

        // [WHEN] Set valid Mod-97 VAT Registration number to "VAT Registration No." field of "Company Information" page.
        VATRegNo := 'NL003714803B30';
        CompanyInformationPage.OpenEdit();
        CompanyInformationPage."VAT Registration No.".SetValue(VATRegNo);
        CompanyInformationPage.Close();

        // [THEN] VAT number was set to Company Information.
        CompanyInformation.Get();
        CompanyInformation.TestField("VAT Registration No.", VATRegNo);
    end;

    [Test]
    procedure SetValidMod11VatOnCompanyInfoPage()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        VATRegNo: Text[20];
    begin
        // [SCENARIO 425345] Set VAT number which is valid according to Mod-11 algorithm to "VAT Registration No." field of page "Company Information".
        Initialize();

        // [WHEN] Set valid Mod-97 VAT Registration number to "VAT Registration No." field of "Company Information" page.
        VATRegNo := 'NL777777770B77';
        CompanyInformationPage.OpenEdit();
        CompanyInformationPage."VAT Registration No.".SetValue(VATRegNo);
        CompanyInformationPage.Close();

        // [THEN] VAT number was set to Company Information.
        CompanyInformation.Get();
        CompanyInformation.TestField("VAT Registration No.", VATRegNo);
    end;

    [Test]
    procedure SetNotValidMod97Mod11VatOnCompanyInfoPage()
    var
        CompanyInformationPage: TestPage "Company Information";
        VATRegNo: Text[20];
        ErrorText: Text;
    begin
        // [SCENARIO 425345] Set VAT number which is not valid according to Mod-11 and Mod-97 algorithm to "VAT Registration No." field of page "Company Information".
        Initialize();

        // [WHEN] Set invalid Mod-11 and Mod-97 VAT Registration number to "VAT Registration No." field of "Company Information" page.
        VATRegNo := 'NL003714803B31';
        CompanyInformationPage.OpenEdit();
        asserterror CompanyInformationPage."VAT Registration No.".SetValue(VATRegNo);

        // [THEN] Error about invalid VAT according to Mod-11 and Mod-97 is thrown.
        ErrorText := GetLastErrorText();
        Assert.ExpectedMessage(VatMod11Err, ErrorText);
        Assert.ExpectedMessage(VatMod97Err, ErrorText);
        Assert.ExpectedErrorCode('TestValidation');
    end;

    local procedure Initialize()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT TAB EVAT");
        ElecTaxDeclVATCategory.DeleteAll();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveCompanyInformation();
        IsInitialized := true;
    end;

    local procedure CreateElectronicTaxDeclarationVATCategory(Category: Option; FieldNo: Integer; Fieldvalue: Option)
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        ElecTaxDeclVATCategory.Code := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclVATCategory.Category := Category;
        RecRef.GetTable(ElecTaxDeclVATCategory);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Fieldvalue);
        RecRef.SetTable(ElecTaxDeclVATCategory);
        ElecTaxDeclVATCategory.Insert();
    end;

    local procedure CreateElectronicTaxDeclarationSetup(var ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup"; VATContactType: Option)
    begin
        ElecTaxDeclarationSetup."Primary Key" := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationSetup."VAT Contact Type" := VATContactType;
        ElecTaxDeclarationSetup.Insert();
        CreateElectronicTaxDeclarationHeader();
    end;

    local procedure CreateElectronicTaxDeclarationHeader()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        ElecTaxDeclarationHeader."Declaration Type" := ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration";
        ElecTaxDeclarationHeader."No." := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationHeader.Status := ElecTaxDeclarationHeader.Status::Submitted;
        ElecTaxDeclarationHeader.Insert();
    end;

    local procedure ElectronicTaxDeclarationVATCategoryError(Category: Option; FieldNo: Integer; Fieldvalue: Option; ExpectedErrorCode: Text)
    begin
        // Exercise.
        asserterror CreateElectronicTaxDeclarationVATCategory(Category, FieldNo, Fieldvalue);

        // Verify.
        Assert.ExpectedErrorCode(ExpectedErrorCode);
    end;

    local procedure UpdateCountryRegionOnCompany(CountryRegionCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", CountryRegionCode);
        CompanyInformation.Modify(true);
    end;
}

