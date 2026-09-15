codeunit 117081 "Create Job Queue Setup"
{
    trigger OnRun()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        InsertJobQueueCategory(GetSalesPurchasePostCategoryCode(), DocPostDescrLbl);
        InsertJobQueueCategory(GetJrnlPostPostCategoryCode(), JournlPostDescrLbl);

        if SalesReceivablesSetup.Get() then begin
            SalesReceivablesSetup."Job Queue Category Code" := GetSalesPurchasePostCategoryCode();
            SalesReceivablesSetup.Modify();
        end;

        if PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup."Job Queue Category Code" := GetSalesPurchasePostCategoryCode();
            PurchasesPayablesSetup.Modify();
        end;

        if GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup."Job Queue Category Code" := GetJrnlPostPostCategoryCode();
            GeneralLedgerSetup.Modify();
        end;
    end;

    var
        DocPostCodeLbl: Label 'DOCPOST', Comment = 'Must be max. 10 chars and no spacing.';
        DocPostDescrLbl: Label 'Sales/Purchase Posting';
        JournlPostCodeLbl: Label 'JRNLPOST', Comment = 'Must be max. 10 chars and no spacing.';
        JournlPostDescrLbl: Label 'General Ledger Posting';

    local procedure InsertJobQueueCategory(Name: Code[10]; Description: Text[30])
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueCategory.Init();
        JobQueueCategory.Code := Name;
        JobQueueCategory.Description := Description;
        JobQueueCategory.Insert();
    end;

    local procedure GetSalesPurchasePostCategoryCode(): Code[10]
    begin
        exit(CopyStr(DocPostCodeLbl, 1, 10));
    end;

    local procedure GetJrnlPostPostCategoryCode(): Code[10]
    begin
        exit(CopyStr(JournlPostCodeLbl, 1, 10));
    end;
}

