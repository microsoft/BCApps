codeunit 144029 "UT PAG REQDESCR"
{
    //  Include test case:
    // 
    //  1. Test to verify that control Omit Default Descr. in Jnl exist on GL Account Card Page.
    // 
    //  Covers Test Cases for WI -  341772
    //  ----------------------------------------------------------------------------------------------
    //  Test Function Name                                                                      TFS ID
    //  ----------------------------------------------------------------------------------------------
    //  OmitDefaultDescriptionInJournalExistOnGLAccountCardPage

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OmitDefaultDescriptionInJournalExistOnGLAccountCardPage()
    var
        GLAccount: Record "G/L Account";
        ControlExist: Boolean;
    begin
        // Purpose of the test is to validate that Control Omit Default Descr. in Jnl exist on GL Account Card Page.

        // Setup and Exercise: Find Control Omit Default Descr. in Jnl on GL Account Card Page.
        ControlExist := LibraryUtilityOnPrem.FindControl(17, GLAccount.FieldNo("Omit Default Descr. in Jnl."));  // 17 used for GL Account Card Page Id.

        // Verify: Verify that control Omit Default Descr. in Jnl exist on GL Account Card Page.
        Assert.AreEqual(true, ControlExist, 'Control must exist');
    end;
}

