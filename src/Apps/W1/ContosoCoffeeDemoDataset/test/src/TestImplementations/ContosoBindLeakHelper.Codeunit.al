namespace Microsoft.Test.DemoTool;

using Microsoft.DemoTool;

codeunit 148142 "Contoso Bind Leak Helper"
{
    // Manually bindable codeunit used to reproduce the demo data binding leak.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure OnAfterGeneratingDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    begin
    end;
}
