codeunit 163552 "Create P. AdvLetter Header CZZ"
{

    trigger OnRun()
    begin
        InsertData('10000', true, WorkDate(), WorkDate(), WorkDate(), CreateAdvLetterTemplateCZZ.GetAdvanceLetterTemplateCode("Advance Letter Type CZZ"::Purchase, 'XDOMESTIC'), 'ZAL22/01');
        InsertData('10000', true, WorkDate(), WorkDate(), WorkDate(), CreateAdvLetterTemplateCZZ.GetAdvanceLetterTemplateCode("Advance Letter Type CZZ"::Purchase, 'XDOMESTIC'), 'ZAL22/02');
        InsertData('10000', true, WorkDate(), WorkDate(), WorkDate(), CreateAdvLetterTemplateCZZ.GetAdvanceLetterTemplateCode("Advance Letter Type CZZ"::Purchase, 'XDOMESTIC'), 'ZAL22/03');
    end;

    var
        PurchAdvLetterHeaderCZZ: Record "Purch. Adv. Letter Header CZZ";
        CreateAdvLetterTemplateCZZ: Codeunit "Create AdvLetter Template CZZ";

    procedure InsertData(VendorNo: Code[20]; AmountsIncludingVAT: Boolean; PostingDate: Date; AdvanceDueDate: Date; VATDate: Date; LetterCode: Code[20]; VendorAdvLetterNo: Code[35])
    begin
        PurchAdvLetterHeaderCZZ.Init();
        PurchAdvLetterHeaderCZZ."No." := '';
        PurchAdvLetterHeaderCZZ."Advance Letter Code" := LetterCode;
        PurchAdvLetterHeaderCZZ.Insert(true);

        PurchAdvLetterHeaderCZZ.Validate("Pay-to Vendor No.", VendorNo);
        PurchAdvLetterHeaderCZZ.Validate("Posting Date", PostingDate);
        PurchAdvLetterHeaderCZZ."Advance Due Date" := AdvanceDueDate;
        PurchAdvLetterHeaderCZZ."VAT Date" := VATDate;
        PurchAdvLetterHeaderCZZ."Vendor Adv. Letter No." := VendorAdvLetterNo;
        PurchAdvLetterHeaderCZZ.Modify();
    end;
}
