codeunit 144049 "UT REP EVAT"
{
    // // [FEATURE] [VAT] [VAT Statement]
    // 1 - 12. Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period =
    //             January, February, March, April, May, June, July, August, September, October, November, December.
    // 13 - 21. Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period =
    //           First Quarter, Second Quarter, Third Quarter, Fourth Quarter, Year, January-February, April-May, July-August, October-November, Year.
    //      22. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact ID is blank on Elec. Tax Declaration Setup.
    //      23. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Phone No is blank on Elec. Tax Declaration Setup.
    //      24. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Address is blank on Elec. Tax Declaration Setup.
    //      25. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Post Code is blank on Elec. Tax Declaration Setup.
    //      26. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact City is blank on Elec. Tax Declaration Setup.
    //      27. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Name is blank on Elec. Tax Declaration Setup.
    //      28. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Tax Payer Contact Phone No is blank on Elec. Tax Declaration Setup.
    //      29. Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Tax Payer Contact Name is blank on Elec. Tax Declaration Setup.
    // 30 - 37. Purpose of this test is to validate Blank Agent Contact ID, Agent Contact Name, Agent Contact Address, Agent Contact Post Code, Agent Contact City, Agent Contact Phone No,
    //          Tax Payer Contact Name and Tax Payer Contact Phone No. on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
    //      38. Purpose of this test is to validate Blank VAT Template Name and VAT Statement Name on Report 11403 Create Elec. VAT Declaration.
    // 39 - 40. Purpose of this test is to validate Agent Details and Tax Payer Details OnAfterGetRecord Trigger of Electronic Tax Declaration Header on Report 11403 Create Elec. VAT Declaration.
    //      41. Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11403 (Create Elec. VAT Declaration).
    //      42. Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11404 (Create Elec. ICP Declaration) with ICP Contact Type Agent.
    //      43. Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11404 (Create Elec. ICP Declaration) with Part of Fiscal Entity as True.
    //      44. Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11404 (Create Elec. ICP Declaration) with Part of Fiscal Entity as False.
    //      45. Purpose of this test is to verify error on Report 11403 (Create Elec. VAT Declaration) with blank Electronic Tax Declaraton VAT Category Code on VAT Statement Line.
    //      46. Purpose of this test is to verify error on Report 11405 (Submit Elec. Tax Declaration) with From E-Mail on Electronic Tax Declaration Setup.
    //      47. Purpose of this test is to verify error on Report 11406 (Process Response Messages) with blank attachment on Electronic Tax Declaration Response Message.
    //      48. Purpose of the test is to validate  OnPreReport Trigger of Report ID - 11408 Receive Response Messages to verify Password error.
    //      49. Purpose of the test is to validate  OnPreReport Trigger of Report ID - 11408 Receive Response Messages to verify Certificate with Type Encryption error.
    //      50. Purpose of the test is to validate  OnPreReport Trigger of Report ID - 11408 Receive Response Messages to verify CA Certificate error.
    //      51. Purpose of the test is to validate  OnPreReport Trigger of Report ID - 11408 Receive Response Messages error, BAPI Log File Name must have a value.
    //      52. Purpose of the test is to validate Elec. Tax Declaration Card Value of Taxonomy "bd-ob:VATIdentificationNumberNLFiscalEntityDivision" should be the same as "Fiscal Entity No." in Company Information when Part of Fiscal Entity as True.
    // 
    // Covers Test Cases for WI - 343067
    // -----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                              TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicICPDeclarationPeriodJanuary, ElectronicICPDeclarationPeriodFebruary
    // ElectronicICPDeclarationPeriodMarch, ElectronicICPDeclarationPeriodApril
    // ElectronicICPDeclarationPeriodMay, ElectronicICPDeclarationPeriodJune                                                           171555
    // ElectronicICPDeclarationPeriodJuly, ElectronicICPDeclarationPeriodAugust
    // ElectronicICPDeclarationPeriodSeptember, ElectronicICPDeclarationPeriodOctober
    // ElectronicICPDeclarationPeriodNovember, ElectronicICPDeclarationPeriodDecember                                                  171553
    // ElectronicICPDeclarationPeriodFirstQuarter, ElectronicICPDeclarationPeriodSecondQuarter
    // ElectronicICPDeclarationPeriodThirdQuarter, ElectronicICPDeclarationPeriodFourthQuarter
    // ElectronicICPDeclarationPeriodJanuaryFebruary, ElectronicICPDeclarationPeriodAprilMay                                           171581
    // ElectronicICPDeclarationPeriodJulyAugust, ElectronicICPDeclarationPeriodOctoberNovember
    // ElectronicICPDeclarationPeriodYear, ElectronicICPDeclarationAgentContactIDError
    // ElectronicICPDeclarationAgentContactNoError, ElectronicICPDeclarationAgentContactAddressError                                   171556
    // ElectronicICPDeclarationAgentContactPostCodeError, ElectronicICPDeclarationAgentContactCityError
    // ElectronicICPDeclarationAgentContactNameError, ElectronicICPDeclarationTaxPayerContPhoneNoError                                 171554
    // ElectronicICPDeclarationTaxPayerContactNameError                                                                                171557
    // 
    // Covers Test Cases for WI - 343069
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicVATDeclarationAgentContactIDErr, ElectronicVATDeclarationAgentContactNameErr                                         171584
    // ElectronicVATDeclarationAgentContactAddressErr, ElectronicVATDeclarationAgentContactPostCodeErr                                171585
    // ElectronicVATDeclarationAgentContactCityErr, ElectronicVATDeclarationAgentContactPhoneNoErr                                    171586
    // ElectronicVATDeclarationTaxPayerContactNameErr, ElectronicVATDeclarationTaxPayerContactPhoneNoErr                              171587
    // ElectronicVATDeclarationVATStmtAndTemplateErr, OnAfterGetRecElecTaxDeclarationHeaderTypeAgent                                  171588
    // OnAfterGetRecElecTaxDeclarationHeaderTypeTaxPayer                                                                              171589
    // 
    // Covers Test Cases for WI - 343288
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicVATDeclarationICPContactTypeAgent                                                                      171563,171564,171575
    // ElectronicICPDeclarationICPContactTypeAgent                                                                      171516,171517,171537
    // ElectronicICPDeclarationPartOfFiscalEntityTrue                                                                          171518,171515
    // ElectronicICPDeclarationPartOfFiscalEntityFalse                                                                                171523
    // 
    // Covers Test Cases for WI - 343619
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicVATDeclarationCategoryCodeErr                                                                                         171649
    // 
    // Covers Test Cases for WI - 344020
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicTaxDeclarationTaxAuthoritiesCertificateErr, ElectronicTaxDeclarationResponseMsgAttachmentErr
    // OnPreReportReceiveResponseMessagesPwdErr, OnPreReportReceiveResponseInvalidCertificateErr
    // OnPreReportReceiveResponseMessagesCACertificateErr, OnPreReportReceiveResponseMessagesBAPILogFileErr
    // 
    // Covers Test Cases for NL - 103683
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicICPDeclarationVATIdentificationNumberNLFiscalEntityDivision                                                          359510
    // 
    // Covers Test Cases for NL - 109083
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // ElectronicICPDeclarationICPContactTypeAgentEmptyContactPrefix
    // ElectronicICPDeclarationICPContactTypeTaxPayerEmptyContactPrefix

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        TestFieldErr: Label 'TestField';
        ContactPrefixTok: Label 'bd-alg:ContactPrefix';
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        TaxedTurnoverSuppliesServicesReducedTariffTok: Label 'bd-i:TaxedTurnoverSuppliesServicesReducedTariff';
        TaxedTurnoverSuppliesServicesOtherRatesTok: Label 'bd-i:TaxedTurnoverSuppliesServicesOtherRates';
        ValueAddedTaxSuppliesServicesReducedTariffTok: Label 'bd-i:ValueAddedTaxSuppliesServicesReducedTariff';
        ValueAddedTaxSuppliesServicesOtherRatesTok: Label 'bd-i:ValueAddedTaxSuppliesServicesOtherRates';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodJanuary()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = January.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer",
          ElecTaxDeclarationHeader."Declaration Period"::January, true, false, true);  // PartOfFiscalEntity, EUService as True and EU3PartyTrade as False.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodFebruary()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = February.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::February, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodMarch()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = March.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::March, false, false, false);  // PartOfFiscalEntity, EUService and EU3PartyTrade as False.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodApril()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = April.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::April, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodMay()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = May.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::May, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodJune()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = June.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::June, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodJuly()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = July.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::July, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodAugust()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = August.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::August, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodSeptember()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = September.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::September, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodOctober()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = October.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::October, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodNovember()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = November.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::November, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodDecember()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = December.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::December, false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodFirstQuarter()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = First Quarter.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"First Quarter", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodSecondQuarter()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = Second Quarter.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"Second Quarter", true, false, true);  // PartOfFiscalEntity, EUService as True and EU3PartyTrade as False.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodThirdQuarter()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = Third Quarter.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"Third Quarter", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodFourthQuarter()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = Fourth Quarter.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"Fourth Quarter", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodJanuaryFebruary()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = January-February.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"January-February", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodAprilMay()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = April-May.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::"April-May", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodJulyAugust()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = July-August.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"July-August", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodOctoberNovember()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Report 11404 (Create Elec. ICP Declaration) with Declaration Period = October-November.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Period"::"October-November", false, true, false);  // PartOfFiscalEntity, EUService as False and EU3PartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPeriodYear()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of the test is to validate Elec. Tax Declaration Header - OnAfterGetRecord Trigger of Report 11404 (Create Elec. ICP Declaration) with Declaration Period = Year.
        CreateElectronicTaxDeclaration(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::Year, true, false, true);  // PartOfFiscalEntity, EUService as True and EU3PartyTrade as False.
    end;

    local procedure CreateElectronicTaxDeclaration(ICPContactType: Option; DeclarationPeriod: Enum "Elec. Tax Declaration Period"; PartOfFiscalEntity: Boolean; EU3PartyTrade: Boolean; EUService: Boolean)
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        No: Code[20];
    begin
        // Setup.
        Initialize();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(ICPContactType, DeclarationPeriod, PartOfFiscalEntity, EU3PartyTrade, EUService);

        // Exercise.
        RunCreateElectronicTaxDeclarationReport(No);

        // Verify: Verify Elec. Tax Declaration Line for ICP Declaration Type Exists.
        ElecTaxDeclarationLine.Init();
        ElecTaxDeclarationLine.SetRange("Declaration Type", ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
        ElecTaxDeclarationLine.SetRange("Declaration No.", No);
        Assert.RecordIsNotEmpty(ElecTaxDeclarationLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationAgentContactIDError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact ID is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Agent Contact ID must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationSetup.FieldNo("Agent Contact ID"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationAgentContactNoError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Phone No is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Agent Contact Phone No. must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationSetup.FieldNo("Agent Contact Phone No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationAgentContactAddressError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Address is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Agent Contact Address must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationSetup.FieldNo("Agent Contact Address"));  // PartOfFiscalEntity, EUService as True and EU3PartyTrade as False.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationAgentContactPostCodeError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Post Code is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Agent Contact Post Code must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationSetup.FieldNo("Agent Contact Post Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationAgentContactCityError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact City is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Agent Contact City must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationSetup.FieldNo("Agent Contact City"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationAgentContactNameError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Agent Contact Name is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Agent Contact Name must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationSetup.FieldNo("Agent Contact Name"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationTaxPayerContPhoneNoError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Tax Payer Contact Phone No is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Tax Payer Contact Phone No. must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationSetup.FieldNo("Tax Payer Contact Phone No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationTaxPayerContactNameError()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to verify error on Report 11404 (Create Elec. ICP Declaration) when Tax Payer Contact Name is blank on Elec. Tax Declaration Setup.
        // Verify Actual Error: "Tax Payer Contact Name must have a value in Elec. Tax Declaration Setup."
        CreateAndModifyElecTaxDeclarationSetup(
          ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationSetup.FieldNo("Tax Payer Contact Name"));
    end;

    local procedure CreateAndModifyElecTaxDeclarationSetup(ICPContactType: Option; FieldNo: Integer)
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        No: Code[20];
    begin
        // Setup.
        Initialize();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ICPContactType, ElecTaxDeclarationHeader."Declaration Period"::January, true, false, true);  // PartOfFiscalEntity, EUService as True and EU3PartyTrade as False.
        ModifyDiffFieldsAsBlankOnElecTaxDeclarationSetup(FieldNo);

        // Exercise.
        asserterror RunCreateElectronicTaxDeclarationReport(No);

        // Verify.
        Assert.ExpectedErrorCode('TestWrapped:TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationAgentContactIDErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact ID and Verify error code "Agent Contact ID must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty."
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, '', LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Blank Agent Contact ID, Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationAgentContactNameErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact Name and verify error code "Agent Contact Name must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty.".
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode(), '', LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Blank Agent Contact Name, Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationAgentContactAddressErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact Address and verify error code "Agent Contact Address must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty."
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '',
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Blank Agent Contact Address, Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationAgentContactPostCodeErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact Post Code and verify error code "Agent Contact Post Code must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty.".
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), '', LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Blank Agent Contact Post Code, Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationAgentContactCityErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact City and verify error code "Agent Contact City must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty."
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', LibraryUTUtility.GetNewCode(), '', '');  // Blank Agent Contact City, Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationAgentContactPhoneNoErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact Phone No and verify error code "Agent Contact Phone No. must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty."
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode10(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '', '');  // Blank Agent Contact Phone No, Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationTaxPayerContactNameErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact Details and Tax Payer Contact No. and verify error code "Tax Payer Contact Name must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty."
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer", '', '', '', '', '', '', LibraryUTUtility.GetNewCode(), '');  // Blank Agent Contact Detais and Tax Payer Contact Phone No.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationTaxPayerContactPhoneNoErr()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Blank Agent Contact Details and Tax Payer Contact Name and verify error code "Tax Payer Contact Phone No. must have a value in Elec. Tax Declaration Setup: Primary Key=. It cannot be zero or empty."
        // on OnInitReport Trigger of Report 11403 Create Elec. VAT Declaration.
        ElectronicVATDeclarationError(
          ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer", '', '', '', '', '', '', '', LibraryUTUtility.GetNewCode());  // Blank Agent Contact Detais and Tax Payer Contact Name.
    end;

    local procedure ElectronicVATDeclarationError(VATContactType: Option; AgentContactID: Code[17]; AgentContactName: Text; AgentContactAddress: Text; AgentContactPostCode: Code[20]; AgentContactCity: Text; AgentContactPhoneNo: Text; TaxPayerContactName: Text; TaxPayerContactPhoneNo: Text)
    begin
        // Setup: Update Electronic Tax Delcaration Setup.
        Initialize();
        UpdateElectronicTaxDeclarationSetup(
          VATContactType, AgentContactID, AgentContactName, AgentContactAddress, AgentContactPostCode, AgentContactCity,
          AgentContactPhoneNo, TaxPayerContactName, TaxPayerContactPhoneNo);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Create Elec. VAT Declaration");

        // Verify: Verify error code.
        Assert.ExpectedErrorCode(TestFieldErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecTaxDeclarationBlankTemplateReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationVATStmtAndTemplateErr()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        // Purpose of this test is to validate Blank VAT Template Name and VAT Statement Name.

        // Setup: Create Electronic Tax Delcaration Header.
        Initialize();
        CreateElecTaxDeclarationHeader(
          ElecTaxDeclarationHeader."Declaration Period"::January, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");

        // Exercise.
        asserterror REPORT.Run(REPORT::"Create Elec. VAT Declaration");

        // Verify: Verify error code, actual error is " Please specify a VAT Template Name and a VAT Statement Name.".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecElecTaxDeclarationHeaderTypeAgent()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Agent Details OnAfterGetRecord Trigger of Electronic Tax Declaration Header on Report 11403 Create Elec. VAT Declaration.
        ElectronicTaxDeclarationHeaderWithType(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Blank Tax Payer Contact Name and Tax Payer Contact Phone No.
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecElecTaxDeclarationHeaderTypeTaxPayer()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose of this test is to validate Tax Payer Details OnAfterGetRecord Trigger of Electronic Tax Declaration Header on Report 11403 Create Elec. VAT Declaration.
        ElectronicTaxDeclarationHeaderWithType(
          ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer", '', '', '', '', '', '',
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Blank Contact Agent Details.
    end;

    local procedure ElectronicTaxDeclarationHeaderWithType(VATContactType: Option; AgentContactID: Code[17]; AgentContactName: Text; AgentContactAddress: Text; AgentContactPostCode: Code[20]; AgentContactCity: Text; AgentContactPhoneNo: Text; TaxPayerContactName: Text; TaxPayerContactPhoneNo: Text)
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        VATStatementLine: Record "VAT Statement Line";
        DeclarationNo: Code[20];
    begin
        // Setup: Update Electronic Tax Delcaration Setup,Create Electronic Tax Delcaration Header and Create VAT Statement Line.
        Initialize();
        UpdateElectronicTaxDeclarationSetup(
          VATContactType, AgentContactID, AgentContactName, AgentContactAddress, AgentContactPostCode, AgentContactCity, AgentContactPhoneNo,
          TaxPayerContactName, TaxPayerContactPhoneNo);
        DeclarationNo :=
          CreateElecTaxDeclarationHeader(
            ElecTaxDeclarationHeader."Declaration Period"::January, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        CreateVATStatementLine(VATStatementLine);
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.

        // Exercise.
        ElectronicTaxDeclarationHeaderByPage(DeclarationNo);

        // Verify: Verify Elec. Tax Declaration Line for VAT Declaration Exists.
        ElecTaxDeclarationLine.Init();
        ElecTaxDeclarationLine.SetRange("Declaration Type", ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclarationLine.SetRange("Declaration No.", DeclarationNo);
        Assert.RecordIsNotEmpty(ElecTaxDeclarationLine);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationICPContactTypeAgent()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        VATStatementLine: Record "VAT Statement Line";
        No: Code[20];
        NamePrefix: Text;
    begin
        // Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11403 (Create Elec. VAT Declaration).
        // Setup.
        Initialize();
        NamePrefix := DelChr(LibraryUTUtility.GetNewCode(), '=', ' ');
        UpdateElectronicTaxDeclarationSetup(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode(),
          NamePrefix + ' ' + LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Tax Payer Contact Name and Tax Payer Contact Phone No as blank.
        No :=
          CreateElecTaxDeclarationHeader(
            ElecTaxDeclarationHeader."Declaration Period"::January, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        CreateVATStatementLine(VATStatementLine);
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        ElecTaxDeclarationSetup.Get();

        // Exercise and Verify: Verify values of bd-i:TaxConsultantNumber and bd-i:ContactPrefix on Elec. Tax Declaration Line.
        RunReportAndVerifyElecTaxDeclarationLine(
          No, 'bd-i:TaxConsultantNumber', 'bd-i:ContactPrefix', ElecTaxDeclarationSetup."Agent Contact ID", NamePrefix);
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationICPContactTypeAgent()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        No: Code[20];
    begin
        // Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11404 (Create Elec. ICP Declaration) with ICP Contact Type Agent.
        // Setup.
        Initialize();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ElecTaxDeclarationSetup."ICP Contact Type"::Agent, ElecTaxDeclarationHeader."Declaration Period"::January, true, false, true);  // PartOfFiscalEntity and EUService as True, EU3PartyTrade as False.
        ElecTaxDeclarationSetup.Get();

        // Exercise and Verify: Verify values of bd-i:TaxConsultantNumber and bd-i:ContactSurname on Elec. Tax Declaration Line.
        RunReportAndVerifyElecTaxDeclarationLine(
          No, 'bd-i:TaxConsultantNumber', 'bd-i:ContactSurname', ElecTaxDeclarationSetup."Agent Contact ID",
          ExtractSurname(ElecTaxDeclarationSetup."Agent Contact Name"));  // Only 6 Starting Characters of Agent Contact ID shows in Beconnr of Elec. Tax Declaration Line.
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationICPContactTypeAgentEmptyContactPrefix()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        DeclarationNo: Code[20];
    begin
        // Elec. Tax Declaration when Agent Contact Name does not provide prefix
        Initialize();
        // [GIVEN] Electronic Tax Declaration Setup with solid Agent Contact Name
        InitEmptyContactPrefixScenario(
          DeclarationNo,
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent,
          ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
        // [WHEN] System Report (11404) "Create Elec. ICP Declaration" generates tax declaration lines
        RunCreateElectronicTaxDeclarationReport(DeclarationNo);
        // [THEN] ContactPrefix lines must not be created (due to no prefix extracted from Agent Contact Name
        VerifyElecTaxDeclarationLineAbsence(DeclarationNo, ContactPrefixTok);
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationICPContactTypeTaxPayerEmptyContactPrefix()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        DeclarationNo: Code[20];
    begin
        // Elec. Tax Declaration when Tax Payer Name does not provide prefix
        Initialize();
        // [GIVEN] Electronic Tax Declaration Setup with solid Tax Payer Name
        InitEmptyContactPrefixScenario(
          DeclarationNo,
          ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer",
          ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
        // [WHEN] System Report (11404) "Create Elec. ICP Declaration" generates tax declaration lines
        RunCreateElectronicTaxDeclarationReport(DeclarationNo);
        // [THEN] ContactPrefix lines must not be created (due to no prefix extracted from Tax Payer Name
        VerifyElecTaxDeclarationLineAbsence(DeclarationNo, ContactPrefixTok);
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPartOfFiscalEntityTrue()
    var
        CompanyInformation: Record "Company Information";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        No: Code[20];
    begin
        // Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11404 (Create Elec. ICP Declaration) with Part of Fiscal Entity as True.
        // Setup.
        Initialize();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationHeader."Declaration Period"::January, true, false,
            true);  // PartOfFiscalEntity and EUService as True, EU3PartyTrade as False.
        ElecTaxDeclarationSetup.Get();
        CompanyInformation.Get();

        // Exercise and Verify: Verify values of bd-i:ContactSurname and bd-i:VATIdentificationNumberNLFiscalEntityDivision on Elec. Tax Declaration Line.
        RunReportAndVerifyElecTaxDeclarationLine(
          No, 'bd-i:ContactSurname', 'bd-i:VATIdentificationNumberNLFiscalEntityDivision',
          ExtractSurname(ElecTaxDeclarationSetup."Tax Payer Contact Name"), DelStr(CompanyInformation."VAT Registration No.", 1, 2));
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPartOfFiscalEntityFalse()
    var
        CompanyInformation: Record "Company Information";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        No: Code[20];
    begin
        // Purpose of the test is to verify Elec. Tax Declaration Header - OnAfterGetRecord of Report 11404 (Create Elec. ICP Declaration) with Part of Fiscal Entity as False.
        // Setup.
        Initialize();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationHeader."Declaration Period"::January, false, false,
            true);  // PartOfFiscalEntity, EU3PartyTrade as False and EUService as True.
        ElecTaxDeclarationSetup.Get();
        CompanyInformation.Get();

        // Exercise and Verify: Verify values of bd-i:ContactSurname and xbrli:identifier on Elec. Tax Declaration Line.
        RunReportAndVerifyElecTaxDeclarationLine(
          No, 'bd-i:ContactSurname', 'xbrli:identifier',
          ExtractSurname(ElecTaxDeclarationSetup."Tax Payer Contact Name"), CopyStr(CompanyInformation."VAT Registration No.", 3));  // Prefix NL in VAT registration number of company deleted in declaration.
        VerifyElecTaxDeclarationLineAbsence(No, 'bd-i:VATIdentificationNumberNLFiscalEntityDivision'); // TFS 209004
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationPartOfFiscalEntityFalseWithEmptyFiscalEntity()
    var
        CompanyInformation: Record "Company Information";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        No: Code[20];
    begin
        // [SCENARIO 204131] 'bd-ob:VATIdentificationNumberNLFiscalEntityDivision' should not be exported when "Part Of Fiscal Entity" is false and "Fiscal Entity No." is empty
        Initialize();

        // [GIVEN] "Part Of Fiscal Entity" is No in Elec.Tax Declaration Setup and "Fiscal Entity No." = '' in Company Information
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationHeader."Declaration Period"::January, false, false,
            true);  // PartOfFiscalEntity, EU3PartyTrade as False and EUService as True.
        CompanyInformation.Get();
        CompanyInformation."Fiscal Entity No." := '';
        CompanyInformation.Modify();

        // [WHEN] Run Create Elec. ICP Declaration report
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Declaration Line with 'bd-ob:VATIdentificationNumberNLFiscalEntityDivision' Name is not created
        VerifyElecTaxDeclarationLineAbsence(No, 'bd-ob:VATIdentificationNumberNLFiscalEntityDivision');
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationIdentifierWhenPartOfFiscalEntitySet()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        VATStatementLine: Record "VAT Statement Line";
        CompanyInformation: Record "Company Information";
        No: Code[20];
    begin
        // [FEATURE] [VAT Declaration]
        // [SCENARIO 196180] The value of "xbrli:identifier" tag of Electronic VAT Declaration is "Fiscal Entity No." from Company Information if "Part of Fiscal Entity " is set in Electronic Tax Declaration Setup

        Initialize();
        // [GIVEN] "VAT Registration No." = "X", "Fiscal Entity No." = "Y" in Company Information
        // [GIVEN] "Part Of Fiscal Entity" is set in Electronic Tax Declaration Setup
        // [GIVEN] Electronic Tax Declaration Header with type "VAT Declaration"
        No :=
          CreateElecTaxDeclarationHeader(
            ElecTaxDeclarationHeader."Declaration Period"::January, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        CreateVATStatementLine(VATStatementLine);
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        ModifyPartOfFiscalEntityInElecTaxDeclarationSetup(true);

        // [WHEN] Run Create Electronic Tax Declaration against Electronic Tax Declaration Header
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Value of Taxonomy "xbrli:identifier" is "Y"
        CompanyInformation.Get();
        VerifyElecTaxDeclarationLine(No, 'xbrli:identifier', CompanyInformation."Fiscal Entity No.");
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicVATDeclarationIdentifierWhenPartOfFiscalEntityIsNotSet()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        VATStatementLine: Record "VAT Statement Line";
        CompanyInformation: Record "Company Information";
        No: Code[20];
    begin
        // [FEATURE] [VAT Declaration]
        // [SCENARIO 196180] The value of "xbrli:identifier" tag of Electronic VAT Declaration is "VAT Registration No." from Company Information if "Part of Fiscal Entity " is not set in Electronic Tax Declaration Setup

        Initialize();
        // [GIVEN] "VAT Registration No." = "X", "Fiscal Entity No." = "Y" in Company Information
        // [GIVEN] "Part Of Fiscal Entity" is not set in Electronic Tax Declaration Setup
        // [GIVEN] Electronic Tax Declaration Header with type "VAT Declaration"
        Initialize();
        No :=
          CreateElecTaxDeclarationHeader(
            ElecTaxDeclarationHeader."Declaration Period"::January, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");
        CreateVATStatementLine(VATStatementLine);
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        ModifyPartOfFiscalEntityInElecTaxDeclarationSetup(false);

        // [WHEN] Run Create Electronic Tax Declaration against Electronic Tax Declaration Header
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Value of Taxonomy "xbrli:identifier" is "X"
        CompanyInformation.Get();
        VerifyElecTaxDeclarationLine(No, 'xbrli:identifier', DelStr(CompanyInformation."VAT Registration No.", 1, 2));
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationVATIdentificationNumberNLFiscalEntityDivision()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInformation: Record "Company Information";
        No: Code[20];
    begin
        // [FEATURE] [ICP Declaration]
        // [SCENARIO 196180] The VAT identification values of Electronic ICP Declaration are correct if "Part of Fiscal Entity " is set in Electronic Tax Declaration Setup

        Initialize();

        // [GIVEN] "VAT Registration No." = "X", "Fiscal Entity No." = "Y" in Company Information
        // [GIVEN] "Part Of Fiscal Entity" is set in Electronic Tax Declaration Setup
        // [GIVEN] Electronic Tax Declaration Header with Type "ICP Declaration"
        UpdateCompanyInformationForFiscalEntityNo();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationHeader."Declaration Period"::January, true, false,
            true);  // PartOfFiscalEntity and EUService as True, EU3PartyTrade as False.

        // [WHEN] Run Create Electronic Tax Declaration against Electronic Tax Declaration Header
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Value of Taxonomy "xbrli:identifier" is "Y"
        // [THEN] Value of Taxonomy "bd-i:VATIdentificationNumberNLFiscalEntityDivision" is "X"
        CompanyInformation.Get();
        VerifyElecTaxDeclarationLine(
          No, 'xbrli:identifier', CompanyInformation."Fiscal Entity No.");
        VerifyElecTaxDeclarationLine(
          No, 'bd-i:VATIdentificationNumberNLFiscalEntityDivision', DelStr(CompanyInformation."VAT Registration No.", 1, 2));
    end;

    [Test]
    [HandlerFunctions('CreateElectronicICPDeclarationRequestPageHadler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ElectronicICPDeclarationVATIdentificationNumberNLNotFiscalEntityDivision()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInformation: Record "Company Information";
        No: Code[20];
    begin
        // [FEATURE] [ICP Declaration]
        // [SCENARIO 196180] The VAT identification values of Electronic ICP Declaration are correct if "Part of Fiscal Entity " is not set in Electronic Tax Declaration Setup

        Initialize();

        // [GIVEN] "VAT Registration No." = "X", "Fiscal Entity No." = "Y" in Company Information
        // [GIVEN] "Part Of Fiscal Entity" is not set in Electronic Tax Declaration Setup
        // [GIVEN] Electronic Tax Declaration Header with Type "ICP Declaration"
        UpdateCompanyInformationForFiscalEntityNo();
        No :=
          ModifyElecTaxDeclarationSetupAndCreateVATEntry(
            ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer", ElecTaxDeclarationHeader."Declaration Period"::January, false, false,
            true);  // PartOfFiscalEntity as False, EUService as True, EU3PartyTrade as False.

        // [WHEN] Run Create Electronic Tax Declaration against Electronic Tax Declaration Header
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Value of Taxonomy "xbrli:identifier" is "X"
        // [THEN] Line "bd-ob:VATIdentificationNumberNLFiscalEntityDivision" is not created (TFS 209004)
        CompanyInformation.Get();
        VerifyElecTaxDeclarationLine(
          No, 'xbrli:identifier', DelStr(CompanyInformation."VAT Registration No.", 1, 2));
        VerifyElecTaxDeclarationLineAbsence(No, 'bd-ob:VATIdentificationNumberNLFiscalEntityDivision');
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecElecTaxDeclarationHeaderTaxTurnOverVATDeclaration1B()
    var
        SalesLine: Record "Sales Line";
        VATStatementLine: Record "VAT Statement Line";
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        No: Code[20];
        Amount: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375329] Export amounts via "Create Elec. VAT Declaration" report for "1b. Sales Amount (Low Rate)"
        Initialize();

        // [GIVEN] "VAT Statement Line" - "L"
        // [GIVEN] "L"."Elec. Tax Declaration Category Code" = "1b. Sales Amount (Low Rate)"
        // [GIVEN] "L"."VAT Prod. Posting Group" = "X"
        // [GIVEN] "L"."Print With" = "Opposite Sign"
        No := CreateElecTaxDeclHeaderWithSetup();
        CreateVATStatementLine(VATStatementLine);

        // [GIVEN] Posted Sales Invoice - "I"
        // [GIVEN] "I"."VAT Prod. Posting Group" = "X"
        // [GIVEN] "I".Amount = 100
        Amount :=
          PostSalesInvoiceForCategory(
            FindCategoryCode(
              ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)",
              ElecTaxDeclVATCategory."By Us (Domestic)"::"1b. Sales Amount (Low Rate)"),
            VATStatementLine,
            SalesLine);

        // [WHEN] Run "Create Elec. VAT Declaration" report
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        Commit();
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Report output has: bd-i:TaxedTurnoverSuppliesServicesReducedTariff = 100
        VerifyElecTaxDeclarationLine(No, TaxedTurnoverSuppliesServicesReducedTariffTok, FormatAmount(Amount));
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecElecTaxDeclarationHeaderTaxTurnOverVATDeclaration1C()
    var
        SalesLine: Record "Sales Line";
        VATStatementLine: Record "VAT Statement Line";
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        No: Code[20];
        Amount: Integer;
        CategoryCode: Code[10];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375329] Export amounts via "Create Elec. VAT Declaration" report for "1c. Sales Amount (Other Non-Zero Rates)"
        Initialize();

        // [GIVEN] "VAT Statement Line" - "L"
        // [GIVEN] "L"."Elec. Tax Declaration Category Code" = "1c. Sales Amount (Other Non-Zero Rates)"
        // [GIVEN] "L"."VAT Prod. Posting Group" = "Y"
        // [GIVEN] "L"."Print With" = "Sign"
        No := CreateElecTaxDeclHeaderWithSetup();
        CategoryCode :=
          FindCategoryCode(
            ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)",
            ElecTaxDeclVATCategory."By Us (Domestic)"::"1c. Sales Amount (Other Non-Zero Rates)");

        CreateVATStatementLine(VATStatementLine);
        InsertVATStatementLine(
          VATStatementLine, CategoryCode, VATStatementLine."Amount Type"::Base,
          VATStatementLine.Type::"VAT Entry Totaling", VATStatementLine."Gen. Posting Type"::Sale);

        // [GIVEN] Posted Sales Invoice - "I"
        // [GIVEN] "I"."VAT Prod. Posting Group" = "Y"
        // [GIVEN] "I".Amount = 100
        Amount := PostSalesInvoiceForCategory(CategoryCode, VATStatementLine, SalesLine);

        // [WHEN] Run "Create Elec. VAT Declaration" report
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        Commit();
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Report output has: bd-i:TaxedTurnoverSuppliesServicesOtherRates = -100
        VerifyElecTaxDeclarationLine(No, TaxedTurnoverSuppliesServicesOtherRatesTok, FormatAmount(-Amount));
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecElecTaxDeclarationHeaderValueAddedVATDeclaration1B()
    var
        SalesLine: Record "Sales Line";
        VATStatementLine: Record "VAT Statement Line";
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        No: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379549] Export amounts via "Create Elec. VAT Declaration" report for "1b. Tax Amount (Low Rate)"
        Initialize();

        // [GIVEN] "VAT Statement Line" - "L"
        // [GIVEN] "L"."Elec. Tax Declaration Category Code" = "1b. Tax Amount (Low Rate)"
        // [GIVEN] "L"."VAT Prod. Posting Group" = "X"
        // [GIVEN] "L"."Print With" = "Opposite Sign"
        No := CreateElecTaxDeclHeaderWithSetup();
        CreateVATStatementLine(VATStatementLine);

        // [GIVEN] Posted Sales Invoice, where "VAT Prod. Posting Group" = "X", Amount = 100, "VAT %" = 15
        PostSalesInvoiceForCategory(
          FindCategoryCode(
            ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)",
            ElecTaxDeclVATCategory."By Us (Domestic)"::"1b. Tax Amount (Low Rate)"),
          VATStatementLine,
          SalesLine);

        // [WHEN] Run "Create Elec. VAT Declaration" report
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        Commit();
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Report output has: bd-i:ValueAddedTaxSuppliesServicesReducedTariff = 100 * 15% = 15
        VerifyElecTaxDeclarationLine(
          No, ValueAddedTaxSuppliesServicesReducedTariffTok, FormatAmount(SalesLine.Amount * SalesLine."VAT %" / 100));
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecElecTaxDeclarationHeaderValueAddedVATDeclaration1C()
    var
        SalesLine: Record "Sales Line";
        VATStatementLine: Record "VAT Statement Line";
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        No: Code[20];
        CategoryCode: Code[10];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379549] Export amounts via "Create Elec. VAT Declaration" report for "1c. Tax Amount (Other Non-Zero Rates)"
        Initialize();

        // [GIVEN] "VAT Statement Line" - "L"
        // [GIVEN] "L"."Elec. Tax Declaration Category Code" = "1c. Tax Amount (Other Non-Zero Rates)"
        // [GIVEN] "L"."VAT Prod. Posting Group" = "Y"
        // [GIVEN] "L"."Print With" = "Sign"
        No := CreateElecTaxDeclHeaderWithSetup();
        CategoryCode :=
          FindCategoryCode(
            ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)",
            ElecTaxDeclVATCategory."By Us (Domestic)"::"1c. Tax Amount (Other Non-Zero Rates)");

        CreateVATStatementLine(VATStatementLine);
        InsertVATStatementLine(
          VATStatementLine, CategoryCode, VATStatementLine."Amount Type"::Amount,
          VATStatementLine.Type::"VAT Entry Totaling", VATStatementLine."Gen. Posting Type"::Sale);

        // [GIVEN] Posted Sales Invoice, where "VAT Prod. Posting Group" = "X", Amount = 100, "VAT %" = 15
        PostSalesInvoiceForCategory(CategoryCode, VATStatementLine, SalesLine);

        // [WHEN] Run "Create Elec. VAT Declaration" report
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        Commit();
        RunCreateElectronicTaxDeclarationReport(No);

        // [THEN] Report output has: bd-i:ValueAddedTaxSuppliesServicesOtherRates = -(100 * 15%) = -15
        VerifyElecTaxDeclarationLine(
          No, ValueAddedTaxSuppliesServicesOtherRatesTok, FormatAmount(-SalesLine.Amount * SalesLine."VAT %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetVATIdentificationNoWhenPartOfFiscalEntityIsSet()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 196180] The return value of GetVATIdentificationNo function in Table 39 "Company Information" is "Fiscal Entity No." when "Part Of Fiscal Entity" is set

        Initialize();
        CompanyInformation.Get();
        Assert.AreEqual(
          CompanyInformation."Fiscal Entity No.", CompanyInformation.GetVATIdentificationNo(true), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetVATIdentificationNoWhenPartOfFiscalEntityIsNotSet()
    var
        CompanyInformation: Record "Company Information";
        NewCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 196180] The return value of GetVATIdentificationNo function in Table 39 "Company Information" is "VAT Registration No." when "Part Of Fiscal Entity" is not set

        Initialize();
        NewCode := LibraryUTUtility.GetNewCode10();
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := 'NL' + NewCode;
        CompanyInformation.Modify();
        Assert.AreEqual(
          NewCode, CompanyInformation.GetVATIdentificationNo(false), '');

        // Tear down
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ElecTaxDeclEndpointsTakenFromTheSetup()
    var
        ElecTaxDeclSetup: Record "Elec. Tax Declaration Setup";
        ElecTaxDeclMgt: Codeunit "Elec. Tax Declaration Mgt.";
    begin
        // [SCENARIO 454920] The endpoints for the electronic tax declaration taken from the Elec. Tax Declaration Setup

        Initialize();
        ElecTaxDeclSetup.DeleteAll();
        ElecTaxDeclSetup."Tax Decl. Schema Version" := LibraryUtility.GenerateGUID();
        ElecTaxDeclSetup."Tax Decl. BD Data Endpoint" := LibraryUtility.GenerateGUID();
        ElecTaxDeclSetup."Tax Decl. BD Tuples Endpoint" := LibraryUtility.GenerateGUID();
        ElecTaxDeclSetup."Tax Decl. Schema Endpoint" := LibraryUtility.GenerateGUID();
        ElecTaxDeclSetup."ICP Decl. Schema Endpoint" := LibraryUtility.GenerateGUID();
        ElecTaxDeclSetup.insert();
        Assert.AreEqual(ElecTaxDeclSetup."Tax Decl. Schema Version", ElecTaxDeclMgt.GetSchemaVersion(), '');
        Assert.AreEqual(ElecTaxDeclSetup."Tax Decl. BD Data Endpoint", ElecTaxDeclMgt.GetBDDataEndpoint(), '');
        Assert.AreEqual(ElecTaxDeclSetup."Tax Decl. BD Tuples Endpoint", ElecTaxDeclMgt.GetBDTuplesEndpoint(), '');
        Assert.AreEqual(ElecTaxDeclSetup."Tax Decl. Schema Endpoint", ElecTaxDeclMgt.GetVATDeclarationSchemaEndpoint(), '');
        Assert.AreEqual(ElecTaxDeclSetup."ICP Decl. Schema Endpoint", ElecTaxDeclMgt.GetICPDeclarationSchemaEndpoint(), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT REP EVAT");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        UpdateCompanyInformation();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT REP EVAT");

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT REP EVAT");
    end;

    local procedure InitEmptyContactPrefixScenario(var DeclarationNo: Code[20]; VATContactType: Option; DeclarationType: Option)
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        VATStatementLine: Record "VAT Statement Line";
    begin
        ElecTaxDeclarationHeader.DeleteAll();
        ElecTaxDeclarationLine.DeleteAll();

        UpdateElectronicTaxDeclarationSetup(
          VATContactType, LibraryUTUtility.GetNewCode10(),
          LibraryUtility.GenerateGUID(),// agent contact name without prefix
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUtility.GenerateGUID(),// tax payer name without prefix
          LibraryUTUtility.GetNewCode());
        DeclarationNo := CreateElecTaxDeclarationHeader(ElecTaxDeclarationHeader."Declaration Period"::January, DeclarationType);
        CreateVATStatementLine(VATStatementLine);
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
    end;

    local procedure CreateElecTaxDeclarationHeader(DeclarationPeriod: Enum "Elec. Tax Declaration Period"; DeclarationType: Option): Code[20]
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        ElecTaxDeclarationHeader."Declaration Type" := DeclarationType;
        ElecTaxDeclarationHeader."No." := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationHeader."Declaration Period" := DeclarationPeriod;
        ElecTaxDeclarationHeader."Declaration Year" := Date2DMY(WorkDate(), 3);
        ElecTaxDeclarationHeader."Our Reference" := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationHeader.Insert();
        exit(ElecTaxDeclarationHeader."No.");
    end;

    local procedure CreateElecTaxDeclHeaderWithSetup(): Code[20]
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        NamePrefix: Text;
    begin
        NamePrefix := DelChr(LibraryUTUtility.GetNewCode(), '=', ' ');

        UpdateElectronicTaxDeclarationSetup(
          ElecTaxDeclarationSetup."VAT Contact Type"::Agent, LibraryUTUtility.GetNewCode10(),
          NamePrefix + ' ' + LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', '');  // Tax Payer Contact Name and Tax Payer Contact Phone No as blank.

        exit(
          CreateElecTaxDeclarationHeader(
            ElecTaxDeclarationHeader."Declaration Period"::Year, ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration"));
    end;

    local procedure CreateVATEntry(EU3PartyTrade: Boolean; EUService: Boolean)
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."VAT Registration No." := LibraryUTUtility.GetNewCode();
        VATEntry."EU 3-Party Trade" := EU3PartyTrade;
        VATEntry."EU Service" := EUService;
        VATEntry.Insert();
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line")
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        InsertVATStatementLine(
          VATStatementLine,
          FindCategoryCode(
            ElecTaxDeclVATCategory.Category::"5. Calculation",
            ElecTaxDeclVATCategory.Calculation::"5g. Tax Amount To Pay/Claim"),
          VATStatementLine."Amount Type"::" ",
          VATStatementLine.Type::"Account Totaling",
          VATStatementLine."Gen. Posting Type"::" ");
    end;

    local procedure InsertVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; CategoryCode: Code[10]; AmountType: Enum "VAT Statement Line Amount Type"; Type: Enum "VAT Statement Line Type"; GenPostingType: Enum "General Posting Type")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementTemplate.FindFirst();
        VATStatementName.FindFirst();
        VATStatementLine."Statement Template Name" := VATStatementTemplate.Name;
        VATStatementLine."Statement Name" := VATStatementName.Name;
        VATStatementLine."Line No." := LibraryUtility.GetNewRecNo(VATStatementLine, VATStatementLine.FieldNo("Line No."));
        VATStatementLine."Elec. Tax Decl. Category Code" := CategoryCode;
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine.Type := Type;
        VATStatementLine."Gen. Posting Type" := GenPostingType;
        VATStatementLine.Insert();
    end;

    local procedure ElectronicTaxDeclarationHeaderByPage(No: Code[20])
    var
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", No);
        ElecTaxDeclarationCard.CreateElectronicTaxDeclaration.Invoke();
    end;

    local procedure FindCategoryCode(Category: Option; SubCategory: Option): Code[10]
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        exit(ElecTaxDeclVATCategory.GetCategoryCode(Category, SubCategory));
    end;

    local procedure FormatAmount(Value: Decimal): Text
    begin
        exit(Format(Value, 0, '<Sign><Integer>'))
    end;

    local procedure ModifyDiffFieldsAsBlankOnElecTaxDeclarationSetup(FieldNo: Integer)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        ElecTaxDeclarationSetup.Get();
        RecRef.GetTable(ElecTaxDeclarationSetup);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate('');  // Set Field Value as blank.
        RecRef.SetTable(ElecTaxDeclarationSetup);
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure ModifyElecTaxDeclarationSetupAndCreateVATEntry(ICPContactType: Option; DeclarationPeriod: Enum "Elec. Tax Declaration Period"; PartOfFiscalEntity: Boolean; EU3PartyTrade: Boolean; EUService: Boolean) No: Code[20]
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."ICP Contact Type" := ICPContactType;
        ElecTaxDeclarationSetup."Agent Contact ID" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Agent Contact Name" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Agent Contact Phone No." := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Agent Contact Address" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Agent Contact Post Code" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Agent Contact City" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Tax Payer Contact Name" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Tax Payer Contact Phone No." := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Part of Fiscal Entity" := PartOfFiscalEntity;
        ElecTaxDeclarationSetup.Modify();
        No := CreateElecTaxDeclarationHeader(DeclarationPeriod, ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");
        CreateVATEntry(EU3PartyTrade, EUService);
    end;

    local procedure ModifyPartOfFiscalEntityInElecTaxDeclarationSetup(PartOfFiscalEntity: Boolean)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."Part of Fiscal Entity" := PartOfFiscalEntity;
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure PostSalesInvoiceForCategory(CategoryCode: Code[10]; var VATStatementLine: Record "VAT Statement Line"; var SalesLine: Record "Sales Line"): Integer
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        VATStatementLine.SetRange("Elec. Tax Decl. Category Code", CategoryCode);
        VATStatementLine.FindFirst();
        VATStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStatementLine.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(500));
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(SalesLine."Line Amount");
    end;

    local procedure RunCreateElectronicTaxDeclarationReport(No: Code[20])
    var
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", No);
        ElecTaxDeclarationCard.CreateElectronicTaxDeclaration.Invoke();
        ElecTaxDeclarationCard.Close();
    end;

    local procedure RunReportAndVerifyElecTaxDeclarationLine(No: Code[20]; Caption: Text; Caption2: Text; Value: Text; Value2: Text)
    begin
        // Exercise.
        RunCreateElectronicTaxDeclarationReport(No);

        // Verify.
        VerifyElecTaxDeclarationLine(No, Caption, Value);
        VerifyElecTaxDeclarationLine(No, Caption2, Value2);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Fiscal Entity No." := LibraryUTUtility.GetNewCode();
        CompanyInformation.Modify();
    end;

    local procedure UpdateCompanyInformationForFiscalEntityNo(): Text[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Fiscal Entity No.", '777777770B77');
        CompanyInformation.Modify(true);
        exit(CompanyInformation."Fiscal Entity No.");
    end;

    local procedure UpdateElectronicTaxDeclarationSetup(VATContactType: Option; AgentContactID: Code[17]; AgentContactName: Text; AgentContactAddress: Text; AgentContactPostCode: Code[20]; AgentContactCity: Text; AgentContactPhoneNo: Text; TaxPayerContactName: Text; TaxPayerContactPhoneNo: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup."VAT Contact Type" := VATContactType;
        ElecTaxDeclarationSetup."Agent Contact ID" := AgentContactID;
        ElecTaxDeclarationSetup."Agent Contact Name" := AgentContactName;
        ElecTaxDeclarationSetup."Agent Contact Address" := AgentContactAddress;
        ElecTaxDeclarationSetup."Agent Contact Post Code" := AgentContactPostCode;
        ElecTaxDeclarationSetup."Agent Contact City" := AgentContactCity;
        ElecTaxDeclarationSetup."Agent Contact Phone No." := AgentContactPhoneNo;
        ElecTaxDeclarationSetup."Tax Payer Contact Name" := TaxPayerContactName;
        ElecTaxDeclarationSetup."Tax Payer Contact Phone No." := TaxPayerContactPhoneNo;
        ElecTaxDeclarationSetup."Part of Fiscal Entity" := true;
        ElecTaxDeclarationSetup."Service Agency Contact ID" := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationSetup."Service Agency Contact Name" := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup."Svc. Agency Contact Phone No." := LibraryUTUtility.GetNewCode();
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure VerifyElecTaxDeclarationLine(DeclarationNo: Code[20]; Name: Text; Data: Text)
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclarationLine.SetRange("Declaration No.", DeclarationNo);
        ElecTaxDeclarationLine.SetRange(Name, Name);
        ElecTaxDeclarationLine.FindFirst();
        ElecTaxDeclarationLine.TestField(Data, Data);
    end;

    local procedure VerifyElecTaxDeclarationLineAbsence(DeclarationNo: Code[20]; Name: Text)
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclarationLine.Init();
        ElecTaxDeclarationLine.SetRange("Declaration No.", DeclarationNo);
        ElecTaxDeclarationLine.SetRange(Name, Name);
        Assert.RecordIsEmpty(ElecTaxDeclarationLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateElectronicICPDeclarationRequestPageHadler(var CreateElecICPDeclaration: TestRequestPage "Create Elec. ICP Declaration")
    begin
        CreateElecICPDeclaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateElecVATDeclarationRequestPageHandler(var CreateElecVATDeclaration: TestRequestPage "Create Elec. VAT Declaration")
    var
        VATTemplateName: Variant;
        VATStatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATTemplateName);
        LibraryVariableStorage.Dequeue(VATStatementName);
        CreateElecVATDeclaration.VATTemplateName.SetValue(VATTemplateName);
        CreateElecVATDeclaration.VATStatementName.SetValue(VATStatementName);
        CreateElecVATDeclaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateElecTaxDeclarationBlankTemplateReqPageHandler(var CreateElecVATDeclaration: TestRequestPage "Create Elec. VAT Declaration")
    begin
        CreateElecVATDeclaration.VATTemplateName.SetValue('');
        CreateElecVATDeclaration.VATStatementName.SetValue('');
        CreateElecVATDeclaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
    end;

    local procedure ExtractSurname(FullName: Text[35]) Surname: Text[35]
    begin
        Surname := CopyStr(FullName, StrPos(FullName, ' ') + 1)
    end;
}

