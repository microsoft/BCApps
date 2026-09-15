codeunit 140001 "Library - ERM Tax"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        DummyCountryRegionCode: Option US,CA;

    [Scope('OnPrem')]
    procedure CreateTaxArea_US(): Code[20]
    begin
        exit(CreateTaxAreaWithCountryRegion(DummyCountryRegionCode::US));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxArea_CA(): Code[20]
    begin
        exit(CreateTaxAreaWithCountryRegion(DummyCountryRegionCode::CA));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxAreaWithCountryRegion(CountryRegion: Option): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        TaxArea.Validate("Country/Region", CountryRegion);
        TaxArea.Modify(true);
        exit(TaxArea.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxAreaLine(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxAreaWithLine_CA(): Code[20]
    begin
        exit(CreateTaxAreaWithLine(DummyCountryRegionCode::CA));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxAreaWithLine(CountryRegion: Option): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxAreaLine(
          TaxAreaLine,
          CreateTaxAreaWithCountryRegion(CountryRegion),
          CreateTaxJurisdictionWithCountryRegion(CountryRegion));
        exit(TaxAreaLine."Tax Area");
    end;

    [Scope('OnPrem')]
    procedure CreateTaxGroupCode(): Code[20]
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        exit(TaxGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxJurisdiction_US(): Code[10]
    begin
        exit(CreateTaxJurisdictionWithCountryRegion(DummyCountryRegionCode::US));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxJurisdiction_CA(): Code[10]
    begin
        exit(CreateTaxJurisdictionWithCountryRegion(DummyCountryRegionCode::CA));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxJurisdictionWithCountryRegion(CountryRegion: Option): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Country/Region", CountryRegion);
        TaxJurisdiction.Validate("Tax Account (Sales)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Validate("Tax Account (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxJurisdictionWithSelfReportTo_US(): Code[10]
    begin
        exit(CreateTaxJurisdictionWithCountryRegionAndSelfReportTo(DummyCountryRegionCode::US));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxJurisdictionWithSelfReportTo_CA(): Code[10]
    begin
        exit(CreateTaxJurisdictionWithCountryRegionAndSelfReportTo(DummyCountryRegionCode::CA));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxJurisdictionWithCountryRegionAndSelfReportTo(CountryRegion: Option): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get(CreateTaxJurisdictionWithCountryRegion(CountryRegion));
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxBelowMaximum: Decimal)
    begin
        CreateTaxDetailWithTaxType(
          TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", TaxBelowMaximum, 0);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDetailExpenseCapitalize(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxBelowMaximum: Decimal; ExpenseCapitalize: Boolean)
    begin
        CreateTaxDetailWithTaxType(
          TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", TaxBelowMaximum, 0);
        TaxDetail.Validate("Expense/Capitalize", ExpenseCapitalize);
        TaxDetail.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDetailWithTaxType(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; TaxBelowMaximum: Decimal; MaximumAmount: Decimal)
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxType, WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMaximum);
        TaxDetail.Validate("Maximum Amount/Qty.", MaximumAmount);
        TaxDetail.Modify(true);
    end;
}

