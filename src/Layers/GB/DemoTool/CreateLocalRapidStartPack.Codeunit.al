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
#if not CLEAN28
        CreateTable(DATABASE::"Fin. Charge Interest Rate");
#endif
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
#if not CLEAN28
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Fin. Charge Interest Rate");
#endif
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    begin
        case TableID of
        end;
    end;
}

