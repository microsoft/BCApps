codeunit 144014 "UT PAG Company"
{
    // 1. Purpose of the test is to validate OnInit trigger of Page 5050 - Contact Card.
    // 
    // Covers Test Cases for WI - 345001.
    // ------------------------------------------
    // Test Function Name           TFS ID
    // ------------------------------------------
    // OnInitContactCard            151241,151242

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInitContactCard()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // Purpose of the test is to validate OnInit trigger of Page 5050 - Contact Card.

        // Setup.
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", CreateContact());

        // Exercise.
        ContactCard.Type.SetValue(Contact.Type::Person);

        // Verify.
        Assert.IsFalse(ContactCard."Trade Register".Enabled(), 'Field should be disabled.');
    end;

    local procedure CreateContact(): Code[20]
    var
        Contact: Record Contact;
    begin
        Contact."No." := LibraryUTUtility.GetNewCode();
        Contact.Insert();
        exit(Contact."No.");
    end;
}

