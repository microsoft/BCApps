codeunit 101261 "Create VAT Clause"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" in [DemoDataSetup."Data Type"::Evaluation, DemoDataSetup."Data Type"::Standard] then begin
            // NAVCZ
            InsertData(XEU, 'Jedná se o plnění osvobozené od daně dle zákona č. 235/2004Sb. Zákona o dani z přidané hodnoty v platném znění. Daň odvede zákazník.', '');
            InsertData(XRC21, 'Dle §92a zákona č. 235/2004 Sb o DPH se jedná o přenesení daňové povinnosti, kdy výši daně je POVINEN DOPLNIT A PŘIZNAT', 'plátce daně, pro kterého se plnění uskutečnilo. Sazba DPH je 21% a daň odvede zákazník.');
            InsertData(XRC15, 'Dle §92a zákona č. 235/2004 Sb o DPH se jedná o přenesení daňové povinnosti, kdy výši daně je POVINEN DOPLNIT A PŘIZNAT', 'plátce daně, pro kterého se plnění uskutečnilo. Sazba DPH je 15% a daň odvede zákazník.');
            // NAVCZ
            ModifyVATPostingSetup();
        end;
    end;

    var
        XEU: Label 'EU';
        XRC21: Label 'RC21', Comment = 'Reverse Charge 21%';
        XRC15: Label 'RC15', Comment = 'Reverse Charge 15%';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(CodeValue: Code[10]; DescriptionValue: Text[250]; Description2: Text[250])
    var
        VATClause: Record "VAT Clause";
    begin
        VATClause.Init();
        VATClause.Validate(Code, CodeValue);
        VATClause.Validate(Description, DescriptionValue);
        VATClause.Validate("Description 2", Description2); // NAVCZ
        VATClause.Insert(true);
    end;

    local procedure ModifyVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // NAVCZ
        VATPostingSetup.SetRange("VAT Bus. Posting Group", DemoDataSetup.DomesticCode());
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.SetRange("VAT %", 15);
        VATPostingSetup.ModifyAll("VAT Clause Code", XRC15);

        VATPostingSetup.SetRange("VAT %", 21);
        VATPostingSetup.ModifyAll("VAT Clause Code", XRC21);

        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("VAT Bus. Posting Group", DemoDataSetup.EUCode());
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', DemoDataSetup.NoVATCode());
        VATPostingSetup.ModifyAll("VAT Clause Code", XEU);
        // NAVCZ
    end;
}

