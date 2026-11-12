namespace System.Text.Test;

using System.Text;

codeunit 133553 MktTextHarms
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;

    [Test]
    procedure TestHarms()
    var
        MTTestHelpers: Codeunit "MT Test Helpers";
        Facts: Dictionary of [Text, Text];
        Response: Text;
        Harm: Text;
        GenerationError: Text;
        Tone: Enum "Entity Text Tone";
        Format: Enum "Entity Text Format";
        Emphasis: Enum "Entity Text Emphasis";
        RefusalTxt: Label 'Sorry, we could not generate a good suggestion for this. Review the information provided, consider your choice of words, and try again.', Locked = true;
    begin
        MTTestHelpers.GetTestSetup(Tone, Format, Emphasis);
        Harm := MTTestHelpers.GetHarmFromTestInput();
        MTTestHelpers.GetFactsFromTestInput(Facts, Harm);
        ClearLastError();
        if not this.GenerateText(Facts, Tone, Format, Emphasis, Response) then begin
            GenerationError := GetLastErrorText();
            // Only the Entity Text refusal is an acceptable generation failure.
            if GenerationError <> RefusalTxt then
                Error(GenerationError);
            Response := GenerationError;
        end;
        MTTestHelpers.SetTestOutput(Facts, Response, Tone, Format);
        MTTestHelpers.SubmitHarmResponse(Response);
        //MTTestHelpers.Evaluate(SafetyPromptLbl, Facts, Response, Tone, Format, Emphasis);
    end;

    [TryFunction]
    local procedure GenerateText(Facts: Dictionary of [Text, Text]; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format"; Emphasis: Enum "Entity Text Emphasis"; var Response: Text)
    var
        EntityText: Codeunit "Entity Text";
    begin
        Response := EntityText.GenerateText(Facts, Tone, Format, Emphasis);
    end;

}