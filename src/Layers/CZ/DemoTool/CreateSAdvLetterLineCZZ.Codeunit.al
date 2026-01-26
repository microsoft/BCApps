codeunit 163556 "Create S. AdvLetter Line CZZ"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('PZ01220001', DemoDataSetup.BaseVATItemCode(), XEnergyAdvance, 24200.00);
        InsertData('PZ01220002', DemoDataSetup.BaseVATItemCode(), XServiceAdvance, 1210.00);
        InsertData('PZ01220003', DemoDataSetup.BaseVATItemCode(), XServiceAdvance, 1210.00);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        SalesAdvLetterLineCZZ: Record "Sales Adv. Letter Line CZZ";
        XEnergyAdvance: Label 'Energy Advance';
        XServiceAdvance: Label 'Service Advance';

    procedure InsertData(DocumentNo: Code[20]; VATProdPostingGroup: Code[20]; Description: Text[50]; AmountIncludingVAT: Decimal)
    begin
        SalesAdvLetterLineCZZ.Init();
        SalesAdvLetterLineCZZ.Validate("Document No.", DocumentNo);
        SalesAdvLetterLineCZZ.Validate("Line No.", 10000);
        SalesAdvLetterLineCZZ.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesAdvLetterLineCZZ.Description := Description;
        SalesAdvLetterLineCZZ.Validate("Amount Including VAT", AmountIncludingVAT);
        SalesAdvLetterLineCZZ.Insert();
    end;
}
