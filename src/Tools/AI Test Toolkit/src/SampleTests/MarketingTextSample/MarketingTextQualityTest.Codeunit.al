codeunit 149033 "Marketing Text Quality Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AITestContext: Codeunit "AIT Test Context";
        Context: Text;
        Question: Text;
        Format: Enum "Entity Text Format";
        Tone: Enum "Entity Text Tone";

    [Test] // Test No. 0
    procedure CheckLengthOfMarketingText()
    var
        TestSetup: Codeunit "Test Input Json";
        Answer: Text;
        Facts: Dictionary of [Text, Text];
    begin
        // [Scenario] Test check the maximum length of the marketing text
        // [GIVEN] Item with attributes
        // Sample from the dataset:
        // {"test_setup": {"Product Name":"ATHENS Mobile Pedestal","Color":"Black","Depth":"75 CM","Height":"90 CM","Material Description":"Wood","Model Year":"1942","Category":"Assorted Tables"}}
        TestSetup := AITestContext.GetTestSetupAsJson();
        Format := Enum::"Entity Text Format"::TaglineParagraph;
        Tone := Enum::"Entity Text Tone"::Inspiring;
        Facts := ItemJsonPropertiesToDictionary(TestSetup);

        // [WHEN] Generate marketing text with inspiring tone
        Answer := GenerateMarketingText(Facts, Tone, Format);

        // [THEN] Assert that the length of the marketing text is less than or equal to 1000 characters
        if StrLen(Answer) > 1000 then
            Error('The length of the marketing text is greater than 1000 characters. Actual length: %1', StrLen(Answer));
    end;

    [Test] // Test No. 1
    procedure TaglineParagraphInspiring()
    var
        TestSetup: Codeunit "Test Input Json";
        Answer: Text;
        ContextTemplateLbl: Label 'Here are some facts about the item: %1', Comment = '%1 = Item Attributes';
        QuestionTemplateLbl: Label 'Create %1 marketing text for an item with %2 for %3', Comment = '%1 = Format, %2 = Tone, %3 = Item Attributes';
        Facts: Dictionary of [Text, Text];
    begin
        // [Scenario] Test for the TaglineParagraph format with inspiring tone
        // [GIVEN] Item with attributes
        // Sample from the dataset:
        // {"test_setup": {"Product Name":"ATHENS Mobile Pedestal","Color":"Black","Depth":"75 CM","Height":"90 CM","Material Description":"Wood","Model Year":"1942","Category":"Assorted Tables"}}
        TestSetup := AITestContext.GetTestSetupAsJson();
        Format := Enum::"Entity Text Format"::TaglineParagraph;
        Tone := Enum::"Entity Text Tone"::Inspiring;
        Facts := ItemJsonPropertiesToDictionary(TestSetup);

        // [WHEN] Generate marketing text with inspiring tone
        Answer := GenerateMarketingText(Facts, Tone, Format);

        // [THEN] Test output is stored based on the context, question and answer
        Context := StrSubstNo(ContextTemplateLbl, GetFactsAsText(Facts)); // Here are some facts about the item: %1
        Question := StrSubstNo(QuestionTemplateLbl, Format, Tone, GetFactsAsText(Facts)); // Create %1 marketing text for an item with %2 for %3
        AITestContext.SetTestOutput(Context, Question, Answer);
    end;

    [Test] // Test No. 2
    procedure TaglineParagraphFormal()
    var
        TestSetup: Codeunit "Test Input Json";
        Answer: Text;
        ContextTemplateLbl: Label 'Here are some facts about the item: %1', Comment = '%1 = Item Attributes';
        Facts: Dictionary of [Text, Text];
        QuestionTemplateLbl: Label 'Create %1 marketing text for an item with %2 for %3', Comment = '%1 = Format, %2 = Tone, %3 = Item Attributes';
    begin
        // [Scenario] Test for the TaglineParagraph format with formal tone
        // [GIVEN] Item with attributes
        TestSetup := AITestContext.GetTestSetupAsJson();
        Format := Enum::"Entity Text Format"::TaglineParagraph;
        Tone := Enum::"Entity Text Tone"::Formal;
        Facts := ItemJsonPropertiesToDictionary(TestSetup);

        // [WHEN] Generate marketing text with formal tone
        Answer := GenerateMarketingText(Facts, Tone, Format);

        // [THEN] Test output is stored based on the context, question and answer
        Context := StrSubstNo(ContextTemplateLbl, GetFactsAsText(Facts));
        Question := StrSubstNo(QuestionTemplateLbl, Format, Tone, GetFactsAsText(Facts));
        AITestContext.SetTestOutput(Context, Question, Answer);
    end;

    local procedure ItemJsonPropertiesToDictionary(TestSetup: Codeunit "Test Input Json"): Dictionary of [Text, Text];
    var
        Attributes: Dictionary of [Text, Text];
        InputJson: JsonObject;
        AttributeValueToken: JsonToken;
        AttributeKey: Text;
        Input: Text;
    begin
        TestSetup.ValueAsJsonObject().WriteTo(Input);
        InputJson.ReadFrom(Input);

        foreach AttributeKey in InputJson.Keys() do begin
            InputJson.Get(AttributeKey, AttributeValueToken);
            Attributes.Add(AttributeKey, AttributeValueToken.AsValue().AsText());
        end;
        exit(Attributes);
    end;

    local procedure GetFactsAsText(var Facts: Dictionary of [Text, Text]): Text
    var
        FactTemplateTxt: Label '- %1: %2%3', Locked = true;
        FactKey: Text;
        FactValue: Text;
        FactsList: Text;
        NewLineChar: Char;
        MaxFacts: Integer;
        TotalFacts: Integer;
        MaxFactLength: Integer;
    begin
        NewLineChar := 10;
        TotalFacts := Facts.Count();

        MaxFacts := 20;
        MaxFactLength := 250;

        TotalFacts := 0;
        foreach FactKey in Facts.Keys() do begin
            if TotalFacts < MaxFacts then begin
                Facts.Get(FactKey, FactValue);
                FactKey := FactKey.Replace(NewLineChar, '').Trim();
                FactValue := FactValue.Replace(NewLineChar, '').Trim();
                FactsList += StrSubstNo(FactTemplateTxt, CopyStr(FactKey, 1, MaxFactLength), CopyStr(FactValue, 1, MaxFactLength), NewLineChar);
            end;
            TotalFacts += 1;
        end;
        exit(FactsList);
    end;

    local procedure GenerateMarketingText(Facts: Dictionary of [Text, Text]; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format"): Text
    begin
        // Mocked Responses, replace this with actual logic to generate marketing text based on facts, tone, and format
        case Facts.Get('Product Name') of
            'ATHENS Mobile Pedestal':
                exit('ATHENS Mobile Pedestal: Stands tall in black, making storage chic!<br /><br />Introducing the ATHENS Mobile Pedestal, a perfect blend of style and functionality. This mobile pedestal, draped in a sleek black color, makes a bold statement in any space. Its imposing height of 90 CM and depth of 75 CM ensures ample storage without compromising on style. Crafted from the finest wood, this pedestal is not only durable but also exudes a timeless charm. Its vintage model year of 1942 narrates a tale of excellence and craftsmanship that has stood the test of time. This versatile piece belongs to our ''Assorted Tables'' category and showcases the perfect balance between aesthetics and practicality. With the ATHENS Mobile Pedestal, you''re not just buying a piece of furniture; you''re investing in a legacy of superior quality and design. Elevate your space with this black beauty and experience the blend of style, storage, and sophistication!');
            'Whole Roasted Beans, Colombia':
                exit('Whole Roasted Beans, Colombia - Light on weight, heavy on taste!<br /><br />Introducing our Whole Roasted Beans from Colombia, a product that is as light as a feather but packs a punch when it comes to taste. Weighing in at just 1 KG, these beans have been lightly roasted to perfection, preserving the full-bodied flavor and aroma that Colombian beans are renowned for. Whether you''re a coffee connoisseur or a casual drinker, our Whole Roasted Beans offer an unforgettable brewing experience. Sourced from the lush landscapes of Colombia, each bean carries the rich heritage of its land, promising an authentic coffee experience. The light roast gives it a smooth, subtle flavor that is sure to delight your palate. Brew it your way - French press, drip, pour-over, or espresso, and savor the smooth, rich flavor of our Whole Roasted Beans. Light on weight, heavy on taste - our Whole Roasted Beans are your ticket to a perfect coffee moment any time of the day.');
            'MUNICH Swivel Chair, yellow':
                exit('Introducing the MUNICH Swivel Chair in vibrant yellow, a perfect addition to any office space. <br /><br />- It''s luxuriously designed with a depth of 70 CM, a height of 110 CM, and a width of 90 CM, ensuring optimal comfort and fit for your workspace. <br />- The bold yellow color adds a pop of color and energy to your office. <br />- Crafted with high-quality material, it promises durability and longevity. <br /><br />Upgrade your office with the MUNICH Swivel Chair, where style meets comfort!');
        end;
    end;

    local procedure Assert(Expected: Integer; Actual: Integer; Message: Text)
    var
        ErrMsg: Label 'Expected %1 but got %2. \%3', Comment = '%1 = Expected, %2 = Actual, %3 = Message', Locked = true;
    begin
        if Actual <> Expected then
            Error(ErrMsg, Expected, Actual, Message);
    end;
}