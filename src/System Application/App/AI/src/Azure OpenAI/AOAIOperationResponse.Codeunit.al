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
    // FinishReason: Text; //TODO: Enable this when FinishReason is added to ALCopilotOperationResponse dotnet class

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
    /// Gets the finish reason of last response.
    /// </summary>
    /// <returns></returns>
    // TODO: Enable this when FinishReason is added to ALCopilotOperationResponse dotnet class
    // procedure GetFinishReason(): Text
    // begin
    //     exit(FinishReason);
    // end;

    internal procedure SetOperationResponse(var ALCopilotOperationResponse: DotNet ALCopilotOperationResponse)
    begin
        Success := ALCopilotOperationResponse.IsSuccess();
        StatusCode := ALCopilotOperationResponse.StatusCode;
        Result := ALCopilotOperationResponse.Result();
        Error := ALCopilotOperationResponse.ErrorText();
        // FinishReason := ALCopilotOperationResponse.FinishReason; //TODO: Add FinishReason to ALCopilotOperationResponse dotnet class

        if Error = '' then
            Error := GetLastErrorText();
    end;
}