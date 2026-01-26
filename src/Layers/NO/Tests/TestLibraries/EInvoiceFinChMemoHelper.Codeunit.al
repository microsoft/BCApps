codeunit 143015 "E-Invoice Fin. Ch. Memo Helper"
{

    trigger OnRun()
    begin
    end;

    var
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        TestValueTxt: Label 'Test Value';
        EInvoiceSalesHelper: Codeunit "E-Invoice Sales Helper";

    [Scope('OnPrem')]
    procedure CreateFinChMemo(): Code[20]
    var
        FinChMemoHeader: Record "Finance Charge Memo Header";
    begin
        CreateFinChMemoDoc(FinChMemoHeader);
        exit(IssueFinanceChargeMemo(FinChMemoHeader."No."));
    end;

    [Scope('OnPrem')]
    procedure CreateFinChMemoDoc(var FinChMemoHeader: Record "Finance Charge Memo Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        HowManyLinesToCreate: Integer;
        LineNo: Integer;
        VATProdPostGroupCode: Code[20];
    begin
        CreateFinChMemoHeader(FinChMemoHeader);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATProdPostGroupCode := VATPostingSetup."VAT Prod. Posting Group";
        HowManyLinesToCreate := 1 + LibraryRandom.RandInt(5);
        CreateFinChMemoLines(FinChMemoHeader."No.", HowManyLinesToCreate, VATProdPostGroupCode, LineNo);
    end;

    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemo(FinChMemoHeaderNo: Code[20]): Code[20]
    var
        FinChMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        FinChMemoHeader.SetRange("No.", FinChMemoHeaderNo);
        REPORT.Run(REPORT::"Issue Finance Charge Memos", false, true, FinChMemoHeader);

        IssuedFinChargeMemoHeader.SetFilter("Pre-Assigned No.", FinChMemoHeaderNo);
        IssuedFinChargeMemoHeader.FindFirst();
        exit(IssuedFinChargeMemoHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFinChMemoHeader(var FinChMemoHeader: Record "Finance Charge Memo Header")
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        Customer: Record Customer;
    begin
        EInvoiceHelper.CreateCustomer(Customer);

        FinChMemoHeader.Init();
        FinChMemoHeader.Validate("Customer No.", Customer."No.");
        FinanceChargeTerms.FindFirst();
        FinChMemoHeader.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinChMemoHeader."Post Interest" := true;
        FinChMemoHeader."Post Additional Fee" := true;
        FinChMemoHeader."Your Reference" := TestValueTxt;
        FinChMemoHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFinChMemoLines(FinanceChargeMemoHeaderNo: Code[20]; NoOfLines: Integer; VATProdPostGroupCode: Code[20]; var LineNo: Integer)
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLines do begin
            FinanceChargeMemoLine.Init();
            FinanceChargeMemoLine."Finance Charge Memo No." := FinanceChargeMemoHeaderNo;
            LineNo := LineNo + 10000;
            FinanceChargeMemoLine."Line No." := LineNo;
            FinanceChargeMemoLine."VAT Prod. Posting Group" := VATProdPostGroupCode;
            FinanceChargeMemoLine.Validate(Type, FinanceChargeMemoLine.Type::"G/L Account");
            FinanceChargeMemoLine.Validate("No.", CreateGLAccount(VATProdPostGroupCode));
            FinanceChargeMemoLine.Description := TestValueTxt;
            FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandInt(1000));
            FinanceChargeMemoLine.Insert(true);
        end;
    end;

    local procedure CreateGLAccount(VATProdPostGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup."Auto Insert Default" := false;
        GenProductPostingGroup.Modify();

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProdPostGroupCode;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFinChMemoWithVATGroups(var FinChMemoHeader: Record "Finance Charge Memo Header"; VATRate: array[5] of Decimal): Code[20]
    var
        VATProdPostingGroupCode: Code[20];
        NoOfLines: Integer;
        i: Integer;
        LineNo: Integer;
    begin
        CreateFinChMemoHeader(FinChMemoHeader);
        LineNo := 0;
        for i := 1 to ArrayLen(VATRate) do
            if VATRate[i] >= 0 then begin
                NoOfLines := 2;
                VATProdPostingGroupCode :=
                  EInvoiceSalesHelper.NewVATPostingSetup(VATRate[i], FinChMemoHeader."VAT Bus. Posting Group", false);
                CreateFinChMemoLines(FinChMemoHeader."No.", NoOfLines, VATProdPostingGroupCode, LineNo);
            end;

        exit(IssueFinanceChargeMemo(FinChMemoHeader."No."));
    end;
}

