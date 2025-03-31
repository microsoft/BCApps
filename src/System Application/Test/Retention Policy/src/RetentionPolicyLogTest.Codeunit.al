// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.DataAdministration;

using System.DataAdministration;
using System.TestLibraries.DataAdministration;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

// This codeunit must be executed by a test-runnner which has test-isolation disabled.

codeunit 138705 "Retention Policy Log Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        RetentionPolicyTestLibrary: Codeunit "Retention Policy Test Library";
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
        ErrorOccuredDuringApplyErrLbl: Label 'An error occured while applying the retention policy for table %1 %2.\\%3', Comment = '%1 = table number, %2 = table name, %3 = error message';
        TestLogMessageLbl: Label 'TestLog %1 Entry No. %2', Locked = true;
        RetentionPolicySetupRecordNotTempErr: Label 'The retention policy setup record instance must be temporary. Contact your Microsoft Partner for assistance.';
        RecordDoesNotExistErr: Label 'The Retention Policy Setup does not exist. Identification fields and values: %1', Comment = '%1 is a guid';

    [Test]
    procedure TestLogInfo()
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        //Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();

        //Exercise
        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Info, LastRetentionPolicyLogEntryNo + 1)); // runs a background task
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Info, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Info, LastRetentionPolicyLogEntryNo + 1));

        // verify
        asserterror
            error('An error to ensure rollback');

        // info is rolled back
        asserterror
            VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Info, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Info, LastRetentionPolicyLogEntryNo + 1));
    end;

    [Test]
    procedure TestLogWarning()
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        //Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();

        //Exercise
        RetentionPolicyLog.LogWarning(RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Warning, LastRetentionPolicyLogEntryNo + 1)); // runs a background task
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Warning, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Warning, LastRetentionPolicyLogEntryNo + 1));

        // verify
        asserterror
            error('An error to ensure rollback');

        // warning is rolled back
        asserterror
            VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Warning, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Warning, LastRetentionPolicyLogEntryNo + 1));
    end;

    [Test]
    procedure TestLogError()
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        //Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();

        //Exercise
        asserterror
            RetentionPolicyLog.LogError(RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Error, LastRetentionPolicyLogEntryNo + 1)); // runs a background task

        // Verify
        // error is NOT rolled back
        sleep(50); // need some time for background session
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Error, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Error, LastRetentionPolicyLogEntryNo + 1));
    end;

    [Test]
    procedure TestLogErrorWithDisplay()
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        //Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();

        //Exercise
        asserterror
            RetentionPolicyLog.LogError(RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Error, LastRetentionPolicyLogEntryNo + 1), true); // runs a background task

        // Verify
        // error is NOT rolled back
        sleep(50); // need some time for background session
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Error, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Error, LastRetentionPolicyLogEntryNo + 1));
    end;

    [Test]
    procedure TestLogErrorWithoutDisplay()
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        //Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();

        //Exercise
        RetentionPolicyLog.LogError(RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Error, LastRetentionPolicyLogEntryNo + 1), false); // runs a background task

        // Verify
        // error is NOT rolled back
        sleep(50); // need some time for background session
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Error, RetentionPolicyLogCategory::"Retention Policy - Period", StrSubstNo(TestLogMessageLbl, enum::"Retention Policy Log Message Type"::Error, LastRetentionPolicyLogEntryNo + 1));
    end;

    [Test]
    procedure TestApplyRetentionPolicyRecordMustBeTemp()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
        RunSuccessful: Boolean;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        // Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();
        RetentionPolicySetup.SystemId := CreateGuid();
        RetentionPolicySetup."Table Id" := Database::"Retention Policy Test Data";
        RetentionPolicySetup.CalcFields("Table Name");
        ClearLastError();

        // Exercise
        RunSuccessful := RetentionPolicyTestLibrary.RunApplyRetentionPolicyImpl(RetentionPolicySetup);
        assert.IsFalse(RunSuccessful, 'ApplyRetentionPolicyImpl should return false when record is not temporary');
        RetentionPolicyLog.LogError(RetentionPolicyLogCategory::"Retention Policy - Apply", StrSubstNo(ErrorOccuredDuringApplyErrLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Name", GetLastErrorText()), false);

        // Verify
        // error is NOT rolled back
        sleep(50);
        Assert.ExpectedError(RetentionPolicySetupRecordNotTempErr);
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Error, RetentionPolicyLogCategory::"Retention Policy - Apply",
            StrSubstNo(ErrorOccuredDuringApplyErrLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Name", RetentionPolicySetupRecordNotTempErr));
    end;

    [Test]
    procedure TestApplyRetentionPolicyRecordMustExist()
    var
        TempRetentionPolicySetup: Record "Retention Policy Setup" temporary;
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LastRetentionPolicyLogEntryNo: BigInteger;
        RunSuccessful: Boolean;
    begin
        PermissionsMock.Set('Retention Pol. Admin');
        // Setup
        LastRetentionPolicyLogEntryNo := RetentionPolicyTestLibrary.RetentionPolicyLogLastEntryNo();
        TempRetentionPolicySetup.SystemId := CreateGuid();
        TempRetentionPolicySetup."Table Id" := Database::"Retention Policy Test Data";
        TempRetentionPolicySetup.CalcFields("Table Name");
        ClearLastError();

        // Exercise
        RunSuccessful := RetentionPolicyTestLibrary.RunApplyRetentionPolicyImpl(TempRetentionPolicySetup);
        assert.IsFalse(RunSuccessful, 'ApplyRetentionPolicyImpl should return false when record does not exist');
        RetentionPolicyLog.LogError(RetentionPolicyLogCategory::"Retention Policy - Apply", StrSubstNo(ErrorOccuredDuringApplyErrLbl, TempRetentionPolicySetup."Table Id", TempRetentionPolicySetup."Table Name", GetLastErrorText()), false);

        // Verify
        // error is NOT rolled back
        sleep(50);
        Assert.ExpectedError(StrSubstNo(RecordDoesNotExistErr, TempRetentionPolicySetup.SystemId));
        VerifyLogEntry(LastRetentionPolicyLogEntryNo + 1, enum::"Retention Policy Log Message Type"::Error, RetentionPolicyLogCategory::"Retention Policy - Apply",
            StrSubstNo(ErrorOccuredDuringApplyErrLbl, TempRetentionPolicySetup."Table Id", TempRetentionPolicySetup."Table Name", StrSubstNo(RecordDoesNotExistErr, TempRetentionPolicySetup.SystemId)));
    end;

    local procedure VerifyLogEntry(EntryNo: BigInteger; MessageType: Enum "Retention Policy Log Message Type"; Category: Enum "Retention Policy Log Category"; Message: Text)
    var
        FieldValues: Dictionary of [Text, Text];
    begin
        FieldValues := RetentionPolicyTestLibrary.GetNextRetentionPolicyLogEntry(EntryNo);
        Assert.AreEqual(Format(MessageType), FieldValues.Get('MessageType'), 'wrong message type');
        Assert.AreEqual(Format(Category), FieldValues.Get('Category'), 'wrong category');
        Assert.AreEqual(Message, FieldValues.Get('Message'), 'wrong message');
    end;
}