namespace Microsoft.Test.DemoTool;

using Microsoft.DemoTool;

codeunit 148141 "DemoTool Binding Test"
{
    Subtype = Test;

    [Test]
    procedure BoundCodeunitsAreReleasedWhenGenerationFails()
    var
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
        ContosoBindLeakSubscriber: Codeunit "Contoso Bind Leak Subscriber";
    begin
        // [SCENARIO 641669] A failure during demo data generation must not leave manually bound codeunits bound,
        // otherwise the next generation attempt fails with "The binding of codeunit ... has already been bound."
        ContosoDemoTool.RefreshModules();

        // [GIVEN] A localization-like subscriber that binds a codeunit in OnBeforeGeneratingDemoData and unbinds it in OnAfterGeneratingDemoData
        BindSubscription(ContosoBindLeakSubscriber);

        // [GIVEN] The module fails while its demo data is being generated
        ContosoBindLeakSubscriber.SetFailOnGenerate(true);

        // [WHEN] Generating demo data for the module fails
        ContosoDemoDataModule.SetRange(Module, Enum::"Contoso Demo Data Module"::"Contoso Bind Leak");
        asserterror ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");

        // [THEN] Retrying generation succeeds instead of failing with a binding error, because the bound codeunit was released
        ContosoBindLeakSubscriber.SetFailOnGenerate(false);
        ContosoDemoDataModule.SetRange(Module, Enum::"Contoso Demo Data Module"::"Contoso Bind Leak");
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");

        UnbindSubscription(ContosoBindLeakSubscriber);
    end;
}
