codeunit 139005 "Test Experience Change"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Application Area]
    end;

    var
        Assert: Codeunit Assert;
        OnGetBasicExperienceAppAreasFired: Boolean;
        OnGetEssentialExperienceAppAreasFired: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestEventIsFiredWhenSelectingEssentialExperience()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        TestExperienceChange: Codeunit "Test Experience Change";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        // Before test
        BindSubscription(TestExperienceChange);
        TestExperienceChange.SetOnGetBasicExperienceAppAreasFired(false);
        TestExperienceChange.SetOnGetEssentialExperienceAppAreasFired(false);

        // [Given] No experince is selected
        ClearSelectedExperience();

        // [When] Select Essential Experience
        ApplicationAreaMgmt.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        // [Then] See OnGetEssentialExperienceAppAreasSubscriber and OnGetBasicExperienceAppAreasSubscriber
        Assert.IsTrue(TestExperienceChange.IsOnGetBasicExperienceAppAreasFired(), 'Event was not fired');
        Assert.IsTrue(TestExperienceChange.IsOnGetEssentialExperienceAppAreasFired(), 'Event was not fired');

        // After test
        UnbindSubscription(TestExperienceChange);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetEssentialExperienceAppAreas', '', false, false)]
    local procedure OnGetEssentialExperienceAppAreasSubscriber()
    begin
        SetOnGetEssentialExperienceAppAreasFired(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetBasicExperienceAppAreas', '', false, false)]
    local procedure OnGetBasicExperienceAppAreasSubscriber()
    begin
        SetOnGetBasicExperienceAppAreasFired(true);
    end;

    local procedure ClearSelectedExperience()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        if ExperienceTierSetup.Get(CompanyName) then
            ExperienceTierSetup.Init();
    end;

    [Scope('OnPrem')]
    procedure IsOnGetBasicExperienceAppAreasFired(): Boolean
    begin
        exit(OnGetBasicExperienceAppAreasFired);
    end;

    [Scope('OnPrem')]
    procedure SetOnGetBasicExperienceAppAreasFired(IsEventFired: Boolean)
    begin
        OnGetBasicExperienceAppAreasFired := IsEventFired;
    end;

    [Scope('OnPrem')]
    procedure IsOnGetEssentialExperienceAppAreasFired(): Boolean
    begin
        exit(OnGetEssentialExperienceAppAreasFired);
    end;

    [Scope('OnPrem')]
    procedure SetOnGetEssentialExperienceAppAreasFired(IsEventFired: Boolean)
    begin
        OnGetEssentialExperienceAppAreasFired := IsEventFired;
    end;
}

