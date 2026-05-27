// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6339 "E-Doc. MLLM VL Math Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_line_math');
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
        PropObj.Add('type', 'string');
        PropObj.Add('description', 'The id field of the invoice line being verified');
        PropsObj.Add('line_id', PropObj);
        Clear(PropObj);
        PropObj.Add('type', 'number');
        PropObj.Add('description', 'Gross unit price before discounts');
        PropsObj.Add('unit_price', PropObj);
        Clear(PropObj);
        PropObj.Add('type', 'number');
        PropObj.Add('description', 'Quantity of units');
        PropsObj.Add('quantity', PropObj);
        Clear(PropObj);
        PropObj.Add('type', 'number');
        PropObj.Add('description', 'Combined discount percentage 0-100 (use 0 if no discount)');
        PropsObj.Add('discount_pct', PropObj);
        Clear(PropObj);
        PropObj.Add('type', 'number');
        PropObj.Add('description', 'line_extension_amount from the invoice');
        PropsObj.Add('line_extension_amount', PropObj);
        RequiredArr.Add('line_id');
        RequiredArr.Add('unit_price');
        RequiredArr.Add('quantity');
        RequiredArr.Add('discount_pct');
        RequiredArr.Add('line_extension_amount');
        ParamsObj.Add('type', 'object');
        ParamsObj.Add('properties', PropsObj);
        ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that gross_unit_price × quantity × (1 − discount_pct/100) matches line_extension_amount within 1%. Call once per invoice line.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function');
        ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
        ResultObj: JsonObject;
        ErrorText, ResultText, LineId : Text;
        UnitPrice, Quantity, DiscountPct, LineExtAmt : Decimal;
        Token: JsonToken;
        Passed: Boolean;
    begin
        GetDecimalArg(Arguments, 'unit_price', UnitPrice);
        GetDecimalArg(Arguments, 'quantity', Quantity);
        GetDecimalArg(Arguments, 'discount_pct', DiscountPct);
        GetDecimalArg(Arguments, 'line_extension_amount', LineExtAmt);
        if Arguments.Get('line_id', Token) then
            LineId := Token.AsValue().AsText();

        Passed := VerifyTools.VerifyLineMath(UnitPrice, Quantity, DiscountPct, LineExtAmt, ErrorText);

        if ExtractionPlan.IsInitialized() then
            ExtractionPlan.MarkItem('verify_line_' + LineId, Passed, ErrorText);

        if Passed then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure GetDecimalArg(Arguments: JsonObject; PropertyName: Text; var Value: Decimal)
    var
        Token: JsonToken;
        DecimalValue: Decimal;
    begin
        if not Arguments.Get(PropertyName, Token) then
            exit;
        if Token.AsValue().IsNull() then
            exit;
        if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
            Value := DecimalValue;
    end;
}
