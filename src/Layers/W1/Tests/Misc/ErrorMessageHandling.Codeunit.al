codeunit 132500 "Error Message Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Error Handling]
    end;

    var
        Assert: Codeunit Assert;
        LibraryErrorMessage: Codeunit "Library - Error Message";
        HandledErr: Label 'Handled Error %1', Comment = '%1 - number';
        UnhandledErr: Label 'Unhandled Error.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure T001_SecondSubscriberCannotSubscribeOfficially()
    var
        ErrorMessageHandler: array[2] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Result: Boolean;
    begin
        // [SCENARIO] The first handler only should show logged errors.
        Initialize();
        // [GIVEN] Two subscribers are subscribed correctly
        ErrorMessageMgt.Activate(ErrorMessageHandler[1]);
        ErrorMessageMgt.Activate(ErrorMessageHandler[2]);
        VerifyCountOfActiveSubscribers(1);
        // [GIVEN] Run posting with the error
        PostWithHandledError(HandledErr);

        // [WHEN] HasErrors() of the first subscriber
        Result := ErrorMessageHandler[1].HasErrors();
        // [THEN] There is error message
        Assert.IsTrue(Result, 'first subscriber has no error');

        // [WHEN] HasErrors() of the second subscriber
        Result := ErrorMessageHandler[2].HasErrors();
        // [THEN] There is no error message
        Assert.IsFalse(Result, 'second subscriber has an error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_FirstUnofficialSubscriberGetsSkipped()
    var
        ErrorMessageHandler: array[2] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Result: Boolean;
    begin
        // [SCENARIO] Directly subscribed handler before the activated handler should be inactive.
        Initialize();
        // [GIVEN] The unofficial subscriber is subscribed directly
        BindSubscription(ErrorMessageHandler[1]);
        ErrorMessageMgt.Activate(ErrorMessageHandler[2]);
        VerifyCountOfActiveSubscribers(2);
        // [GIVEN] Run posting with the error
        PostWithHandledError(HandledErr);

        // [WHEN] HasErrors() of the first subscriber
        Result := ErrorMessageHandler[1].HasErrors();
        // [THEN] There is no error message
        Assert.IsFalse(Result, 'first subscriber has an error');

        // [WHEN] HasErrors() of the second subscriber
        Result := ErrorMessageHandler[2].HasErrors();
        // [THEN] There is error message
        Assert.IsTrue(Result, 'second subscriber has no error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T003_FirstOfficialSecondUnofficialSubscriber()
    var
        ErrorMessageHandler: array[2] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Result: Boolean;
    begin
        // [SCENARIO] Directly subscribed handler after the activated handler should be inactive.
        Initialize();
        // [GIVEN] Two subscribers are subscribed, but the second is unofficial
        ErrorMessageMgt.Activate(ErrorMessageHandler[1]);
        BindSubscription(ErrorMessageHandler[2]);
        VerifyCountOfActiveSubscribers(2);
        // [GIVEN] Run posting with the error
        PostWithHandledError(HandledErr);

        // [WHEN] HasErrors() of the first subscriber
        Result := ErrorMessageHandler[1].HasErrors();
        // [THEN] There is error message
        Assert.IsTrue(Result, 'first subscriber has no error');

        // [WHEN] HasErrors() of the second subscriber
        Result := ErrorMessageHandler[2].HasErrors();
        // [THEN] There is no error message
        Assert.IsFalse(Result, 'second subscriber has an error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T004_TestOfficialSubscribers()
    var
        ErrorMessageHandler: array[4] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [SCENARIO] The first activation enabled handling, all others activations and subscriptions are ignored.
        Initialize();
        // [WHEN] Subscribe 1st directly: subscribers - 1, isActive - FALSE
        BindSubscription(ErrorMessageHandler[1]);
        VerifyCountOfActiveSubscribers(1);
        Assert.IsFalse(ErrorMessageMgt.IsActive(), 'after first one');

        // [WHEN] Subscribe 2nd officially: subscribers - 2, isActive - TRUE
        ErrorMessageMgt.Activate(ErrorMessageHandler[2]);
        VerifyCountOfActiveSubscribers(2);
        Assert.IsTrue(ErrorMessageMgt.IsActive(), 'after second one');

        // [WHEN] Subscribe 3rd directly: subscribers - 3, isActive - TRUE
        BindSubscription(ErrorMessageHandler[3]);
        VerifyCountOfActiveSubscribers(3);
        Assert.IsTrue(ErrorMessageMgt.IsActive(), 'after third one');

        // [WHEN] Subscribe 4th officially: subscribers - 3, isActive - TRUE
        ErrorMessageMgt.Activate(ErrorMessageHandler[4]);
        VerifyCountOfActiveSubscribers(3);
        Assert.IsTrue(ErrorMessageMgt.IsActive(), 'after fourth one');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T005_SecondActivationShouldBeSkipped()
    var
        ErrorMessageHandler: array[2] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Result: Boolean;
    begin
        // [SCENARIO] Second activated subscriber is not active and does not show error page.
        Initialize();
        // [GIVEN] Subscriber 'A' is subscribed correctly
        ErrorMessageMgt.Activate(ErrorMessageHandler[1]);
        // [GIVEN] Subscriber 'B' is subscribed correctly
        // [GIVEN] Error is logged and called 'B'.ShowErrors
        ActivateAndShowErrors(ErrorMessageHandler[2]);

        // [WHEN] HasErrors() of the 'A' subscriber
        Result := ErrorMessageHandler[1].HasErrors();
        // [THEN] There is error message
        Assert.IsTrue(Result, 'first subscriber has no error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T006_CallstackDoesNotIncludeCOD28Calls()
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        CallStack: Text;
        Pos: Integer;
    begin
        // [SCENARIO] "Error Call Stack" does not include calls of COD28 methods that lead to TrowError()
        Initialize();
        CallStack := ErrorMessageManagement.GetCurrCallStack();

        Pos := StrPos(CallStack, '(CodeUnit 28)');
        if Pos > 0 then
            error('Must be no COD28 in returned callstack: %1', CopyStr(CallStack, Pos, 50));

        Assert.AreEqual(1, StrPos(CallStack, '"Error Message Handling"(CodeUnit 132500).T006_CallstackDoesNotIncludeCOD28Calls line'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T007_CallstackDoesNotAddeForNotError()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] "Error Call Stack" is blank for Info and Warning error messages.
        Initialize();
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Information, 'Information');
        Assert.AreEqual('', TempErrorMessage.GetErrorCallStack(), 'CallStack must be blank');

        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, 'Warning');
        Assert.AreEqual('', TempErrorMessage.GetErrorCallStack(), 'CallStack must be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T008_CallstackStartsFromLineBeforeCOD28Call()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        CallStack: text;
        Pos: Integer;
    begin
        // [SCENARIO] "Error Call Stack" starts from a call right before first COD28 method call.
        Initialize();

        ErrorMessageManagement.Activate(ErrorMessageHandler);
        ErrorMessageManagement.LogSimpleErrorMessage('Error');
        ErrorMessageManagement.GetErrors(TempErrorMessage);
        CallStack := TempErrorMessage.GetErrorCallStack();
        Pos :=
            StrPos(CallStack, '"Error Message Handling"(CodeUnit 132500).T008_CallstackStartsFromLineBeforeCOD28Call line');
        Assert.AreEqual(1, Pos, 'wrong start');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure T009_ShowErrorCallStack()
    var
        TempErrorMessage: Record "Error Message" temporary;
        CallStack: Text;
    begin
        // [SCEANRIO] ShowErrorCallStack shows the error call stack as a message dialog.
        Initialize();
        // [GIVEN] Error Message, where "Error Call Stack" is 'X'
        Callstack := LibraryUtility.GenerateGUID();
        TempErrorMessage.SetErrorCallStack(Callstack);
        TempErrorMessage.Insert();
        // [WHEN] ShowErrorCallStack
        TempErrorMessage.ShowErrorCallStack();
        // [THEN] Show the Message: 'X'
        Assert.AreEqual(CallStack, LibraryVariableStorage.DequeueText(), 'wrong message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T010_UnhandledErrorAfterHandledOneEnabledHandling()
    var
        TempActualErrorMessage: Record "Error Message" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
    begin
        // [SCENARIO] Unhandled error should be added to the list if happens after the collected one.
        Initialize();
        PushContext(TempErrorMessage, 'Global Context');
        // [GIVEN] Unhandled error 'B' happens after one error 'A' is collected
        PushContext(TempErrorMessage, 'Local Context');
        AddHandledError(TempErrorMessage, StrSubstNo(HandledErr, 1));
        PopContext(TempErrorMessage);
        AddUnhandledError(TempErrorMessage, UnhandledErr);
        AddFinishCall(TempErrorMessage);

        // [WHEN] Run posting with enabled error handling
        LibraryErrorMessage.TrapErrorMessages();
        PostingCodeunitMock.RunWithActiveErrorHandling(TempErrorMessage, false);

        // [THEN] Page "Error Messages" is open, where are both errors: 'A' and 'B'
        LibraryErrorMessage.GetErrorMessages(TempActualErrorMessage);
        Assert.RecordCount(TempActualErrorMessage, 2);
        // [THEN] Handled error 'A', where "Additional Info" is 'Local Context'
        TempActualErrorMessage.FindSet();
        TempActualErrorMessage.TestField("Message", StrSubstNo(HandledErr, 1));
        Assert.AreEqual('Local Context', TempActualErrorMessage."Additional Information", 'Additional info in the handled error');
        // [THEN] Unhandled error 'B', where "Additional Info" is 'Global Context'
        TempActualErrorMessage.Next();
        TempActualErrorMessage.TestField("Message", UnhandledErr);
        Assert.AreEqual('Global Context', TempActualErrorMessage."Additional Information", 'Additional info in the unhandled error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T011_UnhandledErrorAfterHandledOneDisabledHanlding()
    var
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
    begin
        // [SCENARIO] First handled error should be thrown if handling is not enabled.
        Initialize();
        // [GIVEN] Unhandled error 'B' happens after one error 'A' is collected, but before error messages are shown
        AddHandledError(TempErrorMessage, HandledErr);
        AddUnhandledError(TempErrorMessage, UnhandledErr);
        AddFinishCall(TempErrorMessage);

        // [WHEN] Run posting with disabled error handling
        PostingCodeunitMock.TryRun(TempErrorMessage);

        // [THEN] Error 'A' is thrown; Page "Error Messages" is not open.
        Assert.AreEqual(HandledErr, GetLastErrorText, 'unexpected last error text');
    end;

    [Test]
    procedure T012_UnhandledErrorAfterHandledOneEnabledHandlingLogToFile()
    var
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        LogFile: File;
        InStr: InStream;
        LogLine: Text;
        ExpectedLogLine: Array[3] of Text;
        ErrorMsg: Text;
        LineNo: Integer;
    begin
        // [FEATURE] [Log File]
        // [SCENARIO] Unhandled and handled errors should be written to the file.
        Initialize();
        PushContext(TempErrorMessage, 'Global Context');
        // [GIVEN] Unhandled error 'B' happens after one error 'A' is collected
        PushContext(TempErrorMessage, 'Local Context');
        AddHandledError(TempErrorMessage, StrSubstNo(HandledErr, 1));
        PopContext(TempErrorMessage);
        AddUnhandledError(TempErrorMessage, UnhandledErr);
        AddFinishCall(TempErrorMessage);

        // [WHEN] Run posting with enabled error handling and logging to file
        asserterror PostingCodeunitMock.RunWithActiveErrorHandling(TempErrorMessage, true);

        // [THEN] WriteMessagesToFile() re-throws unhandled error 'B' including the callstack
        ErrorMsg := 'Unhandled Error';
        ExpectedLogLine[1] := 'Local Context : Handled Error 1';
        ExpectedLogLine[2] := StrSubstNo('Global Context : %1.', ErrorMsg);
        ExpectedLogLine[3] := '"Posting Codeunit Mock"(CodeUnit 132479).OnRun';
        Assert.ExpectedError(ErrorMsg);
        Assert.ExpectedError(ExpectedLogLine[3]);
        // [THEN] The handled error 'A' is not thrown
        asserterror Assert.ExpectedError(ExpectedLogLine[1]);
        Assert.ExpectedError('x');
        // [THEN] The log file is created in the server folder
        Assert.IsTrue(LogFile.Open(PostingCodeunitMock.GetLogFileName()), 'Log file is not created');
        // [THEN] it contains three lines: error messages 'A' and 'B' with contexts and the callstack line
        LineNo := 0;
        LogFile.CreateInStream(InStr);
        while not InStr.EOS do begin
            LineNo += 1;
            InStr.ReadText(LogLine);
            Assert.ExpectedMessage(ExpectedLogLine[LineNo], LogLine);
        end;
        LogFile.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T015_HistoricalErrorShouldBeClearedOnFirstActivation()
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Historical error happened before activation should not be collected
        Initialize();
        // [GIVEN] A historical error 'XX'
        ClearLastError();
        asserterror Error(HandledErr);
        Assert.AreEqual(HandledErr, GetLastErrorText, 'GETLASTERRORTEXT is empty');

        // [WHEN] Subscriber 'A' is subscribed
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [THEN] GETLASTERRORTEXT is <blank>
        Assert.AreEqual('', GetLastErrorText, 'GETLASTERRORTEXT must be empty after activation');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T016_HistoricalErrorBetweenActivationsShouldNotBeClearedBySecondActivation()
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: array[2] of Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Historical error should not be cleared by second activation
        Initialize();

        // [GIVEN] Subscriber 'A' is subscribed
        ErrorMessageMgt.Activate(ErrorMessageHandler[1]);
        // [GIVEN] A historical error 'XX'
        ClearLastError();
        asserterror Error(HandledErr);
        Assert.AreEqual(HandledErr, GetLastErrorText, 'GETLASTERRORTEXT is empty');

        // [WHEN] Subscriber 'B' is subscribed
        ErrorMessageMgt.Activate(ErrorMessageHandler[2]);

        // [THEN] GETLASTERRORTEXT is 'XX'
        Assert.AreEqual(HandledErr, GetLastErrorText, 'GETLASTERRORTEXT must be not empty after second activation');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T020_RolbackErrorNotCollectedByAppendTo()
    var
        TempActualErrorMessage: Record "Error Message" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [SCENARIO] Rollback error should not be added to the error list if errors exist.
        Initialize();

        // [GIVEN] Expected one error to be logged
        AddHandledError(TempErrorMessage, HandledErr);
        AddFinishCall(TempErrorMessage);

        // [GIVEN] Run posting with enabled error handling
        LibraryErrorMessage.TrapErrorMessages();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        PostingCodeunitMock.TryRun(TempErrorMessage);

        // [WHEN] Collect errors by AppendTo
        ErrorMessageHandler.AppendTo(TempActualErrorMessage);

        // [THEN] One error in the list
        Assert.RecordCount(TempActualErrorMessage, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T021_AloneRolbackErrorNotCollectedByAppendTo()
    var
        TempActualErrorMessage: Record "Error Message" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [SCENARIO] Unhandled error should not be collected by AppendTo() if errors do not exist.
        Initialize();

        // [GIVEN] Expected no error to be logged
        AddFinishCall(TempErrorMessage);

        // [GIVEN] Run posting with enabled error handling
        LibraryErrorMessage.TrapErrorMessages();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        PostingCodeunitMock.TryRun(TempErrorMessage);

        // [WHEN] Collect errors by AppendTo
        ErrorMessageHandler.AppendTo(TempActualErrorMessage);

        // [THEN] Zero errors in the list
        Assert.RecordCount(TempActualErrorMessage, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T022_UnhandledErrorAfterHandledCollectedByAppendTo()
    var
        TempActualErrorMessage: Record "Error Message" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [SCENARIO] Unhandled error should be collected by AppendTo() if errors exist.
        Initialize();

        // [GIVEN] Expected unhandled error after a handled one during execution
        AddHandledError(TempErrorMessage, HandledErr);
        AddUnhandledError(TempErrorMessage, UnhandledErr);

        // [GIVEN] Run posting with enabled error handling
        LibraryErrorMessage.TrapErrorMessages();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        PostingCodeunitMock.TryRun(TempErrorMessage);

        // [WHEN] Collect errors by AppendTo
        ErrorMessageHandler.AppendTo(TempActualErrorMessage);

        // [THEN] Two errors in the list
        Assert.RecordCount(TempActualErrorMessage, 2);
        TempActualErrorMessage.TestField("Message", UnhandledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T023_AloneUnhandledErrorNotCollectedByAppendTo()
    var
        TempActualErrorMessage: Record "Error Message" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [SCENARIO] Rollback error should not be added to the error list if errors do not exist.
        Initialize();

        // [GIVEN] Expected unhandled error during execution
        AddUnhandledError(TempErrorMessage, UnhandledErr);

        // [GIVEN] Run posting with enabled error handling
        LibraryErrorMessage.TrapErrorMessages();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        PostingCodeunitMock.TryRun(TempErrorMessage);

        // [WHEN] Collect errors by AppendTo
        ErrorMessageHandler.AppendTo(TempActualErrorMessage);

        // [THEN] Zero errors in the list
        Assert.RecordCount(TempActualErrorMessage, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T030_FinishDoesNotAffectContext()
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [SCENARIO] Finish method pops context.
        Initialize();

        // [WHEN] PushContext on inactive handling
        // [THEN] Context is not pushed
        Assert.AreEqual(0, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, '1'), 'Push#1 on inactive handling.');

        // [WHEN] PushContext on active handling
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        // [THEN] One context level is added
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, '2'), 'Push#2');

        // [WHEN] Finish, while no errors logged
        ErrorMessageMgt.Finish(4);
        // [THEN] Context is popped
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, '3'), 'Push#3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T031_NestedContexts()
    var
        ErrorContextElement: array[3] of Codeunit "Error Context Element";
        ErrorMessageHandler: array[3] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Error happened in the nested Activate-Finish module goes to the outer handler with local context
        Initialize();

        // [GIVEN] Initial activation with context '1'
        ErrorMessageMgt.Activate(ErrorMessageHandler[1]);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, '1'), 'Push#1');

        // [GIVEN] Nested (skipped) activation with context '2'
        ErrorMessageMgt.Activate(ErrorMessageHandler[2]);
        Assert.AreEqual(2, ErrorMessageMgt.PushContext(ErrorContextElement[2], 4, 0, '2'), 'Push#2');

        // [GIVEN] Nested (skipped) activation with context '3'
        ErrorMessageMgt.Activate(ErrorMessageHandler[3]);
        Assert.AreEqual(3, ErrorMessageMgt.PushContext(ErrorContextElement[3], 4, 0, '3'), 'Push#3');
        // [GIVEN] Error 'X' with context '3'
        ErrorMessageMgt.LogError(0, 'Error3', '');

        // [WHEN] Nested Finish
        asserterror ErrorMessageMgt.Finish(4);
        Assert.ExpectedError('');

        // [THEN] "Error Messages" page shows error 'X' with context '3'
        ErrorMessagesPage.Trap();
        ErrorMessageHandler[1].ShowErrors();
        ErrorMessagesPage.Description.AssertEquals('Error3');
        ErrorMessagesPage."Additional Information".AssertEquals('3');
        ErrorMessagesPage.Close();
        // [THEN] Handlers 2, 3 collected no errors
        ErrorMessageHandler[2].ShowErrors();
        ErrorMessageHandler[3].ShowErrors();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T032_ContextsInBatch()
    var
        SalesInvoiceHeader: array[3] of Record "Sales Invoice Header";
        ErrorContextElement: array[2] of Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Error logged in the first context is not shown for next contexts
        Initialize();
        // [GIVEN] Sales Invoice Header 'A' and 'B'
        SalesInvoiceHeader[1]."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader[1].Insert();
        SalesInvoiceHeader[2]."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader[2].Insert();
        Clear(SalesInvoiceHeader[3]);

        // [GIVEN] Initial activation with context 'blank SalesInvoiceHeader' (batch header)
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement[1], SalesInvoiceHeader[3].RecordId, 0, '1'), 'Push#1');

        // [GIVEN] push context Sales Invoice Header 'A', Info is '2' (document #1 posting)
        Assert.AreEqual(2, PushLocalContext(SalesInvoiceHeader[1].RecordId, '2', ''), 'Push#2');

        // [GIVEN] push context Sales Invoice Header 'A', Info is '3' (document #1 validation)
        // [GIVEN] Error 'X' with context '3'
        Assert.AreEqual(2, PushLocalContext(SalesInvoiceHeader[1].RecordId, '3', 'Error3'), 'Push#3');

        // [GIVEN] Finish #1 fails
        asserterror ErrorMessageMgt.Finish(SalesInvoiceHeader[1].RecordId);
        Assert.IsTrue(ErrorMessageMgt.IsTransactionStopped(), 'Is Transaction #1 not Stopped');

        // [GIVEN] push context '4' (document #2 posting)
        Assert.AreEqual(2, ErrorMessageMgt.PushContext(ErrorContextElement[2], SalesInvoiceHeader[2].RecordId, 0, '4'), 'Push#4');

        // [WHEN] Finish #2 does not fail
        ErrorMessageMgt.Finish(SalesInvoiceHeader[2].RecordId);

        // [THEN] "Error Messages" page shows error 'X' with Sales Invoice Header 'A', Info is '3'
        ErrorMessagesPage.Trap();
        ErrorMessageHandler.ShowErrors();
        ErrorMessagesPage.Context.AssertEquals(Format(SalesInvoiceHeader[1].RecordId));
        ErrorMessagesPage.Description.AssertEquals('Error3');
        ErrorMessagesPage."Additional Information".AssertEquals('3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T040_FinishStopsTransaction()
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] IsTransactionStopped is Yes if the last error was COD28.StopTransaction()
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, 'Context');
        ErrorMessageMgt.LogError(4, 'Error', '');
        asserterror ErrorMessageMgt.Finish(4);
        Assert.IsTrue(ErrorMessageMgt.IsTransactionStopped(), 'IsTransactionStopped');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T041_FinishMustMatchLoggedContext()
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Finish does not stop transaction if context does not match the logged error.
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, 'Context');
        ErrorMessageMgt.LogError(4, 'Error', '');
        ErrorMessageMgt.Finish(15);
        Assert.IsFalse(ErrorMessageMgt.IsTransactionStopped(), 'IsTransactionStopped');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T042_FinishSkipsLoggedWarnings()
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Finish does not stop transaction on a logged warning.
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, 15, 0, 'Context');
        ErrorMessageMgt.LogWarning(0, 'Warning', 15, 0, '');
        ErrorMessageMgt.Finish(15);
        Assert.IsFalse(ErrorMessageMgt.IsTransactionStopped(), 'IsTransactionStopped');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T043_FinishIgnoresErrorsLoggedBeforeCurrContext()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: array[3] of Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Finish includes errors logged after the original context with other context.
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, '4');
        ErrorMessageMgt.LogError(4, 'Error4', '');
        ErrorMessageMgt.PushContext(ErrorContextElement[2], 15, 0, '15');
        ErrorMessageMgt.PushContext(ErrorContextElement[3], 17, 0, '17');
        ErrorMessageMgt.LogError(17, 'Error17', '');
        asserterror ErrorMessageMgt.Finish(15);
        Assert.IsTrue(ErrorMessageMgt.IsTransactionStopped(), 'IsTransactionStopped');
        ErrorMessageMgt.GetErrorsInContext(15, TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.TestField("Message", 'Error17');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T044_FinishCollectsAllErrorsLoggedUnderParentContext()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: array[3] of Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Finish includes errors logged after the original context with other context.
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, '4');
        ErrorMessageMgt.LogWarning(0, 'Warning4', 4, 0, '');
        ErrorMessageMgt.PushContext(ErrorContextElement[2], 15, 0, '15');
        ErrorMessageMgt.LogWarning(0, 'Warning15', 15, 0, '');
        ErrorMessageMgt.PushContext(ErrorContextElement[3], 17, 0, '17');
        ErrorMessageMgt.LogError(17, 'Error17', '');
        asserterror ErrorMessageMgt.Finish(4);
        Assert.IsTrue(ErrorMessageMgt.IsTransactionStopped(), 'IsTransactionStopped');
        ErrorMessageMgt.GetErrorsInContext(4, TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.TestField("Message", 'Error17');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T045_FinishCollectsAllErrorsLoggedUnderFirstContextUsage()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: array[4] of Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Finish includes errors logged after the first usage of the original context
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, '4');
        ErrorMessageMgt.LogError(4, 'Error4', ''); // this error should be ignored by Finish(17)
        ErrorMessageMgt.PushContext(ErrorContextElement[2], 17, 0, '17#1');
        ErrorMessageMgt.LogError(17, 'Error17#1', '');
        ErrorMessageMgt.PushContext(ErrorContextElement[3], 15, 0, '15');
        ErrorMessageMgt.LogError(15, 'Error15', '');
        ErrorMessageMgt.PushContext(ErrorContextElement[4], 17, 0, '17#2');
        ErrorMessageMgt.LogError(17, 'Error17#2', '');
        asserterror ErrorMessageMgt.Finish(17);
        Assert.IsTrue(ErrorMessageMgt.IsTransactionStopped(), 'IsTransactionStopped');
        ErrorMessageMgt.GetErrorsInContext(17, TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T046_GetErrorsInBlankContextReturnsAllErrorMessages()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: array[4] of Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] GetErrorsInContext with blank context returns all logged 'Error' messages
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, '4');
        ErrorMessageMgt.LogError(4, 'Error4', '');
        ErrorMessageMgt.PushContext(ErrorContextElement[2], 17, 0, '17#1');
        ErrorMessageMgt.LogError(17, 'Error17#1', '');
        ErrorMessageMgt.PushContext(ErrorContextElement[3], 15, 0, '15');
        ErrorMessageMgt.LogWarning(0, 'Warning15', 15, 0, '');
        ErrorMessageMgt.PushContext(ErrorContextElement[4], 17, 0, '17#2');
        ErrorMessageMgt.LogError(17, 'Error17#2', '');
        ErrorMessageMgt.GetErrorsInContext(0, TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T050_EmptyAdditionalInformationFilledFromStack()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] If the error logged without additional information it is filled from top of call stack
        Initialize();
        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        if not CODEUNIT.Run(CODEUNIT::TestCodeunitRunError) then
            ErrorMessageMgt.LogError(0, GetLastErrorText, '');
        Assert.IsTrue(ErrorMessageMgt.GetErrors(TempErrorMessage), 'GetErrors');
        TempErrorMessage.FindFirst();
        Assert.ExpectedMessage('(CodeUnit 132441).OnRun', TempErrorMessage."Additional Information");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T060_PushContextNonActive()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        Assert.AreEqual(0, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, ''), 'PushContext without active error handler');
        Assert.IsFalse(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T061_PushErrorContextElement()
    var
        Currency: Record Currency;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 1, 'PushContext#1'), 'PushContext#1');
        Assert.IsTrue(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
        TempErrorMessage.TestField("Additional Information", 'PushContext#1');
        TempErrorMessage.TestField(ID, 1);
        TempErrorMessage.TestField("Context Record ID", Currency.RecordId);
        TempErrorMessage.TestField("Context Field Number", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T062_PushErrorContextElementTwice()
    var
        Currency: Record Currency;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 3, 1, 'PushContext#1'), 'PushContext#1');
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 2, 'PushContext#2'), 'PushContext#2');

        Assert.IsTrue(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
        TempErrorMessage.TestField("Additional Information", 'PushContext#2');
        TempErrorMessage.TestField(ID, 1);
        TempErrorMessage.TestField("Context Record ID", Currency.RecordId);
        TempErrorMessage.TestField("Context Field Number", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T063_PushLocalErrorContextElements()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 4, 0, 'PushContext#1'), 'PushContext#1');
        Assert.AreEqual(2, PushLocalContext(4, 'LocalContext#1', ''), 'PushLocalContext#1');
        Assert.AreEqual(2, PushLocalContext(4, 'LocalContext#2', ''), 'PushLocalContext#2');
        Assert.IsTrue(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
        TempErrorMessage.TestField("Additional Information", 'PushContext#1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T064_PushTwoErrorContextElements()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: array[2] of Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, 'PushContext#1'), 'PushContext#1');
        Assert.AreEqual(2, PushLocalContext(4, 'LocalContext#1', ''), 'PushLocalContext#1');
        Assert.AreEqual(2, ErrorMessageMgt.PushContext(ErrorContextElement[2], 15, 0, 'PushContext#2'), 'PushContext#2');
        Assert.AreEqual(3, PushLocalContext(4, 'LocalContext#2', ''), 'PushLocalContext#2');
        Assert.IsTrue(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
        TempErrorMessage.TestField("Additional Information", 'PushContext#2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T065_PushBlankErrorContextElement()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        BlankRecID: RecordID;
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, 0, 0, 'PushContext#1'), 'PushContext#1');

        Assert.IsTrue(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
        TempErrorMessage.TestField("Additional Information", 'PushContext#1');
        TempErrorMessage.TestField(ID, 1);
        Clear(BlankRecID);
        TempErrorMessage.TestField("Context Record ID", BlankRecID);
        TempErrorMessage.TestField("Context Field Number", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T066_PushNotExistingTableErrorContextElement()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        BlankRecID: RecordID;
        TableNo: Integer;
    begin
        // [FEATURE] [Context] [UT]
        Initialize();
        TableNo := GetNotExistingTableNo();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement, TableNo, 0, 'PushContext#1'), 'PushContext#1');

        Assert.IsTrue(ErrorMessageMgt.GetTopContext(TempErrorMessage), 'GetTopContext');
        TempErrorMessage.TestField("Additional Information", 'PushContext#1');
        TempErrorMessage.TestField(ID, 1);
        Clear(BlankRecID);
        TempErrorMessage.TestField("Context Record ID", BlankRecID);
        TempErrorMessage.TestField("Context Field Number", 0);
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesModalPageHandler')]
    [Scope('OnPrem')]
    procedure T100_ErrorMessageRegisterPage()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageRegister: Record "Error Message Register";
        ErrorMessageRegisterPage: TestPage "Error Message Register";
    begin
        // [FEATURE] [Register] [UI]
        Initialize();
        // [GIVEN] Error Message Register, where "Description" is 'A', "Created On" is '01.10.19 13:23', "User ID" is 'X'
        ErrorMessageRegister.ID := CreateGuid();
        ErrorMessageRegister."Created On" := CurrentDateTime;
        ErrorMessageRegister."User ID" := UserId;
        ErrorMessageRegister."Message" := LibraryUtility.GenerateGUID();
        ErrorMessageRegister.Insert();
        // [GIVEN] 1 Error Message, where "Message Type" is 'Error'
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Error, '1');
        // [GIVEN] 2 Error Messages, where "Message Type" is 'Warning'
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '2');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '3');
        // [GIVEN] 3 Error Messages, where "Message Type" is 'Information'
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '4');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '5');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '6');
        // [GIVEN] 1 Error Message related to another register
        LogSimpleMessage(TempErrorMessage, CreateGuid(), ErrorMessage."Message Type"::Error, 'X');
        TempErrorMessage.Reset();
        ErrorMessage.CopyFromTemp(TempErrorMessage);

        // [WHEN] Open Error Message Register page
        ErrorMessageRegisterPage.OpenView();

        // [THEN] One record in the page, where "Description" is 'A', "Created On" is '01.10.19 13:23', "User ID" is 'X',
        ErrorMessageRegisterPage.Description.AssertEquals(ErrorMessageRegister."Message");
        ErrorMessageRegisterPage."User ID".AssertEquals(ErrorMessageRegister."User ID");
        ErrorMessageRegisterPage."Created On".AssertEquals(ErrorMessageRegister."Created On");
        // [THEN] "Errors" is 1, "Warnings" is 2, "Information" is 3
        ErrorMessageRegisterPage.Errors.AssertEquals('1');
        ErrorMessageRegisterPage.Warnings.AssertEquals('2');
        ErrorMessageRegisterPage.Information.AssertEquals('3');

        // [WHEN] run action Show
        ErrorMessageRegisterPage.Show.Invoke();

        // [THEN] open Error Messages modal page, where are 3 records
        Assert.AreEqual(6, LibraryVariableStorage.DequeueInteger(), 'wrong number of records');
        Assert.AreEqual('6', LibraryVariableStorage.DequeueText(), 'wron Description in the last record');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesModalPageHandler')]
    [Scope('OnPrem')]
    procedure T110_RegisterDrillDownErrors()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageRegister: Record "Error Message Register";
        ErrorMessageRegisterPage: TestPage "Error Message Register";
    begin
        // [FEATURE] [Register] [UI]
        Initialize();
        // [GIVEN] Error Message Register
        ErrorMessageRegister.ID := CreateGuid();
        ErrorMessageRegister.Insert();
        // [GIVEN] 3 Error Messages, where "Message Type" is 'Error'
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '1');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Error, '2');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Error, '3');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Error, '4');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '5');
        // [GIVEN] 1 'Error' Error Message related to another register
        LogSimpleMessage(TempErrorMessage, CreateGuid(), ErrorMessage."Message Type"::Error, 'X');
        TempErrorMessage.Reset();
        ErrorMessage.CopyFromTemp(TempErrorMessage);

        // [WHEN] DrillDown on "Errors" in Error Message Register page
        ErrorMessageRegisterPage.OpenView();
        ErrorMessageRegisterPage.Errors.AssertEquals('3');
        ErrorMessageRegisterPage.Errors.Drilldown();

        // [THEN] open Error Messages modal page, where are 3 records with "Message Type" 'Error'
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), 'wrong number of records');
        Assert.AreEqual('4', LibraryVariableStorage.DequeueText(), 'wron Description in the last record');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesModalPageHandler')]
    [Scope('OnPrem')]
    procedure T111_RegisterDrillDownWarnings()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageRegister: Record "Error Message Register";
        ErrorMessageRegisterPage: TestPage "Error Message Register";
    begin
        // [FEATURE] [Register] [UI]
        Initialize();
        // [GIVEN] Error Message Register
        ErrorMessageRegister.ID := CreateGuid();
        ErrorMessageRegister.Insert();
        // [GIVEN] 3 Error Messages, where "Message Type" is 'Warning'
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Error, '1');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '2');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '3');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '4');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '5');
        // [GIVEN] 1 'Warning' Error Message related to another register
        LogSimpleMessage(TempErrorMessage, CreateGuid(), ErrorMessage."Message Type"::Warning, 'X');
        TempErrorMessage.Reset();
        ErrorMessage.CopyFromTemp(TempErrorMessage);

        // [WHEN] DrillDown on "Errors" in Error Message Register page
        ErrorMessageRegisterPage.OpenView();
        ErrorMessageRegisterPage.Warnings.AssertEquals('3');
        ErrorMessageRegisterPage.Warnings.Drilldown();

        // [THEN] open Error Messages modal page, where are 3 records with "Message Type" 'Warning'
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), 'wrong number of records');
        Assert.AreEqual('4', LibraryVariableStorage.DequeueText(), 'wron Description in the last record');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesModalPageHandler')]
    [Scope('OnPrem')]
    procedure T112_RegisterDrillDownInformation()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageRegister: Record "Error Message Register";
        ErrorMessageRegisterPage: TestPage "Error Message Register";
    begin
        // [FEATURE] [Register] [UI]
        Initialize();
        // [GIVEN] Error Message Register
        ErrorMessageRegister.ID := CreateGuid();
        ErrorMessageRegister.Insert();
        // [GIVEN] 3 Error Messages, where "Message Type" is 'Information'
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Warning, '1');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '2');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '3');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Information, '4');
        LogSimpleMessage(TempErrorMessage, ErrorMessageRegister.ID, ErrorMessage."Message Type"::Error, '5');
        // [GIVEN] 1 'Information' Error Message related to another register
        LogSimpleMessage(TempErrorMessage, CreateGuid(), ErrorMessage."Message Type"::Information, 'X');
        TempErrorMessage.Reset();
        ErrorMessage.CopyFromTemp(TempErrorMessage);

        // [WHEN] DrillDown on "Errors" in Error Message Register page
        ErrorMessageRegisterPage.OpenView();
        ErrorMessageRegisterPage.Information.AssertEquals('3');
        ErrorMessageRegisterPage.Information.Drilldown();

        // [THEN] open Error Messages modal page, where are 3 records with "Message Type" 'Information'
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), 'wrong number of records');
        Assert.AreEqual('4', LibraryVariableStorage.DequeueText(), 'wron Description in the last record');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_RegisterNew()
    var
        ErrorMessageRegister: Record "Error Message Register";
        Description: Text[250];
    begin
        // [FEATURE] [Register] [UT]
        Initialize();
        Description := LibraryUtility.GenerateGUID();
        ErrorMessageRegister.New(Description);
        // [THEN] Register is inserted, "ID" is filled automatically, "User ID" and "Created On" are filled with current values.
        ErrorMessageRegister.Find();
        ErrorMessageRegister.TestField(ID);
        ErrorMessageRegister.TestField("Message", Description);
        Assert.AreNearlyEqual(0, CurrentDateTime - ErrorMessageRegister."Created On", 1000, 'Created On');
        ErrorMessageRegister.TestField("User ID", UserId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_RegisterDelete()
    var
        ErrorMessage: Record "Error Message";
        ErrorMessageRegister: Record "Error Message Register";
        RegisterID: Guid;
    begin
        // [FEATURE] [Register] [UT]
        Initialize();
        // [GIVEN] Error message for register 'A'
        RegisterID := CreateGuid();
        ErrorMessage."Register ID" := RegisterID;
        ErrorMessage.ID := 0;
        ErrorMessage.Insert(true);

        // [GIVEN] Error message for register 'B'
        ErrorMessageRegister.New('');
        ErrorMessage."Register ID" := ErrorMessageRegister.ID;
        ErrorMessage.ID := 0;
        ErrorMessage.Insert(true);

        // [WHEN] Delete error register 'B'
        ErrorMessageRegister.Delete(true);

        // [THEN] Exists message for register 'A'
        ErrorMessage.SetRange("Register ID", RegisterID);
        Assert.RecordIsNotEmpty(ErrorMessage);
        // [THEN] Deleted message for register 'B'
        ErrorMessage.SetRange("Register ID", ErrorMessageRegister.ID);
        Assert.RecordIsEmpty(ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T130_UnhandledErrorGetsRegistered()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageRegister: Record "Error Message Register";
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [Register] [UT]
        Initialize();
        // [GIVEN] Unhandled error 'B' happens after error 'A' are collected
        AddHandledError(TempErrorMessage, StrSubstNo(HandledErr, 2));
        AddUnhandledError(TempErrorMessage, UnhandledErr);
        AddFinishCall(TempErrorMessage);
        // [WHEN] Run posting with enabled error handling
        ErrorMessagesPage.Trap();
        PostingCodeunitMock.RunWithActiveErrorHandling(TempErrorMessage, false);
        // [THEN] Error Messages list page open
        ErrorMessagesPage.Close();
        // [THEN] Error Register contains 2 'Error' records: 'A' and 'B'.
        ErrorMessageRegister.FindFirst();
        ErrorMessageRegister.CalcFields(Errors, Warnings);
        ErrorMessageRegister.TestField(Errors, 2);
        ErrorMessage.SetRange("Register ID", ErrorMessageRegister.ID);
        Assert.IsTrue(ErrorMessage.Find('-'), '1st error not found');
        ErrorMessage.TestField("Message", StrSubstNo(HandledErr, 2));
        Assert.IsTrue(ErrorMessage.Next() <> 0, '2nd error not found');
        ErrorMessage.TestField("Message", UnhandledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T131_SecondRegisterInsertedOnError()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageRegister: Record "Error Message Register";
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [Register] [UT]
        Initialize();
        // [GIVEN] Unhandled error 'B' happens after error 'A' are collected
        AddHandledError(TempErrorMessage, StrSubstNo(HandledErr, 2));
        AddUnhandledError(TempErrorMessage, UnhandledErr);
        AddFinishCall(TempErrorMessage);
        // [WHEN] Run posting with enabled error handling twice
        ErrorMessagesPage.Trap();
        PostingCodeunitMock.RunWithActiveErrorHandling(TempErrorMessage, false);
        ErrorMessagesPage.Close();
        ErrorMessagesPage.Trap();
        PostingCodeunitMock.RunWithActiveErrorHandling(TempErrorMessage, false);
        ErrorMessagesPage.Close();
        // [THEN] 2 Error Registers each contains 2 'Error' records: 'A' and 'B'.
        Assert.IsTrue(ErrorMessageRegister.Find('-'), '1st register not found');
        ErrorMessage.SetRange("Register ID", ErrorMessageRegister.ID);
        Assert.RecordCount(ErrorMessage, 2);
        Assert.IsTrue(ErrorMessageRegister.Next() <> 0, '2nd register not found');
        ErrorMessage.SetRange("Register ID", ErrorMessageRegister.ID);
        Assert.IsTrue(ErrorMessage.Find('-'), '1st error not found');
        ErrorMessage.TestField("Message", StrSubstNo(HandledErr, 2));
        Assert.IsTrue(ErrorMessage.Next() <> 0, '2nd error not found');
        ErrorMessage.TestField("Message", UnhandledErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T990_ForwardLinkPageNameIsNotEditable()
    var
        NamedForwardLink: Record "Named Forward Link";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        ForwardLinks: TestPage "Forward Links";
    begin
        // [FEATURE] [UI] [Forward Link]
        Initialize();

        NamedForwardLink.DeleteAll();
        NamedForwardLink.Init();
        NamedForwardLink.Name := ForwardLinkMgt.GetHelpCodeForAllowedPostingDate();
        NamedForwardLink.Description := NamedForwardLink.Name;
        NamedForwardLink.Link := 'https://go.microsoft.com/fwlink/?linkid=2208139';
        NamedForwardLink.Insert();

        ForwardLinks.OpenEdit();

        Assert.IsFalse(ForwardLinks.Name.Editable(), 'Name should not be editable');
        Assert.IsTrue(ForwardLinks.Description.Editable(), 'Description should be editable');
        Assert.IsTrue(ForwardLinks.Link.Editable(), 'Link should be editable');
        asserterror ForwardLinks.New();
        Assert.ExpectedError('Insert is not allowed. Page = Forward Links, Id = 1431.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T991_ForwardLinkPageLoadData()
    var
        NamedForwardLink: Record "Named Forward Link";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        ForwardLinks: TestPage "Forward Links";
    begin
        // [FEATURE] [UI] [Forward Link]
        Initialize();
        // [GIVEN] No Forward Links
        NamedForwardLink.DeleteAll();

        // [WHEN] Run action "Load" on the page
        ForwardLinks.OpenView();
        ForwardLinks.Load.Invoke();

        // [THEN] 9 records added
        Assert.RecordCount(NamedForwardLink, 10);
        // [THEN] 'Allowed Posting Date', 'Working with dims', 'Blocked Item', 'Blocked Customer' links exist
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForAllowedPostingDate());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForWorkingWithDimensions());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForBlockedCustomer());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForBlockedItem());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForSalesLineDropShipmentErr());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForEmptyPostingSetupAccount());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForTroubleshootingDimensions());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForAllowedVATDate());
        // [THEN] 'Blocked Gen./VAT Posting Setup' links exist
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForFinancePostingGroups());
        NamedForwardLink.Get(ForwardLinkMgt.GetHelpCodeForFinanceSetupVAT());

        // [THEN] none of fields (Name, Description, Link) are blank.
        NamedForwardLink.FilterGroup(-1);
        NamedForwardLink.SetRange(Name, '');
        NamedForwardLink.SetRange(Description, '');
        NamedForwardLink.SetRange(Link, '');
        Assert.RecordIsEmpty(NamedForwardLink);
    end;

    [Test]
    procedure T992_ExistingForwardLinkDoesNotGetOverriden()
    var
        NamedForwardLink: Record "Named Forward Link";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
    begin
        // [FEATURE] [UT] [Forward Link]
        Initialize();
        // [GIVEN] No Forward Links
        NamedForwardLink.DeleteAll();
        // [GIVEN] Action "A", where Description 'D', Link 'L'
        ForwardLinkMgt.AddLink('A', 'D', 'L');

        // [WHEN] Try to add action "A", where Description 'D2', Link 'L2'
        ForwardLinkMgt.AddLink('A', 'D2', 'L2');

        // [THEN]  Link "A", where Description 'D', Link 'L'
        NamedForwardLink.Get('A');
        NamedForwardLink.Testfield(Description, 'D');
        NamedForwardLink.Testfield(Link, 'L');
    end;

    [Test]
    procedure T993_PopContextTopElementId()
    var
        ErrorContextElement: array[3] of Codeunit "Error Context Element";
        ErrorMessageHandler: array[3] of Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        // [FEATURE] [UT] [PopContext]
        // [Scenario 395037] PopContext 
        Initialize();

        // [GIVEN] Initial activation with context '1'
        ErrorMessageMgt.Activate(ErrorMessageHandler[1]);
        Assert.AreEqual(1, ErrorMessageMgt.PushContext(ErrorContextElement[1], 4, 0, '1'), 'Push#1');

        // [GIVEN] Nested (skipped) activation with context '2'
        ErrorMessageMgt.Activate(ErrorMessageHandler[2]);
        Assert.AreEqual(2, ErrorMessageMgt.PushContext(ErrorContextElement[2], 4, 0, '2'), 'Push#2');

        // [GIVEN] Nested (skipped) activation with context '3'
        ErrorMessageMgt.Activate(ErrorMessageHandler[3]);
        Assert.AreEqual(3, ErrorMessageMgt.PushContext(ErrorContextElement[3], 4, 0, '3'), 'Push#3');

        // [WHEN] Invoke PopContext
        Assert.AreEqual(2, ErrorMessageMgt.PopContext(ErrorContextElement[3]), 'Pop#3');
        Assert.AreEqual(1, ErrorMessageMgt.PopContext(ErrorContextElement[2]), 'Pop#2');
        Assert.AreEqual(0, ErrorMessageMgt.PopContext(ErrorContextElement[1]), 'Pop#1');
    end;

    local procedure Initialize()
    var
        ErrorMessageRegister: Record "Error Message Register";
    begin
        ClearLastError();
        LibraryApplicationArea.EnableFoundationSetup();
        ErrorMessageRegister.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure ActivateAndShowErrors(var ErrorMessageHandler: Codeunit "Error Message Handler")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.LogError(700, 'ErrorB', '');
        ErrorMessageHandler.ShowErrors();
    end;

    local procedure AddFinishCall(var TempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.LogMessage(700, 0, TempErrorMessage."Message Type"::Information, '');
    end;

    local procedure AddHandledError(var TempErrorMessage: Record "Error Message" temporary; ErrorMessage: Text[250])
    begin
        TempErrorMessage.LogMessage(700, 0, TempErrorMessage."Message Type"::Warning, ErrorMessage);
    end;

    local procedure AddUnhandledError(var TempErrorMessage: Record "Error Message" temporary; ErrorMessage: Text[250])
    begin
        TempErrorMessage.LogMessage(700, 0, TempErrorMessage."Message Type"::Error, ErrorMessage);
    end;

    local procedure GetNotExistingTableNo() TableNo: Integer
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        repeat
            TableNo += 1;
        until not AllObjWithCaption.Get(AllObjWithCaption."Object Type", TableNo);
    end;

    local procedure LogSimpleMessage(var TempErrorMessage: Record "Error Message" temporary; RegID: guid; MessageType: Option; Descr: text)
    begin
        TempErrorMessage.LogSimpleMessage(MessageType, Descr);
        TempErrorMessage."Register ID" := RegID;
        if TempErrorMessage."Message Type" = TempErrorMessage."Message Type"::Error then
            if TempErrorMessage.GetErrorCallStack() = '' then
                TempErrorMessage.SetErrorCallStack(LibraryUtility.GenerateGUID());
        TempErrorMessage.Modify();
    end;

    local procedure PostWithHandledError(ErrorMessage: Text[250]): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
        PostingCodeunitMock: Codeunit "Posting Codeunit Mock";
    begin
        AddHandledError(TempErrorMessage, ErrorMessage);
        exit(PostingCodeunitMock.TryRun(TempErrorMessage));
    end;

    local procedure PushContext(var TempErrorMessage: Record "Error Message" temporary; AdditionalInfo: Text[250])
    var
        Int: Integer;
    begin
        Int := -1;
        TempErrorMessage.LogSimpleMessage(Int, AdditionalInfo);
    end;

    local procedure PopContext(var TempErrorMessage: Record "Error Message" temporary)
    var
        Int: Integer;
    begin
        Int := -3;
        TempErrorMessage.LogSimpleMessage(Int, '');
    end;

    local procedure PushLocalContext(ContextVariant: Variant; AddInfo: Text; ErrorMsg: Text[250]) ContextID: Integer
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        ContextID := ErrorMessageMgt.PushContext(ErrorContextElement, ContextVariant, 0, AddInfo);
        if ErrorMsg <> '' then
            ErrorMessageMgt.LogError(4, ErrorMsg, '');
    end;

    local procedure VerifyCountOfActiveSubscribers(ExpectedCount: Integer)
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.Get(CODEUNIT::"Error Message Handler", 'OnLogErrorHandler');
        EventSubscription.TestField("Active Manual Instances", ExpectedCount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesModalPageHandler(var ErrorMessagesPage: TestPage "Error Messages")
    var
        Counter: Integer;
    begin
        Counter := 0;
        if ErrorMessagesPage.First() then begin
            Counter := 1;
            if ErrorMessagesPage."Message Type".Value() = 'Error' then
                Assert.IsTrue(ErrorMessagesPage.CallStack.Value() <> '', 'Error Call Stack is empty.');
        end;
        while ErrorMessagesPage.Next() do begin
            Counter += 1;
            if ErrorMessagesPage."Message Type".Value() = 'Error' then
                Assert.IsTrue(ErrorMessagesPage.CallStack.Value() <> '', 'Error Call Stack is empty.');
        end;
        LibraryVariableStorage.Enqueue(Counter);
        LibraryVariableStorage.Enqueue(ErrorMessagesPage.Description.Value);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

