// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Email;

using System.Email;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 134707 "Email Message Headers Test"
{
    Subtype = Test;
    Permissions = tabledata "Email Message" = rm;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddHeaderRoundTripsCaseInsensitively()
    var
        Message: Codeunit "Email Message";
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');
        Message.AddHeader('Authentication-Results', 'spf=pass');
        Message.AddHeader('X-MS-Exchange-Organization-AuthAs', 'Internal');

        Assert.IsTrue(Message.Get(Message.GetId()), 'Message not found after reload');
        Assert.IsTrue(Message.TryGetHeader('authentication-results', Value), 'Header lookup should succeed case-insensitively');
        Assert.AreEqual('spf=pass', Value, 'Authentication-Results header value mismatch');
        Assert.IsTrue(Message.TryGetHeader('X-MS-EXCHANGE-ORGANIZATION-AUTHAS', Value), 'AuthAs header lookup should succeed case-insensitively');
        Assert.AreEqual('Internal', Value, 'AuthAs header value mismatch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryGetHeaderReturnsFalseWhenNoHeadersStored()
    var
        Message: Codeunit "Email Message";
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');

        Assert.IsFalse(Message.TryGetHeader('any-header', Value), 'Lookup on a message with no headers should return false');
        Assert.AreEqual('', Value, 'Value should be empty when no headers stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddHeaderJoinsRepeatedValuesWithLineFeed()
    var
        Message: Codeunit "Email Message";
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');
        Message.AddHeader('Received', 'from hop1');
        Message.AddHeader('Received', 'from hop2');

        Assert.IsTrue(Message.Get(Message.GetId()), 'Message not found after reload');
        Assert.IsTrue(Message.TryGetHeader('Received', Value), 'Repeated header lookup should succeed');
        Assert.AreEqual('from hop1' + #10 + 'from hop2', Value, 'Repeated AddHeader calls should join values with line feed in insertion order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetHeaderReplacesExistingValue()
    var
        Message: Codeunit "Email Message";
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');
        Message.AddHeader('Received', 'from hop1');
        Message.AddHeader('Received', 'from hop2');
        Message.SetHeader('Received', 'canonical');

        Assert.IsTrue(Message.Get(Message.GetId()), 'Message not found after reload');
        Assert.IsTrue(Message.TryGetHeader('Received', Value), 'Header lookup after SetHeader should succeed');
        Assert.AreEqual('canonical', Value, 'SetHeader should replace any previously joined values');
    end;
}
