codeunit 101931 "Create Local RapidStart Pack"
{
    // Extension for codeunit 101995 Create RapidStart Package


    trigger OnRun()
    begin
    end;

    var
        CreateConfigPackageHelper: Codeunit "Create Config. Package Helper";

    procedure CreateTables()
    begin
        CreateTable(DATABASE::Area);
    end;

    procedure CreateTable(TableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTable(TableID);
        SetFieldsAndFilters(TableID);
    end;

    procedure CreateWorksheetLines()
    begin
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
            end;
    end;
}

