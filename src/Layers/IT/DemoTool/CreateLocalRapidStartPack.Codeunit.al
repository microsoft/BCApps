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

        CreateTable(DATABASE::"Withhold Code");
        CreateTable(DATABASE::"Withhold Code Line");
        CreateTable(DATABASE::"Contribution Code");
        CreateTable(DATABASE::"Contribution Code Line");
        CreateTable(DATABASE::"Contribution Bracket");
        CreateTable(DATABASE::"Contribution Bracket Line");
        CreateTable(DATABASE::"VAT Identifier");
        CreateTable(DATABASE::"VAT Register");
        CreateTable(DATABASE::"Payment Lines");
        CreateTable(DATABASE::"ABI/CAB Codes");
        CreateTable(DATABASE::"Bill Posting Group");
        CreateTable(DATABASE::Bill);
        CreateTable(DATABASE::"Fattura Setup");
        CreateTable(DATABASE::"Fattura Document Type");
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
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Withhold Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Withhold Code Line");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Contribution Code");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Contribution Code Line");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Contribution Bracket");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Contribution Bracket Line");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"VAT Identifier");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"VAT Register");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Payment Lines");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"ABI/CAB Codes");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::"Bill Posting Group");
        CreateConfigWorksheet.CreateConfigLine(DATABASE::Bill);
    end;

    procedure SetFieldsAndFilters(TableID: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Record "No. Series";
        PaymentLines: Record "Payment Lines";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        case TableID of
            DATABASE::"No. Series":
                begin
                    CreateConfigPackageHelper.IncludeField(NoSeries.FieldNo("Reverse Sales VAT No. Series"), false);
                    CreateConfigPackageHelper.ValidateField(NoSeries.FieldNo("No. Series Type"), false);
                    CreateConfigPackageHelper.ValidateField(NoSeries.FieldNo("VAT Register"), false);
                end;
            DATABASE::"Payment Lines":
                begin
                    CreateConfigPackageHelper.CreateProcessingFilter(
                      0, PaymentLines.FieldNo(Type), StrSubstNo('=%1', Format(PaymentLines.Type::"Payment Terms", 0, 9)));
                    CreateConfigPackageHelper.SetSkipTableTriggers();
                end;
            DATABASE::"Bill Posting Group":
                CreateConfigPackageHelper.CreateProcessingFilter(0, BillPostingGroup.FieldNo("No."), StrSubstNo('=%1', ''' '''));
            DATABASE::"Purchase Header":
                begin
                    CreateConfigPackageHelper.IncludeField(PurchaseHeader.FieldNo("Check Total"), true);
                    CreateConfigPackageHelper.IncludeField(PurchaseHeader.FieldNo("Due Date"), true);
                end;
            DATABASE::"Sales Header":
                CreateConfigPackageHelper.IncludeField(SalesHeader.FieldNo("Due Date"), true);
            DATABASE::"VAT Posting Setup":
                CreateConfigPackageHelper.ValidateField(VATPostingSetup.FieldNo("VAT Identifier"), false);
        end;
    end;
}
