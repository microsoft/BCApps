codeunit 101319 "Create Tax Area Lines"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax"
        then begin
            // Alberta
            InsertData('AB', 'CA');

            // North West Territories
            InsertData('NT', 'CA');

            // Nunavut
            InsertData('NU', 'CA');

            // Yukon
            InsertData('YK', 'CA');

            // HST provinces
            // New Brunswick
            InsertData('NB', 'CANB');

            // Newfoundland and Labrador
            InsertData('NL', 'CANL');

            // Nova Scotia
            InsertData('NS', 'CANS');

            // Ontario
            InsertData('ON', 'CAON');

            // Prince Edward Island
            InsertData('PE', 'CAPE');

            // QST - Quebec sales tax
            InsertData('QC', 'CAQC');
            InsertData('QC', 'CA');

            // PST provinces
            // British Columbia
            InsertData('BC', 'CABC');
            InsertData('BC', 'CA');

            // Manitoba
            InsertData('MB', 'CAMB');
            InsertData('MB', 'CA');

            // Saskatchewan
            InsertData('SK', 'CASK');
            InsertData('SK', 'CA');
        end;
    end;

    local procedure InsertData(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.Init();
        TaxAreaLine.Validate("Tax Area", TaxAreaCode);
        TaxAreaLine.Validate("Tax Jurisdiction Code", TaxJurisdictionCode);
        TaxAreaLine.Insert();
    end;
}

