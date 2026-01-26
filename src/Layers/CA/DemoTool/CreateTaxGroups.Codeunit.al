codeunit 101321 "Create Tax Groups"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then begin
            InsertData(xTAXABLETok, xTaxableDescription);
            InsertData(xNONTAXABLETok, xNonTaxableDescription);
            TaxSetup.Get();
            TaxSetup."Auto. Create Tax Details" := true;
            TaxSetup."Non-Taxable Tax Group Code" := xNONTAXABLETok;
            TaxSetup.Modify();
        end;
    end;

    var
        xNONTAXABLETok: Label 'NonTAXABLE';
        xTAXABLETok: Label 'TAXABLE';
        xTaxableDescription: Label 'Taxable Goods and Services';
        xNonTaxableDescription: Label 'Non-taxable Goods and Services';
        TaxSetup: Record "Tax Setup";

    local procedure InsertData("Code": Code[10]; Description: Text[30])
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Init();
        TaxGroup.Validate(Code, Code);
        TaxGroup.Validate(Description, Description);
        TaxGroup.Insert();
    end;
}

