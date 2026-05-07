// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Holder object for SharePoint Graph API operation results.
/// </summary>
codeunit 9129 "SharePoint Graph Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SharePointGraphRequestHelper: Codeunit "SharePoint Graph Req. Helper";
        IsSuccess: Boolean;
        ErrorMessage: Text;
        ErrorCallStack: Text;

    /// <summary>
    /// Checks whether the operation was successful.
    /// </summary>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure IsSuccessful(): Boolean
    begin
        exit(IsSuccess);
    end;

    /// <summary>
    /// Gets the error message (if any) of the response.
    /// </summary>
    /// <returns>Text representation of the error that occurred during the operation.</returns>
    procedure GetError(): Text
    begin
        exit(ErrorMessage);
    end;

    /// <summary>
    /// Gets the call stack at the time of the error.
    /// </summary>
    /// <returns>The call stack when the error occurred.</returns>
    procedure GetErrorCallStack(): Text
    begin
        exit(ErrorCallStack);
    end;

    /// <summary>
    /// Gets the HTTP diagnostics for the last HTTP request (if any).
    /// </summary>
    /// <returns>HTTP diagnostics interface for detailed HTTP response information.</returns>
    procedure GetHttpDiagnostics(): Interface "HTTP Diagnostics"
    begin
        exit(SharePointGraphRequestHelper.GetDiagnostics());
    end;

    /// <summary>
    /// Sets the response as successful.
    /// </summary>
    internal procedure SetSuccess()
    begin
        IsSuccess := true;
        ErrorMessage := '';
        ErrorCallStack := '';
    end;

    /// <summary>
    /// Sets the response as failed with an error message.
    /// </summary>
    /// <param name="NewErrorMessage">The error message to set.</param>
    internal procedure SetError(NewErrorMessage: Text)
    begin
        IsSuccess := false;
        ErrorMessage := NewErrorMessage;
        ErrorCallStack := SessionInformation.Callstack();
    end;

    /// <summary>
    /// Sets the request helper for HTTP diagnostics access.
    /// </summary>
    /// <param name="NewSharePointGraphRequestHelper">The request helper instance.</param>
    internal procedure SetRequestHelper(var NewSharePointGraphRequestHelper: Codeunit "SharePoint Graph Req. Helper")
    begin
        SharePointGraphRequestHelper := NewSharePointGraphRequestHelper;
    end;
}