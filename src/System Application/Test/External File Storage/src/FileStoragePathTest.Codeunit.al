// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.ExternalFileStorage;
using System.TestLibraries.Utilities;

codeunit 134754 "File Storage Path Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteDirectoryWithParentSegmentFails()
    var
        TempFileAccount: Record "File Account" temporary;
        FileConnectorMock: Codeunit "File Connector Mock";
        ExternalFileStorage: Codeunit "External File Storage";
        PathContainsRelativeSegmentErr: Label 'The path %1 contains the relative path segment %2, which is not allowed.', Locked = true;
    begin
        // [Scenario] A directory cannot be deleted through a path that contains a parent segment ("..")

        // [Given] A file account
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);
        ExternalFileStorage.Initialize(TempFileAccount);

        // [When] A directory is deleted with a path that ends in a parent segment
        // [Then] The delete fails
        Assert.IsFalse(ExternalFileStorage.DeleteDirectory('Test Folder/..'), 'The delete should fail for a path with a parent segment.');
        Assert.AreEqual(StrSubstNo(PathContainsRelativeSegmentErr, 'Test Folder/..', '..'), GetLastErrorText(), 'The error message is wrong.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateDirectoryWithCurrentSegmentFails()
    var
        TempFileAccount: Record "File Account" temporary;
        FileConnectorMock: Codeunit "File Connector Mock";
        ExternalFileStorage: Codeunit "External File Storage";
        PathContainsRelativeSegmentErr: Label 'The path %1 contains the relative path segment %2, which is not allowed.', Locked = true;
    begin
        // [Scenario] A directory cannot be created through a path that contains a current directory segment (".")

        // [Given] A file account
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);
        ExternalFileStorage.Initialize(TempFileAccount);

        // [When] A directory is created with a path that contains a current directory segment
        // [Then] The create fails
        Assert.IsFalse(ExternalFileStorage.CreateDirectory('Test Folder/./New'), 'The create should fail for a path with a current directory segment.');
        Assert.AreEqual(StrSubstNo(PathContainsRelativeSegmentErr, 'Test Folder/./New', '.'), GetLastErrorText(), 'The error message is wrong.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PathWithDotsInNameIsAllowed()
    var
        TempFileAccount: Record "File Account" temporary;
        FileConnectorMock: Codeunit "File Connector Mock";
        ExternalFileStorage: Codeunit "External File Storage";
    begin
        // [Scenario] A path with dots inside a segment name is not a relative path and is allowed

        // [Given] A file account
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);
        ExternalFileStorage.Initialize(TempFileAccount);

        // [When] A file is deleted with a path whose segments contain dots, but are not "." or ".."
        // [Then] The delete succeeds and the connector receives the path
        Assert.IsTrue(ExternalFileStorage.DeleteFile('Test Folder/v1..2/..hidden/a.'), 'The delete should succeed for a path with dots in the segment names.');
        Assert.AreEqual('Test Folder/v1..2/..hidden/a.', FileConnectorMock.GetLastDeletedPath(), 'The connector should receive the path.');
    end;
}
