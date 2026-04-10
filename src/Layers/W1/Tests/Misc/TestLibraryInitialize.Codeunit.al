codeunit 132529 "Test Library Initialize"
{
    // // The codeunit is an example how Library - Test Initialize can be used

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test] [Library - Test Initialize]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        TestLibraryInitialize: Codeunit "Test Library Initialize";
        IsInitialized: Boolean;
        IsBinded: Boolean;
        TestInitializedTxt: Label 'TestInitialized';
        OnBeforeTestSuiteTxt: Label 'OnBeforeTestSuite';
        OnAfterTestSuiteTxt: Label 'OnAfterTestSuite';

    [Test]
    [Scope('OnPrem')]
    procedure InitializeTestSuite()
    begin
        // [SCENARIO] Test if Library Initialize EVents are raised
        // events: OnTestInitialize, OnBeforeTestSuiteInitialize, OnAfterTestSuiteInitialize

        // [GIVEN] Test CU
        // [WHEN] The first test is run
        Initialize();

        // [THEN] Initialize function is called for the first time, all three events are raised
        Assert.IsTrue(GetNameValue(TestInitializedTxt), 'OnTestInitialize event is not raised');
        Assert.IsTrue(GetNameValue(OnBeforeTestSuiteTxt), 'OnBeforeTestSuiteInitialize is not raised');
        Assert.IsTrue(GetNameValue(OnAfterTestSuiteTxt), 'OnAfterTestSuiteInitialize is not raised');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitializeTest()
    begin
        // [SCENARIO] Test if Library Initialize Event events: OnTestInitialize is raised

        // [GIVEN] Test CU
        // [WHEN] The second test is run
        Initialize();

        // [THEN] Initialize function is called for the first time, all three events are raised
        Assert.IsTrue(GetNameValue(TestInitializedTxt), 'TestInitialize event is not raised');
        Assert.IsFalse(GetNameValue(OnBeforeTestSuiteTxt), 'OnBeforeTestSuite is raised');
        Assert.IsFalse(GetNameValue(OnAfterTestSuiteTxt), 'OnAfterTestSuite is raised');
    end;

    local procedure Initialize()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        if not IsBinded then begin
            BindSubscription(TestLibraryInitialize);
            IsBinded := true;
        end;

        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Library Initialize");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Library Initialize");

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Library Initialize");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Test Initialize", 'OnTestInitialize', '', false, false)]
    local procedure TestInitializeSubscriber(CallerCodeunitID: Integer)
    begin
        if CallerCodeunitID = CODEUNIT::"Test Library Initialize" then
            InsertNameValue(TestInitializedTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Test Initialize", 'OnBeforeTestSuiteInitialize', '', false, false)]
    local procedure OnBeforeTestSuiteInitializeSubscriber(CallerCodeunitID: Integer)
    begin
        if CallerCodeunitID = CODEUNIT::"Test Library Initialize" then
            InsertNameValue(OnBeforeTestSuiteTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Test Initialize", 'OnAfterTestSuiteInitialize', '', false, false)]
    local procedure OnAfterTestSuiteInitializeEventSubscriber(var Sender: Codeunit "Library - Test Initialize"; CallerCodeunitID: Integer)
    begin
        if CallerCodeunitID = CODEUNIT::"Test Library Initialize" then
            InsertNameValue(OnAfterTestSuiteTxt);
    end;

    local procedure GetNameValue(EventName: Text[250]): Boolean
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetFilter(Name, EventName);
        exit(NameValueBuffer.FindFirst())
    end;

    local procedure InsertNameValue(EventName: Text[250])
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init();
        NameValueBuffer.Name := EventName;
        NameValueBuffer.Insert();
    end;
}

