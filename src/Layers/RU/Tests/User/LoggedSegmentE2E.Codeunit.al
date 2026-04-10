codeunit 135405 "Logged Segment E2E"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [Feature] [Logged Segment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteLogSegment()
    var
        SegmentHeader: Record "Segment Header";
        LoggedSegment: Record "Logged Segment";
        Campaign: Record Campaign;
        InteractionTemplate: Record "Interaction Template";
        DeleteLoggedSegments: Report "Delete Logged Segments";
    begin
        // [Scenario] Test permissions: User can delete canceled Logged Segments

        // [Given] Logged Segments are created and then canceled
        Initialize();

        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateSegment(SegmentHeader, Campaign."No.", InteractionTemplate.Code);
        RunLogSegment(SegmentHeader."No.", false);
        LoggedSegment.SetRange("Segment No.", SegmentHeader."No.");
        LoggedSegment.FindFirst();
        LoggedSegment.ToggleCanceledCheckmark();

        // [When] User tries to run the report that deletes the canceled logged segments 
        DeleteLoggedSegments.SetTableView(LoggedSegment);
        DeleteLoggedSegments.UseRequestPage(false);

        // [Then] No error occur
        ClearLastError();
        DeleteLoggedSegments.RunModal();

        Assert.AreEqual('', GetLastErrorText(), 'No error should have occurred when deleting canceled logged segments');

        // [Then] Canceled logged segments have been deleted
        LoggedSegment.SetRange("Segment No.", SegmentHeader."No.");
        LoggedSegment.SetRange(Canceled, true);

        Assert.IsFalse(LoggedSegment.FindFirst(), 'Canceled logged segments should have been deleted');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Logged Segment E2E");

        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Logged Segment E2E");

        LibrarySetupStorage.Save(Database::"Marketing Setup");
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Logged Segment E2E");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateSegment(var SegmentHeader: Record "Segment Header"; CampaignNo: Code[20]; InteractionTemplateCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // Create Campaign, Interaction Template, Segment Header and Segment Line with Contact No.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify(true);

        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        Contact.SetFilter("Salesperson Code", '<>''''');
        Contact.FindFirst();
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    local procedure RunLogSegment(SegmentNo: Code[20]; FollowUp: Boolean)
    var
        LogSegment: Report "Log Segment";
    begin
        LogSegment.SetSegmentNo(SegmentNo);
        LogSegment.InitializeRequest(false, FollowUp);
        LogSegment.UseRequestPage(false);
        LogSegment.RunModal();
    end;

}