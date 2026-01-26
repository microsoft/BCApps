codeunit 144121 "OCR Setup UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Banking] [OCR] [Setup] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateBalAccountTypeClearsBalAccountNo()
    var
        OCRSetup: Record "OCR Setup";
    begin
        OCRSetup.Init();
        OCRSetup."Bal. Account No." := 'TESTCODE';

        OCRSetup.Validate("Bal. Account Type");

        Assert.AreEqual('', OCRSetup."Bal. Account No.", 'Expected balance account no to be cleared');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateJournalTemplateNameClearsJournalName()
    var
        OCRSetup: Record "OCR Setup";
    begin
        OCRSetup.Init();
        OCRSetup."Journal Name" := 'TestName';

        OCRSetup.Validate("Journal Template Name");

        Assert.AreEqual('', OCRSetup."Journal Name", 'Expected Journal Name to be cleared');
    end;
}

