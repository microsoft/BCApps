codeunit 101908 "Make Corrections"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLEntry: Record "G/L Entry";
        CalcAndPostVAT: Report "Calc. and Post VAT Settlement";
        "Create Gen. Journal Line": Codeunit "Create Gen. Journal Line";
        CA: Codeunit "Make Adjustments";
        DocNo: Code[20];
        XSET1Q: Label 'SET-1Q';
        XVAT1Q: Label 'VAT-1Q';
        XSET2Q: Label 'SET-2Q';
        XVAT2Q: Label 'VAT-2Q';
        XSET3Q: Label 'SET-3Q';
        XVAT3Q: Label 'VAT-3Q';
        XVATSettlement: Label 'VAT Settlement';
        XVATSET: Label 'VATSET';
        XSTART: Label 'START';
        XDEFAULT: Label 'DEFAULT';
        VATDocNumber: Label '%1%2';

    procedure CalcAndPostVATSettle(Date: Date)
    begin
        DemoDataSetup.Get();

        Clear(CalcAndPostVAT);

        case Date of
            CA.AdjustDate(19020501D):
                begin
                    DocNo := StrSubstNo(VATDocNumber, XSET1Q, Date2DMY(Date, 3));
                    CalcAndPostVAT.InitializeRequest(
                      0D, CA.AdjustDate(19020331D), CA.AdjustDate(19020501D), StrSubstNo(VATDocNumber, XVAT1Q, Date2DMY(Date, 3)),
                      CA.Convert('995710'), false, true);
                    CalcAndPostVAT.UseRequestPage(false);
                end;
            CA.AdjustDate(19020801D):
                begin
                    DocNo := StrSubstNo(VATDocNumber, XSET2Q, Date2DMY(Date, 3));
                    CalcAndPostVAT.InitializeRequest(
                      0D, CA.AdjustDate(19020630D), CA.AdjustDate(19020801D), StrSubstNo(VATDocNumber, XVAT2Q, Date2DMY(Date, 3)),
                      CA.Convert('995710'), false, true);
                    CalcAndPostVAT.UseRequestPage(false);
                end;
            CA.AdjustDate(19021101D):
                begin
                    DocNo := StrSubstNo(VATDocNumber, XSET3Q, Date2DMY(Date, 3));
                    CalcAndPostVAT.InitializeRequest(
                      0D, CA.AdjustDate(19020930D), CA.AdjustDate(19021101D), StrSubstNo(VATDocNumber, XVAT3Q, Date2DMY(Date, 3)),
                      CA.Convert('995710'), false, true);
                    CalcAndPostVAT.UseRequestPage(false);
                end;
            else
                DocNo := XVATSET;
        end;

        CalcAndPostVAT.SaveAsPdf(TemporaryPath + Format(CreateGuid()) + '.pdf');

        GLEntry.FindLast();
        InsertOtherEntry(
          0, '995310', GLEntry."Posting Date", DocNo, XVATSettlement, GLEntry.Amount,
          0, '995710', '');
    end;

    procedure InsertOtherEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; "Shortcut Dimension 1 Code": Code[20])
    var
        "Gen. Journal Line": Record "Gen. Journal Line";
    begin
        "Create Gen. Journal Line".InitGenJnlLine("Gen. Journal Line", XSTART, XDEFAULT);
        "Gen. Journal Line".Validate("Account Type", "Account Type");
        if "Gen. Journal Line"."Account Type" = "Gen. Journal Line"."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        "Gen. Journal Line".Validate("Account No.", "Account No.");
        "Gen. Journal Line".Validate("Posting Date", Date);
        "Gen. Journal Line".Validate("Document Type", 0);
        "Gen. Journal Line".Validate("Document No.", "Document No.");
        "Gen. Journal Line".Validate(Description, Description);
        "Gen. Journal Line".Validate("Bal. Account Type", "Bal. Account Type");
        if "Gen. Journal Line"."Bal. Account Type" = "Gen. Journal Line"."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        "Gen. Journal Line".Validate("Bal. Account No.", "Bal. Account No.");
        "Gen. Journal Line".Validate(Amount, Amount);
        "Gen. Journal Line".Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        "Gen. Journal Line".Insert(true);
    end;
}

