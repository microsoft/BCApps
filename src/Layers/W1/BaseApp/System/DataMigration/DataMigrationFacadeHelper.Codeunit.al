namespace System.Integration;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using System.Globalization;

codeunit 1797 "Data Migration Facade Helper"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";

    procedure CreateShipmentMethodIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        if ShipmentMethod.Get(CodeToSet) then
            exit(CodeToSet);

        ShipmentMethod.Validate(Code, CodeToSet);
        ShipmentMethod.Validate(Description, DescriptionToSet);
        ShipmentMethod.Insert(true);
        exit(ShipmentMethod.Code);
    end;

    procedure CreateSalespersonPurchaserIfNeeded(CodeToSet: Code[20]; NameToSet: Text[50]; PhoneNoToSet: Text[30]; EmailToSet: Text[80]): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if SalespersonPurchaser.Get(CodeToSet) then
            exit(CodeToSet);

        SalespersonPurchaser.Init();
        SalespersonPurchaser.Validate(Code, CodeToSet);
        SalespersonPurchaser.Validate(Name, NameToSet);
        SalespersonPurchaser.Validate("Phone No.", PhoneNoToSet);
        SalespersonPurchaser.Validate("E-Mail", EmailToSet);
        SalespersonPurchaser.Validate("Search E-Mail", EmailToSet);
        SalespersonPurchaser.Insert(true);
        exit(SalespersonPurchaser.Code);
    end;

    procedure CreateCustomerPriceGroupIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; PriceIncludesVatToSet: Boolean): Code[10]
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        if CustomerPriceGroup.Get(CodeToSet) then
            exit(CodeToSet);

        CustomerPriceGroup.Init();
        CustomerPriceGroup.Validate(Code, CodeToSet);
        CustomerPriceGroup.Validate(Description, DescriptionToSet);
        CustomerPriceGroup.Validate("Price Includes VAT", PriceIncludesVatToSet);
        CustomerPriceGroup.Insert(true);
        exit(CustomerPriceGroup.Code);
    end;

    procedure CreatePaymentTermsIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; DueDateCalculationToSet: DateFormula): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(CodeToSet) then
            exit(CodeToSet);

        PaymentTerms.Init();
        PaymentTerms.Validate(Code, CodeToSet);
        PaymentTerms.Validate(Description, DescriptionToSet);
        PaymentTerms.Validate("Due Date Calculation", DueDateCalculationToSet);
        PaymentTerms.Insert(true);
        exit(PaymentTerms.Code);
    end;

    procedure CreateTerritoryIfNeeded(CodeToSet: Code[10]; Name: Text[50]): Code[10]
    var
        Territory: Record Territory;
    begin
        if Territory.Get(CodeToSet) then
            exit(CodeToSet);

        Territory.Init();
        Territory.Validate(Code, CodeToSet);
        Territory.Validate(Name, Name);
        Territory.Insert(true);
        exit(Territory.Code);
    end;

    procedure CreateTaxAreaIfNeeded(CodeToSet: Code[20]; Description: Text[50]): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        if TaxArea.Get(CodeToSet) then
            exit(CodeToSet);

        TaxArea.Init();
        TaxArea.Validate(Code, CodeToSet);
        TaxArea.Validate(Description, Description);
        TaxArea.Insert(true);
        exit(TaxArea.Code);
    end;

    procedure CreatePaymentMethodIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.Get(CodeToSet) then
            exit(CodeToSet);

        PaymentMethod.Init();
        PaymentMethod.Validate(Code, CodeToSet);
        PaymentMethod.Validate(Description, DescriptionToSet);
        PaymentMethod.Insert(true);
        exit(PaymentMethod.Code);
    end;

    procedure DoesPostCodeExist(CodeToSearch: Code[20]; CityToSearch: Text[30]): Boolean
    var
        PostCode: Record "Post Code";
    begin
        exit(PostCode.Get(CodeToSearch, CityToSearch));
    end;

    procedure CreatePostCodeIfNeeded(CodeToSet: Code[20]; CityToSet: Text[30]; CountyToSet: Text[30]; CountryRegionCodeToSet: Code[10]): Boolean
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(Code, CodeToSet);
        PostCode.SetRange("Search City", UpperCase(CityToSet));
        if PostCode.FindFirst() then
            exit(false);

        PostCode.Init();
        PostCode.Validate(Code, CodeToSet);
        PostCode.Validate(City, CityToSet);
        PostCode.Validate(County, CountyToSet);
        PostCode.Validate("Country/Region Code", CountryRegionCodeToSet);
        PostCode.Insert(true);
        exit(true);
    end;

    procedure CreateCountryIfNeeded(CodeToSet: Code[10]; NameToSet: Text[50]; AddressFormatToSet: Option "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City"; ContactAddressFormatToSet: Option First,"After Company Name",Last): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CodeToSet) then
            exit(CountryRegion.Code);

        CountryRegion.Init();
        CountryRegion.Validate(Code, CodeToSet);
        CountryRegion.Validate(Name, NameToSet);
        CountryRegion.Validate("Address Format", AddressFormatToSet);
        CountryRegion.Validate("Contact Address Format", ContactAddressFormatToSet);
        CountryRegion.Insert(true);

        exit(CountryRegion.Code);
    end;

    procedure SearchCountry(CodeToSearch: Code[10]; NameToSearch: Text[50]; EUCountryRegionCodeToSearch: Code[10]; IntrastatCodeToSet: Code[10]; var CodeToGet: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CodeToSearch <> '' then
            CountryRegion.SetRange(Code, CodeToSearch);

        if NameToSearch <> '' then
            CountryRegion.SetRange(Name, NameToSearch);

        if EUCountryRegionCodeToSearch <> '' then
            CountryRegion.SetRange("EU Country/Region Code", EUCountryRegionCodeToSearch);

        if IntrastatCodeToSet <> '' then
            CountryRegion.SetRange("Intrastat Code", IntrastatCodeToSet);

        if CountryRegion.FindFirst() then begin
            CodeToGet := CountryRegion.Code;
            exit(true);
        end;
    end;

    procedure SearchLanguage(AbbreviatedNameToSearch: Code[3]; var CodeToGet: Code[10]): Boolean
    var
        WindowsLanguageSearch: Record "Windows Language";
        Language: Codeunit Language;
    begin
        WindowsLanguageSearch.SetRange("Abbreviated Name", AbbreviatedNameToSearch);
        if WindowsLanguageSearch.FindFirst() then begin
            CodeToGet := Language.GetLanguageCode(WindowsLanguageSearch."Language ID");

            if CodeToGet <> '' then
                exit(true);
        end;
    end;

    procedure FixIfLcyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.FindFirst();

        if CurrencyCode = GeneralLedgerSetup."LCY Code" then
            exit('');
        exit(CurrencyCode);
    end;

    procedure CreateGeneralJournalBatchIfNeeded(GeneralJournalBatchCode: Code[10]; NoSeriesCode: Code[20]; PostingNoSeriesCode: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TemplateName: Code[10];
    begin
        TemplateName := CreateGeneralJournalTemplateIfNeeded(GeneralJournalBatchCode);
        GenJournalBatch.SetRange("Journal Template Name", TemplateName);
        GenJournalBatch.SetRange(Name, GeneralJournalBatchCode);
        GenJournalBatch.SetRange("No. Series", NoSeriesCode);
        GenJournalBatch.SetRange("Posting No. Series", PostingNoSeriesCode);
        if not GenJournalBatch.FindFirst() then begin
            GenJournalBatch.Init();
            GenJournalBatch.Validate("Journal Template Name", TemplateName);
            GenJournalBatch.SetupNewBatch();
            GenJournalBatch.Validate(Name, GeneralJournalBatchCode);
            GenJournalBatch.Validate(Description, GeneralJournalBatchCode);
            GenJournalBatch."No. Series" := NoSeriesCode;
            GenJournalBatch."Posting No. Series" := PostingNoSeriesCode;
            GenJournalBatch.Insert(true);
        end;
    end;

    local procedure CreateGeneralJournalTemplateIfNeeded(GeneralJournalBatchCode: Code[10]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.SetRange(Recurring, false);
        if not GenJournalTemplate.FindFirst() then begin
            GenJournalTemplate.Init();
            GenJournalTemplate.Validate(Name, GeneralJournalBatchCode);
            GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
            GenJournalTemplate.Validate(Recurring, false);
            GenJournalTemplate.Insert(true);
        end;
        exit(GenJournalTemplate.Name);
    end;

    procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GeneralJournalBatchCode: Code[10]; DocumentNo: Code[20]; Description: Text[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; DueDate: Date; Amount: Decimal; AmountLCY: Decimal; Currency: Code[10]; BalancingAccount: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineCurrent: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        LineNum: Integer;
    begin
        GenJournalBatch.Get(CreateGeneralJournalTemplateIfNeeded(GeneralJournalBatchCode), GeneralJournalBatchCode);

        GenJournalLineCurrent.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLineCurrent.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLineCurrent.FindLast() then
            LineNum := GenJournalLineCurrent."Line No." + 10000
        else
            LineNum := 10000;

        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");

        GenJournalLine.Init();
        GenJournalLine.SetHideValidation(true);
        GenJournalLine.Validate("Source Code", GenJournalTemplate."Source Code");
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Line No.", LineNum);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate(Description, Description);
        GenJournalLine.Validate("Document Date", PostingDate);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Amount (LCY)", AmountLCY);
        GenJournalLine.Validate("Currency Code", DataMigrationFacadeHelper.FixIfLcyCode(Currency));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalancingAccount);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::" ");
        GenJournalLine.Validate("Bal. Gen. Bus. Posting Group", '');
        GenJournalLine.Validate("Bal. Gen. Prod. Posting Group", '');
        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", '');
        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", '');
        GenJournalLine.Insert(true);
    end;

    procedure GetOrCreateDimension(DimensionCode: Code[20]; DimensionDescription: Text[50]; var Dimension: Record Dimension)
    begin
        if Dimension.Get(DimensionCode) then
            exit;

        Dimension.Init();
        Dimension.Validate(Code, DimensionCode);
        Dimension.Validate(Description, DimensionDescription);
        Dimension.Insert(true);
    end;

    procedure GetOrCreateDimensionValue(DimensionCode: Code[20]; DimensionValueCode: Code[20]; DimensionValueName: Text[50]; var DimensionValue: Record "Dimension Value")
    begin
        if DimensionValue.Get(DimensionCode, DimensionValueCode) then
            exit;

        DimensionValue.Init();
        DimensionValue.Validate("Dimension Code", DimensionCode);
        DimensionValue.Validate(Code, DimensionValueCode);
        DimensionValue.Validate(Name, DimensionValueName);
        DimensionValue.Insert(true);
    end;

    procedure CreateOnlyDefaultDimensionIfNeeded(DimensionCode: Code[20]; DimensionValueCode: Code[20]; TableId: Integer; EntityNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        if DefaultDimension.Get(TableId, EntityNo, DimensionCode) then
            exit;

        DefaultDimension.Init();
        DefaultDimension.Validate("Dimension Code", DimensionCode);
        DefaultDimension.Validate("Dimension Value Code", DimensionValueCode);
        DefaultDimension.Validate("Table ID", TableId);
        DefaultDimension.Validate("No.", EntityNo);
        DefaultDimension.Insert(true);
    end;

    procedure CreateDimensionSetId(OldDimensionSetId: Integer; DimensionCode: Code[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50]): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if (DimensionCode = '') or (DimensionValueCode = '') then
            exit(OldDimensionSetId);

        GetOrCreateDimension(DimensionCode, DimensionDescription, Dimension);
        GetOrCreateDimensionValue(DimensionCode, DimensionValueCode, DimensionValueName, DimensionValue);

        DimensionSetEntry.SetRange("Dimension Set ID", OldDimensionSetId);
        DimensionSetEntry.SetFilter("Dimension Code", '<>%1', DimensionCode);
        if DimensionSetEntry.FindSet() then
            repeat
                TempDimensionSetEntry.TransferFields(DimensionSetEntry);
                TempDimensionSetEntry.Insert(true);
            until DimensionSetEntry.Next() = 0;

        TempDimensionSetEntry.Init();
        TempDimensionSetEntry.Validate("Dimension Set ID", OldDimensionSetId);
        TempDimensionSetEntry.Validate("Dimension Code", DimensionCode);
        TempDimensionSetEntry.Validate("Dimension Value Code", DimensionValueCode);
        TempDimensionSetEntry.Insert(true);
        exit(DimensionManagement.GetDimensionSetID(TempDimensionSetEntry));
    end;

    procedure CreateSourceCodeIfNeeded(SourceCodeCode: Code[10]): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        if SourceCode.Get(SourceCodeCode) then
            exit(SourceCode."Code");

        SourceCode.Init();
        SourceCode.Validate("Code", SourceCodeCode);
        SourceCode.Insert(true);
        exit(SourceCode."Code");
    end;

    procedure SetAlternativeContact(NameToSet: Text[50]; AddressToSet: Text[50]; Address2ToSet: Text[50]; PostCodeToSet: Code[20]; CityToSet: Text[30]; CountryToSet: Code[10]; EmailToset: Text[80]; PhoneNoToSet: Text[30]; FaxToSet: Text[30]; MobileNoToSet: Text[30]; LinkToTable: Integer; EntityNo: Code[20])
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        if not MarketingSetup.Get() then
            exit;

        if LinkToTable = DATABASE::Vendor then begin
            ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Vendors");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
            ContactBusinessRelation.SetRange("No.", EntityNo);
            if not ContactBusinessRelation.FindFirst() then
                exit;
        end else
            if LinkToTable = DATABASE::Customer then begin
                ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");
                ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                ContactBusinessRelation.SetRange("No.", EntityNo);
                if not ContactBusinessRelation.FindFirst() then
                    exit;
            end else
                exit;

        Contact.Init();
        Contact.Validate(Name, NameToSet);
        Contact.Validate(Address, AddressToSet);
        Contact.Validate("Address 2", Address2ToSet);
        Contact.Validate("Country/Region Code", CountryToSet);
        Contact.Validate("Post Code", PostCodeToSet);
        Contact.Validate(City, CityToSet);
        Contact.Validate("E-Mail", EmailToset);
        Contact.Validate("Phone No.", PhoneNoToSet);
        Contact.Validate("Fax No.", FaxToSet);
        Contact.Validate("Mobile Phone No.", MobileNoToSet);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Validate("Company No.", ContactBusinessRelation."Contact No.");
        ContactBusinessRelation.CalcFields("Contact Name");
        Contact.Validate("Company Name", ContactBusinessRelation."Contact Name");
        Contact.Insert(true);
    end;
}

