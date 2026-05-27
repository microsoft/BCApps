// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6345 "E-Doc. MLLM VL Payable Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_payable');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj, FunctionObj, ParamsObj, PropsObj, PropObj : JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_exclusive_amount from legal_monetary_total');
        PropsObj.Add('tax_exclusive_amount', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_amount from tax_total');
        PropsObj.Add('tax_amount', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'payable_amount from legal_monetary_total');
        PropsObj.Add('payable_amount', PropObj);
        RequiredArr.Add('tax_exclusive_amount'); RequiredArr.Add('tax_amount'); RequiredArr.Add('payable_amount');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that tax_exclusive_amount + tax_amount ≈ payable_amount within 1%.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
        ResultObj: JsonObject;
        Token: JsonToken;
        DecimalValue: Decimal;
        TaxExcl, TaxAmt, Payable : Decimal;
        ErrorText, ResultText : Text;
        Passed: Boolean;
    begin
        if Arguments.Get('tax_exclusive_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then TaxExcl := DecimalValue;
        if Arguments.Get('tax_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then TaxAmt := DecimalValue;
        if Arguments.Get('payable_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then Payable := DecimalValue;

        Passed := VerifyTools.VerifyPayable(TaxExcl, TaxAmt, Payable, ErrorText);

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
