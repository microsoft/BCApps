namespace System.Text.Test;

using System.Text;

codeunit 133551 MktTextAccuracy
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;

    [Test]
    procedure TestAccuracy()
    var
        EntityText: Codeunit "Entity Text";
        MTTestHelpers: Codeunit "MT Test Helpers";
        Facts: Dictionary of [Text, Text];
        Response: Text;
        Tone: Enum "Entity Text Tone";
        Format: Enum "Entity Text Format";
        Emphasis: Enum "Entity Text Emphasis";
    begin
        MTTestHelpers.GetTestSetup(Tone, Format, Emphasis);
        MTTestHelpers.GetFactsFromTestInput(Facts, '');
        Response := EntityText.GenerateText(Facts, Tone, Format, Emphasis);
        MTTestHelpers.SetTestOutput(Facts, Response, Tone, Format);

        MTTestHelpers.Evaluate(this.GroundednessAccuracyPromptLbl, Facts, Response, Tone, Format, Emphasis);
        MTTestHelpers.Evaluate(this.FluencyPromptLbl, Facts, Response, Tone, Format, Emphasis);
    end;

    var
        GroundednessAccuracyPromptLbl: Label 'evaluation_prompts/groundedness_and_accuracy.prompty', Locked = true;
        FluencyPromptLbl: Label 'evaluation_prompts/fluency.prompty', Locked = true;

}