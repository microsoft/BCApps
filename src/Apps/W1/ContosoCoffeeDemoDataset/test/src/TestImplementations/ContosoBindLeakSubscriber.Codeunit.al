namespace Microsoft.Test.DemoTool;

using Microsoft.DemoTool;

codeunit 148143 "Contoso Bind Leak Subscriber"
{
    // Mimics a localization codeunit: it manually binds a subscription in OnBeforeGeneratingDemoData
    // and releases it in OnAfterGeneratingDemoData.
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        FailOnGenerate: Boolean;

    procedure SetFailOnGenerate(NewFailOnGenerate: Boolean)
    begin
        FailOnGenerate := NewFailOnGenerate;
    end;

    procedure GetFailOnGenerate(): Boolean
    begin
        exit(FailOnGenerate);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnBeforeGeneratingDemoData', '', false, false)]
    local procedure OnBeforeGeneratingDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    var
        ContosoBindLeakHelper: Codeunit "Contoso Bind Leak Helper";
    begin
        if Module <> Enum::"Contoso Demo Data Module"::"Contoso Bind Leak" then
            exit;

        BindSubscription(ContosoBindLeakHelper);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure OnAfterGeneratingDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    var
        ContosoBindLeakHelper: Codeunit "Contoso Bind Leak Helper";
    begin
        if Module <> Enum::"Contoso Demo Data Module"::"Contoso Bind Leak" then
            exit;

        UnbindSubscription(ContosoBindLeakHelper);
    end;
}
