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
        CreateTable(Database::"VAT Reporting Code");
        CreateTable(DATABASE::"VAT Period");
        CreateTable(DATABASE::"E-Invoice Export Header");
        CreateTable(DATABASE::"E-Invoice Export Line");
        CreateTable(DATABASE::"E-Invoice Transfer File");
        CreateTable(DATABASE::"Regulatory Reporting Code");
        CreateTable(DATABASE::"Gen. Jnl. Line Reg. Rep. Code");
        CreateTable(Database::"VAT Posting Setup");
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
    begin
        case TableID of
            database::"VAT Posting Setup":
                begin
                    CreateConfigPackageHelper.IncludeField(10620, false);
                    CreateConfigPackageHelper.IncludeField(10621, false);
                    CreateConfigPackageHelper.IncludeField(10622, false);
                    CreateConfigPackageHelper.IncludeField(10623, false);
                    CreateConfigPackageHelper.IncludeField(10670, false);
                    CreateConfigPackageHelper.IncludeField(10671, false);
                    CreateConfigPackageHelper.IncludeField(10672, false);
                    CreateConfigPackageHelper.IncludeField(10673, false);
                end;
        end;
    end;
}

