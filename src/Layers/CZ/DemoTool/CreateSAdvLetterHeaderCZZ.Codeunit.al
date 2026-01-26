codeunit 163555 "Create S. AdvLetter Header CZZ"
{

    trigger OnRun()
    begin
        InsertData('10000', true, WorkDate(), WorkDate(), WorkDate(), CreateAdvLetterTemplateCZZ.GetAdvanceLetterTemplateCode("Advance Letter Type CZZ"::Sales, 'XDOMESTIC'));
        InsertData('10000', true, WorkDate(), WorkDate(), WorkDate(), CreateAdvLetterTemplateCZZ.GetAdvanceLetterTemplateCode("Advance Letter Type CZZ"::Sales, 'XDOMESTIC'));
        InsertData('10000', true, WorkDate(), WorkDate(), WorkDate(), CreateAdvLetterTemplateCZZ.GetAdvanceLetterTemplateCode("Advance Letter Type CZZ"::Sales, 'XDOMESTIC'));
    end;

    var
        SalesAdvLetterHeaderCZZ: Record "Sales Adv. Letter Header CZZ";
        CreateAdvLetterTemplateCZZ: Codeunit "Create AdvLetter Template CZZ";

    procedure InsertData(CustomerNo: Code[20]; AmountsIncludingVAT: Boolean; PostingDate: Date; AdvanceDueDate: Date; VATDate: Date; LetterCode: Code[10])
    begin
        SalesAdvLetterHeaderCZZ.Init();
        SalesAdvLetterHeaderCZZ."No." := '';
        SalesAdvLetterHeaderCZZ."Advance Letter Code" := LetterCode;
        SalesAdvLetterHeaderCZZ.Insert(true);

        SalesAdvLetterHeaderCZZ.Validate("Bill-to Customer No.", CustomerNo);
        SalesAdvLetterHeaderCZZ.Validate("Posting Date", PostingDate);
        SalesAdvLetterHeaderCZZ."Advance Due Date" := AdvanceDueDate;
        SalesAdvLetterHeaderCZZ."VAT Date" := VATDate;
        SalesAdvLetterHeaderCZZ.Modify();
    end;
}
