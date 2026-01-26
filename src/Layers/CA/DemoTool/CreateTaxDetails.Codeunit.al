codeunit 101322 "Create Tax Details"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        GovermentTaxRate: Integer;
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax"
        then begin
            GovermentTaxRate := 5;

            DefaultTaxGroup := xTAXABLETok;

            // GST only provinces
            // Goverment
            InsertTaxDetail('CA', xTAXABLETok, GovermentTaxRate);
            InsertTaxDetail('CA', xNONTAXABLETok, 0);

            // HST provinces
            // New Brunswick
            InsertTaxDetail('CANB', xTAXABLETok, GovermentTaxRate + 10);
            InsertTaxDetail('CANB', xNONTAXABLETok, 0);

            // Newfoundland and Labrador
            InsertTaxDetail('CANL', xTAXABLETok, GovermentTaxRate + 10);
            InsertTaxDetail('CANL', xNONTAXABLETok, 0);

            // Nova Scotia
            InsertTaxDetail('CANS', xTAXABLETok, GovermentTaxRate + 10);
            InsertTaxDetail('CANS', xNONTAXABLETok, 0);

            // Ontario
            InsertTaxDetail('CAON', xTAXABLETok, GovermentTaxRate + 8);
            InsertTaxDetail('CAON', xNONTAXABLETok, 0);

            // Prince Edward Island
            InsertTaxDetail('CAPE', xTAXABLETok, GovermentTaxRate + 10);
            InsertTaxDetail('CAPE', xNONTAXABLETok, 0);

            // QST - Quebec sales tax
            InsertTaxDetail('CAQC', xTAXABLETok, 9.975);
            InsertTaxDetail('CAQC', xNONTAXABLETok, 0);

            // PST provinces
            // British Columbia
            InsertTaxDetail('CABC', xTAXABLETok, 7);
            InsertTaxDetail('CABC', xNONTAXABLETok, 0);

            // Manitoba
            InsertTaxDetail('CAMB', xTAXABLETok, 7);
            InsertTaxDetail('CAMB', xNONTAXABLETok, 0);

            // Saskatchewan
            InsertTaxDetail('CASK', xTAXABLETok, 6);
            InsertTaxDetail('CASK', xNONTAXABLETok, 0);
        end;
    end;

    var
        xNONTAXABLETok: Label 'NonTAXABLE';
        xTAXABLETok: Label 'TAXABLE';
        DefaultTaxGroup: Text;

    local procedure InsertTaxDetail(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[10]; TaxBelowMaximum: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        EffectiveDate: Date;
        StartingDate: Text;
    begin
        StartingDate := '2013-01-01';
        Evaluate(EffectiveDate, StartingDate, 9);
        TaxDetail.Init();
        TaxDetail.Validate("Tax Jurisdiction Code", TaxJurisdictionCode);
        TaxDetail.Validate("Tax Group Code", TaxGroupCode);
        TaxDetail.Validate("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        TaxDetail.Validate("Effective Date", EffectiveDate);
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMaximum);
        TaxDetail.Insert();

        if TaxGroupCode = DefaultTaxGroup then begin
            TaxDetail."Tax Group Code" := '';
            TaxDetail.Insert();
        end;

    end;
}

