namespace System.Integration;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;

codeunit 6111 "Vendor Data Migration Facade"
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
                OnMigrateVendor(Rec."Staging Table RecId To Process");
                OnMigrateVendorDimensions(Rec."Staging Table RecId To Process");

                // migrate transactions for this vendor
                OnMigrateVendorPostingGroups(Rec."Staging Table RecId To Process", ChartOfAccountsMigrated);
                OnMigrateVendorTransactions(Rec."Staging Table RecId To Process", ChartOfAccountsMigrated);
                GenJournalLineIsSet := false;
                VendorIsSet := false;
            until Rec.Next() = 0;
    end;

    var
        GlobalVendor: Record Vendor;
        GlobalGenJournalLine: Record "Gen. Journal Line";
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
        VendorIsSet: Boolean;
        InternalVendorNotSetErr: Label 'Internal Vendor is not set. Create it first.';
        GenJournalLineIsSet: Boolean;
        InternalGenJournalLineNotSetErr: Label 'Internal Gen. Journal Line is not set. Create it first.';
        InternalVendorPostingSetupNotSetErr: Label 'Internal Vendor Posting Setup is not set. Create it first.';

    [IntegrationEvent(true, false)]
    local procedure OnMigrateVendor(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateVendorDimensions(RecordIdToMigrate: RecordID)
    begin
    end;

    procedure CreateVendorIfNeeded(VendorNoToSet: Code[20]; VendorNameToSet: Text[100]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNoToSet) then begin
            GlobalVendor := Vendor;
            VendorIsSet := true;
            exit;
        end;
        Vendor.Init();

        Vendor.Validate("No.", VendorNoToSet);
        Vendor.Validate(Name, VendorNameToSet);

        Vendor.Insert(true);

        GlobalVendor := Vendor;
        VendorIsSet := true;
        exit(true);
    end;

    procedure CreatePostingSetupIfNeeded(VendorPostingGroupCode: Code[20]; VendorPostingGroupDescription: Text[50]; PayablesAccount: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then begin
            VendorPostingGroup.Init();
            VendorPostingGroup.Validate(Code, VendorPostingGroupCode);
            VendorPostingGroup.Validate(Description, VendorPostingGroupDescription);
            VendorPostingGroup.Validate("Payables Account", PayablesAccount);
            VendorPostingGroup.Insert(true);
        end else
            if VendorPostingGroup."Payables Account" <> PayablesAccount then begin
                VendorPostingGroup.Validate("Payables Account", PayablesAccount);
                VendorPostingGroup.Modify(true);
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
          GlobalGenJournalLine."Account Type"::Vendor,
          GlobalVendor."No.",
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

    procedure SetGeneralJournalLineBalAccountNo(BalAccountNoToSet: Code[20])
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Bal. Account No.", BalAccountNoToSet);
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

    procedure SetGeneralJournalLinePaymentTerms(PaymentTermsCodeToSet: Code[10])
    begin
        if not GenJournalLineIsSet then
            Error(InternalGenJournalLineNotSetErr);

        GlobalGenJournalLine.Validate("Payment Terms Code", PaymentTermsCodeToSet);
        GlobalGenJournalLine.Modify(true);
    end;

    procedure SetGlobalVendor(VendorNo: Code[20]): Boolean
    begin
        VendorIsSet := GlobalVendor.Get(VendorNo);
        exit(VendorIsSet);
    end;

    procedure ModifyVendor(RunTrigger: Boolean)
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Modify(RunTrigger);
    end;

    procedure SetSearchName(SearchNameToSet: Code[50])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Search Name", SearchNameToSet);
    end;

    procedure SetAddress(AdressToSet: Text[50]; Adress2ToSet: Text[50]; CountryRegionCodeToSet: Code[10]; PostCodeToSet: Code[20]; CityToSet: Text[30])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate(Address, AdressToSet);
        GlobalVendor.Validate("Address 2", Adress2ToSet);
        GlobalVendor.Validate("Country/Region Code", CountryRegionCodeToSet);
        GlobalVendor.Validate("Post Code", PostCodeToSet);
        GlobalVendor.Validate(City, CityToSet);
    end;

    procedure SetPhoneNo(PhoneNoToSet: Text[30])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Phone No.", PhoneNoToSet);
    end;

    procedure SetTelexNo(TelexNoToSet: Text[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Telex No.", TelexNoToSet);
    end;

    procedure SetOurAccountNo(OurAccountNoToSet: Text[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Our Account No.", OurAccountNoToSet);
    end;

    procedure SetCurrencyCode(CurrencyCodeToSet: Code[10])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Currency Code", DataMigrationFacadeHelper.FixIfLcyCode(CurrencyCodeToSet));
    end;

    procedure SetLanguageCode(LanguageCodeToSet: Code[10])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Language Code", LanguageCodeToSet);
    end;

    procedure SetPaymentTermsCode(PaymentTermsCodeToSet: Code[10])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Payment Terms Code", PaymentTermsCodeToSet);
    end;

    procedure SetPaymentMethod(PaymentMethodCodeToSet: Code[10])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Payment Method Code", PaymentMethodCodeToSet);
    end;

    procedure SetPurchaserCode(PurchaserCodeToSet: Code[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Purchaser Code", PurchaserCodeToSet);
    end;

    procedure SetShipmentMethodCode(ShipmentMethodCodeToSet: Code[10])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Shipment Method Code", ShipmentMethodCodeToSet);
    end;

    procedure SetInvoiceDiscCode(InvoiceDiscCodeToSet: Code[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Invoice Disc. Code", InvoiceDiscCodeToSet);
    end;

    procedure SetBlocked(BlockedTypeToSet: Enum "Vendor Blocked")
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate(Blocked, BlockedTypeToSet);
    end;

    procedure SetFaxNo(FaxNoToSet: Text[30])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Fax No.", FaxNoToSet);
    end;

    procedure SetVATRegistrationNo(VatRegistrationNoToSet: Text[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("VAT Registration No.", VatRegistrationNoToSet);
    end;

    procedure SetHomePage(HomePageToSet: Text[80])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Home Page", HomePageToSet);
    end;

    procedure SetPayToVendorNo(PayToVendorToSet: Code[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Pay-to Vendor No.", PayToVendorToSet);
    end;

    procedure SetContact(ContactToSet: Text[50])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate(Contact, ContactToSet);
    end;

    procedure SetLastDateModified(LastDateModifiedToSet: Date)
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Last Date Modified", LastDateModifiedToSet);
    end;

    procedure SetLastModifiedDateTime(LastModifiedDateTimeToSet: DateTime)
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Last Modified Date Time", LastModifiedDateTimeToSet);
    end;

    procedure SetVendorPostingGroup(VendorPostingGroupCode: Code[20]): Boolean
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            exit;

        GlobalVendor.Validate("Vendor Posting Group", VendorPostingGroupCode);

        exit(true);
    end;

    procedure SetGenBusPostingGroup(GenBusinessPostingCode: Code[20]): Boolean
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        if not GenBusinessPostingGroup.Get(GenBusinessPostingCode) then
            exit;

        GlobalVendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingCode);

        exit(true);
    end;

    procedure SetEmail(Email: Text[80])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("E-Mail", Email);
    end;

    procedure SetName2(Name2: Text[50])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Name 2", Name2);
    end;

    procedure SetTaxLiable(TaxLiable: Boolean)
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Tax Liable", TaxLiable);
    end;

    procedure SetTaxAreaCode(TaxAreaCodeToSet: Code[20])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        GlobalVendor.Validate("Tax Area Code", TaxAreaCodeToSet);
    end;

    procedure DoesVendorExist(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        exit(Vendor.Get(VendorNo));
    end;

    procedure CreateDefaultDimensionAndRequirementsIfNeeded(DimensionCode: Text[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        DataMigrationFacadeHelper.GetOrCreateDimension(DimensionCode, DimensionDescription, Dimension);
        DataMigrationFacadeHelper.GetOrCreateDimensionValue(Dimension.Code, DimensionValueCode, DimensionValueName,
          DimensionValue);
        DataMigrationFacadeHelper.CreateOnlyDefaultDimensionIfNeeded(Dimension.Code, DimensionValue.Code,
          DATABASE::Vendor, GlobalVendor."No.");
    end;

    procedure CreateShipmentMethodIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreateShipmentMethodIfNeeded(CodeToSet, DescriptionToSet));
    end;

    procedure CreateSalespersonPurchaserIfNeeded(CodeToSet: Code[10]; NameToSet: Text[50]; PhoneNoToSet: Text[30]; EmailToSet: Text[80]): Code[20]
    begin
        exit(DataMigrationFacadeHelper.CreateSalespersonPurchaserIfNeeded(CodeToSet, NameToSet, PhoneNoToSet, EmailToSet));
    end;

    procedure CreatePaymentTermsIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; DueDateCalculationToSet: DateFormula): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreatePaymentTermsIfNeeded(CodeToSet, DescriptionToSet, DueDateCalculationToSet));
    end;

    procedure CreatePaymentMethodIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreatePaymentMethodIfNeeded(CodeToSet, DescriptionToSet));
    end;

    procedure CreateVendorInvoiceDiscountIfNeeded(CodeToSet: Code[20]; CurencyCodeToSet: Code[10]; MinimumAmountToSet: Decimal; DiscountPercentToSet: Decimal): Boolean
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        if VendorInvoiceDisc.Get(CodeToSet, CurencyCodeToSet, MinimumAmountToSet) then
            exit(false);

        VendorInvoiceDisc.Init();
        VendorInvoiceDisc.Validate(Code, CodeToSet);
        VendorInvoiceDisc.Validate("Currency Code", CurencyCodeToSet);
        VendorInvoiceDisc.Validate("Minimum Amount", MinimumAmountToSet);
        VendorInvoiceDisc.Validate("Discount %", DiscountPercentToSet);
        VendorInvoiceDisc.Insert(true);
        exit(true);
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
        exit(DataMigrationFacadeHelper.SearchCountry(CodeToSearch, NameToSearch,
            EUCountryRegionCodeToSearch, IntrastatCodeToSet, CodeToGet));
    end;

    procedure SearchLanguage(AbbreviatedNameToSearch: Code[3]; var CodeToGet: Code[10]): Boolean
    begin
        exit(DataMigrationFacadeHelper.SearchLanguage(AbbreviatedNameToSearch, CodeToGet));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateVendorPostingGroups(RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateVendorTransactions(RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
    end;

    procedure SetVendorPostingGroupAccounts(VendorPostingGroupCode: Code[20]; PayablesAccount: Code[20]; ServiceChargeAcc: Code[20]; PaymentDiscDebitAcc: Code[20]; InvoiceRoundingAccount: Code[20]; DebitCurrApplnRndgAcc: Code[20]; CreditCurrApplnRndgAcc: Code[20]; DebitRoundingAccount: Code[20]; CreditRoundingAccount: Code[20]; PaymentDiscCreditAcc: Code[20]; PaymentToleranceDebitAcc: Code[20]; PaymentToleranceCreditAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            exit;

        VendorPostingGroup.Validate("Payables Account", PayablesAccount);
        VendorPostingGroup.Validate("Service Charge Acc.", ServiceChargeAcc);
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", PaymentDiscDebitAcc);
        VendorPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingAccount);
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", DebitCurrApplnRndgAcc);
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", CreditCurrApplnRndgAcc);
        VendorPostingGroup.Validate("Debit Rounding Account", DebitRoundingAccount);
        VendorPostingGroup.Validate("Credit Rounding Account", CreditRoundingAccount);
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", PaymentDiscCreditAcc);
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", PaymentToleranceDebitAcc);
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", PaymentToleranceCreditAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupServiceChargeAcc(VendorPostingGroupCode: Code[20]; ServiceChargeAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Service Charge Acc.", ServiceChargeAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupPaymentDiscDebitAcc(VendorPostingGroupCode: Code[20]; PaymentDiscDebitAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", PaymentDiscDebitAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupInvoiceRoundingAccount(VendorPostingGroupCode: Code[20]; InvoiceRoundingAccount: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingAccount);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupDebitCurrApplnRndgAcc(VendorPostingGroupCode: Code[20]; DebitCurrApplnRndgAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", DebitCurrApplnRndgAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupCreditCurrApplnRndgAcc(VendorPostingGroupCode: Code[20]; CreditCurrApplnRndgAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", CreditCurrApplnRndgAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupDebitRoundingAccount(VendorPostingGroupCode: Code[20]; DebitRoundingAccount: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Debit Rounding Account", DebitRoundingAccount);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupCreditRoundingAccount(VendorPostingGroupCode: Code[20]; CreditRoundingAccount: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Credit Rounding Account", CreditRoundingAccount);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupPaymentDiscCreditAcc(VendorPostingGroupCode: Code[20]; PaymentDiscCreditAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", PaymentDiscCreditAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupPaymentToleranceDebitAcc(VendorPostingGroupCode: Code[20]; PaymentToleranceDebitAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", PaymentToleranceDebitAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorPostingGroupPaymentToleranceCreditAcc(VendorPostingGroupCode: Code[20]; PaymentToleranceCreditAcc: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get(VendorPostingGroupCode) then
            Error(InternalVendorPostingSetupNotSetErr);

        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", PaymentToleranceCreditAcc);
        VendorPostingGroup.Modify(true);
    end;

    procedure SetVendorAlternativeContact(NameToSet: Text[50]; AddressToSet: Text[50]; Address2ToSet: Text[50]; PostCodeToSet: Code[20]; CityToSet: Text[30]; CountryToSet: Code[10]; EmailToset: Text[80]; PhoneNoToSet: Text[30]; FaxToSet: Text[30]; MobileNoToSet: Text[30])
    begin
        if not VendorIsSet then
            Error(InternalVendorNotSetErr);

        DataMigrationFacadeHelper.SetAlternativeContact(NameToSet, AddressToSet, Address2ToSet, PostCodeToSet, CityToSet, CountryToSet,
          EmailToset, PhoneNoToSet, FaxToSet, MobileNoToSet, DATABASE::Vendor, GlobalVendor."No.");
    end;
}

