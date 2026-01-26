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
        CreateTable(DATABASE::"Vendor Location");
        CreateTable(DATABASE::"GIFI Code");
        CreateTable(DATABASE::"Data Dictionary Info");
        CreateTable(DATABASE::"Account Identifier");
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
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Vendor Location");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"GIFI Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Data Dictionary Info");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Account Identifier");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"SAT MX Resources");
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    begin
        case TableID of
        end;
    end;
}
