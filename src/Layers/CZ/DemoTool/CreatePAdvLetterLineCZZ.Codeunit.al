codeunit 163553 "Create P. AdvLetter Line CZZ"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('NZ01220001', DemoDataSetup.BaseVATItemCode(), XEnergyAdvance, 24200.00);
        InsertData('NZ01220002', DemoDataSetup.BaseVATItemCode(), XServiceAdvance, 1210.00);
        InsertData('NZ01220003', DemoDataSetup.BaseVATItemCode(), XServiceAdvance, 1210.00);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        PurchAdvLetterLineCZZ: Record "Purch. Adv. Letter Line CZZ";
        XEnergyAdvance: Label 'Energy Advance';
        XServiceAdvance: Label 'Service Advance';

    procedure InsertData(DocumentNo: Code[20]; VATProdPostingGroup: Code[20]; Description: Text[50]; AmountIncludingVAT: Decimal)
    begin
        PurchAdvLetterLineCZZ.Init();
        PurchAdvLetterLineCZZ.Validate("Document No.", DocumentNo);
        PurchAdvLetterLineCZZ.Validate("Line No.", 10000);
        PurchAdvLetterLineCZZ.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchAdvLetterLineCZZ.Description := Description;
        PurchAdvLetterLineCZZ.Validate("Amount Including VAT", AmountIncludingVAT);
        PurchAdvLetterLineCZZ.Insert();
    end;
}
