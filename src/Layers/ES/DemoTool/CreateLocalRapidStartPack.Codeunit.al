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

        CreateTable(DATABASE::"Payment Day");
        CreateTable(DATABASE::"Non-Payment Period");
        CreateTable(DATABASE::"AEAT Transference Format");
        CreateTable(DATABASE::"Statistical Code");
        CreateTable(DATABASE::"AEAT Transference Format XML");

        CreateTable(DATABASE::"Operation Code");
        CreateTable(DATABASE::"Category Code");
        CreateTable(DATABASE::"Operation Fee");
        CreateTable(DATABASE::"Cartera Report Selections");
        CreateTable(DATABASE::"Cartera Setup");
        CreateTable(DATABASE::Installment);
        CreateTable(DATABASE::"Fee Range");
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
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Day");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Non-Payment Period");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"AEAT Transference Format");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"AEAT Transference Format XML");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Statistical Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Operation Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Category Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Operation Fee");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Cartera Report Selections");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Cartera Setup");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::Installment);
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Fee Range");
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        GenJournalTemplate: Record "Gen. Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
        VatPostingSetup: Record "VAT Posting Setup";
    begin
        case TableID of
            DATABASE::Customer:
                CreateConfigPackageHelper.IncludeField(Customer.FieldNo("Payment Method Code"), true);
            DATABASE::Vendor:
                CreateConfigPackageHelper.IncludeField(Vendor.FieldNo("Payment Method Code"), true);
            DATABASE::"Gen. Journal Template":
                CreateConfigPackageHelper.ValidateField(GenJournalTemplate.FieldNo("Source Code"), false);
            DATABASE::"Source Code Setup":
                CreateConfigPackageHelper.ValidateField(SourceCodeSetup.FieldNo("Cartera Journal"), false);
            DATABASE::"Acc. Schedule Line":
                UpdateAccScheduleLineFieldProcessingOrder();
            Database::"VAT Posting Setup":
                begin
                    CreateConfigPackageHelper.ValidateField(VatPostingSetup.FieldNo("VAT Identifier"), false);
                    CreateConfigPackageHelper.ValidateField(VatPostingSetup.FieldNo("EC %"), false);
                end;
        end;
    end;

    local procedure UpdateAccScheduleLineFieldProcessingOrder()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ConfigPackageField1: Record "Config. Package Field";
        ConfigPackageField2: Record "Config. Package Field";
        ProcessingOrder: Integer;
    begin
        ConfigPackageField1.Get(
          CreateConfigPackageHelper.GetPackageCode(), DATABASE::"Acc. Schedule Line", AccScheduleLine.FieldNo("Totaling Type"));
        ConfigPackageField2.Get(
          CreateConfigPackageHelper.GetPackageCode(), DATABASE::"Acc. Schedule Line", AccScheduleLine.FieldNo(Totaling));

        ProcessingOrder := ConfigPackageField1."Processing Order";
        ConfigPackageField1."Processing Order" := ConfigPackageField2."Processing Order";
        ConfigPackageField2."Processing Order" := ProcessingOrder;
        ConfigPackageField1.Modify();
        ConfigPackageField2.Modify();
    end;
}

