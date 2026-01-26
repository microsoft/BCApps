codeunit 101931 "Create Local RapidStart Pack"
{
    // Extension for codeunit 101995 Create RapidStart Package


    trigger OnRun()
    begin
    end;

    var
        CreateConfigPackageHelper: Codeunit "Create Config. Package Helper";

    procedure CreateTables()
    var
        TDSPostingSetup: Record "TDS Posting Setup";
        GSTRegNo: Record "GST Registration Nos.";
    begin
        CreateTable(Database::"GST Setup");
        CreateTable(Database::"Tax Transaction Value");
        CreateTable(Database::"Tax Rate");
        CreateTable(Database::"Tax Rate Value");

        CreateTable(Database::"Tax Accounting Period");
        CreateTable(Database::"Concessional Code");
        CreateTable(Database::"Journal Voucher Posting Setup");
        CreateTable(Database::"Voucher Posting Debit Account");
        CreateTable(Database::"Voucher Posting Credit Account");
        CreateTable(Database::"Assessee Code");

        CreateTable(Database::"Act Applicable");
        CreateTable(Database::"TDS Nature Of Remittance");
        CreateTable(Database::"Deductor Category");
        CreateTable(Database::"Ministry");
        CreateTable(Database::"TDS Posting Setup");
        SkipValidateField(TDSPostingSetup.FieldNo("TDS Account"));
        SkipValidateField(TDSPostingSetup.FieldNo("TDS Receivable Account"));
        CreateTable(Database::"Allowed Sections");
        CreateTable(Database::"TDS Concessional Code");
        CreateTable(Database::"Customer Allowed Sections");
        CreateTable(Database::"TDS Customer Concessional Code");
        CreateTable(Database::"TAN Nos.");
        CreateTable(Database::"TDS Section");

        CreateTable(Database::"T.C.A.N. No.");
        CreateTable(Database::"TCS Nature Of Collection");
        CreateTable(Database::"TCS Posting Setup");
        CreateTable(Database::"Allowed NOC");

        CreateTable(Database::"State");
        CreateTable(Database::"GST Registration Nos.");
        SkipValidateField(GSTRegNo.FieldNo("State Code"));
        SkipValidateField(GSTRegNo.FieldNo(Description));
        SkipValidateField(GSTRegNo.FieldNo("Input Service Distributor"));
        CreateTable(Database::"GST Group");
        CreateTable(Database::"HSN/SAC");
        CreateTable(Database::"GST Posting Setup");
        CreateTable(Database::"Tax Rate");
        CreateTable(Database::"GST Recon. Mapping");
        CreateTable(Database::"Bank Charge Deemed Value Setup");
        CreateTable(Database::"Bank Charge");
        CreateTable(Database::"Service Transfer Header");
        CreateTable(Database::"Service Transfer Line");
    end;

    procedure CreateTable(TableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTable(TableID);
        if (TableID >= 20130) and (TableID <= 20399) then
            CreateConfigPackageHelper.SetSkipTableTriggers();
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

    local procedure SkipValidateField(FieldID: Integer)
    begin
        CreateConfigPackageHelper.ValidateField(FieldID, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Demonstration Data", 'OnAfterIsTableIDIncludedIntoFullPack', '', false, false)]
    local procedure OnAfterIsTableIDIncludedIntoFullPack(TableID: Integer; var IsTableIDExcluded: Boolean)
    begin
        if not (TableID in [20130 .. 20399]) then
            exit;

        IsTableIDExcluded := true;
        if TableID in [Database::"Tax Transaction Value", Database::"Tax Rate", Database::"Tax Rate Value"] then
            IsTableIDExcluded := false;
    end;
}

