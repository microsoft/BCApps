codeunit 118005 "Create Availability Setup"
{

    trigger OnRun()
    begin
        ModifyData('<90D>', CompanyInfo."Check-Avail. Time Bucket"::Week);
    end;

    var
        CompanyInfo: Record "Company Information";

    procedure ModifyData("Avail. Period Calc.": Code[10]; "Avail. Time Bucket": Enum "Analysis Period Type")
    begin
        CompanyInfo.Get();
        Evaluate(CompanyInfo."Check-Avail. Period Calc.", "Avail. Period Calc.");
        CompanyInfo.Validate("Check-Avail. Period Calc.");
        CompanyInfo.Validate("Check-Avail. Time Bucket", "Avail. Time Bucket");
        CompanyInfo.Modify();
    end;
}

