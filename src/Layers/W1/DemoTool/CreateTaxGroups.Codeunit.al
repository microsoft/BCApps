codeunit 101321 "Create Tax Groups"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then begin
            if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard then begin
                InsertData(XFURNITURE, XTaxableCONTOSOFurniture);
                InsertData(XLABOR, XLaboronJob);
                InsertData(XMATERIALS, XTaxableRawMaterials);
                InsertData(XSUPPLIES, XTaxableCONTOSOSupplies);

                InsertLocalData();
            end;
            InsertData(NONTAXABLETok, XNontaxableTxt);
        end;
    end;

    var
        "Tax Group": Record "Tax Group";
        DemoDataSetup: Record "Demo Data Setup";
        XFURNITURE: Label 'FURNITURE';
        XTaxableCONTOSOFurniture: Label 'Taxable CONTOSO Furniture';
        XLABOR: Label 'LABOR';
        XLaboronJob: Label 'Labor on Job';
        XMATERIALS: Label 'MATERIALS';
        XTaxableRawMaterials: Label 'Taxable Raw Materials';
        XSUPPLIES: Label 'SUPPLIES';
        XTaxableCONTOSOSupplies: Label 'Taxable CONTOSO Supplies';
        NONTAXABLETok: Label 'NonTAXABLE';
        XNontaxableTxt: Label 'Nontaxable';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Tax Group".Init();
        "Tax Group".Validate(Code, Code);
        "Tax Group".Validate(Description, Description);
        "Tax Group".Insert();
    end;

    local procedure InsertLocalData()
    begin
    end;
}

