#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

using System.Utilities;

#pragma warning disable AL0432, AS0105
codeunit 9764 "SFTP Operation Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'The SFTP module has been removed because platform hardening prevents support for SFTP connections.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    internal procedure GetResponseStream(var ResultInstream: InStream)
    begin
        ResultInstream := TempBlob.CreateInStream();
    end;

    internal procedure SetTempBlob(NewTempBlob: Codeunit "Temp Blob")
    begin
        TempBlob := NewTempBlob;
    end;

    internal procedure SetError(NewErrorMsg: Text)
    begin
        IsErrorVar := true;
        ErrorMsg := NewErrorMsg;
    end;

    internal procedure SetExceptionType(NewExceptionType: Enum "SFTP Exception Type")
    begin
        ErrorType := NewExceptionType;
    end;

    /// <summary>
    /// Returns the error message if an error occurred during the SFTP operation.
    /// If no error occurred, it returns an empty string.
    /// </summary>
    /// <returns>The error message</returns>
    procedure GetError(): Text
    begin
        exit(ErrorMsg);
    end;

    /// <summary>
    /// Checks if an error occurred during the SFTP operation.
    /// Returns true if an error occurred, false otherwise.
    /// </summary>
    /// <returns>True if an error occurred, false otherwise.</returns>
    procedure IsError(): Boolean
    begin
        exit(IsErrorVar);
    end;

    /// <summary>
    /// Returns the type of error that occurred during the SFTP operation.
    /// If no error occurred, it returns the default value of the enum.
    /// </summary>
    /// <returns>An enum representing the exception.</returns>
    procedure GetErrorType(): Enum "SFTP Exception Type"
    begin
        exit(ErrorType);
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        IsErrorVar: Boolean;
        ErrorType: Enum "SFTP Exception Type";
        ErrorMsg: Text;
}
#pragma warning restore AL0432, AS0105
#endif
