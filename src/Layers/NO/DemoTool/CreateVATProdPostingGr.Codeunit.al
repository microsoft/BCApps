codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(XFULLVAT, XMiscFullVAT);
            InsertData(XWITHOUT, XMiscWithoutVAT);
            InsertData(XHIGHVAT, XMiscHighVAT);
            InsertData(XLOWVAT, XMiscLowVAT);
            InsertData(XOUTSIDE, XMiscOutsideVAT);
            InsertData(XSERVVAT, XMiscServiceVAT);
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XFULLVAT: Label 'FULL';
        XWITHOUT: Label 'WITHOUT';
        XHIGHVAT: Label 'HIGH';
        XLOWVAT: Label 'LOW';
        XOUTSIDE: Label 'OUTSIDE';
        XSERVVAT: Label 'SERVICE';
        XMiscFullVAT: Label 'Full vat.';
        XMiscWithoutVAT: Label 'Misc - without vat.';
        XMiscHighVAT: Label 'Misc - high vat.';
        XMiscLowVAT: Label 'Misc - low vat.';
        XMiscOutsideVAT: Label 'Misc - outside vat area ';
        XMiscServiceVAT: Label 'Inverse vat.';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Validate(Code, Code);
        VATProductPostingGroup.Validate(Description, Description);
        VATProductPostingGroup.Insert();
    end;

    procedure GetNormalVATProdPostingGroup(): Code[20]
    begin
        exit(XHIGHVAT);
    end;

    procedure GetReducedVATProdPostingGroup(): Code[20]
    begin
        exit(XLOWVAT);
    end;

    procedure GetNoVATVATProdPostingGroup(): Code[20]
    begin
        exit(XWITHOUT);
    end;
}

