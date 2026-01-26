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
    var
        ExportProtocol: Record "Export Protocol";
    begin
        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then begin
            CreateTable(DATABASE::"Transaction Specification");
            CreateConfigPackageHelper.SetParentTableID(DATABASE::"Bank Acc. Reconciliation", DATABASE::"General Ledger Setup");
            CreateConfigPackageHelper.SetParentTableID(DATABASE::"Sales Header", DATABASE::"Sales & Receivables Setup");
            CreateConfigPackageHelper.SetParentTableID(DATABASE::"Purchase Header", DATABASE::"Sales & Receivables Setup");
            CreateConfigPackageHelper.SetParentTableID(DATABASE::Item, DATABASE::"Sales & Receivables Setup");
            CreateConfigPackageHelper.SetParentTableID(DATABASE::"BOM Component", DATABASE::Item);
        end;
        CreateTable(DATABASE::Area);

        CreateTable(DATABASE::"IBLC/BLWI Transaction Code");
        CreateTable(DATABASE::"Export Protocol");
        CreateConfigPackageHelper.ValidateField(ExportProtocol.FieldNo("Export Object ID"), false);
        CreateTable(DATABASE::"Domiciliation Journal Template");
        CreateTable(DATABASE::"Domiciliation Journal Batch");
        CreateTable(DATABASE::"CODA Statement");
        CreateConfigPackageHelper.CreateTableChild(DATABASE::"CODA Statement Line", DATABASE::"CODA Statement");
        CreateTable(DATABASE::"Transaction Coding");
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
        end;
    end;
}

