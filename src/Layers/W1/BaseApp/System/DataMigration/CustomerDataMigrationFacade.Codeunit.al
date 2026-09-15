namespace System.Integration;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;

codeunit 6112 "Customer Data Migration Facade"
{
    TableNo = "Data Migration Parameters";

    trigger OnRun()
    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
        ChartOfAccountsMigrated: Boolean;
    begin
        ChartOfAccountsMigrated := DataMigrationStatusFacade.HasMigratedChartOfAccounts(Rec);
        if Rec.FindSet() then
            repeat
                OnMigrateCustomer(Rec."Staging Table RecId To Process");
                OnMigrateCustomerDimensions(Rec."Staging Table RecId To Process");

                // migrate transactions for this customer
                OnMigrateCustomerPostingGroups(Rec."Staging Table RecId To Process", ChartOfAccountsMigrated);
                OnMigrateCustomerTransactions(Rec."Staging Table RecId To Process", ChartOfAccountsMigrated);
                GenJournalLineIsSet := false;
                CustomerIsSet := false;
            until Rec.Next() = 0;
    end;

    var
        GlobalCustomer: Record Customer;
        GlobalGenJournalLine: Record "Gen. Journal Line";
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
        CustomerIsSet: Boolean;
        GenJournalLineIsSet: Boolean;

        InternalCustomerNotSetErr: Label 'Internal Customer is not set. Create it first.';
        InternalGenJournalLineNotSetErr: Label 'Internal Gen. Journal Line is not set. Create it first.';
        InternalCustomerPostingSetupNotSetErr: Label 'Internal Customer Posting Setup is not set. Create it first.';

    [IntegrationEvent(true, false)]
    local procedure OnMigrateCustomer(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateCustomerDimensions(RecordIdToMigrate: RecordID)
    begin
    end;

    procedure CreateCustomerIfNeeded(CustomerNoToSet: Code[20]; CustomerNameToSet: Text[100]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNoToSet) then begin
            GlobalCustomer := Customer;
            CustomerIsSet := true;
            exit;
        end;

        Customer.Init();

        Customer.Validate("No.", CustomerNoToSet);
        Customer.Validate(Name, CustomerNameToSet);

        Customer.Insert(true);

        GlobalCustomer := Customer;
        CustomerIsSet := true;
        exit(true);
    end;

    procedure CreatePostingSetupIfNeeded(CustomerPostingGroupCode: Code[20]; CustomerPostingGroupDescription: Text[50]; ReceivablesAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then begin
            CustomerPostingGroup.Init();
            CustomerPostingGroup.Validate(Code, CustomerPostingGroupCode);
            CustomerPostingGroup.Validate(Description, CustomerPostingGroupDescription);
            CustomerPostingGroup.Validate("Receivables Account", ReceivablesAccount);
            CustomerPostingGroup.Insert(true);
        end else
            if CustomerPostingGroup."Receivables Account" <> ReceivablesAccount then begin
                CustomerPostingGroup.Validate("Receivables Account", ReceivablesAccount);
                CustomerPostingGroup.Modify(true);
            end;
    end;

    procedure CreateGeneralJournalBatchIfNeeded(GeneralJournalBatchCode: Code[10]; NoSeriesCode: Code[20]; PostingNoSeriesCode: Code[20])
    begin
        DataMigrationFacadeHelper.CreateGeneralJournalBatchIfNeeded(GeneralJournalBatchCode, NoSeriesCode, PostingNoSeriesCode);
    end;

    procedure CreateGeneralJournalLine(GeneralJournalBatchCode: Code[10]; DocumentNo: Code[20]; Description: Text[50]; PostingDate: Date; DueDate: Date; Amount: Decimal; AmountLCY: Decimal; Currency: Code[10]; BalancingAccount: Code[20])
    begin
        DataMigrationFacadeHelper.CreateGeneralJournalLine(GlobalGenJournalLine,
          GeneralJournalBatchCode,
          DocumentNo,
          Description,
          GlobalGenJournalLine."Account Type"::Customer,
          GlobalCustomer."No.",
          PostingDate,
          DueDate,
          Amount,
          AmountLCY,
          Currency,
          BalancingAccount);
        GenJournalLineIsSet := true;
    end;

    procedure SetGeneralJournalLineDimension(DimensionCode: Code[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Dimension Set ID",
          DataMigrationFacadeHelper.CreateDimensionSetId(GlobalGenJournalLine."Dimension Set ID",
            DimensionCode, DimensionDescription,
            DimensionValueCode, DimensionValueName));
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGeneralJournalLineDocumentType(DocumentTypeToSet: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund)
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Document Type", DocumentTypeToSet);
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGeneralJournalLineSourceCode(SourceCodeToSet: Code[10])
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Source Code", SourceCodeToSet);
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGeneralJournalLineExternalDocumentNo(ExternalDocumentNoToSet: Code[35])
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("External Document No.", ExternalDocumentNoToSet);
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGeneralJournalLineSalesPersonCode(SalespersonCodeToSet: Code[20])
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Salespers./Purch. Code", SalespersonCodeToSet);
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGeneralJournalLinePaymentTerms(PaymentTermsCodeToSet: Code[10])
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Payment Terms Code", PaymentTermsCodeToSet);
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGlobalCustomer(CustomerNo: Code[20]): Boolean
    begin
        CustomerIsSet := GlobalCustomer.Get(CustomerNo);
        exit(CustomerIsSet);
    end;

    procedure ModifyCustomer(RunTrigger: Boolean)
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Modify(RunTrigger);
    end;

    procedure SetSearchName(SearchNameToSet: Code[50])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Search Name", SearchNameToSet);
    end;

    procedure DoesCustomerExist(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        exit(Customer.Get(CustomerNo));
    end;

    procedure SetAddress(AdressToSet: Text[50]; Adress2ToSet: Text[50]; CountryRegionCodeToSet: Code[10]; PostCodeToSet: Code[20]; CityToSet: Text[30])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate(Address, AdressToSet);
        GlobalCustomer.Validate("Address 2", Adress2ToSet);
        GlobalCustomer.Validate("Country/Region Code", CountryRegionCodeToSet);
        GlobalCustomer.Validate("Post Code", PostCodeToSet);
        GlobalCustomer.Validate(City, CityToSet);
    end;

    procedure SetPhoneNo(PhoneNoToSet: Text[30])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Phone No.", PhoneNoToSet);
    end;

    procedure SetTelexNo(TelexNoToSet: Text[20])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Telex No.", TelexNoToSet);
    end;

    procedure SetCreditLimitLCY(CreditLimitToSet: Decimal)
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Credit Limit (LCY)", CreditLimitToSet);
    end;

    procedure SetCurrencyCode(CurrencyCodeToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Currency Code", DataMigrationFacadeHelper.FixIfLcyCode(CurrencyCodeToSet));
    end;

    procedure SetCustomerPriceGroup(CustomerPriceGroupToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Customer Price Group", CustomerPriceGroupToSet);
    end;

    procedure SetGenBusPostingGroup(GenBusPostingGroupToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Gen. Bus. Posting Group", GenBusPostingGroupToSet);
    end;

    procedure SetLanguageCode(LanguageCodeToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Language Code", LanguageCodeToSet);
    end;

    procedure SetShipmentMethodCode(ShipmentMethodCodeToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Shipment Method Code", ShipmentMethodCodeToSet);
    end;

    procedure SetPaymentTermsCode(PaymentTermsCodeToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Payment Terms Code", PaymentTermsCodeToSet);
    end;

    procedure SetSalesPersonCode(SalespersonCodeToSet: Code[20])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Salesperson Code", SalespersonCodeToSet);
    end;

    procedure SetInvoiceDiscCode(InvoiceDiscCodeToSet: Code[20])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Invoice Disc. Code", InvoiceDiscCodeToSet);
    end;

    procedure SetBlocked(BlockedTypeToSet: Enum "Customer Blocked")
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate(Blocked, BlockedTypeToSet);
    end;

    procedure SetFaxNo(FaxNoToSet: Text[30])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Fax No.", FaxNoToSet);
    end;

    procedure SetVATRegistrationNo(VatRegistrationNoToSet: Text[20])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("VAT Registration No.", VatRegistrationNoToSet);
    end;

    procedure SetHomePage(HomePageToSet: Text[80])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Home Page", HomePageToSet);
    end;

    procedure SetBillToCustomerNo(BillToCustomerToSet: Code[20])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Bill-to Customer No.", BillToCustomerToSet);
    end;

    procedure SetPaymentMethodCode(PaymentMethodCodeToSet: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Payment Method Code", PaymentMethodCodeToSet);
    end;

    procedure SetContact(ContactToSet: Text[50])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate(Contact, ContactToSet);
    end;

    procedure SetLastDateModified(LastDateModifiedToSet: Date)
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Last Date Modified", LastDateModifiedToSet);
    end;

    procedure SetLastModifiedDateTime(LastModifiedDateTimeToSet: DateTime)
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Last Modified Date Time", LastModifiedDateTimeToSet);
    end;

    procedure SetTaxLiable(TaxLiable: Boolean)
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Tax Liable", TaxLiable);
    end;

    procedure SetTaxAreaCode(TaxAreaCodeToSet: Code[20])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Tax Area Code", TaxAreaCodeToSet);
    end;

    procedure SetEmail(EmailToSet: Text[80])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("E-Mail", EmailToSet);
    end;

    procedure SetName2(Name2: Text[50])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Name 2", Name2);
    end;

    procedure SetTerritoryCode(TerritoryCode: Code[10])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Territory Code", TerritoryCode);
    end;

    procedure SetPrintStatement(PrintStatement: Boolean)
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        GlobalCustomer.Validate("Print Statements", PrintStatement);
    end;

    procedure CreateDefaultDimensionAndRequirementsIfNeeded(DimensionCode: Text[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        DataMigrationFacadeHelper.GetOrCreateDimension(DimensionCode, DimensionDescription, Dimension);
        DataMigrationFacadeHelper.GetOrCreateDimensionValue(Dimension.Code, DimensionValueCode, DimensionValueName,
          DimensionValue);
        DataMigrationFacadeHelper.CreateOnlyDefaultDimensionIfNeeded(Dimension.Code, DimensionValue.Code,
          DATABASE::Customer, GlobalCustomer."No.");
    end;

    procedure CreateCustomerDiscountGroupIfNeeded(CodeToSet: Code[20]; DescriptionToSet: Text[50]): Code[20]
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        if CustomerDiscountGroup.Get(CodeToSet) then
            exit(CodeToSet);

        CustomerDiscountGroup.Init();
        CustomerDiscountGroup.Validate(Code, CodeToSet);
        CustomerDiscountGroup.Validate(Description, DescriptionToSet);
        CustomerDiscountGroup.Insert(true);
        exit(CustomerDiscountGroup.Code);
    end;

    procedure CreateShipmentMethodIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreateShipmentMethodIfNeeded(CodeToSet, DescriptionToSet));
    end;

    procedure CreateSalespersonPurchaserIfNeeded(CodeToSet: Code[20]; NameToSet: Text[50]; PhoneNoToSet: Text[30]; EmailToSet: Text[80]): Code[20]
    begin
        exit(DataMigrationFacadeHelper.CreateSalespersonPurchaserIfNeeded(CodeToSet, NameToSet, PhoneNoToSet, EmailToSet));
    end;

    procedure CreateCustomerPriceGroupIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; PriceIncludesVatToSet: Boolean): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreateCustomerPriceGroupIfNeeded(CodeToSet, DescriptionToSet, PriceIncludesVatToSet));
    end;

    procedure CreatePaymentTermsIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; DueDateCalculationToSet: DateFormula): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreatePaymentTermsIfNeeded(CodeToSet, DescriptionToSet, DueDateCalculationToSet));
    end;

    procedure CreatePaymentMethodIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreatePaymentMethodIfNeeded(CodeToSet, DescriptionToSet));
    end;

    procedure CreateTerritoryCodeIfNeeded(TerritoryCodeToSet: Code[10]; TerritoryNameToSet: Text[50]): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreateTerritoryIfNeeded(TerritoryCodeToSet, TerritoryNameToSet));
    end;

    procedure CreateTaxAreaIfNeeded(TaxAreaCodeToSet: Code[20]; TaxDescriptionToSet: Text[50]): Code[20]
    begin
        exit(DataMigrationFacadeHelper.CreateTaxAreaIfNeeded(TaxAreaCodeToSet, TaxDescriptionToSet));
    end;

    procedure DoesPostCodeExist(CodeToSearch: Code[20]; CityToSearch: Text[30]): Boolean
    begin
        exit(DataMigrationFacadeHelper.DoesPostCodeExist(CodeToSearch, CityToSearch));
    end;

    procedure CreatePostCodeIfNeeded(CodeToSet: Code[20]; CityToSet: Text[30]; CountyToSet: Text[30]; CountryRegionCodeToSet: Code[10]): Boolean
    begin
        exit(DataMigrationFacadeHelper.CreatePostCodeIfNeeded(CodeToSet, CityToSet, CountyToSet, CountryRegionCodeToSet));
    end;

    procedure CreateCountryIfNeeded(CodeToSet: Code[10]; NameToSet: Text[50]; AddressFormatToSet: Option "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City"; ContactAddressFormatToSet: Option First,"After Company Name",Last): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreateCountryIfNeeded(CodeToSet, NameToSet, AddressFormatToSet, ContactAddressFormatToSet));
    end;

    procedure SearchCountry(CodeToSearch: Code[10]; NameToSearch: Text[50]; EUCountryRegionCodeToSearch: Code[10]; IntrastatCodeToSet: Code[10]; var CodeToGet: Code[10]): Boolean
    begin
        exit(
          DataMigrationFacadeHelper.SearchCountry(CodeToSearch, NameToSearch, EUCountryRegionCodeToSearch, IntrastatCodeToSet, CodeToGet));
    end;

    procedure SearchLanguage(AbbreviatedNameToSearch: Code[3]; var CodeToGet: Code[10]): Boolean
    begin
        exit(DataMigrationFacadeHelper.SearchLanguage(AbbreviatedNameToSearch, CodeToGet));
    end;

    procedure SetCustomerPostingGroup(CustomerPostingGroupCode: Code[20]): Boolean
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            exit;

        GlobalCustomer.Validate("Customer Posting Group", CustomerPostingGroupCode);

        exit(true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateCustomerPostingGroups(RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateCustomerTransactions(RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
    end;

    procedure SetCustomerPostingGroupAccounts(CustomerPostingGroupCode: Code[20]; ReceivablesAccount: Code[20]; ServiceChargeAcc: Code[20]; PaymentDiscDebitAcc: Code[20]; InvoiceRoundingAccount: Code[20]; AdditionalFeeAccount: Code[20]; InterestAccount: Code[20]; DebitCurrApplnRndgAcc: Code[20]; CreditCurrApplnRndgAcc: Code[20]; DebitRoundingAccount: Code[20]; CreditRoundingAccount: Code[20]; PaymentDiscCreditAcc: Code[20]; PaymentToleranceDebitAcc: Code[20]; PaymentToleranceCreditAcc: Code[20]; AddFeePerLineAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            exit;

        CustomerPostingGroup.Validate("Receivables Account", ReceivablesAccount);
        CustomerPostingGroup.Validate("Service Charge Acc.", ServiceChargeAcc);
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", PaymentDiscDebitAcc);
        CustomerPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingAccount);
        CustomerPostingGroup.Validate("Additional Fee Account", AdditionalFeeAccount);
        CustomerPostingGroup.Validate("Interest Account", InterestAccount);
        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", DebitCurrApplnRndgAcc);
        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", CreditCurrApplnRndgAcc);
        CustomerPostingGroup.Validate("Debit Rounding Account", DebitRoundingAccount);
        CustomerPostingGroup.Validate("Credit Rounding Account", CreditRoundingAccount);
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", PaymentDiscCreditAcc);
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", PaymentToleranceDebitAcc);
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", PaymentToleranceCreditAcc);
        CustomerPostingGroup.Validate("Add. Fee per Line Account", AddFeePerLineAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupServiceChargeAcc(CustomerPostingGroupCode: Code[20]; ServiceChargeAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Service Charge Acc.", ServiceChargeAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupPaymentDiscDebitAcc(CustomerPostingGroupCode: Code[20]; PaymentDiscDebitAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", PaymentDiscDebitAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupInvoiceRoundingAccount(CustomerPostingGroupCode: Code[20]; InvoiceRoundingAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupAdditionalFeeAccount(CustomerPostingGroupCode: Code[20]; AdditionalFeeAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Additional Fee Account", AdditionalFeeAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupInterestAccount(CustomerPostingGroupCode: Code[20]; InterestAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Interest Account", InterestAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupDebitCurrApplnRndgAcc(CustomerPostingGroupCode: Code[20]; DebitCurrApplnRndgAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", DebitCurrApplnRndgAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupCreditCurrApplnRndgAcc(CustomerPostingGroupCode: Code[20]; CreditCurrApplnRndgAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", CreditCurrApplnRndgAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupDebitRoundingAccount(CustomerPostingGroupCode: Code[20]; DebitRoundingAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Debit Rounding Account", DebitRoundingAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupCreditRoundingAccount(CustomerPostingGroupCode: Code[20]; CreditRoundingAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Credit Rounding Account", CreditRoundingAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupPaymentDiscCreditAcc(CustomerPostingGroupCode: Code[20]; PaymentDiscCreditAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", PaymentDiscCreditAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupPaymentToleranceDebitAcc(CustomerPostingGroupCode: Code[20]; PaymentToleranceDebitAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", PaymentToleranceDebitAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupPaymentToleranceCreditAcc(CustomerPostingGroupCode: Code[20]; PaymentToleranceCreditAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", PaymentToleranceCreditAcc);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerPostingGroupAddFeePerLineAccount(CustomerPostingGroupCode: Code[20]; AddFeePerLineAccount: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(InternalCustomerPostingSetupNotSetErr);

        CustomerPostingGroup.Validate("Add. Fee per Line Account", AddFeePerLineAccount);
        CustomerPostingGroup.Modify(true);
    end;

    procedure SetCustomerAlternativeContact(NameToSet: Text[50]; AddressToSet: Text[50]; Address2ToSet: Text[50]; PostCodeToSet: Code[20]; CityToSet: Text[30]; CountryToSet: Code[10]; EmailToset: Text[80]; PhoneNoToSet: Text[30]; FaxToSet: Text[30]; MobileNoToSet: Text[30])
    begin
        if not CustomerIsSet then
            Error(InternalCustomerNotSetErr);

        DataMigrationFacadeHelper.SetAlternativeContact(NameToSet, AddressToSet, Address2ToSet, PostCodeToSet, CityToSet, CountryToSet,
          EmailToset, PhoneNoToSet, FaxToSet, MobileNoToSet, DATABASE::Customer, GlobalCustomer."No.");
    end;
}

