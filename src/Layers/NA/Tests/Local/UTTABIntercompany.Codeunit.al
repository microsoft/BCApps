codeunit 141011 "UT TAB Intercompany"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Journal Template] [UT]
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TypeOnValidateItemJournalTemplate()
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Purpose of the test is to validate Type - OnValidate of Table ID - 82 Item Journal Template.
        // Setup & Exercise.
        ItemJournalTemplate.Validate(Type);

        // Verify: Verify Test Report ID and Posting Report ID on table - Item Journal Template.
        ItemJournalTemplate.TestField("Posting Report ID", REPORT::"Item Register");
        ItemJournalTemplate.TestField("Test Report ID", REPORT::"Inventory Posting - Test")
    end;
}

