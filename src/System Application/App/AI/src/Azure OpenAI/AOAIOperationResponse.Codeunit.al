// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

/// <summary>
/// The status and result of an operation.
/// </summary>
codeunit 7770 "AOAI Operation Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StatusCode: Integer;
        Success: Boolean;
        Result: Text;
        Error: Text;
        FunctionCallSuccess: Boolean;
        FunctionCallingName: Text;
        FunctionResult: Variant;
        FunctionError: Text;
        FunctionErrorCallStack: Text;

    /// <summary>
    /// Check whether the operation was successful.
    /// </summary>
    /// <returns>True if the operation was successful.</returns>
    procedure IsSuccess(): Boolean
    begin
        exit(Success);
    end;

    /// <summary>
    /// Get the status code of the operation.
    /// </summary>
    /// <returns>The status code of the operation.</returns>
    procedure GetStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Get the result of the operation.
    /// </summary>
    /// <returns>The result of the operation.</returns>
    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    /// <summary>
    /// Get the error text of the operation.
    /// </summary>
    /// <returns>The error text of the operation.</returns>
    procedure GetError(): Text
    begin
        exit(Error);
    end;

    /// <summary>
    /// Get whether the operation was a function call.
    /// </summary>
    /// <returns>True if it was a function call, false otherwise.</returns>
    procedure IsFunctionCall(): Boolean
    begin
        exit(FunctionCallingName <> '');
    end;

    /// <summary>
    /// Get whether the function call was successful.
    /// </summary>
    /// <returns>True if the call was successful, false otherwise.</returns>
    procedure IsFunctionCallSuccess(): Boolean
    begin
        exit(FunctionCallSuccess);
    end;

    /// <summary>
    /// Get the name of the function that was called.
    /// </summary>
    /// <returns>The name of the function that was called.</returns>
    procedure GetFunctionName(): Text
    begin
        exit(FunctionCallingName);
    end;

    /// <summary>
    /// Get the return value of the function that was called.
    /// </summary>
    /// <returns>The return value from the function</returns>
    procedure GetFunctionResult(): Variant
    begin
        exit(FunctionResult);
    end;

    /// <summary>
    /// Get the error message from the function that was called.
    /// </summary>
    /// <returns>The error message from the function.</returns>
    procedure GetFunctionError(): Text
    begin
        exit(FunctionError);
    end;

    /// <summary>
    /// Get the error call stack from the function that was called.
    /// </summary>
    /// <returns>The error call stack from the function.</returns>
    procedure GetFunctionErrorCallStack(): Text
    begin
        exit(FunctionErrorCallStack);
    end;

    internal procedure SetOperationResponse(var ALCopilotOperationResponse: DotNet ALCopilotOperationResponse)
    begin
        Success := ALCopilotOperationResponse.IsSuccess();
        StatusCode := ALCopilotOperationResponse.StatusCode;
        Result := ALCopilotOperationResponse.Result();
        Error := ALCopilotOperationResponse.ErrorText();

        if Error = '' then
            Error := GetLastErrorText();
    end;

    internal procedure SetFunctionCallingResponse(NewFunctionCallSuccess: Boolean; NewFunctionCalled: Text; NewFunctionError: Text; NewFunctionErrorCallStack: Text)
    var
        EmptyVariant: Variant;
    begin
        SetFunctionCallingResponse(NewFunctionCallSuccess, NewFunctionCalled, EmptyVariant, NewFunctionError, NewFunctionErrorCallStack);
    end;

    internal procedure SetFunctionCallingResponse(NewFunctionCallSuccess: Boolean; NewFunctionCalled: Text; NewFunctionResult: Variant)
    begin
        SetFunctionCallingResponse(NewFunctionCallSuccess, NewFunctionCalled, NewFunctionResult, '', '');
    end;

    local procedure SetFunctionCallingResponse(NewFunctionCallSuccess: Boolean; NewFunctionCalled: Text; NewFunctionResult: Variant; NewFunctionError: Text; NewFunctionErrorCallStack: Text)
    begin
        FunctionCallSuccess := NewFunctionCallSuccess;
        FunctionCallingName := NewFunctionCalled;
        FunctionResult := NewFunctionResult;
        FunctionError := NewFunctionError;
        FunctionErrorCallStack := NewFunctionErrorCallStack;
    end;
}