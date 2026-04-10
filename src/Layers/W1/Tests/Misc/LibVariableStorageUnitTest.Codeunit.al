codeunit 132539 "Lib Variable Storage Unit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Variable Storage]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        OverflowError: Label 'Queue overflow.';
        UnderflowError: Label 'Queue underflow.';
        WrongSize: Label 'Size of the Queue is wrong.';
        WrongValue: Label 'Dequeued value is wrong.';

    [Test]
    [Scope('OnPrem')]
    procedure DequeueMoreThanExpected()
    var
        Value: Variant;
    begin
        // Pre-Setup
        Initialize();

        // Setup
        EnqueueElements(LibraryVariableStorage.MaxLength());

        // Post-Setup
        DequeueElements(LibraryVariableStorage.MaxLength());

        // Exercise
        asserterror LibraryVariableStorage.Dequeue(Value);

        // Verify
        Assert.ExpectedError(UnderflowError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DequeueMultipleElements()
    begin
        // Pre-Setup
        Initialize();

        // Setup
        EnqueueElements(LibraryVariableStorage.MaxLength());

        // Exercise
        DequeueElements(LibraryVariableStorage.MaxLength());

        // Verify
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DequeueSingleElement()
    var
        Value: Variant;
    begin
        // Pre-Setup
        Initialize();

        // Setup
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(100));

        // Exercise
        LibraryVariableStorage.Dequeue(Value);

        // Verify
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueMoreThanExpected()
    begin
        // Pre-Setup
        Initialize();

        // Setup
        EnqueueElements(LibraryVariableStorage.MaxLength());

        // Exercise
        asserterror LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(100));

        // Verify
        Assert.ExpectedError(OverflowError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueMultipleElements()
    begin
        // Setup
        Initialize();

        // Exercise
        EnqueueElements(LibraryVariableStorage.MaxLength());

        // Verify
        LibraryVariableStorage.AssertFull();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueSingleElement()
    begin
        // Setup
        Initialize();

        // Exercise
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(100));

        // Verify
        Assert.AreEqual(1, LibraryVariableStorage.Length(), WrongSize);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleEnqueueDequeueOperations()
    var
        NoOfDequeuedElements: Integer;
    begin
        // Pre-Setup
        Initialize();

        // Setup
        EnqueueElements(LibraryVariableStorage.MaxLength());

        // Post-Setup
        NoOfDequeuedElements := LibraryRandom.RandInt(LibraryVariableStorage.Length() div 2);
        DequeueElements(NoOfDequeuedElements);

        // Exercise
        EnqueueElements(NoOfDequeuedElements);

        // Post-Exercise
        NoOfDequeuedElements := LibraryRandom.RandInt(LibraryVariableStorage.Length() div 2);
        DequeueElements(NoOfDequeuedElements);

        // Verify
        EnqueueElements(NoOfDequeuedElements);
        LibraryVariableStorage.AssertFull();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleEnqueueDequeueOperations()
    var
        FirstOutput: Variant;
        SecondOutput: Variant;
        FirstValue: Integer;
        SecondValue: Integer;
    begin
        // Pre-Setup
        Initialize();

        // Setup
        FirstValue := LibraryRandom.RandInt(100);
        SecondValue := FirstValue + LibraryRandom.RandInt(100);

        // Exercise
        LibraryVariableStorage.Enqueue(FirstValue);
        LibraryVariableStorage.Enqueue(SecondValue);

        // Post-Exercise
        LibraryVariableStorage.Dequeue(FirstOutput);
        LibraryVariableStorage.Dequeue(SecondOutput);

        // Verify
        Assert.AreEqual(FirstValue, FirstOutput, WrongValue);
        Assert.AreEqual(SecondValue, SecondOutput, WrongValue);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure DequeueElements(NoOfElements: Integer)
    var
        Value: Variant;
        Index: Integer;
    begin
        for Index := 1 to NoOfElements do
            LibraryVariableStorage.Dequeue(Value);
    end;

    local procedure EnqueueElements(NoOfElements: Integer)
    var
        Index: Integer;
    begin
        for Index := 1 to NoOfElements do
            LibraryVariableStorage.Enqueue(Index);
    end;
}

