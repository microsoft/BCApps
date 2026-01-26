codeunit 161503 "Create CH VAT Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        // Blanc
        InsertLine('', xCodeNormal, 0.0, '2200', '1170', 'Z', 'E');
        InsertLine('', xCodeRed, 0.0, '2200', '1170', 'Z', 'E');
        InsertLine('', xCodeBetrieb, 0.0, '2200', '1171', 'Z', 'E');
        InsertLine('', DemoDataSetup.NoVATCode(), 0.0, '2200', '1170', 'Z', 'E');
        // CH
        InsertLine(DemoDataSetup.DomesticCode(), xCodeNormal, 8.0, '2200', '1170', 'A', 'S');
        InsertLine(DemoDataSetup.DomesticCode(), xCodeRed, 2.4, '2200', '1170', 'B', 'S');
        InsertLine(DemoDataSetup.DomesticCode(), xCodeBetrieb, 8.0, '2200', '1171', 'A', 'S');
        InsertLine(DemoDataSetup.DomesticCode(), xCodeHalbNor, 3.66089, '2200', '1171', 'D', 'S');
        InsertLine(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 0.0, '2200', '1170', 'Z', 'E');
        InsertLine(DemoDataSetup.DomesticCode(), xCodeHotel, 3.6, '2200', '1170', 'C', 'S');
        InsertLine(DemoDataSetup.DomesticCode(), xCodeImport, 100, '', '1174', 'H', 'S');
        // Foreign
        InsertLine(DemoDataSetup.ExportCode(), xCodeNormal, 0.0, '2200', '1170', 'Z', 'E');
        InsertLine(DemoDataSetup.ExportCode(), xCodeRed, 0.0, '2200', '1170', 'Z', 'E');
        InsertLine(DemoDataSetup.ExportCode(), xCodeBetrieb, 0.0, '', '1171', 'Z', 'E');
        InsertLine(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), 0.0, '2200', '1170', 'Z', 'E');
        // EU
        InsertLine(DemoDataSetup.EUCode(), xCodeNormal, 0.0, '2200', '1170', 'Z', 'E');
        InsertLine(DemoDataSetup.EUCode(), xCodeRed, 0.0, '2200', '1170', 'Z', 'E');
        InsertLine(DemoDataSetup.EUCode(), xCodeBetrieb, 0.0, '', '1171', 'Z', 'E');
        InsertLine(DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), 0.0, '2200', '1170', 'Z', 'E');
        // 5.00 NEW
        InsertLine(DemoDataSetup.EUCode(), xCodeHotel, 0.0, '2200', '1170', 'Z', 'E');
    end;

    var
        xCodeNormal: Label 'NORMAL';
        xCodeRed: Label 'RED';
        xCodeBetrieb: Label 'OPEXP';
        xCodeHalbNor: Label 'HALF NORM';
        xCodeHotel: Label 'HOTEL';
        xCodeImport: Label 'IMPORT';
        DemoDataSetup: Record "Demo Data Setup";
        VATPostingSetup: Record "VAT Posting Setup";

    procedure InsertLine(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Percent: Decimal; SalesVATAccount: Code[20]; PurchaseVATAccount: Code[20]; VATID: Code[10]; TaxCategory: Code[10])
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATPostingSetup."VAT %" := Percent;
        VATPostingSetup."VAT Identifier" := VATID;
        VATPostingSetup."Adjust for Payment Discount" := true;
        VATPostingSetup.Validate("Sales VAT Account", SalesVATAccount);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAccount);
        VATPostingSetup."Sales VAT Unreal. Account" := '';
        VATPostingSetup."Purch. VAT Unreal. Account" := '';
        VATPostingSetup."Tax Category" := TaxCategory;
        if Percent = 100 then
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Full VAT"
        else
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::" ";
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();
    end;
}

