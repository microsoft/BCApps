codeunit 101931 "Create Local RapidStart Pack"
{
    // Extension for codeunit 101995 Create RapidStart Package


    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CreateConfigPackageHelper: Codeunit "Create Config. Package Helper";

    procedure CreateTables()
    begin
        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then begin
            CreateTable(Database::"Bank Statement Header CZB");
            CreateTableChild(Database::"Bank Statement Line CZB", Database::"Bank Statement Header CZB");
            CreateTable(Database::"Payment Order Header CZB");
            CreateTableChild(Database::"Payment Order Line CZB", Database::"Payment Order Header CZB");
#if not CLEAN28
            CreateTable(Database::"VAT Period CZL");
#endif
            CreateTable(Database::"VAT Return Period");
            CreateTable(Database::"Company Official CZL");
            CreateTable(Database::"EET Business Premises CZL");
            CreateTable(Database::"EET Cash Register CZL");
            CreateTable(Database::"Document Footer CZL");
            CreateTable(Database::"Cash Desk CZP");
            CreateTableChild(Database::"Cash Desk User CZP", Database::"Cash Desk CZP");
            CreateTableChild(Database::"Cash Desk Event CZP", Database::"Cash Desk CZP");
            CreateTableChild(Database::"Cash Document Header CZP", Database::"Cash Desk CZP");
            CreateTableChild(Database::"Cash Document Line CZP", Database::"Cash Document Header CZP");
            CreateTable(Database::"Purch. Adv. Letter Header CZZ");
            CreateTableChild(Database::"Purch. Adv. Letter Line CZZ", Database::"Purch. Adv. Letter Header CZZ");
            CreateTable(Database::"Sales Adv. Letter Header CZZ");
            CreateTableChild(Database::"Sales Adv. Letter Line CZZ", Database::"Sales Adv. Letter Header CZZ");
        end;

        CreateTable(Database::"Invt. Movement Template CZL");
        CreateTable(Database::"Statutory Reporting Setup CZL");
        CreateTable(Database::"Reason Code");
        CreateTable(Database::"Tax Depreciation Group CZF");
        CreateTable(Database::"Compensations Setup CZC");
        CreateTable(Database::"Rounding Method");
        CreateTable(Database::"FA Extended Posting Group CZF");
        CreateTable(Database::"Item Journal Template");
        CreateTable(Database::"Item Journal Batch");
        CreateTable(Database::"Acc. Schedule File Mapping CZL");
        CreateTable(Database::"Tariff Number");
        CreateTable(Database::"Commodity CZL");
        CreateTable(Database::"Commodity Setup CZL");
        CreateTable(Database::"Currency Nominal Value CZP");
        CreateTable(Database::"Unrel. Payer Service Setup CZL");
        CreateTable(Database::"Reg. No. Service Config CZL");
        CreateTable(Database::"Advance Letter Template CZZ");

        if CreateConfigPackageHelper.GetCompanyType() = DemoDataSetup."Company Type"::VAT then
            CreateTable(Database::"VAT Attribute Code CZL");
    end;

    procedure CreateTable(TableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTable(TableID);
        SetFieldsAndFilters(TableID);
    end;

    procedure CreateTableChild(TableID: Integer; ParentTableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTableChild(TableID, ParentTableID);
        SetFieldsAndFilters(TableID);
    end;

    procedure CreateWorksheetLines()
    begin
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        ColumnLayout: Record "Column Layout";
        CompanyInformation: Record "Company Information";
        CompanyOfficial: Record "Company Official CZL";
        PurchaseHeader: Record "Purchase Header";
        TariffNumber: Record "Tariff Number";
        Vendor: Record Vendor;
    begin
        case TableID of
            Database::"Company Information":
                SkipValidateField(CompanyInformation.FieldNo("Default Bank Account Code CZL"));
            Database::"Gen. Journal Line":
                DeleteProcessingRule(Database::"Gen. Journal Line", 10000); // This rule was failing for CZ
            Database::Vendor:
                IncludeField(Vendor.FieldNo("Disable Unreliab. Check CZL"));
            Database::"Purchase Header":
                begin
                    IncludeField(PurchaseHeader.FieldNo("Prepayment %"));
                    IncludeField(PurchaseHeader.FieldNo("Original Doc. VAT Date CZL"));
                end;
            Database::"Company Official CZL":
                SkipValidateField(CompanyOfficial.FieldNo("Employee No."));
            Database::"Acc. Schedule Line":
                begin
                    SkipValidateField(AccScheduleLine.FieldNo(Totaling));
                    SkipValidateField(AccScheduleLine.FieldNo("Totaling Type"));
                end;
            Database::"Tariff Number":
                begin
                    SkipValidateField(TariffNumber.FieldNo("Statement Code CZL"));
                    SkipValidateField(TariffNumber.FieldNo("Statement Limit Code CZL"));
                end;
            Database::"Column Layout":
                SkipValidateField(ColumnLayout.FieldNo("Comparison Period Formula"));
            Database::"Bank Account":
                CreateConfigPackageHelper.SetSkipTableTriggers();
            Database::"Cash Document Header CZP":
                SkipValidateField(CashDocumentHeaderCZP.FieldNo("Document Type"));
            Database::"Sales Adv. Letter Header CZZ":
                SetSalesAdvLetterHeaderCZZ();
            Database::"Sales Adv. Letter Line CZZ":
                SetSalesAdvLetterLineCZZ();
            Database::"Purch. Adv. Letter Header CZZ":
                SetPurchAdvLetterHeaderCZZ();
            Database::"Purch. Adv. Letter Line CZZ":
                SetPurchAdvLetterLineCZZ();
        end;
    end;

    local procedure DeleteProcessingRule(TableID: Integer; RuleNo: Integer)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigTableProcessingRule.SetRange("Package Code", CreateConfigPackageHelper.GetPackageCode());
        ConfigTableProcessingRule.SetRange("Table ID", TableID);
        ConfigTableProcessingRule.SetRange("Rule No.", RuleNo);
        ConfigTableProcessingRule.DeleteAll(true);
    end;

    local procedure SetPurchAdvLetterHeaderCZZ()
    var
        PurchAdvLetterHeaderCZZ: Record "Purch. Adv. Letter Header CZZ";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("No."));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("Advance Letter Code"));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("Pay-to Vendor No."));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("Posting Date"));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("Advance Due Date"));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("VAT Date"));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("Automatic Post VAT Usage"));
        IncludeField(PurchAdvLetterHeaderCZZ.FieldNo("Vendor Adv. Letter No."));
    end;

    local procedure SetPurchAdvLetterLineCZZ()
    var
        PurchAdvLetterLineCZZ: Record "Purch. Adv. Letter Line CZZ";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(PurchAdvLetterLineCZZ.FieldNo("Document No."));
        IncludeField(PurchAdvLetterLineCZZ.FieldNo("Line No."));
        IncludeField(PurchAdvLetterLineCZZ.FieldNo("VAT Prod. Posting Group"));
        IncludeField(PurchAdvLetterLineCZZ.FieldNo(Description));
        IncludeField(PurchAdvLetterLineCZZ.FieldNo("Amount Including VAT"));
    end;

    local procedure SetSalesAdvLetterHeaderCZZ()
    var
        SalesAdvLetterHeaderCZZ: Record "Sales Adv. Letter Header CZZ";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(SalesAdvLetterHeaderCZZ.FieldNo("No."));
        IncludeField(SalesAdvLetterHeaderCZZ.FieldNo("Advance Letter Code"));
        IncludeField(SalesAdvLetterHeaderCZZ.FieldNo("Bill-to Customer No."));
        IncludeField(SalesAdvLetterHeaderCZZ.FieldNo("Posting Date"));
        IncludeField(SalesAdvLetterHeaderCZZ.FieldNo("Advance Due Date"));
        IncludeField(SalesAdvLetterHeaderCZZ.FieldNo("VAT Date"));
    end;

    local procedure SetSalesAdvLetterLineCZZ()
    var
        SalesAdvLetterLineCZZ: Record "Sales Adv. Letter Line CZZ";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(SalesAdvLetterLineCZZ.FieldNo("Document No."));
        IncludeField(SalesAdvLetterLineCZZ.FieldNo("Line No."));
        IncludeField(SalesAdvLetterLineCZZ.FieldNo("VAT Prod. Posting Group"));
        IncludeField(SalesAdvLetterLineCZZ.FieldNo(Description));
        IncludeField(SalesAdvLetterLineCZZ.FieldNo("Amount Including VAT"));
    end;

    local procedure IncludeField(FieldID: Integer)
    begin
        CreateConfigPackageHelper.IncludeField(FieldID, true);
    end;

    local procedure SkipValidateField(FieldID: Integer)
    begin
        CreateConfigPackageHelper.ValidateField(FieldID, false);
    end;
}
