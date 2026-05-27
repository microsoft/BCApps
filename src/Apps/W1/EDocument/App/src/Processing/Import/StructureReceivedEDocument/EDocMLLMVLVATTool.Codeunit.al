// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6314 "E-Doc. MLLM VL VAT Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_vat');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_exclusive_amount');
        PropsObj.Add('tax_exclusive_amount', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'VAT rate percentage 0-100');
        PropsObj.Add('vat_rate', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_amount');
        PropsObj.Add('tax_amount', PropObj);
        RequiredArr.Add('tax_exclusive_amount'); RequiredArr.Add('vat_rate'); RequiredArr.Add('tax_amount');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that tax_exclusive_amount × vat_rate/100 ≈ tax_amount within 1%.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        ResultText: Text;
        TaxExcl: Decimal;
        VATRate: Decimal;
        TaxAmt: Decimal;
        Token: JsonToken;
        DecimalValue: Decimal;
        Passed: Boolean;
    begin
        if Arguments.Get('tax_exclusive_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then TaxExcl := DecimalValue;
        if Arguments.Get('vat_rate', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then VATRate := DecimalValue;
        if Arguments.Get('tax_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then TaxAmt := DecimalValue;
        Passed := VerifyTools.VerifyVAT(TaxExcl, VATRate, TaxAmt, ErrorText);
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
