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
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        PurchaseHeader: Record "Purchase Header";
    begin
        case TableID of
            DATABASE::"Bank Account":
                CreateConfigPackageHelper.ValidateField(BankAccount.FieldNo("Bank Account No."), false);
            DATABASE::"Customer Bank Account":
                begin
                    CreateConfigPackageHelper.ValidateField(CustomerBankAccount.FieldNo("Bank Account No."), false);
                    CreateConfigPackageHelper.ValidateField(CustomerBankAccount.FieldNo("Country/Region Code"), false);
                end;
            DATABASE::"Vendor Bank Account":
                begin
                    CreateConfigPackageHelper.ValidateField(VendorBankAccount.FieldNo("Bank Account No."), false);
                    CreateConfigPackageHelper.ValidateField(VendorBankAccount.FieldNo("Country/Region Code"), false);
                end;
            DATABASE::"Purchase Header":
                begin
                    CreateConfigPackageHelper.IncludeField(PurchaseHeader.FieldNo("Message Type"), true);
                    CreateConfigPackageHelper.IncludeField(PurchaseHeader.FieldNo("Invoice Message"), true);
                end;
        end;
    end;
}

