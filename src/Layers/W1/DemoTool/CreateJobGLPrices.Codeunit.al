codeunit 101212 "Create Job G/L Prices"
{

    trigger OnRun()
    begin
        InsertData(XGUILDFORD10CR, '', '998450', 0, '', 1.15, 0, 0);
    end;

    var
        JobGLPrice: Record "Job G/L Account Price";
        CA: Codeunit "Make Adjustments";
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; "G/L Account No.": Code[20]; "Unit Price": Decimal; "Currency Code": Code[10]; "Unit Cost Factor": Decimal; "Line Discount %": Decimal; "Unit Cost": Decimal)
    begin
        JobGLPrice.Init();
        JobGLPrice.Validate("Job No.", "Job No.");
        JobGLPrice.Validate("Job Task No.", "Job Task No.");
        JobGLPrice.Validate("G/L Account No.", CA.Convert("G/L Account No."));
        JobGLPrice.Validate("Currency Code", "Currency Code");
        JobGLPrice.Validate("Unit Price", "Unit Price");
        JobGLPrice.Validate("Unit Cost Factor", "Unit Cost Factor");
        JobGLPrice.Validate("Line Discount %", "Line Discount %");
        JobGLPrice.Validate("Unit Cost", "Unit Cost");
        JobGLPrice.Insert();
    end;
}
