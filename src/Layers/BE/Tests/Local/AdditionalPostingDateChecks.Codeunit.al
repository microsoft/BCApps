codeunit 144048 AdditionalPostingDateChecks
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesBefore()
    begin
        ResetSetups();

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', 0D),
          'Expected a posting date less than the Gen. Journal Template Allow Posting Date From to return true in DateNotAllowed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesAfter()
    begin
        ResetSetups();

        // Verify posting date after allow from to
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-2D>', '<-1D>', 0D),
          'Expected a posting date greater than the Gen. Journal Template Allow Posting Date To to return true in DateNotAllowed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesInside()
    begin
        ResetSetups();

        // Verify posting date inside allow to an from
        Assert.IsFalse(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-1D>', '<1D>', 0D),
          'Expected a posting date inside than the Gen. Journal Template Allow Posting Date From and To return false in DateNotAllowed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeUserSetupBefore()
    var
        PostingDate: Date;
    begin
        ResetSetups();

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate());

        // Configure User setup so the posting date is valid
        ReconfigureUserSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting Date From return true in DateNotAllowed even is UserSetup allows it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeUserSetupAfter()
    var
        PostingDate: Date;
    begin
        ResetSetups();

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate());

        // Configure User setup so the posting date is valid
        ReconfigureUserSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting Date From return true in DateNotAllowed even is UserSetup allows it');

        // Verify posting date after allow to date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-2D>', '<-1D>', PostingDate),
          'Expected a posting date greater than the Gen. Journal Template Allow Posting Date To return true in DateNotAllowed even is UserSetup allows it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeGLSetupBefore()
    var
        PostingDate: Date;
    begin
        ResetSetups();

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate());

        // Configure General Ledger setup so the posting date is valid
        ReconfigureGLSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting Date From return true in DateNotAllowed even is UserSetup allows it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeGLSetupAfter()
    var
        PostingDate: Date;
    begin
        ResetSetups();

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate());

        // Configure General Ledger setup so the posting date is valid
        ReconfigureGLSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting Date From return true in DateNotAllowed even is UserSetup allows it');

        // Verify posting date after allow to date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-2D>', '<-1D>', PostingDate),
          'Expected a posting date greater than the Gen. Journal Template Allow Posting Date To return true in DateNotAllowed even is UserSetup allows it');
    end;

    local procedure ResetSetups()
    begin
        ResetGLSetup();
        ResetUserSetup();
    end;

    local procedure ResetGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := 0D;
        GeneralLedgerSetup."Allow Posting To" := 0D;
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := true;
        GeneralLedgerSetup.Modify();
    end;

    local procedure ResetUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then begin
            UserSetup."Allow Posting From" := 0D;
            UserSetup."Allow Posting To" := 0D;
            UserSetup.Modify();
        end;
    end;

    local procedure ReconfigureGenJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; AllowPostingFrom: Date; AllowPostingTo: Date)
    begin
        GenJournalTemplate."Allow Posting Date From" := AllowPostingFrom;
        GenJournalTemplate."Allow Posting Date To" := AllowPostingTo;
        GenJournalTemplate.Modify();
    end;

    local procedure ReconfigureUserSetup(AllowPostingFrom: Date; AllowPostingTo: Date)
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId()) then begin
            UserSetup."User ID" := UserId();
            UserSetup.Insert();
        end;

        UserSetup."Allow Posting From" := AllowPostingFrom;
        UserSetup."Allow Posting To" := AllowPostingTo;
        UserSetup.Modify();
    end;

    local procedure ReconfigureGLSetup(AllowPostingFrom: Date; AllowPostingTo: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := AllowPostingFrom;
        GeneralLedgerSetup."Allow Posting To" := AllowPostingTo;
        GeneralLedgerSetup.Modify();
    end;

    local procedure RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates(AllowPostingFromDateExpression: Text; AllowPostingToDateExpression: Text; PostingDate: Date): Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        AllowDateFrom: DateFormula;
        AllowDateTo: DateFormula;
    begin
        if PostingDate = 0D then
            PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate());

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        Evaluate(AllowDateFrom, AllowPostingFromDateExpression);
        Evaluate(AllowDateTo, AllowPostingToDateExpression);

        ReconfigureGenJournalTemplate(
            GenJournalTemplate, CalcDate(AllowDateFrom, PostingDate), CalcDate(AllowDateTo, PostingDate));

        exit(GenJnlCheckLine.DateNotAllowed(PostingDate, GenJournalTemplate.Name));
    end;
}

