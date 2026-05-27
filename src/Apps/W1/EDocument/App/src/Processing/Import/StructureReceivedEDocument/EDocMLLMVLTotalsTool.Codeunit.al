// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6313 "E-Doc. MLLM VL Totals Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_invoice_totals');
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
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line_extension_amount values');
        PropsObj.Add('line_amounts', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_exclusive_amount from legal_monetary_total');
        PropsObj.Add('tax_exclusive_amount', PropObj);
        RequiredArr.Add('line_amounts'); RequiredArr.Add('tax_exclusive_amount');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that the sum of all line_extension_amounts matches tax_exclusive_amount within 1%.');
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
        LineAmountsToken: JsonToken;
        LineAmountsArray: JsonArray;
        LineToken: JsonToken;
        LineAmounts: List of [Decimal];
        TaxExclusiveAmount: Decimal;
        DecimalValue: Decimal;
        Token: JsonToken;
        Passed: Boolean;
    begin
        if Arguments.Get('line_amounts', LineAmountsToken) then begin
            LineAmountsArray := LineAmountsToken.AsArray();
            foreach LineToken in LineAmountsArray do
                if Evaluate(DecimalValue, LineToken.AsValue().AsText(), 9) then
                    LineAmounts.Add(DecimalValue);
        end;
        if Arguments.Get('tax_exclusive_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
                TaxExclusiveAmount := DecimalValue;
        Passed := VerifyTools.VerifyInvoiceTotals(LineAmounts, TaxExclusiveAmount, ErrorText);
        if ExtractionPlan.IsInitialized() then
            ExtractionPlan.MarkItem('verify_invoice_totals', Passed, ErrorText);
        if Passed then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
