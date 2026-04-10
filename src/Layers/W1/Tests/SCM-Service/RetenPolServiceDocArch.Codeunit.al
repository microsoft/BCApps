// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using System.DataAdministration;
using System.TestLibraries.Utilities;

codeunit 136153 "Reten. Pol. Service Doc. Arch."
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ArchiveServiceDocQst: Label 'Archive Order no.: %1?', Comment = '%1 is a document number';
        ArchiveServiceDocMsg: Label 'Document %1 has been archived.', Comment = '%1 is a document number';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestServiceDocArchiveRetenPolThreeDaysSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateServiceHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateServiceDocument(ServiceHeader);
        ArchiveServiceDocuments(ServiceHeader); // creates 3 versions

        // age the archive
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.ModifyAll("Date Archived", CalcDate('<-3D>', Today()));
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestServiceDocArchiveRetenPolThreeDays()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateServiceHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateServiceDocument(ServiceHeader);
        ArchiveServiceDocuments(ServiceHeader); // creates 3 versions

        // age the archive
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.ModifyAll("Date Archived", CalcDate('<-3D>', Today()));
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestServiceDocArchiveRetenPolTwoWeeksSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateServiceHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateServiceDocument(ServiceHeader);
        ArchiveServiceDocuments(ServiceHeader); // creates 3 versions

        // age the archive
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.ModifyAll("Date Archived", CalcDate('<-2W>', Today()));
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestServiceDocArchiveRetenPolSixWeeksSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateServiceHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateServiceDocument(ServiceHeader);
        ArchiveServiceDocuments(ServiceHeader); // creates 3 versions

        // age the archive
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.ModifyAll("Date Archived", CalcDate('<-6W>', Today()));
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestServiceDocArchiveRetenPolTwoWeeks()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateServiceHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateServiceDocument(ServiceHeader);
        ArchiveServiceDocuments(ServiceHeader); // creates 3 versions
        ServiceHeader.Delete();

        // age the archive
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.ModifyAll("Date Archived", CalcDate('<-2W>', Today()));
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        Assert.AreEqual(1, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestServiceDocArchiveRetenPolSixWeeks()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateServiceHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateServiceDocument(ServiceHeader);
        ArchiveServiceDocuments(ServiceHeader); // creates 3 versions
        ServiceHeader.Delete();

        // age the archive
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.ModifyAll("Date Archived", CalcDate('<-6W>', Today()));
        Assert.AreEqual(3, ServiceHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        Assert.RecordIsEmpty(ServiceHeaderArchive);
    end;

    local procedure Initialize()
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        RetentionPolicySetup: Record "Retention Policy Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Reten. Pol. Service Doc. Arch.");
        LibraryVariableStorage.AssertEmpty();
        ServiceHeaderArchive.DeleteAll(true);
        RetentionPolicySetup.SetFilter("Table Id", '%1', Database::"Service Header Archive");
        RetentionPolicySetup.DeleteAll(true);

        if IsInitialized then
            exit;

        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Order Nos." = '' then begin
            ServiceMgtSetup.Validate("Service Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
            ServiceMgtSetup.Modify();
        end;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Reten. Pol. Service Doc. Arch.");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Reten. Pol. Service Doc. Arch.");
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header");
    begin
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader.InitInsert();
        ServiceHeader.Insert();
    end;

    local procedure ArchiveServiceDocuments(ServiceHeader: Record "Service Header")
    var
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
    begin
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        ServiceDocumentArchiveMgmt.ArchiveServiceDocument(ServiceHeader);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        ServiceDocumentArchiveMgmt.ArchiveServiceDocument(ServiceHeader);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        ServiceDocumentArchiveMgmt.ArchiveServiceDocument(ServiceHeader);
    end;

    local procedure CreateOneWeekRetentionPeriod(var RetentionPeriod: Record "Retention Period")
    begin
        CreateRetentionPeriod(RetentionPeriod, RetentionPeriod."Retention Period"::"1 Week");
    end;

    local procedure CreateOneMonthRetentionPeriod(var RetentionPeriod: Record "Retention Period")
    begin
        CreateRetentionPeriod(RetentionPeriod, RetentionPeriod."Retention Period"::"1 Month");
    end;

    local procedure CreateRetentionPeriod(var RetentionPeriod: Record "Retention Period"; RetentionPeriodEnum: Enum "Retention Period Enum")
    begin
        RetentionPeriod.SetRange("Retention Period", RetentionPeriodEnum);
        if not RetentionPeriod.FindFirst() then begin
            RetentionPeriod.Code := Format(RetentionPeriodEnum);
            RetentionPeriod.Validate("Retention Period", RetentionPeriodEnum);
            RetentionPeriod.Insert();
        end;
    end;

    local procedure CreateServiceHeaderArchiveRetentionPolicySetup(var RetentionPolicySetup: Record "Retention Policy Setup")
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
    begin
        // mandatory: keep all if source doc exists
        // delete all except last version after 1 week
        // delete all after 1 month
        RetentionPolicySetup.Validate("Table Id", Database::"Service Header Archive");
        RetentionPolicySetup.Validate("Apply to all records", false);
        RetentionPolicySetup."Date Field No." := 5045; // "Date Archived" -> bypass system created at issue
        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Insert(true);

        RetentionPolicySetupLine.SetRange("Table ID", Database::"Service Header Archive");
        RetentionPolicySetupLine.FindLast();
        RetentionPolicySetupLine.Init();

        CreateOneMonthRetentionPeriod(RetentionPeriod);
        RetentionPolicySetupLine.Validate("Table ID", Database::"Service Header Archive");
        RetentionPolicySetupLine."Line No." += 1;
        RetentionPolicySetupLine."Date Field No." := RetentionPolicySetup."Date Field No.";
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriod.Code);
        RetentionPolicySetupLine."Keep Last Version" := false;
        RetentionPolicySetupLine.Insert(true);

        CreateOneWeekRetentionPeriod(RetentionPeriod);
        RetentionPolicySetupLine.Validate("Table ID", Database::"Service Header Archive");
        RetentionPolicySetupLine."Line No." += 1;
        RetentionPolicySetupLine."Date Field No." := RetentionPolicySetup."Date Field No.";
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriod.Code);
        RetentionPolicySetupLine."Keep Last Version" := true;
        RetentionPolicySetupLine.Insert(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(StrSubstNo(ArchiveServiceDocQst, LibraryVariableStorage.DequeueText()), Question);
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(StrSubstNo(ArchiveServiceDocMsg, LibraryVariableStorage.DequeueText()), Message);
    end;
}