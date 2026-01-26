codeunit 144190 "IT - Annual VAT Communication"
{
    // Test for new field added on 'VAT Statement Template' and new options added in Annual VAT Communication field in the report and file:
    //   1. Verify 'Activity Code' in exported Annual VAT Communication file.
    //   2. Verify if 'Activity Code' appears in Annual VAT Communication report preview.
    //   3. Verify 'Appointment Code' in exported Annual VAT Communication file.
    //   4. Verify the new option 'CD1 - Sales of Capital Goods' added in Annual VAT Communication field.
    //   5. Verify the new option 'CD2 - Purchases of Capital Goods' added in Annual VAT Communication field.
    //   6. Verify the new option 'CD3 - Gold and Silver Amount' added in Annual VAT Communication field.
    //   7. Verify the new option 'CD3 - Gold and Silver Base' added in Annual VAT Communication field.
    //   8. Verify the new option 'CD3 - Scrap and Recycl. Amount' added in Annual VAT Communication field.
    //   9. Verify the new option 'CD3 - Scrap and Recycl. Base' added in Annual VAT Communication field.
    //   10. Verify exported Annual VAT Communication file when 'Group Settlement is false.
    //   11. Verify exported Annual VAT Communication file when 'Group Settlement is true.
    //   12. Verify 'Company Fiscal Code' in record A of exported Annual VAT Communication file.
    //   13. Verify 'Company Fiscal Code' in record B of exported Annual VAT Communication file.
    //   14. Verify 'Confirmation Flag' in exported Annual VAT Communication file.
    //   15. Verify Company VAT Registration No in exported Annual VAT Communication file.
    //   16. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - EU Sales' in the exported file.
    //   17. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - Sales Of Capital Goods' in the exported file.
    //   18. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - Sales with zero VAT ' in the exported file.
    //   19. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - Total Sales' in the exported file.
    //   20. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - VAT Exempt Sales' in the exported file.
    //   21. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - EU Purchases' in the exported file.
    //   22. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - Purchases Of Capital Goods' in the exported file.
    //   23. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - Purchases with zero VAT' in the exported file.
    //   24. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - Total Purchases' in the exported file.
    //   25. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - VAT Exempt Purchases' in the exported file.
    //   26. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Gold And Silver Amounts' in the exported file.
    //   27. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Gold And Silver Base' in the exported file.
    //   28. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Scrap And Recycl Amount' in the exported file.
    //   29. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Scrap And Recycl Base' in the exported file.
    //   30. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD4 - Payable VAT' in the exported file.
    //   31. Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD5 - Receivable VAT' in the exported file.
    //   32. Run report 'Exp. Annual VAT Communication' and verify the three record types A,B and Z in the exported text file.
    //   33. Verify the 'File Version Code' in exported Annual VAT Communication file.
    //   34. Verify the 'Fiscal Year' in exported Annual VAT Communication file.
    //   35. Verify the 'Legal Entity' in exported Annual VAT Communication file.
    //   36. Verify the number of records of type B in exported Annual VAT Communication file.
    //   37. Verify the 'Separate Accounting' in exported Annual VAT Communication file when 'Separate Ledger' is false.
    //   38. Verify the 'Separate Accounting' in exported Annual VAT Communication file when 'Separate Ledger' is true.
    //   39. Verify 'Special Occurrences' in exported Annual VAT Communication file when 'Exceptional Event' is false.
    //   40. Verify 'Special Occurrences' in exported Annual VAT Communication file when 'Exceptional Event' is true.
    //   41. Verify 'Supplier Type' in exported Annual VAT Communication file when Tax Representative is not blank.
    //   42. Verify 'Supplier Type' in exported Annual VAT Communication file when Tax Representative is blank.
    //   43. Verify 'Tax Code Of Declaration Company' when Tax Representative in not blank.
    //   44. Verify if field 'VAT Stat. Export Report ID' is available on VAT Statement Template page.
    //   45. Verify fiscal code of vendor set as Tax Representative in the exported Annual VAT Communication file.
    //   46. Verify if fiscal code of vendor set as Tax Representative appears in the report preview.
    //   47. Verify Vendor VAT Registration No in exported Annual VAT Communication file when Tax Representative in not blank.
    //   48. Verify if VAT Registration No of vendor set as Tax Representative appear in report preview.
    // 
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------------
    // ActivityCodeInExportedAnnualVATCommunicationFile                                           152822
    // ActivityCodeInReportAnnualVATCommunication
    // AppointmentCodeInExportedAnnualVATCommunicationFile                                        152822
    // CD1SalesOfCapitalGoodsInAnnualVATCommunication                                             202239,202242
    // CD2PurchasesOfCapitalGoodsInAnnualVATCommunication                                         202240,202242
    // CD3GoldAndSilverAmountInAnnualVATCommunication                                             202241
    // CD3GoldAndSilverBaseInAnnualVATCommunication                                               202241
    // CD3ScrapAndRecyclAmountInAnnualVATCommunication                                            202241
    // CD3ScrapAndRecyclBaseInAnnualVATCommunication                                              202241
    // CommunicationByCompanyBelongingToVATGroupWhenGroupSettlementIsFalse                        152842,152822
    // CommunicationByCompanyBelongingToVATGroupWhenGroupSettlementIsTrue                         152842,152822
    // CompanyFiscalCodeInRecordAOfExportedAnnualVATCommunicationFile                             152822
    // CompanyFiscalCodeInRecordBOfExportedAnnualVATCommunicationFile                             152822
    // ConfirmationFlagInExportedAnnualVATCommunicationFile                                       152822
    // CompanyVATRegistrationNoInExportedAnnualVATCommunicationFile                               152822
    // ExportAnnualVATCommunicationWithCD1EUSalesOption
    // ExportAnnualVATCommunicationWithCD1SalesOfCapitalGoodsOption                               202243,202244,202245
    // ExportAnnualVATCommunicationWithCD1SalesWithZeroVATOption
    // ExportAnnualVATCommunicationWithCD1TotalSalesOption
    // ExportAnnualVATCommunicationWithCD1VATExemptSalesOption
    // ExportAnnualVATCommunicationWithCD2EUPurchasesOption
    // ExportAnnualVATCommunicationWithCD2PurchasesOfCapitalGoodsOption                           202243,202244,202245
    // ExportAnnualVATCommunicationWithCD2PurchasesWithZeroVATOption
    // ExportAnnualVATCommunicationWithCD2TotalPurchasesOption
    // ExportAnnualVATCommunicationWithCD2VATExemptPurchasesOption
    // ExportAnnualVATCommunicationWithCD3GoldAndSilverAmountsOption                              202243,202244,202245
    // ExportAnnualVATCommunicationWithCD3GoldAndSilverBaseOption                                 202243,202244,202245
    // ExportAnnualVATCommunicationWithCD3ScrapAndRecyclAmountOption                              202243,202244,202245
    // ExportAnnualVATCommunicationWithCD3ScrapAndRecyclBaseOption                                202243,202244,202245
    // ExportAnnualVATCommunicationWithCD4PayableVATOption
    // ExportAnnualVATCommunicationWithCD5ReceivableVATOption
    // ExportAnnualVATCommunicationWithThreeRecordTypes                                           202243,202244,202245
    // FileVersionCodeInExportedAnnualVATCommunicationFile                                        152822
    // FiscalYearInExportedAnnualVATCommunicationFile                                             152822
    // LegalEntityInExportedAnnualVATCommunicationFile                                            152822
    // NoOfRecordsOfTypeBInExportedAnnualVATCommunicationFile                                     152822
    // SeparateAccountingInExportedFileWhenSeparateLedgerIsFalse                                  152842,152822
    // SeparateAccountingInExportedFileWhenSeparateLedgerIsTrue                                   152842,152822
    // SpecialOccurrencesInExportedFileWhenExceptionalEventIsFalse                                152842,152822
    // SpecialOccurrencesInExportedFileWhenExceptionalEventIsTrue                                 152842,152822
    // SupplierTypeInExportedFileWhenTaxRepresentativeIsNotBlank                                  152822
    // SupplierTypeInExportedFileWhenTaxRepresentativeIsBlank                                     152822
    // TaxCodeOfDeclarationCompanyWhenTaxRepresentativeIsNotBlank                                 152822
    // VATStatExportReportIDOnVATStatementTemplate                                                202238
    // VendorFiscalCodeInExportedAnnualVATCommunicationFile                                       152843
    // VendorFiscalCodeInReportAnnualVATCommunication                                             152821
    // VendorVATRegistrationNoInExportedAnnualVATCommunicationFile                                152843
    // VendorVATRegistrationNoInReportAnnualVATCommunication                                      152821

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        FieldNotFoundErr: Label 'Field %1 is not available.', Comment = '.';
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        SalesOfCapitalGoodsLbl: Label 'Sales of capital goods';
        PurchaseOfCapitalGoodsLbl: Label 'Purchases of capital goods';
        GoldAndSilverBaseLbl: Label 'Industrial gold and pure silver';
        GoldAndSilverAmountLbl: Label 'Scrap and other recycled material';
        WrongValueInReportErr: Label 'Value must be %1 in Report.', Comment = '.';
        WrongValueInFileErr: Label 'Actual value %1  is not the same as Expected value %2', Comment = '.';

    [Test]
    [Scope('OnPrem')]
    procedure AppointmentCodeInExportedAnnualVATCommunicationFile()
    var
        AppointmentCode: Record "Appointment Code";
    begin
        // Verify 'Appointment Code' in exported Annual VAT Communication file.
        if not AppointmentCode.FindFirst() then
            CreateAppointmentCode(AppointmentCode);
        ExportAnnualVATCommunicationWithVariousDetails(AppointmentCode.Code, 2, 235, 2, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CD1SalesOfCapitalGoodsInAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify the new option 'CD1 - Sales of Capital Goods' added in Annual VAT Communication field.
        NewOptionInAnnualVATCommField(SalesOfCapitalGoodsLbl, VATStatementLine."Annual VAT Comm. Field"::"CD1 - Sales of Capital Goods");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CD2PurchasesOfCapitalGoodsInAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify the new option 'CD2 - Purchases of Capital Goods' added in Annual VAT Communication field.
        NewOptionInAnnualVATCommField(
          PurchaseOfCapitalGoodsLbl, VATStatementLine."Annual VAT Comm. Field"::"CD2 - Purchases of Capital Goods");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CD3GoldAndSilverAmountInAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify the new option 'CD3 - Gold and Silver Amount' added in Annual VAT Communication field.
        NewOptionInAnnualVATCommField(GoldAndSilverBaseLbl, VATStatementLine."Annual VAT Comm. Field"::"CD3 - Gold and Silver Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CD3GoldAndSilverBaseInAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify the new option 'CD3 - Gold and Silver Base' added in Annual VAT Communication field.
        NewOptionInAnnualVATCommField(GoldAndSilverBaseLbl, VATStatementLine."Annual VAT Comm. Field"::"CD3 - Gold and Silver Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CD3ScrapAndRecyclAmountInAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify the new option 'CD3 - Scrap and Recycl. Amount' added in Annual VAT Communication field.
        NewOptionInAnnualVATCommField(
          GoldAndSilverAmountLbl, VATStatementLine."Annual VAT Comm. Field"::"CD3 - Scrap and Recycl. Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CD3ScrapAndRecyclBaseInAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify the new option 'CD3 - Scrap and Recycl. Base' added in Annual VAT Communication field.
        NewOptionInAnnualVATCommField(GoldAndSilverAmountLbl, VATStatementLine."Annual VAT Comm. Field"::"CD3 - Scrap and Recycl. Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommunicationByCompanyBelongingToVATGroupWhenGroupSettlementIsFalse()
    begin
        // Verify exported Annual VAT Communication file when 'Group Settlement is false.
        ExportAnnualVATCommunicationWithVariousDetails('0', 2, 217, 1, true, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommunicationByCompanyBelongingToVATGroupWhenGroupSettlementIsTrue()
    begin
        // Verify exported Annual VAT Communication file when 'Group Settlement is true.
        ExportAnnualVATCommunicationWithVariousDetails('1', 2, 217, 1, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyFiscalCodeInRecordAOfExportedAnnualVATCommunicationFile()
    begin
        // Verify 'Company Fiscal Code' in record A of exported Annual VAT Communication file.
        ExportAnnualVATCommunicationWithCompanyFiscalCode(1, 23);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyFiscalCodeInRecordBOfExportedAnnualVATCommunicationFile()
    begin
        // Verify 'Company Fiscal Code' in record B of exported Annual VAT Communication file.
        ExportAnnualVATCommunicationWithCompanyFiscalCode(2, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfirmationFlagInExportedAnnualVATCommunicationFile()
    begin
        // Verify 'Confirmation Flag' in exported Annual VAT Communication file.
        ExportAnnualVATCommunicationWithVariousDetails('1', 2, 90, 1, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyVATRegistrationNoInExportedAnnualVATCommunicationFile()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        CompanyInformation: Record "Company Information";
        ExportedFileName: Text;
    begin
        // Verify Company VAT Registration No in exported Annual VAT Communication file.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        CompanyInformation.Get();
        VerifyExportedFile(
          ExportedFileName, CompanyInformation."VAT Registration No.", 2, 199, StrLen(CompanyInformation."VAT Registration No."));

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD1EUSalesOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - EU Sales' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales", 281);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD1SalesOfCapitalGoodsOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - Sales Of Capital Goods' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD1 - Sales of Capital Goods", 292);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD1SalesWithZeroVATOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 -Sales with zero VAT ' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD1 - Sales with zero VAT", 259);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD1TotalSalesOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - Total Sales' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(VATStatementLine."Annual VAT Comm. Field"::"CD1 - Total sales", 248);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD1VATExemptSalesOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD1 - VAT Exempt Sales' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD1 - VAT exempt sales", 270);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD2EUPurchasesOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - EU Purchases' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(VATStatementLine."Annual VAT Comm. Field"::"CD2 - EU purchases", 336);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD2PurchasesOfCapitalGoodsOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - Purchases of Capital Goods' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD2 - Purchases of Capital Goods", 347);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD2PurchasesWithZeroVATOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - Purchases with zero VAT' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD2 - Purchases with zero VAT", 314);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD2TotalPurchasesOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - Total Purchases' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD2 - Total purchases", 303);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD2VATExemptPurchasesOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD2 - VAT Exempt Purchases' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD2 - VAT exempt purchases", 325);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD3GoldAndSilverAmountsOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Gold and Silver Amount' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD3 - Gold and Silver Amount", 369);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD3GoldAndSilverBaseOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Gold and Silver Base' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD3 - Gold and Silver Base", 358);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD3ScrapAndRecyclAmountOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Scrap and Recycl. Amount' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD3 - Scrap and Recycl. Amount", 391);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD3ScrapAndRecyclBaseOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD3 - Scrap and Recycl. Base' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(
          VATStatementLine."Annual VAT Comm. Field"::"CD3 - Scrap and Recycl. Base", 380);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD4PayableVATOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD4 - Payable VAT' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(VATStatementLine."Annual VAT Comm. Field"::"CD4 - Payable VAT", 402);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithCD5ReceivableVATOption()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the amount for option 'CD5 - Receivable VAT' in the exported file.
        ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(VATStatementLine."Annual VAT Comm. Field"::"CD5 - Receivable VAT", 413);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAnnualVATCommunicationWithThreeRecordTypes()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        ExportedFileName: Text;
    begin
        // Run report 'Exp. Annual VAT Communication' and verify the three record types A,B and Z in the exported text file.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        VerifyExportedFile(ExportedFileName, 'A', 1, 1, 1);
        VerifyExportedFile(ExportedFileName, 'B', 2, 1, 1);
        VerifyExportedFile(ExportedFileName, 'Z', 3, 1, 1);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FileVersionCodeInExportedAnnualVATCommunicationFile()
    begin
        // Verify the 'File Version Code' in exported Annual VAT Communication file.
        ExportAnnualVATCommunicationWithVariousDetails('IVC10', 1, 16, 5, true, true, true);  // IVC10 is the fixed file version.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FiscalYearInExportedAnnualVATCommunicationFile()
    begin
        // Verify the 'Fiscal Year' in exported Annual VAT Communication file.
        ExportAnnualVATCommunicationWithVariousDetails(Format(Date2DMY(WorkDate(), 3), 4), 2, 195, 4, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegalEntityInExportedAnnualVATCommunicationFile()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify the 'Legal Entity' in exported Annual VAT Communication file.
        CompanyInformation.Get();
        ExportAnnualVATCommunicationWithVariousDetails(CompanyInformation.Name, 2, 91, StrLen(CompanyInformation.Name), true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfRecordsOfTypeBInExportedAnnualVATCommunicationFile()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        ExportedFileName: Text;
        NoOfLines: Integer;
    begin
        // Verify the number of records of type B in exported Annual VAT Communication file.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        NoOfLines := LibraryTextFileValidation.CountNoOfLinesWithValue(ExportedFileName, 'B', 1, 1);
        VerifyExportedFile(ExportedFileName, PadStr('', 9 - StrLen(Format(NoOfLines)), '0') + Format(NoOfLines), 3, 16, 9);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeparateAccountingInExportedFileWhenSeparateLedgerIsFalse()
    begin
        // Verify the 'Separate Accounting' in exported Annual VAT Communication file when 'Separate Ledger' is false.
        ExportAnnualVATCommunicationWithVariousDetails('0', 2, 216, 1, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeparateAccountingInExportedFileWhenSeparateLedgerIsTrue()
    begin
        // Verify the 'Separate Accounting' in exported Annual VAT Communication file when 'Separate Ledger' is true.
        ExportAnnualVATCommunicationWithVariousDetails('1', 2, 216, 1, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOccurrencesInExportedFileWhenExceptionalEventIsFalse()
    begin
        // Verify 'Special Occurrences' in exported Annual VAT Communication file when 'Exceptional Event' is false.
        ExportAnnualVATCommunicationWithVariousDetails('0', 2, 218, 1, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOccurrencesInExportedFileWhenExceptionalEventIsTrue()
    begin
        // Verify 'Special Occurrences' in exported Annual VAT Communication file when 'Exceptional Event' is true.
        ExportAnnualVATCommunicationWithVariousDetails('1', 2, 218, 1, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplierTypeInExportedFileWhenTaxRepresentativeIsNotBlank()
    begin
        // Verify 'Supplier Type' in exported Annual VAT Communication file when Tax Representative is not blank.
        ExportAnnualVATCommunicationWithVariousDetails('10', 1, 21, 2, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplierTypeInExportedFileWhenTaxRepresentativeIsBlank()
    var
        CompanyInformation: Record "Company Information";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        ExportedFileName: Text;
    begin
        // Verify 'Supplier Type' in exported Annual VAT Communication file when Tax Representative is blank.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");
        CompanyInformation.Get();
        CompanyInformation.Validate("Tax Representative No.", '');
        CompanyInformation.Modify(true);

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        VerifyExportedFile(ExportedFileName, '01', 1, 21, 2);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxCodeOfDeclarationCompanyWhenTaxRepresentativeIsNotBlank()
    var
        CompanyInformation: Record "Company Information";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        Vendor: Record Vendor;
        ExportedFileName: Text;
    begin
        // Verify 'Tax Code Of Declaration Company' when Tax Representative in not blank.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        CompanyInformation.Get();
        Vendor.Get(CompanyInformation."Tax Representative No.");
        VerifyExportedFile(ExportedFileName, Vendor."Fiscal Code", 2, 74, 16);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATStatExportReportIDOnVATStatementTemplate()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementTemplatesPage: TestPage "VAT Statement Templates";
    begin
        // Verify if field 'VAT Stat. Export Report ID' is available on VAT Statement Template page.

        // Setup.
        Initialize();

        // Exercise: Open VAT Statement Template page.
        VATStatementTemplatesPage.OpenView();

        // Verify: Verify field 'VAT Stat. Export Report ID' on VAT Statement Template page.
        Assert.IsTrue(
          VATStatementTemplatesPage."VAT Stat. Export Report ID".Visible(),
          StrSubstNo(FieldNotFoundErr, VATStatementTemplate.FieldCaption("VAT Stat. Export Report ID")));

        // Tear Down: Close VAT Statement Template page.
        VATStatementTemplatesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorFiscalCodeInExportedAnnualVATCommunicationFile()
    var
        CompanyInformation: Record "Company Information";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        Vendor: Record Vendor;
        ExportedFileName: Text;
    begin
        // Verify 'Tax Code' in exported Annual VAT Communication file when Tax Representative is not blank.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        CompanyInformation.Get();
        Vendor.Get(CompanyInformation."Tax Representative No.");
        VerifyExportedFile(ExportedFileName, Vendor."Fiscal Code", 2, 219, 16);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorFiscalCodeInReportAnnualVATCommunication()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        // Verify if fiscal code of vendor set as Tax Representative appears in the report preview.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report Annual VAT Communication.
        RunReportAnnualVATCommunication(VATStatementName);

        // Verify: Check that the fiscal code of vendor set as Tax Representative appears in the report preview.
        CompanyInformation.Get();
        Vendor.Get(CompanyInformation."Tax Representative No.");
        VerifyDetailsInReportAnnualVATCommunication(Vendor."Fiscal Code");

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorVATRegistrationNoInExportedAnnualVATCommunicationFile()
    var
        CompanyInformation: Record "Company Information";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        Vendor: Record Vendor;
        ExportedFileName: Text;
    begin
        // Verify Vendor VAT Registration No in exported Annual VAT Communication file when Tax Representative in not blank.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        CompanyInformation.Get();
        Vendor.Get(CompanyInformation."Tax Representative No.");
        VerifyExportedFile(ExportedFileName, Vendor."VAT Registration No.", 2, 237, StrLen(Vendor."VAT Registration No."));

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorVATRegistrationNoInReportAnnualVATCommunication()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        // Verify if VAT Registration No of vendor set as Tax Representative appear in report preview.

        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report Annual VAT Communication.
        RunReportAnnualVATCommunication(VATStatementName);

        // Verify: Check that the fiscal code of vendor set as Tax Representative appears in the report preview.
        CompanyInformation.Get();
        Vendor.Get(CompanyInformation."Tax Representative No.");
        VerifyDetailsInReportAnnualVATCommunication(Vendor."VAT Registration No.");

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    local procedure Initialize()
    var
        AppointmentCode: Record "Appointment Code";
    begin
        if IsInitialized then
            exit;

        if not AppointmentCode.FindFirst() then
            CreateAppointmentCode(AppointmentCode);
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAppointmentCode(var AppointmentCode: Record "Appointment Code")
    begin
        AppointmentCode.Init();
        AppointmentCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(AppointmentCode.FieldNo(Code), DATABASE::"Appointment Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Appointment Code", AppointmentCode.FieldNo(Code))));
        AppointmentCode.Insert(true);
        AppointmentCode.Validate(Description, AppointmentCode.Code); // Validating Description with Code as value is not important.
        AppointmentCode.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // Update Bal. Account Type and Bal. Account No. in Gen Journal Batch.
        LibraryERM.FindBankAccount(BankAccount);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(1000, 2));  // Using random value for field Amount.
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; GLAccountNo: Code[20]; Type: Enum "VAT Statement Line Type"; AnnualVATComm: Option)
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(
          "Row No.",
          CopyStr(LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Statement Line", VATStatementLine.FieldNo("Row No."))));
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Account Totaling", GLAccountNo);
        VATStatementLine.Validate("Annual VAT Comm. Field", AnnualVATComm);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateVATStatementTemplateAndName(var VATStatementName: Record "VAT Statement Name")
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
    end;

    local procedure ExportAnnualVATCommunicationWithAnnualVATCommFieldOptions(AnnualVATCommField: Option; StartPos: Integer)
    var
        VATStatementName: Record "VAT Statement Name";
        ExportedFileName: Text;
        ExpectedString: Text;
        Amount: Decimal;
    begin
        // Setup.
        Initialize();
        Amount := SetupTransactionData(VATStatementName, AnnualVATCommField);

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        // Using hard coded value 11 as this is the field length specified in the File Format.
        ExpectedString := PadStr('', 11 - StrLen(Format(Round(Amount, 1))), ' ') + Format(Round(Amount, 1));  // Rounding off amount as it is specified in the file format.
        VerifyExportedFile(ExportedFileName, ExpectedString, 2, StartPos, 11);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    local procedure ExportAnnualVATCommunicationWithCompanyFiscalCode(RowNo: Integer; StartPos: Integer)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        CompanyInformation: Record "Company Information";
        ExportedFileName: Text;
    begin
        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name, true, true, true);

        // Verify: Verify exported Annual VAT Communication file.
        CompanyInformation.Get();
        VerifyExportedFile(ExportedFileName, CompanyInformation."Fiscal Code", RowNo, StartPos, 16);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    local procedure ExportAnnualVATCommunicationWithVariousDetails(ExpectedValue: Text; RowNo: Integer; StartPos: Integer; FieldLength: Integer; SeparateLedger: Boolean; GroupSettlement: Boolean; ExceptionalEvent: Boolean)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        ExportedFileName: Text;
    begin
        // Setup.
        Initialize();
        SetupTransactionData(VATStatementName, VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales");

        // Exercise: Run report and save the exported file.
        ExportedFileName :=
          RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(
            VATStatementName.Name, SeparateLedger, GroupSettlement, ExceptionalEvent);

        // Verify: Verify exported Annual VAT Communication file.
        VerifyExportedFile(ExportedFileName, ExpectedValue, RowNo, StartPos, FieldLength);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    local procedure GenerateFiscalCode() FiscalCode: Code[16]
    var
        Vendor: Record Vendor;
    begin
        // Using PADSTR to genearte a code of 16 characters. Refer test defect TFSID - 288362
        FiscalCode := PadStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor), 16, '0');
    end;

    local procedure NewOptionInAnnualVATCommField(AnnualVATCommFieldType: Text[33]; NewOption: Option)
    var
        VATStatementName: Record "VAT Statement Name";
        Amount: Decimal;
    begin
        // Setup.
        Initialize();
        Amount := SetupTransactionData(VATStatementName, NewOption);

        // Exercise: Run report Annual VAT Communication.
        RunReportAnnualVATCommunication(VATStatementName);

        // Verify: Check that the new option populates in report preview with correct value of Amount.
        VerifyDetailsInReportAnnualVATCommunication(AnnualVATCommFieldType);
        VerifyDecimalInReportAnnualVATCommunication(Amount);

        // Tear Down.
        TearDown(VATStatementName."Statement Template Name");
    end;

    local procedure RunReportAnnualVATCommunication(VATStatementName: Record "VAT Statement Name")
    var
        AppointmentCode: Record "Appointment Code";
        AnnualVATComm2010: Report "Annual VAT Comm. - 2010";
    begin
        AppointmentCode.FindFirst();
        Clear(AnnualVATComm2010);
        AnnualVATComm2010.UseRequestPage(false);
        AnnualVATComm2010.InitializeRequest(
          VATStatementName."Statement Template Name", VATStatementName.Name, AppointmentCode.Code,
          DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        LibraryReportValidation.SetFileName(VATStatementName."Statement Template Name");
        AnnualVATComm2010.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(StatementName: Code[10]; SeparateLedger: Boolean; GroupSettlement: Boolean; ExceptionalEvent: Boolean) ExportedFileName: Text
    var
        VATStatementName: Record "VAT Statement Name";
        AppointmentCode: Record "Appointment Code";
        ExpAnnualVATComm2010: Report "Exp.Annual VAT Comm. - 2010";
    begin
        VATStatementName.SetRange(Name, StatementName);
        VATStatementName.FindFirst();
        VATStatementName.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        AppointmentCode.FindFirst();
        ExpAnnualVATComm2010.SetTableView(VATStatementName);
        ExpAnnualVATComm2010.UseRequestPage(false);
        ExpAnnualVATComm2010.InitializeRequest('', AppointmentCode.Code, SeparateLedger, GroupSettlement, ExceptionalEvent, true);
        ExpAnnualVATComm2010.RunModal();
        ExportedFileName := ExpAnnualVATComm2010.GetServerFileName();
    end;

    local procedure SetupTransactionData(var VATStatementName: Record "VAT Statement Name"; AnnualVATCommType: Option) Amount: Decimal
    var
        GLAccount: Record "G/L Account";
        VATStatementLine: Record "VAT Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        UpdateCompanyInformation();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateVATStatementTemplateAndName(VATStatementName);
        CreateVATStatementLine(
          VATStatementLine, VATStatementName, GLAccount."No.", VATStatementLine.Type::"Account Totaling", AnnualVATCommType);
        CreateGenJournalLine(GenJournalLine, GLAccount."No.");
        Amount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure TearDown(VATStatementTemplateName: Code[10])
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        // Delete VAT Statement Template.
        VATStatementTemplate.SetRange(Name, VATStatementTemplateName);
        VATStatementTemplate.FindFirst();
        VATStatementTemplate.Delete(true);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Fiscal Code" := GenerateFiscalCode();
        Vendor.Validate(
          "VAT Registration No.",
          CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor),
            1, LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."))));
        Vendor.Modify(true);
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", Vendor."VAT Registration No.");
        CompanyInformation."Fiscal Code" := Vendor."Fiscal Code";
        CompanyInformation.Validate("Tax Representative No.", Vendor."No.");
        CompanyInformation.Modify(true);
    end;

    local procedure VerifyDecimalInReportAnnualVATCommunication(ExpectedValue: Decimal)
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(ExpectedValue), StrSubstNo(WrongValueInReportErr, ExpectedValue));
    end;

    local procedure VerifyDetailsInReportAnnualVATCommunication(ExpectedValue: Text)
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(ExpectedValue), StrSubstNo(WrongValueInReportErr, ExpectedValue));
    end;

    local procedure VerifyExportedFile(FileName: Text; ExpectedValue: Text; LineNo: Integer; StartPos: Integer; FieldLength: Integer)
    var
        ActualValue: Text;
    begin
        ActualValue := LibraryTextFileValidation.ReadValueFromLine(FileName, LineNo, StartPos, FieldLength);
        Assert.AreEqual(ExpectedValue, ActualValue, StrSubstNo(WrongValueInFileErr, ActualValue, ExpectedValue));
    end;
}

