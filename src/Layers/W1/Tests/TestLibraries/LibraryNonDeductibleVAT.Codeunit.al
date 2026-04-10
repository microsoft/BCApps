codeunit 131344 "Library - NonDeductible VAT"
{
    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";

    procedure EnableNonDeductibleVAT()
    var
        VATSetup: Record "VAT Setup";
    begin
        if not VATSetup.Get() then
            VATSetup.Insert();
        VATSetup."Enable Non-Deductible VAT" := true;
        VATSetup.Modify();
    end;

    procedure SetUseForItemCost()
    var
        VATSetup: Record "VAT Setup";
    begin
        VATSetup.Get();
        VATSetup."Use For Item Cost" := true;
        VATSetup.Modify();
    end;

    procedure SetUseForFixedAssetCost()
    var
        VATSetup: Record "VAT Setup";
    begin
        VATSetup.Get();
        VATSetup."Use For Fixed Asset Cost" := true;
        VATSetup.Modify();
    end;

    procedure SetUseForJobCost()
    var
        VATSetup: Record "VAT Setup";
    begin
        VATSetup.Get();
        VATSetup."Use For Job Cost" := true;
        VATSetup.Modify();
    end;

    procedure CreatVATPostingSetupAllowedForNonDeductibleVAT(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType, VATRate);
        SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Modify(true);
    end;

    procedure CreateNonDeductibleNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Modify(true);
    end;

    procedure CreateNonDeductibleReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Modify(true);
    end;

    procedure CreatePurchPrepmtNonDeductibleNormalVATPostingSetup(var GLAccount: Record "G/L Account") PrepmtGLAccNo: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxCalculationType: Enum "Tax Calculation Type";
    begin
        PrepmtGLAccNo := LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, TaxCalculationType::"Normal VAT");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Modify(true);
        exit(PrepmtGLAccNo);
    end;

    procedure SetAllowNonDeductibleVATForVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::Allow);
    end;

    procedure GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(NonDeductibleVAT.GetNonDeductibleVATPct(VATPostingSetup));
    end;

    procedure VerifyNonDeductibleAmountsInPurchLine(PurchLine: Record "Purchase Line"; NonDeductibleVATPct: Decimal; NonDeductibleBase: Decimal; NonDeductibleAmount: Decimal)
    begin
        PurchLine.TestField("Non-Deductible VAT %", NonDeductibleVATPct);
        PurchLine.TestField("Non-Deductible VAT Base", NonDeductibleBase);
        PurchLine.TestField("Non-Deductible VAT Amount", NonDeductibleAmount);
    end;

    procedure VerifyVATAmountsInVATEntry(VATEntry: Record "VAT Entry"; Base: Decimal; Amount: Decimal; NonDeductibleBase: Decimal; NonDeductibleAmount: Decimal)
    begin
        VATEntry.TestField(Base, Base);
        VATEntry.TestField(Amount, Amount);
        VATEntry.TestField("Non-Deductible VAT Base", NonDeductibleBase);
        VATEntry.TestField("Non-Deductible VAT Amount", NonDeductibleAmount);
    end;

    procedure CreateVATPostingSetupWithNonDeductibleDetail(var VATPostingSetup: Record "VAT Posting Setup"; VATPercentage: Decimal; NonDeductibleVATPer: Decimal)
    begin
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("VAT %", VATPercentage);
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Non-Deductible VAT %", NonDeductibleVATPer);
        VATPostingSetup.Modify(true);
    end;
}
