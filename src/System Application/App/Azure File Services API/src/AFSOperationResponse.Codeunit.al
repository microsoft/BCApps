// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage.Files;

/// <summary>
/// Stores the response of an AFS client operation.
/// </summary>
codeunit 8959 "AFS Operation Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AFSOperationResponseImpl: Codeunit "AFS Operation Response Impl.";

    /// <summary>
    /// Checks whether the operation was successful.
    /// </summary>    
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure IsSuccessful(): Boolean
    begin
        exit(AFSOperationResponseImpl.IsSuccessful());
    end;

    /// <summary>
    /// Gets the error (if any) of the response.
    /// </summary>
    /// <returns>Text representation of the error that occurred during the operation.</returns>
    procedure GetError(): Text
    begin
        exit(AFSOperationResponseImpl.GetError());
    end;

    /// <summary>
    /// Gets the HttpHeaders (if any) of the response.
    /// </summary>
    /// <returns>HttpHeaders of the response.</returns>
    procedure GetHeaders(): HttpHeaders
    begin
        exit(AFSOperationResponseImpl.GetHeaders());
    end;

    [NonDebuggable]
    internal procedure GetHeaderValueFromResponseHeaders(HeaderName: Text): Text
    begin
        exit(AFSOperationResponseImpl.GetHeaderValueFromResponseHeaders(HeaderName));
    end;

    internal procedure SetError(Error: Text)
    begin
        AFSOperationResponseImpl.SetError(Error);
    end;

    [NonDebuggable]
    [TryFunction]
    internal procedure GetResultAsText(var Result: Text);
    begin
        AFSOperationResponseImpl.GetResultAsText(Result);
    end;

    [NonDebuggable]
    [TryFunction]
    internal procedure GetResultAsStream(var ResultInStream: InStream)
    begin
        AFSOperationResponseImpl.GetResultAsStream(ResultInStream);
    end;

    [NonDebuggable]
    internal procedure SetHttpResponse(NewHttpResponseMessage: HttpResponseMessage)
    begin
        AFSOperationResponseImpl.SetHttpResponse(NewHttpResponseMessage);
    end;
}