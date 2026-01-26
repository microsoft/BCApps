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
        ColumnLayout: Record "Column Layout";
    begin
        case TableID of
            DATABASE::"Column Layout":
                CreateConfigPackageHelper.ValidateField(ColumnLayout.FieldNo("Comparison Period Formula"), false);
        end;
    end;
}

