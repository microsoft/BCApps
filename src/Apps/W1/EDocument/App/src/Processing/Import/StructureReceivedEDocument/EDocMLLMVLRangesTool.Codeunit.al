// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6317 "E-Doc. MLLM VL Ranges Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_ranges');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        ItemsObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line quantities');
        PropsObj.Add('quantities', PropObj); Clear(PropObj); Clear(ItemsObj);
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line unit prices');
        PropsObj.Add('prices', PropObj); Clear(PropObj); Clear(ItemsObj);
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line VAT rates (0-100)');
        PropsObj.Add('vat_rates', PropObj); Clear(PropObj); Clear(ItemsObj);
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line discount percentages (0-100)');
        PropsObj.Add('discount_pcts', PropObj);
        RequiredArr.Add('quantities'); RequiredArr.Add('prices'); RequiredArr.Add('vat_rates'); RequiredArr.Add('discount_pcts');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that quantities > 0, unit prices > 0, VAT rates 0-100, discount percentages 0-100 for all lines.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
        ResultObj: JsonObject;
        ErrorText: Text;
        ResultText: Text;
        Quantities: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscountPcts: List of [Decimal];
        Passed: Boolean;
    begin
        ParseDecimalArray(Arguments, 'quantities', Quantities);
        ParseDecimalArray(Arguments, 'prices', Prices);
        ParseDecimalArray(Arguments, 'vat_rates', VATRates);
        ParseDecimalArray(Arguments, 'discount_pcts', DiscountPcts);
        Passed := VerifyTools.VerifyRanges(Quantities, Prices, VATRates, DiscountPcts, ErrorText);
        if ExtractionPlan.IsInitialized() then
            ExtractionPlan.MarkItem('verify_ranges', Passed, ErrorText);
        if Passed then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure ParseDecimalArray(Arguments: JsonObject; PropertyName: Text; var Values: List of [Decimal])
    var
        ArrayToken: JsonToken;
        ItemToken: JsonToken;
        DecimalValue: Decimal;
    begin
        if not Arguments.Get(PropertyName, ArrayToken) then
            exit;
        foreach ItemToken in ArrayToken.AsArray() do
            if Evaluate(DecimalValue, ItemToken.AsValue().AsText(), 9) then
                Values.Add(DecimalValue);
    end;
}
