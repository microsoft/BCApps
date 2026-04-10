codeunit 134484 "Change Global Dim. Buffer Mgt."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Change Global Dimensions]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T100_ClearBufferBlanksTempBuffer()
    var
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
    begin
        // [SCENARIO] ClearBuffer() makes ChangeGlobalDimLogMgt clear
        Initialize();

        MockChangeGlobalDimLogEntry();
        ChangeGlobalDimLogMgt.FillBuffer();
        Assert.IsFalse(ChangeGlobalDimLogMgt.IsBufferClear(), 'IsClear before ClearBuffer');

        ChangeGlobalDimLogMgt.ClearBuffer();
        Assert.IsTrue(ChangeGlobalDimLogMgt.IsBufferClear(), 'IsClear after ClearBuffer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T200_FillBufferIfNoLogEntries()
    var
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
    begin
        // [SCENARIO] FillBuffer returns FALSE if table 483 is empty
        Initialize();

        Assert.IsFalse(ChangeGlobalDimLogMgt.FillBuffer(), 'FillBuffer');
        Assert.IsTrue(ChangeGlobalDimLogMgt.IsBufferClear(), 'IsBufferClear');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T201_FillBufferIfLogEntriesExist()
    var
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
    begin
        // [SCENARIO] FillBuffer returns TRUE if table 483 is not empty
        Initialize();
        MockChangeGlobalDimLogEntry();
        Assert.IsTrue(ChangeGlobalDimLogMgt.FillBuffer(), 'FillBuffer');
        Assert.IsFalse(ChangeGlobalDimLogMgt.IsBufferClear(), 'IsBufferClear');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T210_ExcludeTableRemovesItFromTempList()
    var
        Customer: Record Customer;
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
        TableID: Integer;
    begin
        // [SCENARIO] ExcludeTable removed table from the temp list
        Initialize();
        // [GIVEN] LogEntry for table "Customer"
        TableID := MockChangeGlobalDimLogEntry();
        Assert.IsTrue(ChangeGlobalDimLogMgt.FillBuffer(), 'FillBuffer');
        // [WHEN] run ExcludeTable(21)
        ChangeGlobalDimLogMgt.ExcludeTable(TableID);
        // [THEN] Insert of a new customer is not blocked
        Assert.IsTrue(Customer.Insert(), 'customer should be inserted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T220_LogEntryDeleteTriggerRemovesTableFromTempList()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        Customer: Record Customer;
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
        TableID: Integer;
    begin
        // [SCENARIO] ChangeGlobalDimLogEntry.DELETE(TRUE) removes table from the temp list
        Initialize();
        // [GIVEN] LogEntry for table "Customer"
        TableID := MockChangeGlobalDimLogEntry();
        Assert.IsTrue(ChangeGlobalDimLogMgt.FillBuffer(), 'FillBuffer');
        // [WHEN] ChangeGlobalDimLogEntry.DELETE(TRUE)
        ChangeGlobalDimLogEntry.Get(TableID);
        ChangeGlobalDimLogEntry.Delete(true);

        // [THEN] Insert of a new customer is not blocked
        ChangeGlobalDimLogEntry.Insert(); // to mock a block if TempBlockAllObjWithCaption contains Customer record
        Assert.IsTrue(Customer.Insert(), 'customer should be inserted');
    end;

    local procedure Initialize()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Change Global Dim. Buffer Mgt.");
        ChangeGlobalDimLogEntry.DeleteAll();
    end;

    local procedure MockChangeGlobalDimLogEntry(): Integer
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::Customer;
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::"In Progress";
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry.Insert();
        exit(ChangeGlobalDimLogEntry."Table ID");
    end;
}
