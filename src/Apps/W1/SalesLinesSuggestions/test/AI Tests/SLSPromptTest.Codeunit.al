namespace Microsoft.Sales.Document.Test;

using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 133516 "SLS Prompt Test"
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        TestUtility: Codeunit "SLS Test Utility";
        IsInitialized: Boolean;
        JsonPropValueErr: Label '"%1" property is incorrect', Comment = '%1 = Json property name';
        JsonPropIsMissingErr: Label 'Expected data is missing. Expected Json property and value: "%1": %2', Comment = '%1 = Json property name, %2 = Json property value';

    [Test]
    procedure TestSLSCopilotResponse()
    var
        AITestContext: Codeunit "AIT Test Context";
        ExpectedItemProps: Codeunit "Test Input Json";
        ExpectedDocProps: Codeunit "Test Input Json";
        TestUtil: Codeunit "SLS Test Utility";
        CallCompletionAnswerTxt: Text;
        ExpectedSearchItemExists: Boolean;
        ExpectedResultsExist: Boolean;
    begin
        Initialize();

        // [GIVEN] A question from the dataset and expected properties
        ExpectedItemProps := AITestContext.GetInput().Element('Expected').ElementExists('search_item', ExpectedSearchItemExists);
        ExpectedDocProps := AITestContext.GetInput().Element('Expected').ElementExists('results', ExpectedResultsExist);

        // [WHEN] Sales lines are suggested
        TestUtil.RepeatAtMost3TimesToFetchCompletion(CallCompletionAnswerTxt, AITestContext.GetQuery().ValueAsText());

        // [THEN] Copilot response is based on the expected properties
        AITestContext.SetTestOutput(CallCompletionAnswerTxt); // Log the response

        if ExpectedSearchItemExists then
            CheckSearchItemJSONContent(CallCompletionAnswerTxt, ExpectedItemProps, AITestContext.GetQuery().ValueAsText());

        if ExpectedResultsExist then
            CheckDocumentLookupJSONContent(CallCompletionAnswerTxt, ExpectedDocProps);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        TestUtility.RegisterCopilotCapability();

        IsInitialized := true;
    end;

    local procedure CheckSearchItemJSONContent(CompletionAnswerTxt: Text; ExpectedItemProps: Codeunit "Test Input Json"; CustomerRequest: Text)
    var
        Utility: Codeunit "SLS Test Utility";
        Function: JsonToken;
        FunctionArgument: JsonToken;
        FunctionArgumentObject: JsonObject;
        ItemResults: JsonToken;
        ItemResultsArray: JsonArray;
        Evaluation: JsonObject;
        EvaluationToken: JsonToken;
        EvaluationPassed: Boolean;
        EvaluationReason: Text;
    begin
        Function := Utility.GetFunctionToken(CompletionAnswerTxt);

        AssertFunctionName(Function, 'search_items_with_filters');

        Function.AsObject().Get('arguments', FunctionArgument);
        FunctionArgumentObject.ReadFrom(FunctionArgument.AsValue().AsText());

        if FunctionArgumentObject.Get('search_items', ItemResults) then begin
            ItemResultsArray := ItemResults.AsArray();
            Assert.AreEqual(ExpectedItemProps.GetElementCount(), ItemResultsArray.Count(), '"search_items" count is not correct');
        end
        else begin
            Assert.IsTrue(ExpectedItemProps.GetElementCount() = 0, '"search_items" should be empty');
            exit;
        end;

        AssertSearchItemSchema(ItemResultsArray);
        if ItemResultsArray.Count() = 0 then
            exit;

        Evaluation := Utility.EvaluateItemExtraction(CustomerRequest, ExpectedItemProps.AsJsonToken().AsArray(), ItemResultsArray);
        Utility.LogExtractionEvaluation(CustomerRequest, CompletionAnswerTxt, Evaluation);
        Evaluation.Get('passed', EvaluationToken);
        EvaluationPassed := EvaluationToken.AsValue().AsBoolean();
        Evaluation.Get('reason', EvaluationToken);
        EvaluationReason := EvaluationToken.AsValue().AsText();
        Assert.IsTrue(EvaluationPassed, 'Extracted item meaning is incorrect: ' + EvaluationReason);
        Evaluation.Get('item_mapping', EvaluationToken);
        AssertSearchItemContracts(ExpectedItemProps.AsJsonToken().AsArray(), ItemResultsArray, EvaluationToken.AsArray());
    end;

    internal procedure AssertSearchItemContracts(ExpectedItems: JsonArray; ActualItems: JsonArray; ItemMapping: JsonArray)
    var
        ExpectedItemProps: Codeunit "Test Input Json";
        ActualItem: JsonToken;
        ExpectedItem: JsonToken;
        MappingToken: JsonToken;
        UsedIndices: List of [Integer];
        ActualIndex: Integer;
        i: Integer;
    begin
        Assert.AreEqual(ExpectedItems.Count(), ActualItems.Count(), '"search_items" count is not correct');
        AssertSearchItemSchema(ActualItems);
        Assert.AreEqual(ExpectedItems.Count(), ItemMapping.Count(), 'Semantic evaluator item mapping is incomplete.');
        ExpectedItemProps.Initialize(ExpectedItems.AsToken());
        for i := 0 to ExpectedItems.Count() - 1 do begin
            ItemMapping.Get(i, MappingToken);
            ActualIndex := MappingToken.AsValue().AsInteger();
            Assert.IsTrue((ActualIndex >= 0) and (ActualIndex < ActualItems.Count()), 'Semantic evaluator item mapping is out of range.');
            Assert.IsFalse(UsedIndices.Contains(ActualIndex), 'Semantic evaluator returned a duplicate item mapping.');
            UsedIndices.Add(ActualIndex);
            ActualItems.Get(ActualIndex, ActualItem);
            ExpectedItems.Get(i, ExpectedItem);

            ValidateJsonPropertyInArray(ExpectedItemProps, i, ActualItem, 'origin_name');
            ValidateJsonPropertyInArray(ExpectedItemProps, i, ActualItem, 'quantity');
            ValidateJsonPropertyInArray(ExpectedItemProps, i, ActualItem, 'unit_of_measure');
            AssertItemIdentifier(ExpectedItem.AsObject(), ActualItem.AsObject());
        end;
    end;

    local procedure AssertSearchItemSchema(ActualItems: JsonArray)
    var
        Item: JsonToken;
        Value: JsonToken;
        Term: JsonToken;
        PropertyName: Text;
        ArrayProperties: List of [Text];
        ValueText: Text;
        ArrayPropertyErr: Label '%1 must be an array.', Comment = '%1 = Json property name';
    begin
        ArrayProperties.Add('split_name_terms');
        ArrayProperties.Add('features');
        ArrayProperties.Add('common_synonyms_of_name_terms');
        foreach Item in ActualItems do begin
            Assert.IsTrue(Item.AsObject().Get('name', Value), 'Search item name is missing.');
            AssertJsonText(Value);
            Assert.AreNotEqual('', Value.AsValue().AsText(), 'Search item name is empty.');
            Assert.IsTrue(Item.AsObject().Get('quantity', Value), 'Search item quantity is missing.');
            Value.WriteTo(ValueText);
            Assert.IsTrue(Value.IsValue() and (ValueText[1] in ['-', '0' .. '9']), 'Search item quantity must be numeric.');
            if Item.AsObject().Get('origin_name', Value) then
                AssertJsonText(Value);
            if Item.AsObject().Get('unit_of_measure', Value) then
                AssertJsonText(Value);
            Assert.IsTrue(Item.AsObject().Get('split_name_terms', Value), 'Search item name terms are missing.');
            Assert.IsTrue(Value.IsArray(), 'Search item name terms must be an array.');
            Assert.IsTrue(Value.AsArray().Count() > 0, 'Search item name terms are empty.');
            foreach PropertyName in ArrayProperties do
                if Item.AsObject().Get(PropertyName, Value) then begin
                    Assert.IsTrue(Value.IsArray(), StrSubstNo(ArrayPropertyErr, PropertyName));
                    foreach Term in Value.AsArray() do
                        AssertJsonText(Term);
                end;
        end;
    end;

    local procedure AssertJsonText(Value: JsonToken)
    var
        ValueText: Text;
    begin
        Value.WriteTo(ValueText);
        Assert.IsTrue(ValueText.StartsWith('"'), 'Search item text properties must contain strings.');
    end;

    local procedure AssertItemIdentifier(ExpectedItem: JsonObject; ActualItem: JsonObject)
    var
        NameTerms: JsonToken;
        Identifier: JsonToken;
        ActualName: JsonToken;
        IdentifierText: Text;
    begin
        if not ExpectedItem.Get('split_name_terms', NameTerms) then
            exit;
        if NameTerms.AsArray().Count() <> 1 then
            exit;
        NameTerms.AsArray().Get(0, Identifier);
        IdentifierText := Identifier.AsValue().AsText();
        if (IdentifierText = '') or (DelChr(IdentifierText, '=', '0123456789') <> '') then
            exit;

        ActualItem.Get('split_name_terms', NameTerms);
        Assert.AreEqual(1, NameTerms.AsArray().Count(), 'Item identifier must remain a single search term.');
        NameTerms.AsArray().Get(0, ActualName);
        Assert.AreEqual(IdentifierText, ActualName.AsValue().AsText(), 'Item identifier is incorrect.');
    end;

    local procedure CheckDocumentLookupJSONContent(CompletionAnswerTxt: Text; ExpectedDocProps: Codeunit "Test Input Json")
    var
        Utility: Codeunit "SLS Test Utility";
        Function: JsonToken;
        FunctionArgument: JsonToken;
        FunctionArgumentObject: JsonObject;
        ResultsTok: JsonToken;
        ResultsArray: JsonArray;
        JsonItem: JsonToken;
        i: Integer;
    begin
        Function := Utility.GetFunctionToken(CompletionAnswerTxt);

        AssertFunctionName(Function, 'search_items_with_filters');

        Function.AsObject().Get('arguments', FunctionArgument);
        FunctionArgumentObject.ReadFrom(FunctionArgument.AsValue().AsText());

        if FunctionArgumentObject.Get('results', ResultsTok) then begin
            ResultsArray := ResultsTok.AsArray();
            Assert.AreEqual(ExpectedDocProps.GetElementCount(), ResultsArray.Count(), 'ResultsArray count is not correct');
        end
        else begin
            Assert.IsTrue(ExpectedDocProps.GetElementCount() = 0, '"results" should be empty');
            exit;
        end;

        for i := 0 to ExpectedDocProps.GetElementCount() - 1 do begin // Considering the order of the elements in the response is same as the order in the expected element properties
            ResultsArray.Get(i, JsonItem); // No need to check if the index is valid as the count is already checked

            // Check expected properties only
            ValidateJsonPropertyInArray(ExpectedDocProps, i, JsonItem, 'document_type');
            ValidateJsonPropertyInArray(ExpectedDocProps, i, JsonItem, 'document_number');
            ValidateJsonPropertyInArray(ExpectedDocProps, i, JsonItem, 'start_date');
            ValidateJsonPropertyInArray(ExpectedDocProps, i, JsonItem, 'end_date');
        end;
    end;

    local procedure ValidateJsonPropertyInArray(ExpectedPropsArray: Codeunit "Test Input Json"; Index: Integer; ActualJsonToken: JsonToken; PropertyName: Text)
    var
        ExpectedElement: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        ExpectedElement := ExpectedPropsArray.ElementAt(Index).ElementExists(PropertyName, ElementExists);
        if ElementExists then
            ValidateJsonProperty(ExpectedElement, ActualJsonToken, PropertyName);
    end;

    local procedure ValidateJsonProperty(ExpectedElement: Codeunit "Test Input Json"; ActualJsonToken: JsonToken; PropertyName: Text);
    var
        IsPropertyFound: Boolean;
        ActualToken: JsonToken;
    begin
        IsPropertyFound := ActualJsonToken.AsObject().Get(PropertyName, ActualToken);
        case PropertyName of
            'origin_name', 'unit_of_measure', 'document_type', 'document_number':
                if IsPropertyFound then
                    Assert.AreEqual(ExpectedElement.ValueAsText().ToLower(), ActualToken.AsValue().AsText().ToLower(), StrSubstNo(JsonPropValueErr, PropertyName))
                else
                    Assert.AreEqual('', ExpectedElement.ValueAsText(), StrSubstNo(JsonPropIsMissingErr, PropertyName, '"' + ExpectedElement.ValueAsText() + '"'));

            'quantity':
                if IsPropertyFound then
                    Assert.AreEqual(ExpectedElement.ValueAsDecimal(), ActualToken.AsValue().AsDecimal(), StrSubstNo(JsonPropValueErr, PropertyName))
                else
                    Assert.AreEqual(0, ExpectedElement.ValueAsDecimal(), StrSubstNo(JsonPropIsMissingErr, PropertyName, ExpectedElement.ValueAsDecimal()));

            'start_date', 'end_date':
                if IsPropertyFound then
                    Assert.AreEqual(GetDateFromText(ExpectedElement.ValueAsText()), ActualToken.AsValue().AsText(), StrSubstNo(JsonPropValueErr, PropertyName))
                else
                    Assert.AreEqual('', GetDateFromText(ExpectedElement.ValueAsText()), StrSubstNo(JsonPropIsMissingErr, PropertyName, '"' + ExpectedElement.ValueAsText() + '"'));
        end;
    end;

    local procedure AssertFunctionName(FunctionToken: JsonToken; ExpectedName: Text)
    var
        FunctionName: JsonToken;
    begin
        FunctionToken.AsObject().Get('name', FunctionName);
        Assert.AreEqual(ExpectedName, FunctionName.AsValue().AsText(), 'Function name is incorrect.');
    end;

    local procedure GetDateFromText(DateDescription: Text) Result: Text
    begin
        case DateDescription of
            'LAST_YEAR':
                Result := Format(Format(CalcDate('<CY-1Y>', Today()), 0, '<year4>-<month,2>-<day,2>'));
            'START_LAST_YEAR':
                Result := Format(Format(CalcDate('<-CY-1Y>', Today()), 0, '<year4>-<month,2>-<day,2>'));
            'LAST_WEEK':
                Result := FORMAT(Today() - 7, 0, '<Year4>-<Month,2>-<Day,2>');
            'YESTERDAY':
                Result := FORMAT(Today() - 1, 0, '<Year4>-<Month,2>-<Day,2>');
            'TODAY':
                Result := FORMAT(Today(), 0, '<Year4>-<Month,2>-<Day,2>');
            'LAST_FEB_01':
                if (System.Date2DMY(Today(), 2) < 3) then
                    Result := Format(System.Date2DMY(Today(), 3) - 1) + '-02-01'
                else
                    Result := Format(System.Date2DMY(Today(), 3)) + '-02-01';
            'LAST_CHRISTMAS':
                Result := Format(System.Date2DMY(Today(), 3) - 1) + '-12-25';
            'BEFORE_LAST_CHRISTMAS':
                Result := Format(System.Date2DMY(Today(), 3) - 1) + '-12-24'
            else
                Result := DateDescription;
        end;
    end;
}
