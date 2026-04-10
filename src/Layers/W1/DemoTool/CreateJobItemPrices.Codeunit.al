codeunit 101214 "Create Job Item Prices"
{

    trigger OnRun()
    begin
        InsertData(XGUILDFORD10CR, '', X1920S, XPCS, 0, '', 0, 5, '', false, true);
        InsertData(XGUILDFORD10CR, '', X1928S, XPCS, 0, '', 0, 5, '', false, true);
        InsertData(XGUILDFORD10CR, '', X1964S, XPCS, 0, '', 0, 5, '', false, true);
        InsertData(XGUILDFORD10CR, '', X1984W, XPCS, 0, '', 0, 5, '', false, true);
    end;

    var
        JobItemPrice: Record "Job Item Price";
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        X1920S: Label '1920-S';
        XPCS: Label 'PCS';
        X1928S: Label '1928-S';
        X1964S: Label '1964-S';
        X1984W: Label '1984-W';

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; "Item No.": Code[20]; "Unit of Measure Code": Code[10]; "Unit Price": Decimal; "Currency Code": Code[10]; "Unit Cost Factor": Decimal; "Line Discount %": Decimal; "Variant Code": Code[10]; "Apply Job Price": Boolean; "Apply Job Discount": Boolean)
    begin
        JobItemPrice.Init();
        JobItemPrice.Validate("Job No.", "Job No.");
        JobItemPrice.Validate("Job Task No.", "Job Task No.");
        JobItemPrice.Validate("Item No.", "Item No.");
        JobItemPrice.Validate("Unit of Measure Code", "Unit of Measure Code");
        JobItemPrice.Validate("Currency Code", "Currency Code");
        JobItemPrice.Validate("Unit Price", "Unit Price");
        JobItemPrice.Validate("Line Discount %", "Line Discount %");
        JobItemPrice.Validate("Variant Code", "Variant Code");
        JobItemPrice.Validate("Apply Job Price", "Apply Job Price");
        JobItemPrice.Validate("Apply Job Discount", "Apply Job Discount");
        JobItemPrice.Insert();
    end;
}
