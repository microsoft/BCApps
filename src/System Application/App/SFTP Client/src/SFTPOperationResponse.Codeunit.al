namespace System.SFTPClient;

using System.Utilities;

codeunit 50102 "SFTP Operation Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

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

    procedure GetError(): Text
    begin
        exit(ErrorMsg);
    end;

    procedure IsError(): Boolean
    begin
        exit(IsErrorVar);
    end;

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