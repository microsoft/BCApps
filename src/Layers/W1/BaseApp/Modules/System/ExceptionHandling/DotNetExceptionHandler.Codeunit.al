namespace System.Utilities;

using System;

codeunit 1291 "DotNet Exception Handler"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        OuterException: DotNet Exception;

    [Scope('OnPrem')]
    procedure Catch(var Exception: DotNet Exception; Type: DotNet Type)
    begin
        Collect();
        if not CastToType(Exception, Type) then
            Rethrow();
    end;

    procedure Collect()
    begin
        OuterException := GetLastErrorObject();
    end;

    local procedure IsCollected(): Boolean
    begin
        exit(not IsNull(OuterException));
    end;

    [Scope('OnPrem')]
    procedure TryCastToType(Type: DotNet Type): Boolean
    var
        Exception: DotNet FormatException;
    begin
        exit(CastToType(Exception, Type));
    end;

    [Scope('OnPrem')]
    procedure CastToType(var Exception: DotNet Exception; Type: DotNet Type): Boolean
    begin
        if not IsCollected() then
            exit(false);

        Exception := OuterException.GetBaseException();
        if IsNull(Exception) then
            exit(false);

        if Type.Equals(Exception.GetType()) then
            exit(true);

        exit(false);
    end;

    procedure GetMessage(): Text
    var
        Exception: DotNet Exception;
    begin
        if not IsCollected() then
            exit;

        Exception := OuterException.GetBaseException();
        if IsNull(Exception) then
            exit;

        exit(Exception.Message);
    end;

    procedure Rethrow()
    var
        RootCauseMessage: Text;
    begin
        RootCauseMessage := GetMessage();

        if RootCauseMessage <> '' then
            Error(RootCauseMessage);

        if IsNull(OuterException.InnerException) then
            Error(OuterException.Message);

        Error(OuterException.InnerException.Message);
    end;
}

