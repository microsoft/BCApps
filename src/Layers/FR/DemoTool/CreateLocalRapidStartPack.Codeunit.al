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
        CreateTable(DATABASE::"FR Acc. Schedule Name");
        CreateTable(DATABASE::"FR Acc. Schedule Line");
        CreateTable(DATABASE::"Payment Class");
        CreateTable(DATABASE::"Payment Status");
        CreateTable(DATABASE::"Payment Step");
        CreateTable(DATABASE::"Payment Address");
        CreateTable(DATABASE::"Gen. Journal Line");
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
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"FR Acc. Schedule Name");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"FR Acc. Schedule Line");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Class");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Status");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Step");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Address");
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case TableID of
            DATABASE::"Accounting Period":
                CreateConfigPackageHelper.ValidateField(AccountingPeriod.FieldNo("New Fiscal Year"), false);
            DATABASE::"Gen. Journal Line":
                CreateConfigPackageHelper.IncludeField(GenJournalLine.FieldNo("Source Code"), true);
        end;
    end;
}

