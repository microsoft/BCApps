codeunit 144005 "UT TAB Purchase Process"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal Template]
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTypeGenJournalTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Purpose of the test is to validate Type - OnValidate Trigger of Table ID - 80 General Journal Template.
        // Setup.
        SourceCodeSetup.Get();

        // Exercise: Validate Type on General Journal Template.
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);

        // Verify: Verify Page ID, Source Code and Test Report ID on General Journal Template.
        GenJournalTemplate.TestField("Page ID", PAGE::"Payment Journal");
        GenJournalTemplate.TestField("Source Code", SourceCodeSetup."Payment Journal");
        GenJournalTemplate.TestField("Test Report ID", REPORT::"Payment Journal - Test");
    end;
}

