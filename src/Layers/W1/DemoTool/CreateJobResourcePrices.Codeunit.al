codeunit 101213 "Create Job Resource Prices"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XGUILDFORD10CR, '', 0, XLIFT, '', 2140, '', 0, 0, true, true);
        InsertData(XGUILDFORD10CR, '', 0, XLina, '', 856, '', 0, 0, true, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        JobResourcePrice: Record "Job Resource Price";
        XLina: Label 'Lina';
        XLIFT: Label 'LIFT';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; Type: Option Resource,"Group(Resource)",All; "Code": Code[20]; "Work Type Code": Code[10]; "Unit Price": Decimal; "Currency Code": Code[10]; "Unit Cost Factor": Decimal; "Line Discount %": Decimal; "Apply Job Price": Boolean; "Apply Job Discount": Boolean)
    begin
        JobResourcePrice.Init();
        JobResourcePrice.Validate("Job No.", "Job No.");
        JobResourcePrice.Validate("Job Task No.", "Job Task No.");
        JobResourcePrice.Validate(Type, Type);
        JobResourcePrice.Validate(Code, Code);
        JobResourcePrice.Validate("Work Type Code", "Work Type Code");
        JobResourcePrice.Validate("Currency Code", "Currency Code");
        JobResourcePrice.Validate(
          "Unit Price",
          Round(
            "Unit Price" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor"));
        JobResourcePrice.Validate("Apply Job Price", "Apply Job Price");
        JobResourcePrice.Validate("Apply Job Discount", "Apply Job Discount");
        JobResourcePrice.Insert();
    end;
}
