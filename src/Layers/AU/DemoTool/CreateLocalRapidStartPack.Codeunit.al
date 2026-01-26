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
        CreateTable(DATABASE::"BAS Setup");
        CreateTable(DATABASE::"BAS XML Field ID");
        CreateTable(DATABASE::"BAS Business Unit");
        CreateTable(DATABASE::"BAS Setup Name");
        CreateTable(DATABASE::"BAS XML Field Setup Name");
        CreateTable(DATABASE::"BAS XML Field ID Setup");
        CreateTable(DATABASE::"Address ID");
        CreateTable(DATABASE::County);
        CreateTable(DATABASE::"WHT Business Posting Group");
        CreateTable(DATABASE::"WHT Product Posting Group");
        CreateTable(DATABASE::"WHT Revenue Types");
        CreateTable(DATABASE::"WHT Posting Setup");
        CreateTable(Database::"Gen. Journal Line");
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
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"BAS Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"BAS XML Field ID");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"BAS Business Unit");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"BAS Setup Name");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"BAS XML Field Setup Name");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"BAS XML Field ID Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Address ID");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::County);
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"WHT Business Posting Group");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"WHT Product Posting Group");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"WHT Revenue Types");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"WHT Posting Setup");
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        DemoDataSetup: Record "Demo Data Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case TableID of
            DATABASE::"BAS XML Field ID":
                SetBASXMLFieldID();
            DATABASE::"WHT Posting Setup":
                if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Extended then
                    SetWHTPostingSetup();
            Database::"Gen. Journal Line":
                begin
                    CreateConfigPackageHelper.IncludeField(GenJournalLine.FieldNo("Skip WHT"), true);
                    CreateConfigPackageHelper.ValidateField(GenJournalLine.FieldNo("Skip WHT"), false);
                end;
        end;
    end;

    local procedure SetBASXMLFieldID()
    var
        BASXMLFieldID: Record "BAS XML Field ID";
    begin
        CreateConfigPackageHelper.IncludeField(BASXMLFieldID.FieldNo("Line No."), false);
    end;

    local procedure SetWHTPostingSetup()
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        CreateConfigPackageHelper.IncludeField(WHTPostingSetup.FieldNo("Bal. Prepaid Account Type"), false);
        CreateConfigPackageHelper.IncludeField(WHTPostingSetup.FieldNo("Bal. Prepaid Account No."), false);
        CreateConfigPackageHelper.IncludeField(WHTPostingSetup.FieldNo("Bal. Payable Account Type"), false);
        CreateConfigPackageHelper.IncludeField(WHTPostingSetup.FieldNo("Bal. Payable Account No."), false);
    end;
}

