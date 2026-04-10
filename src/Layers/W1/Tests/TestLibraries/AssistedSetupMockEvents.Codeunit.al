codeunit 132475 "Assisted Setup Mock Events"
{
    EventSubscriberInstance = Manual;
    Subtype = Normal;

    var
        FirstTestPageNameTxt: Label 'FIRST TEST Page';
        SecondTestPageNameTxt: Label 'SECOND TEST Page';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    [Normal]
    procedure HandleOnRegisterFirstExtensionAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        GuidedExperience.InsertAssistedSetup(FirstTestPageNameTxt, CopyStr(FirstTestPageNameTxt, 1, 50), '', 5,
            ObjectType::Page, Page::"Item List", AssistedSetupGroup::Uncategorized, '', VideoCategory::Uncategorized, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    [Normal]
    procedure HandleOnRegisterSecondExtensionAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        GuidedExperience.InsertAssistedSetup(SecondTestPageNameTxt, CopyStr(SecondTestPageNameTxt, 1, 50), '', 5,
            ObjectType::Page, Page::"Customer List", AssistedSetupGroup::Uncategorized, '', VideoCategory::Uncategorized, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnAfterRunAssistedSetup', '', false, false)]
    [Normal]
    procedure OnAfterRunAssistedSetup(ExtensionId: Guid; ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if (ObjectID <> PAGE::"Item List") or (ObjectType <> ObjectType::Page) then
            exit;

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, ObjectID);
    end;
}

