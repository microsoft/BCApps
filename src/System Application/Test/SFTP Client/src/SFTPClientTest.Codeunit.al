// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.SFTPClient;

using System.SFTPClient;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139077 "SFTP Client Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TestSocketExceptionHandling()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A Mock SFTP client configured to fail with Socket Exception
        MockSFTPClient.SetShouldFailConnect(true);
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"Socket Exception", 'Some socket error');
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');

        // [WHEN] Initialize is called
        Response := SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [THEN] Response should contain an error with the socket exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'Socket connection to the SSH server or proxy server could not be established, or an error occurred while resolving the hostname.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"Socket Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestSshAuthenticationExceptionHandling()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A Mock SFTP client configured to fail with SSH Authentication Exception
        MockSFTPClient.SetShouldFailConnect(true);
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"SSH Authentication Exception", 'Authentication failed');
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');

        // [WHEN] Initialize is called
        Response := SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [THEN] Response should contain an error with the authentication exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'Authentication of SSH session failed.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"SSH Authentication Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestInvalidOperationExceptionHandling()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A Mock SFTP client configured to fail with Invalid Operation Exception
        MockSFTPClient.SetShouldFailConnect(true);
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"Invalid Operation Exception", 'Already connected');
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);

        // [WHEN] Initialize is called
        Response := SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [THEN] Response should contain an error with the invalid operation exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'The client is already connected.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"Invalid Operation Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestSftpPathNotFoundExceptionHandling()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        FileList: List of [Interface "ISFTP File"];
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A connected Mock SFTP client configured to fail with Path Not Found Exception
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // Configure mock to fail with Path Not Found on ListDirectory
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", 'Path not found');

        // [WHEN] ListFiles is called with non-existent path
        Response := SFTPClientImpl.ListFiles('/nonexistent/path', FileList);

        // [THEN] Response should contain an error with the path not found exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'The specified path is invalid, or its directory was not found on the remote host.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestGenericExceptionHandling()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        GenericMessage: Text;
    begin
        // [GIVEN] A Mock SFTP client configured to fail with Generic Exception
        GenericMessage := 'Some unexpected error occurred';
        MockSFTPClient.SetShouldFailConnect(true);
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"Generic Exception", GenericMessage);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');

        // [WHEN] Initialize is called
        Response := SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [THEN] Response should contain the actual generic exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        Assert.AreEqual(GenericMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"Generic Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestNotConnectedError()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        FileList: List of [Interface "ISFTP File"];
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A Mock SFTP client that is not connected
        MockSFTPClient.SetShouldFailConnect(false);
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"SSH Connection Exception", 'Client is not connected.');
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');

        // [WHEN] A method that requires connection is called without connecting first
        Response := SFTPClientImpl.ListFiles('/some/path', FileList);

        // [THEN] Response should contain an error about not being connected
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'Client is not connected.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"SSH Connection Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestCreateDirectoryException()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A connected Mock SFTP client configured to fail on CreateDirectory
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // Configure mock to fail with SFTP Path Not Found on CreateDirectory
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", 'Parent directory not found');

        // [WHEN] CreateDirectory is called with a path that has a non-existent parent
        Response := SFTPClientImpl.CreateDirectory('/nonexistent/parent/newdir');

        // [THEN] Response should contain an error with the path not found exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'The specified path is invalid, or its directory was not found on the remote host.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestPutFileStreamException()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A connected Mock SFTP client configured to fail on WriteAllBytes
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // Create a test stream
        OutStr := TempBlob.CreateOutStream();
        OutStr.WriteText('Test content');
        InStr := TempBlob.CreateInStream();

        // Configure mock to fail with SFTP Path Not Found on WriteAllBytes
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", 'Directory not found');

        // [WHEN] PutFileStream is called with a path in a non-existent directory
        Response := SFTPClientImpl.PutFileStream('/nonexistent/dir/file.txt', InStr);

        // [THEN] Response should contain an error with the path not found exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'The specified path is invalid, or its directory was not found on the remote host.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestMoveFileException()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A connected Mock SFTP client configured to fail on Get
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // Configure mock to fail with SFTP Path Not Found on Get
        MockSFTPClient.SetExceptionToReturn(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", 'Source file not found');

        // [WHEN] MoveFile is called with a non-existent source file
        Response := SFTPClientImpl.MoveFile('/nonexistent/source.txt', '/some/destination.txt');

        // [THEN] Response should contain an error with the path not found exception message
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'The specified path is invalid, or its directory was not found on the remote host.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"SFTP Path Not Found Exception", Response.GetErrorType(), 'Incorrect error type');
    end;

    [Test]
    procedure TestSuccessfulConnection()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
    begin
        // [GIVEN] A Mock SFTP client configured to succeed
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');

        // [WHEN] Initialize is called
        Response := SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [THEN] Response should not contain an error
        Assert.IsFalse(Response.IsError(), 'Response should not indicate an error');
        Assert.IsTrue(MockSFTPClient.IsConnected(), 'Client should be connected');
    end;

    [Test]
    procedure TestFileOperations()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        FileList: List of [Interface "ISFTP File"];
        InStr: InStream;
        IsFileExists: Boolean;
    begin
        // [GIVEN] A connected Mock SFTP client with a file
        MockSFTPClient.SetShouldFailConnect(false);
        MockSFTPClient.AddFile('/test/file.txt', 'test content');
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [WHEN] File operations are performed
        Response := SFTPClientImpl.FileExists('/test/file.txt', IsFileExists);
        Assert.IsFalse(Response.IsError(), 'FileExists should not return an error');
        Assert.IsTrue(IsFileExists, 'File should exist');

        Response := SFTPClientImpl.ListFiles('/test', FileList);
        Assert.IsFalse(Response.IsError(), 'ListFiles should not return an error');
        Assert.AreEqual(1, FileList.Count, 'There should be one file in the list');

        Response := SFTPClientImpl.GetFileAsStream('/test/file.txt', InStr);
        Assert.IsFalse(Response.IsError(), 'GetFileAsStream should not return an error');

        Response := SFTPClientImpl.DeleteFile('/test/file.txt');
        Assert.IsFalse(Response.IsError(), 'DeleteFile should not return an error');

        // [THEN] File should no longer exist
        Response := SFTPClientImpl.FileExists('/test/file.txt', IsFileExists);
        Assert.IsFalse(Response.IsError(), 'FileExists should not return an error after deletion');
        Assert.IsFalse(IsFileExists, 'File should no longer exist');
    end;

    [Test]
    procedure TestDirectoryOperations()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        WorkingDir: Text;
    begin
        // [GIVEN] A connected Mock SFTP client
        MockSFTPClient.SetShouldFailConnect(false);
        MockSFTPClient.SetWorkingDirectoryInternal('/initial/dir');
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [WHEN] Directory operations are performed
        Response := SFTPClientImpl.GetWorkingDirectory(WorkingDir);
        Assert.IsFalse(Response.IsError(), 'GetWorkingDirectory should not return an error');
        Assert.AreEqual('/initial/dir', WorkingDir, 'Working directory should match initial setting');

        Response := SFTPClientImpl.SetWorkingDirectory('/new/dir');
        Assert.IsFalse(Response.IsError(), 'SetWorkingDirectory should not return an error');

        Response := SFTPClientImpl.GetWorkingDirectory(WorkingDir);
        Assert.IsFalse(Response.IsError(), 'GetWorkingDirectory should not return an error after change');
        Assert.AreEqual('/new/dir', WorkingDir, 'Working directory should be updated');

        Response := SFTPClientImpl.CreateDirectory('/test/newdir');
        Assert.IsFalse(Response.IsError(), 'CreateDirectory should not return an error');
    end;

    [Test]
    procedure TestBinaryFileStreaming()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        TempBlob: Codeunit "Temp Blob";
        InputOutStream: OutStream;
        OutputInStream: InStream;
        TestBinaryData: array[10] of Byte;
        ReadByte: Byte;
        i: Integer;
    begin
        // [GIVEN] Binary data to upload
        for i := 1 to 10 do
            TestBinaryData[i] := i;

        // Set up client
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);
        SFTPClientImpl.AddFingerPrintSHA256('5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=');
        SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // Prepare binary stream
        TempBlob.CreateOutStream(InputOutStream);
        for i := 1 to 10 do
            InputOutStream.Write(TestBinaryData[i]);
        TempBlob.CreateInStream(OutputInStream);

        // [WHEN] Uploading and downloading binary data
        Response := SFTPClientImpl.PutFileStream('/test/binary.dat', OutputInStream);
        Assert.IsFalse(Response.IsError(), 'PutFileStream should not return an error');

        TempBlob.CreateInStream(OutputInStream); // Reset stream position
        Response := SFTPClientImpl.GetFileAsStream('/test/binary.dat', OutputInStream);

        // [THEN] Binary data should be preserved
        Assert.IsFalse(Response.IsError(), 'GetFileAsStream should not return an error');

        // Verify binary content
        for i := 1 to 10 do begin
            OutputInStream.Read(ReadByte);
            Assert.AreEqual(TestBinaryData[i], ReadByte, 'Binary data not preserved correctly');
        end;
    end;

    [Test]
    procedure TestUntrustedServerException()
    var
        MockSFTPClient: Codeunit "Mock SFTP Client";
        SFTPClientImpl: Codeunit "SFTP Client Implementation";
        Response: Codeunit "SFTP Operation Response";
        ExpectedErrorMessage: Text;
    begin
        // [GIVEN] A Mock SFTP client WITHOUT a trusted fingerprint
        MockSFTPClient.SetShouldFailConnect(false);
        SFTPClientImpl.SetISFTPClient(MockSFTPClient);

        // [WHEN] Initialize is called without adding fingerprints
        Response := SFTPClientImpl.Initialize('test.host.com', 22, 'username', SecretStrSubstNo('password'));

        // [THEN] Response should contain an error with the untrusted server exception
        Assert.IsTrue(Response.IsError(), 'Response should indicate an error');
        ExpectedErrorMessage := 'The server''s host key fingerprint 5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo= is not trusted.';
        Assert.AreEqual(ExpectedErrorMessage, Response.GetError(), 'Incorrect error message');
        Assert.AreEqual(Enum::"SFTP Exception Type"::"Untrusted Server Exception", Response.GetErrorType(), 'Incorrect error type');
    end;
}