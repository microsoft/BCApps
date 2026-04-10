codeunit 101931 "Create Local RapidStart Pack"
{
    // Extension for codeunit 101995 Create RapidStart Package


    trigger OnRun()
    begin
    end;

    var
        CreateConfigPackageHelper: Codeunit "Create Config. Package Helper";
        XLocalSettingsTxt: Label 'Local Settings', Locked = true;

    procedure CreateTables()
    begin
        CreateTable(DATABASE::"Company Address");
        CreateTable(DATABASE::OKATO);
        CreateTable(DATABASE::"Default Signature Setup");
        CreateTable(DATABASE::"Depreciation Group");
        CreateTable(DATABASE::"FA Charge");
        CreateTable(DATABASE::"Payment Order Code");
        CreateTable(DATABASE::"Excel Template");
        CreateTable(DATABASE::"Assessed Tax Allowance");
        CreateTable(DATABASE::"Assessed Tax Code");
        CreateTable(DATABASE::"Tax Register");
        CreateTable(DATABASE::"Tax Register Line Setup");
        CreateTable(DATABASE::"Tax Register Template");
        CreateTable(DATABASE::"Tax Register Term");
        CreateTable(DATABASE::"Tax Register Term Formula");
        CreateTable(DATABASE::"Tax Register Section");
        CreateTable(DATABASE::"Tax Register Norm Jurisdiction");
        CreateTable(DATABASE::"Tax Register Norm Group");
        CreateTable(DATABASE::"Tax Register Norm Detail");
        CreateTable(DATABASE::"Tax Register Setup");
        CreateTable(DATABASE::"Gen. Template Profile");
        CreateTable(DATABASE::"Gen. Term Profile");
        CreateTable(DATABASE::"Tax Reg. Norm Template Line");
        CreateTable(DATABASE::"Tax Reg. Norm Term");
        CreateTable(DATABASE::"Tax Reg. Norm Term Formula");
        CreateTable(DATABASE::"Tax Difference");
        CreateTable(DATABASE::"Tax Diff. Posting Group");
        CreateTable(DATABASE::"Tax Diff. Journal Template");
        CreateTable(DATABASE::"Tax Diff. Journal Batch");
        CreateTable(DATABASE::"Tax Calc. Section");
        CreateTable(DATABASE::"Tax Calc. Header");
        CreateTable(DATABASE::"Tax Calc. Selection Setup");
        CreateTable(DATABASE::"Tax Calc. Line");
        CreateTable(DATABASE::"Tax Calc. Dim. Filter");
        CreateConfigPackageHelper.SetSkipTableTriggers();
        CreateTable(DATABASE::"Statutory Report Setup");
    end;

    procedure CreateTable(TableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTable(TableID);
        SetFieldsAndFilters(TableID);
    end;

    procedure CreateWorksheetLines()
    var
        CreateConfigWorksheet: Codeunit "Create Config. Worksheet";
    begin
        CreateConfigWorksheet.CreateConfigGroup(XLocalSettingsTxt);
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Company Address");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::OKATO);
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Default Signature Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Depreciation Group");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"FA Charge");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Order Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Excel Template");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Assessed Tax Allowance");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Assessed Tax Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Line Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Template");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Term");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Term Formula");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Section");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Norm Jurisdiction");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Norm Group");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Norm Detail");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Register Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Gen. Template Profile");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Gen. Term Profile");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Reg. Norm Template Line");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Reg. Norm Term");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Reg. Norm Term Formula");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Difference");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Diff. Posting Group");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Diff. Journal Template");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Diff. Journal Batch");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Calc. Section");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Calc. Header");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Calc. Selection Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Calc. Line");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Tax Calc. Dim. Filter");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Statutory Report Setup");
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        case TableID of
            DATABASE::"General Ledger Setup":
                CreateConfigPackageHelper.IncludeField(GeneralLedgerSetup.FieldNo("Max. VAT Difference Allowed"), false);
            DATABASE::"Default Signature Setup":
                SetDefaultSignSetup();
            DATABASE::"Tax Register Template":
                SetTaxRegisterTemplate();
            DATABASE::"Inventory Setup":
                SetInventorySetup();
            DATABASE::"Statutory Report Setup":
                SetStatutoryReportSetup();
            DATABASE::"Tax Calc. Section":
                SetTaxCalcSection();
        end;
    end;

    local procedure SetDefaultSignSetup()
    var
        DefaultSignSetup: Record "Default Signature Setup";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        CreateConfigPackageHelper.IncludeField(DefaultSignSetup.FieldNo("Table ID"), true);
        CreateConfigPackageHelper.IncludeField(DefaultSignSetup.FieldNo("Document Type"), true);
        CreateConfigPackageHelper.IncludeField(DefaultSignSetup.FieldNo("Employee Type"), true);
        CreateConfigPackageHelper.IncludeField(DefaultSignSetup.FieldNo(Mandatory), true);
    end;

    local procedure SetTaxRegisterTemplate()
    var
        TaxRegisterTemplate: Record "Tax Register Template";
    begin
        CreateConfigPackageHelper.ValidateField(TaxRegisterTemplate.FieldNo("Term Line Code"), false);
    end;

    local procedure SetInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        CreateConfigPackageHelper.ValidateField(InventorySetup.FieldNo("Enable Red Storno"), false);
        CreateConfigPackageHelper.ValidateField(InventorySetup.FieldNo("Automatic Cost Posting"), false);
    end;

    local procedure SetStatutoryReportSetup()
    var
        StatutoryReportSetup: Record "Statutory Report Setup";
    begin
        CreateConfigPackageHelper.ValidateField(StatutoryReportSetup.FieldNo("Default Comp. Addr. Code"), false);
        CreateConfigPackageHelper.ValidateField(StatutoryReportSetup.FieldNo("Default Comp. Addr. Lang. Code"), false);
    end;

    local procedure SetTaxCalcSection()
    var
        TaxCalcSection: Record "Tax Calc. Section";
    begin
        CreateConfigPackageHelper.ValidateField(TaxCalcSection.FieldNo("Starting Date"), false);
    end;
}

