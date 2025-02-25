// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.Utilities;

codeunit 135810 "File Connector Mock"
{
    var
        Any: Codeunit Any;

    procedure Initialize()
    var
        TestFileAccount: Record "Test File Account";
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.DeleteAll();
        TestFileConnectorSetup.Init();
        TestFileConnectorSetup.Id := Any.GuidValue();
        TestFileConnectorSetup."Fail On Send" := false;
        TestFileConnectorSetup."Fail On Register Account" := false;
        TestFileConnectorSetup."Unsuccessful Register" := false;
        TestFileConnectorSetup.Insert();

        TestFileAccount.DeleteAll();
    end;

    procedure GetAccounts(var FileAccount: Record "File Account")
    var
        TestFileAccount: Record "Test File Account";
    begin
        if TestFileAccount.FindSet() then
            repeat
                FileAccount.Init();
                FileAccount."Account Id" := TestFileAccount.Id;
                FileAccount.Name := TestFileAccount.Name;
                FileAccount.Insert();
            until TestFileAccount.Next() = 0;
    end;

    procedure AddAccount(var FileAccount: Record "File Account")
    var
        TestFileAccount: Record "Test File Account";
    begin
        TestFileAccount.Id := Any.GuidValue();
        TestFileAccount.Name := CopyStr(Any.AlphanumericText(250), 1, 250);
        TestFileAccount.Insert();

        FileAccount."Account Id" := TestFileAccount.Id;
        FileAccount.Name := TestFileAccount.Name;
        FileAccount.Connector := Enum::"Ext. File Storage Connector"::"Test File Storage Connector";
    end;

    procedure AddAccount(var Id: Guid)
    var
        TestFileAccount: Record "Test File Account";
    begin
        TestFileAccount.Id := Any.GuidValue();
        TestFileAccount.Name := CopyStr(Any.AlphanumericText(250), 1, 250);
        TestFileAccount.Insert();

        Id := TestFileAccount.Id;
    end;

    procedure FailOnSend(): Boolean
    var
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.FindFirst();
        exit(TestFileConnectorSetup."Fail On Send");
    end;

    procedure FailOnSend(Fail: Boolean)
    var
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.FindFirst();
        TestFileConnectorSetup."Fail On Send" := Fail;
        TestFileConnectorSetup.Modify();
    end;

    procedure FailOnRegisterAccount(): Boolean
    var
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.FindFirst();
        exit(TestFileConnectorSetup."Fail On Register Account");
    end;

    procedure FailOnRegisterAccount(Fail: Boolean)
    var
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.FindFirst();
        TestFileConnectorSetup."Fail On Register Account" := Fail;
        TestFileConnectorSetup.Modify();
    end;

    procedure UnsuccessfulRegister(): Boolean
    var
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.FindFirst();
        exit(TestFileConnectorSetup."Unsuccessful Register");
    end;

    procedure UnsuccessfulRegister(Fail: Boolean)
    var
        TestFileConnectorSetup: Record "Test File Connector Setup";
    begin
        TestFileConnectorSetup.FindFirst();
        TestFileConnectorSetup."Unsuccessful Register" := Fail;
        TestFileConnectorSetup.Modify();
    end;
}