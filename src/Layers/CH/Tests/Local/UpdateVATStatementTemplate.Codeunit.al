codeunit 144011 "Update VAT Statement Template"
{
    // // [FEATURE] [Swiss] [VAT Statement]
    // 1. Check VAT Statement Template Name in Request page
    // 
    // -----------------------------------------------------------------------------------
    // Function Name                                                             TFS ID
    // -----------------------------------------------------------------------------------
    // CheckVATStatementTemplateNameRequestPage                                  360020

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCH: Codeunit "Library - CH";
        ConfirmMsg: Label 'Do you want to delete the existing';
        SuccessMsg: Label 'has been successfully updated or created.';
        WrongVATStatTemplateNameErr: Label 'Wrong VAT Statement Template Name.';
        WrongVATStatTemplateDescriptionErr: Label 'Wrong VAT Statement Template Description.';
        CHTemplateNameTxt: Label 'VAT-%1';
        CHTemplateDescrTxt: Label 'Swiss VAT Statement %1';

    [Test]
    [HandlerFunctions('UpdateVATStatementTemplateReqPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateStatementTemplateFromVATPostingSetup()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
    begin
        // Setup.
        SetupDataForVATStatementTemplate(TempVATPostingSetup, VATStatementTemplate);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(VATStatementTemplate.Name);
        REPORT.Run(REPORT::"Update VAT Statement Template", true, false);

        // Verify.
        VerifyVATStatementLines(TempVATPostingSetup, VATStatementTemplate);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStatementTemplateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckVATStatementTemplateNameRequestPage()
    begin
        // EXERCISE
        REPORT.Run(REPORT::"Update VAT Statement Template", true, false);
        // VERIFY
        // Verification execute in Request Page Handler
    end;

    local procedure SetupDataForVATStatementTemplate(var TempVATPostingSetup: Record "VAT Posting Setup" temporary; var VATStatementTemplate: Record "VAT Statement Template")
    var
        VATStatementName: Record "VAT Statement Name";
        VATCipherSetup: Record "VAT Cipher Setup";
    begin
        VATCipherSetup.Get();
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Revenue of Non-Tax. Services",
          VATCipherSetup."Input Tax on Material and Serv");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Deduction of Tax-Exempt",
          VATCipherSetup."Input Tax on Investsments");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Deduction of Services Abroad",
          VATCipherSetup."Deposit Tax");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Deduction of Transfer",
          VATCipherSetup."Input Tax Corrections");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Deduction of Non-Tax. Services",
          VATCipherSetup."Input Tax Cutbacks");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Reduction in Payments",
          VATCipherSetup."Input Tax on Material and Serv");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup.Miscellaneous,
          VATCipherSetup."Input Tax on Investsments");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Tax Normal Rate Serv. Before",
          VATCipherSetup."Deposit Tax");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Tax Normal Rate Serv. After",
          VATCipherSetup."Input Tax Corrections");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Tax Reduced Rate Serv. Before",
          VATCipherSetup."Input Tax Cutbacks");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Tax Reduced Rate Serv. After",
          VATCipherSetup."Deposit Tax");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Tax Hotel Rate Serv. Before",
          VATCipherSetup."Input Tax Corrections");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Tax Hotel Rate Serv. After",
          VATCipherSetup."Input Tax Cutbacks");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Acquisition Tax Before",
          VATCipherSetup."Input Tax Cutbacks");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Acquisition Tax After",
          VATCipherSetup."Deposit Tax");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Cash Flow Taxes",
          VATCipherSetup."Input Tax on Material and Serv");
        CreateVATPostingSetup(TempVATPostingSetup, VATCipherSetup."Cash Flow Compensations",
          VATCipherSetup."Deposit Tax");
    end;

    local procedure CreateVATPostingSetup(var TempVATPostingSetup: Record "VAT Posting Setup" temporary; SalesVATStatCipher: Code[20]; PurchaseVATStatCipher: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          SalesVATStatCipher, PurchaseVATStatCipher);
        TempVATPostingSetup := VATPostingSetup;
        TempVATPostingSetup.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplateReqPageHandler(var UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template")
    var
        VATStatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATStatementName);
        UpdateVATStatementTemplate.Country.SetValue(UpdateVATStatementTemplate.Country.GetOption(1)); // Switzerland
        UpdateVATStatementTemplate.VATStatementTemplateName.SetValue(VATStatementName);
        UpdateVATStatementTemplate.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplateRequestPageHandler(var UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template")
    begin
        Assert.AreEqual(StrSubstNo(CHTemplateNameTxt, Format(Date2DMY(WorkDate(), 3))),
          Format(UpdateVATStatementTemplate.VATStatementTemplateName), WrongVATStatTemplateNameErr);
        Assert.AreEqual(StrSubstNo(CHTemplateDescrTxt, Format(Date2DMY(WorkDate(), 3))),
          Format(UpdateVATStatementTemplate.Description), WrongVATStatTemplateDescriptionErr);
        UpdateVATStatementTemplate.Cancel().Invoke();
    end;

    local procedure VerifyVATStatementLines(var TempVATPostingSetup: Record "VAT Posting Setup" temporary; VATStatementTemplate: Record "VAT Statement Template")
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATCipherSetup: Record "VAT Cipher Setup";
    begin
        VATCipherSetup.Get();
        VATStatementName.SetRange("Statement Template Name", VATStatementTemplate.Name);
        VATStatementName.FindFirst();

        TempVATPostingSetup.FindSet();
        repeat
            VATStatementLine.SetRange("Statement Template Name", VATStatementTemplate.Name);
            VATStatementLine.SetRange("VAT Bus. Posting Group", TempVATPostingSetup."VAT Bus. Posting Group");
            VATStatementLine.SetRange("VAT Prod. Posting Group", TempVATPostingSetup."VAT Prod. Posting Group");
            VATStatementLine.SetRange("Row No.", Format(TempVATPostingSetup."Sales VAT Stat. Cipher"));
            Assert.AreEqual(1, VATStatementLine.Count, 'Wrong number of vat statement lines:' + VATStatementLine.GetFilters);
            VATStatementLine.FindFirst();
            case TempVATPostingSetup."Sales VAT Stat. Cipher" of
                VATCipherSetup."Acquisition Tax Before", VATCipherSetup."Acquisition Tax After":
                    VATStatementLine.TestField("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
                else
                    VATStatementLine.TestField("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Sale);
            end;
        until TempVATPostingSetup.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ConfirmMsg) > 0, 'Unexpected dialog.');
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, SuccessMsg) > 0, 'Unexpected dialog.');
    end;
}

