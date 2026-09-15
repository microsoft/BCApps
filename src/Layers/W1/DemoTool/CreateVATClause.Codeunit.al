codeunit 101261 "Create VAT Clause"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" in [DemoDataSetup."Data Type"::Evaluation, DemoDataSetup."Data Type"::Standard] then begin
            InsertData(XReducedCodeTxt, XReducedDescTxt);
            InsertData(XZeroCodeTxt, XZeroDescTxt);
            ModifyVATPostingSetup();
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XReducedDescTxt: Label 'Reduced VAT Rate is used due to VAT Act regulation 1 article II';
        XZeroDescTxt: Label 'Zero VAT Rate is used due to VAT Act regulation 2 article III';
        XReducedCodeTxt: Label 'REDUCED', Comment = 'REDUCED';
        XZeroCodeTxt: Label 'ZERO', Locked = true;

    procedure InsertData(CodeValue: Code[10]; DescriptionValue: Text[80])
    var
        VATClause: Record "VAT Clause";
    begin
        VATClause.Init();
        VATClause.Validate(Code, CodeValue);
        VATClause.Validate(Description, DescriptionValue);
        VATClause.Insert(true);
    end;

    local procedure ModifyVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Prod. Posting Group", XReducedCodeTxt);
        VATPostingSetup.ModifyAll("VAT Clause Code", XReducedCodeTxt);

        VATPostingSetup.SetRange("VAT Prod. Posting Group", XZeroCodeTxt);
        VATPostingSetup.ModifyAll("VAT Clause Code", XZeroCodeTxt);
    end;
}

