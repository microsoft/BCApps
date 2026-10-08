codeunit 101932 "Create Config. Worksheet"
{

    trigger OnRun()
    begin
    end;

    var
        XSalesCompanyTxt: Label 'Sales Company', Locked = true;
        XMasterDataTxt: Label 'Master Data', Locked = true;
        XChartofAccountsTxt: Label 'Chart of Accounts', Locked = true;
        XAreaSetupsTxt: Label 'Area Setups', Locked = true;
        XPostingGroupsTxt: Label 'Posting Groups', Locked = true;
        XVATSetupandPostingGroupsTxt: Label 'VAT Setup and Posting Groups', Locked = true;
        XJournalsandOpeningBalancesTxt: Label 'Journals and Opening Balances', Locked = true;
        XGeneralSettingsTxt: Label 'General Settings', Locked = true;
        XSalesTaxSetupTxt: Label 'Sales Tax Setup';
        ConfigMgt: Codeunit "Config. Management";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        CreateLocalRapidStartPack: Codeunit "Create Local RapidStart Pack";
        CreateConfigPackageHelper: Codeunit "Create Config. Package Helper";

    local procedure Intialize()
    var
        ConfigLine: Record "Config. Line";
    begin
        if not ConfigLine.IsEmpty() then
            ConfigLine.DeleteAll(true);
    end;

    local procedure GetNextConfigLineNo(): Integer
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Reset();
        if ConfigLine.FindLast() then
            exit(ConfigLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure GetNextVerticalSorting(): Integer
    var
        ConfigLine: Record "Config. Line";
    begin
        if ConfigLine.FindLast() then
            exit(ConfigLine."Vertical Sorting" + 1);
        exit(1);
    end;

    procedure CreateConfigArea(LineName: Text[50])
    var
        ConfigLine: Record "Config. Line";
    begin
        CreateConfigHeader(ConfigLine."Line Type"::Area, LineName);
    end;

    procedure CreateConfigGroup(LineName: Text[50])
    var
        ConfigLine: Record "Config. Line";
    begin
        CreateConfigHeader(ConfigLine."Line Type"::Group, LineName);
    end;

    local procedure CreateConfigHeader(LineType: Option "Area",Group; LineName: Text[50])
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Init();
        ConfigLine."Line No." := GetNextConfigLineNo();
        ConfigLine."Vertical Sorting" := GetNextVerticalSorting();
        ConfigLine.Validate("Line Type", LineType);
        ConfigLine.Name := LineName;
        ConfigLine.Insert();
        if CreateConfigPackageHelper.GetPackageCode() <> '' then
            ConfigPackageManagement.AssignPackage(ConfigLine, CreateConfigPackageHelper.GetPackageCode());
    end;

    procedure CreateConfigLine(TableID: Integer)
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Init();
        ConfigLine."Line No." := GetNextConfigLineNo();
        ConfigLine."Vertical Sorting" := GetNextVerticalSorting();
        ConfigLine.Validate("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.Validate("Table ID", TableID);
        ConfigLine.Insert();
        if CreateConfigPackageHelper.GetPackageCode() <> '' then
            ConfigPackageManagement.AssignPackage(ConfigLine, CreateConfigPackageHelper.GetPackageCode());
    end;

    procedure CreateMiniWorksheetLines()
    begin
        CreateWorksheetLines(false);
    end;

    procedure CreateExtWorksheetLines()
    begin
        CreateWorksheetLines(true);
    end;

    local procedure CreateWorksheetLines(Extended: Boolean)
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        Intialize();
        CreateConfigArea(XSalesCompanyTxt);
        CreateConfigGroup(XMasterDataTxt);
        CreateConfigLine(DATABASE::Customer);
        SetConfigLineDimsAsColumns();
        CreateConfigLine(DATABASE::Vendor);
        SetConfigLineDimsAsColumns();
        CreateConfigLine(DATABASE::Item);
        SetConfigLineDimsAsColumns();
        if Extended then begin
            CreateConfigLine(DATABASE::"Bank Account");
            CreateConfigLine(DATABASE::"Salesperson/Purchaser");
        end;
        CreateConfigGroup(XChartofAccountsTxt);
        CreateConfigLine(DATABASE::"G/L Account");
        if Extended then
            CreateConfigLine(DATABASE::"Accounting Period");
        CreateConfigGroup(XAreaSetupsTxt);
        CreateConfigLine(DATABASE::"General Ledger Setup");
        CreateConfigLine(DATABASE::"Sales & Receivables Setup");
        CreateConfigLine(DATABASE::"Purchases & Payables Setup");
        CreateConfigLine(DATABASE::"Inventory Setup");
        CreateConfigGroup(XPostingGroupsTxt);
        CreateConfigLine(DATABASE::"Customer Posting Group");
        if Extended then
            CreateConfigLine(DATABASE::"Vendor Posting Group");
        CreateConfigLine(DATABASE::"Inventory Posting Group");
        CreateConfigLine(DATABASE::"Gen. Business Posting Group");
        CreateConfigLine(DATABASE::"Gen. Product Posting Group");
        CreateConfigLine(DATABASE::"General Posting Setup");
        if Extended then
            CreateConfigLine(DATABASE::"Bank Account Posting Group");
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                begin
                    CreateConfigGroup(XVATSetupandPostingGroupsTxt);
                    CreateConfigLine(DATABASE::"VAT Business Posting Group");
                    CreateConfigLine(DATABASE::"VAT Product Posting Group");
                    CreateConfigLine(DATABASE::"VAT Clause");
                    CreateConfigLine(DATABASE::"VAT Posting Setup");
                    if Extended then begin
                        CreateConfigLine(DATABASE::"VAT Report Setup");
                        CreateConfigLine(DATABASE::"VAT Registration No. Format");
                        CreateConfigLine(DATABASE::"VAT Statement Template");
                        CreateConfigLine(DATABASE::"VAT Statement Line");
                        CreateConfigLine(DATABASE::"VAT Statement Name");
                    end;
                end;
            DemoDataSetup."Company Type"::"Sales Tax":
                begin
                    CreateConfigGroup(XSalesTaxSetupTxt);
                    CreateConfigLine(DATABASE::"Tax Area");
                    CreateConfigLine(DATABASE::"Tax Area Line");
                    CreateConfigLine(DATABASE::"Tax Jurisdiction");
                    CreateConfigLine(DATABASE::"Tax Group");
                    CreateConfigLine(DATABASE::"Tax Detail");
                end;
        end;
        CreateConfigGroup(XJournalsandOpeningBalancesTxt);
        CreateConfigLine(DATABASE::"Gen. Journal Template");
        CreateConfigLine(DATABASE::"Gen. Journal Batch");
        if Extended then begin
            CreateConfigLine(DATABASE::"Gen. Journal Line");
            CreateConfigLine(DATABASE::"Item Journal Template");
            CreateConfigLine(DATABASE::"Item Journal Batch");
            CreateConfigLine(DATABASE::"Item Journal Line");
        end;
        CreateConfigGroup(XGeneralSettingsTxt);
        CreateConfigLine(DATABASE::"Payment Method");
        if Extended then
            CreateConfigLine(DATABASE::"Shipping Agent");
        CreateConfigLine(DATABASE::"Payment Terms");

        CreateLocalRapidStartPack.CreateWorksheetLines();
        ConfigMgt.AssignParentLineNos();
    end;

    procedure SetConfigLineDimsAsColumns()
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.FindLast();
        ConfigLine.SetHideValidationDialog(true);
        ConfigLine.Validate("Dimensions as Columns", true);
        ConfigLine.Modify(true);
    end;
}

