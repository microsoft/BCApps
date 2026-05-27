// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6316 "E-Doc. MLLM VL Required Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_required_fields');
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
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Supplier/vendor company name');
        PropsObj.Add('vendor_name', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Invoice number / id');
        PropsObj.Add('invoice_no', PropObj); Clear(PropObj);
        PropObj.Add('type', 'integer'); PropObj.Add('description', 'Number of invoice lines extracted');
        PropsObj.Add('line_count', PropObj);
        RequiredArr.Add('vendor_name'); RequiredArr.Add('invoice_no'); RequiredArr.Add('line_count');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that vendor name, invoice number, and at least one invoice line are present.');
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
        VendorName: Text;
        InvoiceNo: Text;
        LineCount: Integer;
        Token: JsonToken;
        DecimalValue: Decimal;
    begin
        if Arguments.Get('vendor_name', Token) then VendorName := Token.AsValue().AsText();
        if Arguments.Get('invoice_no', Token) then InvoiceNo := Token.AsValue().AsText();
        if Arguments.Get('line_count', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
                LineCount := Round(DecimalValue, 1);
        if VerifyTools.VerifyRequiredFields(VendorName, InvoiceNo, LineCount, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
