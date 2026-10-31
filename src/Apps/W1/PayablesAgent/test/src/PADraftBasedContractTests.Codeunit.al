// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;

// Contract tests of the wrappers over their draft-based backing. Delete together with the draft-based agent.
// Storage construction and inspection go through app-owned semantic fixtures.
codeunit 133736 "PA Draft Based Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DraftBasedUploadRemainsUploadAndMatchesOnlyItsOwnResult()
    var
        Source: Codeunit "PA Task Source";
        Task: Codeunit "Payables Agent Task";
        Fixtures: Codeunit "PA Test Fixtures";
        ExpectedResult: RecordId;
        UnrelatedResult: RecordId;
    begin
        Check(Fixtures.CreateDraftBasedUploadContractScenario(Source, Task, ExpectedResult, UnrelatedResult), 'The draft-based upload scenario must be created.');
        Check(Source.GetSourceType() = "PA Source Type"::Upload, 'A draft-based upload must not be treated as email.');
        Check(Task.IsResultRecord(ExpectedResult), 'The source document is the draft-based review result.');
        Check(not Task.IsResultRecord(UnrelatedResult), 'A different source of the same backing type is not this task result.');
    end;

    [Test]
    procedure DraftBasedDiagnosticsNormalizeTheInvoiceProposal()
    var
        Source: Codeunit "PA Task Source";
        Task: Codeunit "Payables Agent Task";
        Fixtures: Codeunit "PA Test Fixtures";
        ExpectedResult, UnrelatedResult : RecordId;
        Diagnostics, Header, PurchaseInvoice : JsonObject;
        Errors, Lines : JsonArray;
    begin
        Check(Fixtures.CreateDraftBasedUploadContractScenario(Source, Task, ExpectedResult, UnrelatedResult), 'The draft-based upload scenario must be created.');
        Check(Fixtures.GetTaskDiagnosticEvidence(Task.GetAgentTaskId(), Diagnostics), 'Diagnostics must be available for the Payables Agent task.');
        Check(GetText(Diagnostics, 'paVersion') = 'V1', 'Diagnostics must identify the draft-based version.');
        Check(GetText(Diagnostics, 'outcomeStatus') = 'InvoiceProposed', 'A draft without a purchase invoice must be classified as proposed.');
        PurchaseInvoice := GetObject(Diagnostics, 'purchaseInvoice');
        Header := GetObject(PurchaseInvoice, 'header');
        Check(GetText(Header, 'vendorInvoiceNo') = 'FIXTURE-INV', 'The proposal header must use the normalized vendor invoice field.');
        Lines := GetArray(PurchaseInvoice, 'lines');
        Check(Lines.Count() = 1, 'The proposal line must be included in normalized diagnostics.');
        Errors := GetArray(Diagnostics, 'errors');
        Check(Errors.Count() = 0, 'The complete fixture proposal must not produce diagnostic errors.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure DeactivationStopsBackingImporter()
    var
        Fixtures: Codeunit "PA Test Fixtures";
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        Fixtures.SeedDraftBasedImporterEnabled();
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);

        Stored.GetSetup();
        Check(not Stored.GetMonitorOutlook(), 'Deactivation must persist monitoring off.');
        Check(not Fixtures.IsDraftBasedImporterEnabled(), 'Deactivation must also turn the backing importer off.');
    end;

    local procedure GetText(Object: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Object.Get(PropertyName, Token);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetObject(Object: JsonObject; PropertyName: Text): JsonObject
    var
        Token: JsonToken;
    begin
        Object.Get(PropertyName, Token);
        exit(Token.AsObject());
    end;

    local procedure GetArray(Object: JsonObject; PropertyName: Text): JsonArray
    var
        Token: JsonToken;
    begin
        Object.Get(PropertyName, Token);
        exit(Token.AsArray());
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
