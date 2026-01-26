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
        CreateTable(DATABASE::Area);

        CreateTable(DATABASE::"Place of Dispatcher");
        CreateTable(DATABASE::"Place of Receiver");
        CreateTable(DATABASE::"Data Export");
        CreateTable(DATABASE::"Data Export Record Definition");
        CreateTable(DATABASE::"Data Export Record Source");
        CreateTable(DATABASE::"Data Export Record Type");
        CreateTable(DATABASE::"Data Export Record Field");
        CreateTable(DATABASE::"Data Export Table Relation");
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
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Source Code Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Place of Dispatcher");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Place of Receiver");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Data Export");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Data Export Record Definition");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Data Export Record Source");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Data Export Record Type");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Data Export Record Field");
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        DemoDataSetup: Record "Demo Data Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Extended then
            case TableID of
                DATABASE::"General Ledger Setup":
                    CreateConfigPackageHelper.ValidateField(GeneralLedgerSetup.FieldNo("Adjust for Payment Disc."), false);
                DATABASE::"Data Export Record Source",
              DATABASE::"Data Export Record Field":
                    CreateConfigPackageHelper.SetSkipTableTriggers();
            end;
    end;
}

