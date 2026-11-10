// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Agents;

codeunit 3326 "PA Test Fixtures"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = RD, tabledata "Agent Task" = R, tabledata "Payables Agent Setup" = RIM, tabledata "Payables Agent Work Item" = D;

    #region AI evaluation fixtures

    var
        PASetupUpdate: Codeunit "PA Setup Update";
        Versions: Codeunit "PA V1V2 Flag";
        TaskNotFoundErr: Label 'Agent task %1 does not work on a Payables Agent work item.', Locked = true;
        VendorNotFoundErr: Label 'Vendor not found for the given name %1', Locked = true;
        AccountNotFoundErr: Label 'Account not found for the given code %1', Locked = true;
        PurchaseInvoiceOutcomeRequiredErr: Label 'Agent task %1 must have an existing purchase invoice registered as its outcome.', Locked = true;
        PurchaseLinesNotFoundErr: Label 'No purchase invoice lines were found for purchase invoice %1.', Locked = true;
        UnexpectedOutcomeErr: Label 'The task outcome %1 is not an existing purchase invoice.', Locked = true;
        UnknownEvaluationVersionErr: Label 'An evaluation must select version 1 or version 2 of the Payables Agent.';
        EvaluationVersionUnavailableErr: Label 'Payables Agent version %1 is not available in this environment.', Comment = '%1 = Payables Agent version';

    internal procedure EnsureActivatedAndReceivePdf(FileName: Text; PdfInStream: InStream; var WorkItem: Codeunit "PA Work Item"): Boolean
    var
        WorkItemIntake: Codeunit "PA Work Item Intake";
        AlreadyActivated: Boolean;
    begin
        PASetupUpdate.EnsureActivated(AlreadyActivated);
        exit(WorkItemIntake.ReceivePdf(FileName, PdfInStream, WorkItem));
    end;

    /// <summary>
    /// Applies the scripted human choice of an existing vendor to the version-specific record the user reviews.
    /// The caller resumes and waits for the Agent Framework task after this state change.
    /// </summary>
    internal procedure SelectVendor(AgentTaskId: BigInteger; VendorName: Text; var ErrorText: Text): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
        WorkItem: Codeunit "PA Work Item";
    begin
        Clear(ErrorText);
        if not WorkItem.LoadByAgentTaskId(AgentTaskId) then begin
            ErrorText := StrSubstNo(TaskNotFoundErr, AgentTaskId);
            exit(false);
        end;
        if Versions.GetVersion(WorkItem.GetId()) = 1 then
            exit(DraftBasedFixtures.SelectVendor(AgentTaskId, VendorName, ErrorText));

        Vendor.SetRange(Name, VendorName);
        if not Vendor.FindFirst() then begin
            ErrorText := StrSubstNo(VendorNotFoundErr, VendorName);
            exit(false);
        end;
        if not TryGetOutcomePurchaseInvoice(WorkItem, PurchaseHeader, ErrorText) then
            exit(false);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Applies the scripted human G/L-account choice to every current line of the version-specific review record.
    /// This intentionally preserves the existing assisted LineCorrection eval semantics pending dataset redesign.
    /// </summary>
    internal procedure SelectAccount(AgentTaskId: BigInteger; AccountCode: Text; var ErrorText: Text): Boolean
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
        WorkItem: Codeunit "PA Work Item";
        LineDeferralCode: Code[10];
        LineUnitOfMeasureCode: Code[10];
        LineDescription: Text[100];
        LineDirectUnitCost, LineQuantity : Decimal;
    begin
        Clear(ErrorText);
        if not WorkItem.LoadByAgentTaskId(AgentTaskId) then begin
            ErrorText := StrSubstNo(TaskNotFoundErr, AgentTaskId);
            exit(false);
        end;
        if Versions.GetVersion(WorkItem.GetId()) = 1 then
            exit(DraftBasedFixtures.SelectAccount(AgentTaskId, AccountCode, ErrorText));

        if not GLAccount.Get(AccountCode) then begin
            ErrorText := StrSubstNo(AccountNotFoundErr, AccountCode);
            exit(false);
        end;
        if not TryGetOutcomePurchaseInvoice(WorkItem, PurchaseHeader, ErrorText) then
            exit(false);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.IsEmpty() then begin
            ErrorText := StrSubstNo(PurchaseLinesNotFoundErr, PurchaseHeader."No.");
            exit(false);
        end;
        PurchaseLine.FindSet();
        repeat
            LineDescription := PurchaseLine.Description;
            LineQuantity := PurchaseLine.Quantity;
            LineUnitOfMeasureCode := PurchaseLine."Unit of Measure Code";
            LineDirectUnitCost := PurchaseLine."Direct Unit Cost";
            LineDeferralCode := PurchaseLine."Deferral Code";
            PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
            PurchaseLine.Validate("No.", GLAccount."No.");
            PurchaseLine.Validate(Description, LineDescription);
            if LineUnitOfMeasureCode <> '' then
                PurchaseLine.Validate("Unit of Measure Code", LineUnitOfMeasureCode);
            PurchaseLine.Validate(Quantity, LineQuantity);
            PurchaseLine.Validate("Direct Unit Cost", LineDirectUnitCost);
            if LineDeferralCode <> '' then
                PurchaseLine.Validate("Deferral Code", LineDeferralCode);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
        exit(true);
    end;

    /// <summary>
    /// Whether a review the agent requested is the review of what it prepared for the task: the draft of the task's
    /// source (v1) or the purchase invoice registered as the task's outcome (v2).
    /// </summary>
    internal procedure IsReviewOfTaskResult(AgentTaskId: BigInteger; ReviewRecordId: RecordId): Boolean
    var
        WorkItem: Codeunit "PA Work Item";
    begin
        if ReviewRecordId.TableNo() = 0 then
            exit(false);
        if not WorkItem.LoadByAgentTaskId(AgentTaskId) then
            exit(false);
        exit(WorkItem.IsResultRecord(ReviewRecordId));
    end;

    /// <summary>
    /// The semantic suggestion code offered when the agent cannot resolve a vendor.
    /// </summary>
    internal procedure GetCreateVendorSuggestionCode(): Code[20]
    var
        TempRequestDetails: Record "Agent User Int Request Details" temporary;
        TempSuggestion: Record "Agent Task User Int Suggestion" temporary;
        PAAgentTaskExecution: Codeunit "PA Agent Task Execution";
    begin
        PAAgentTaskExecution.GetAgentTaskUserInterventionSuggestions(TempRequestDetails, TempSuggestion);
        if TempSuggestion.FindFirst() then
            exit(TempSuggestion.Code);
        exit('');
    end;

    local procedure TryGetOutcomePurchaseInvoice(WorkItem: Codeunit "PA Work Item"; var PurchaseHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        Outcome: RecordId;
    begin
        Outcome := WorkItem.GetOutcome();
        if Outcome.TableNo <> Database::"Purchase Header" then begin
            ErrorText := StrSubstNo(PurchaseInvoiceOutcomeRequiredErr, WorkItem.GetAgentTaskId());
            exit(false);
        end;
        if not PurchaseHeader.Get(Outcome) then begin
            ErrorText := StrSubstNo(PurchaseInvoiceOutcomeRequiredErr, WorkItem.GetAgentTaskId());
            exit(false);
        end;
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then begin
            ErrorText := StrSubstNo(PurchaseInvoiceOutcomeRequiredErr, WorkItem.GetAgentTaskId());
            exit(false);
        end;
        exit(true);
    end;

    #endregion

    #region Evaluation diagnostics and cleanup

    /// <summary>
    /// Selects the Payables Agent version for the evaluation run; the persisted choice is visible to the agent's runtime sessions.
    /// It uses the V2 preview opt-in, which only takes effect in the designated preview tenant; requesting V2 elsewhere fails instead of silently evaluating V1.
    /// </summary>
    internal procedure PrepareEvaluationVersion(Version: Integer)
    begin
        if not (Version in [1, 2]) then
            Error(UnknownEvaluationVersionErr);
#if not CLEAN30
        SetV2PreviewSelected(Version = 2);
        if Versions.IsV2Active() <> (Version = 2) then
            Error(EvaluationVersionUnavailableErr, Version);
#else
        if Version <> 1 then
            Error(EvaluationVersionUnavailableErr, Version);
#endif
    end;

    /// <summary>
    /// Gets the version explicitly prepared by the evaluation harness, or 0 when none is prepared.
    /// </summary>
    internal procedure GetPreparedEvaluationVersion(): Integer
    begin
#if not CLEAN30
        if IsV2PreviewSelected() then
            exit(2);
#endif
        exit(0);
    end;

    /// <summary>
    /// Clears evaluation state in the test company before configuring the next run.
    /// This also deletes every E-Document and all E-Doc. Vendor Assign. History in that company.
    /// </summary>
    internal procedure ResetEvaluationState()
    begin
        DeleteAllTaskAndEDocumentDataForEvaluation();
#if not CLEAN30
        SetV2PreviewSelected(false);
#endif
    end;

#if not CLEAN30
#pragma warning disable AL0432
    local procedure SetV2PreviewSelected(Selected: Boolean)
    var
        Setup: Record "Payables Agent Setup";
    begin
        Setup.GetOrCreateSetup();
        if Selected then
            Setup."Preview Version" := Setup."Preview Version"::"V2 Preview"
        else
            Setup."Preview Version" := Setup."Preview Version"::" ";
        Setup.Modify();
    end;

    local procedure IsV2PreviewSelected(): Boolean
    var
        Setup: Record "Payables Agent Setup";
    begin
        if not Setup.TryGetSetup() then
            exit(false);
        exit(Setup."Preview Version" = Setup."Preview Version"::"V2 Preview");
    end;
#pragma warning restore AL0432
#endif

    /// <summary>
    /// Deletes V2 tasks, plus every E-Document and all E-Doc. Vendor Assign. History in the test company.
    /// Use only where company-wide E-Document cleanup is intended; this is not limited to Payables Agent documents.
    /// </summary>
    internal procedure DeleteAllTaskAndEDocumentDataForEvaluation()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        StoredWorkItem.DeleteAll(false);
        DraftBasedFixtures.DeleteAllEDocumentDataForEvaluation();
    end;

    /// <summary>
    /// Builds version-neutral failure diagnostics for one Payables Agent task.
    /// Returns false only when the Agent Framework task cannot be resolved as a Payables Agent task.
    /// </summary>
    internal procedure GetTaskDiagnosticEvidence(AgentTaskId: BigInteger; var Diagnostics: JsonObject): Boolean
    var
        WorkItem: Codeunit "PA Work Item";
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
        Outcome: RecordId;
        Errors: JsonArray;
        PurchaseInvoice: JsonObject;
        OutcomeStatus: Text;
        HasPurchaseInvoice: Boolean;
    begin
        Clear(Diagnostics);
        if not WorkItem.LoadByAgentTaskId(AgentTaskId) then
            exit(false);

        Diagnostics.Add('schemaVersion', 1);
        case Versions.GetVersion(WorkItem.GetId()) of
            1:
                Diagnostics.Add('paVersion', 'V1');
            2:
                Diagnostics.Add('paVersion', 'V2');
        end;
        Outcome := WorkItem.GetOutcome();
        if Outcome.TableNo <> 0 then begin
            HasPurchaseInvoice := BuildCreatedPurchaseInvoice(Outcome, PurchaseInvoice);
            if HasPurchaseInvoice then
                OutcomeStatus := 'InvoiceCreated'
            else begin
                OutcomeStatus := 'Unexpected';
                AddDiagnosticError(Errors, 'Outcome', StrSubstNo(UnexpectedOutcomeErr, Format(Outcome)));
            end;
        end else
            if Versions.GetVersion(WorkItem.GetId()) = 1 then begin
                OutcomeStatus := 'InvoiceProposed';
                HasPurchaseInvoice := DraftBasedFixtures.BuildProposedPurchaseInvoice(WorkItem, PurchaseInvoice, Errors);
            end else
                OutcomeStatus := 'None';

        Diagnostics.Add('outcomeStatus', OutcomeStatus);
        if HasPurchaseInvoice then
            Diagnostics.Add('purchaseInvoice', PurchaseInvoice)
        else
            AddNull(Diagnostics, 'purchaseInvoice');
        Diagnostics.Add('errors', Errors);
        exit(true);
    end;

    local procedure BuildCreatedPurchaseInvoice(Outcome: RecordId; var PurchaseInvoice: JsonObject): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
    begin
        Clear(PurchaseInvoice);
        case Outcome.TableNo of
            Database::"Purchase Header":
                if PurchaseHeader.Get(Outcome) then
                    if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then begin
                        BuildPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
                        exit(true);
                    end;
            Database::"Purch. Inv. Header":
                if PostedInvoice.Get(Outcome) then begin
                    BuildPostedPurchaseInvoice(PostedInvoice, PurchaseInvoice);
                    exit(true);
                end;
        end;
        exit(false);
    end;

    local procedure BuildPurchaseInvoice(PurchaseHeader: Record "Purchase Header"; var PurchaseInvoice: JsonObject)
    var
        PurchaseLine: Record "Purchase Line";
        Header: JsonObject;
        Lines: JsonArray;
        Totals: JsonObject;
        AmountExcludingTax, AmountIncludingTax : Decimal;
    begin
        Header.Add('number', PurchaseHeader."No.");
        AddTextOrNull(Header, 'vendorNo', PurchaseHeader."Buy-from Vendor No.");
        AddTextOrNull(Header, 'vendorName', PurchaseHeader."Buy-from Vendor Name");
        AddTextOrNull(Header, 'vendorInvoiceNo', PurchaseHeader."Vendor Invoice No.");
        AddDateOrNull(Header, 'documentDate', PurchaseHeader."Document Date");
        AddDateOrNull(Header, 'dueDate', PurchaseHeader."Due Date");
        Header.Add('currencyCode', PurchaseHeader."Currency Code");

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                Lines.Add(BuildPurchaseLine(PurchaseLine));
                AmountExcludingTax += PurchaseLine."Line Amount";
                AmountIncludingTax += PurchaseLine."Amount Including VAT";
            until PurchaseLine.Next() = 0;

        Totals.Add('amountExcludingTax', AmountExcludingTax);
        Totals.Add('taxAmount', AmountIncludingTax - AmountExcludingTax);
        Totals.Add('amountIncludingTax', AmountIncludingTax);
        PurchaseInvoice.Add('header', Header);
        PurchaseInvoice.Add('lines', Lines);
        PurchaseInvoice.Add('totals', Totals);
    end;

    local procedure BuildPostedPurchaseInvoice(PostedInvoice: Record "Purch. Inv. Header"; var PurchaseInvoice: JsonObject)
    var
        PostedInvoiceLine: Record "Purch. Inv. Line";
        Header: JsonObject;
        Lines: JsonArray;
        Totals: JsonObject;
        AmountExcludingTax, AmountIncludingTax : Decimal;
    begin
        Header.Add('number', PostedInvoice."No.");
        AddTextOrNull(Header, 'vendorNo', PostedInvoice."Buy-from Vendor No.");
        AddTextOrNull(Header, 'vendorName', PostedInvoice."Buy-from Vendor Name");
        AddTextOrNull(Header, 'vendorInvoiceNo', PostedInvoice."Vendor Invoice No.");
        AddDateOrNull(Header, 'documentDate', PostedInvoice."Document Date");
        AddDateOrNull(Header, 'dueDate', PostedInvoice."Due Date");
        Header.Add('currencyCode', PostedInvoice."Currency Code");

        PostedInvoiceLine.SetRange("Document No.", PostedInvoice."No.");
        if PostedInvoiceLine.FindSet() then
            repeat
                Lines.Add(BuildPostedPurchaseLine(PostedInvoiceLine));
                AmountExcludingTax += PostedInvoiceLine."Line Amount";
                AmountIncludingTax += PostedInvoiceLine."Amount Including VAT";
            until PostedInvoiceLine.Next() = 0;

        Totals.Add('amountExcludingTax', AmountExcludingTax);
        Totals.Add('taxAmount', AmountIncludingTax - AmountExcludingTax);
        Totals.Add('amountIncludingTax', AmountIncludingTax);
        PurchaseInvoice.Add('header', Header);
        PurchaseInvoice.Add('lines', Lines);
        PurchaseInvoice.Add('totals', Totals);
    end;

    local procedure BuildPurchaseLine(PurchaseLine: Record "Purchase Line"): JsonObject
    var
        Line: JsonObject;
    begin
        Line.Add('lineNo', PurchaseLine."Line No.");
        Line.Add('type', Format(PurchaseLine.Type));
        AddTextOrNull(Line, 'number', PurchaseLine."No.");
        AddTextOrNull(Line, 'description', PurchaseLine.Description);
        Line.Add('quantity', PurchaseLine.Quantity);
        AddTextOrNull(Line, 'unitOfMeasureCode', PurchaseLine."Unit of Measure Code");
        Line.Add('directUnitCostExcludingTax', PurchaseLine."Direct Unit Cost");
        Line.Add('lineAmountExcludingTax', PurchaseLine."Line Amount");
        Line.Add('taxPercent', PurchaseLine."VAT %");
        exit(Line);
    end;

    local procedure BuildPostedPurchaseLine(PostedInvoiceLine: Record "Purch. Inv. Line"): JsonObject
    var
        Line: JsonObject;
    begin
        Line.Add('lineNo', PostedInvoiceLine."Line No.");
        Line.Add('type', Format(PostedInvoiceLine.Type));
        AddTextOrNull(Line, 'number', PostedInvoiceLine."No.");
        AddTextOrNull(Line, 'description', PostedInvoiceLine.Description);
        Line.Add('quantity', PostedInvoiceLine.Quantity);
        AddTextOrNull(Line, 'unitOfMeasureCode', PostedInvoiceLine."Unit of Measure Code");
        Line.Add('directUnitCostExcludingTax', PostedInvoiceLine."Direct Unit Cost");
        Line.Add('lineAmountExcludingTax', PostedInvoiceLine."Line Amount");
        Line.Add('taxPercent', PostedInvoiceLine."VAT %");
        exit(Line);
    end;

    local procedure AddDiagnosticError(var Errors: JsonArray; ErrorType: Text; Message: Text)
    var
        DiagnosticError: JsonObject;
    begin
        DiagnosticError.Add('type', ErrorType);
        DiagnosticError.Add('message', Message);
        Errors.Add(DiagnosticError);
    end;

    local procedure AddTextOrNull(var Target: JsonObject; PropertyName: Text; Value: Text)
    begin
        if Value = '' then begin
            AddNull(Target, PropertyName);
            exit;
        end;
        Target.Add(PropertyName, Value);
    end;

    local procedure AddDateOrNull(var Target: JsonObject; PropertyName: Text; Value: Date)
    begin
        if Value = 0D then begin
            AddNull(Target, PropertyName);
            exit;
        end;
        Target.Add(PropertyName, Value);
    end;

    local procedure AddNull(var Target: JsonObject; PropertyName: Text)
    var
        NullToken: JsonToken;
    begin
        NullToken.ReadFrom('null');
        Target.Add(PropertyName, NullToken);
    end;

    #endregion

    #region Deterministic unit-test fixtures

    /// <summary>
    /// Fabricates receipt of an email by the currently implemented mailbox integration, without admitting it to the agent.
    /// The fixture owns the version-specific storage.
    /// </summary>
    internal procedure ReceiveEmail(SenderEmail: Text; Subject: Text; var WorkItem: Codeunit "PA Work Item"): Boolean
    var
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        exit(DraftBasedFixtures.ReceiveEmail(SenderEmail, Subject, WorkItem));
    end;

    /// <summary>
    /// Creates the semantic scenario used to verify the wrapper contract over a draft-based upload.
    /// Stored records and framework correlation details remain inside the compatibility fixture.
    /// </summary>
    internal procedure CreateDraftBasedUploadContractScenario(var WorkItem: Codeunit "PA Work Item"; var ExpectedResult: RecordId; var UnrelatedResult: RecordId): Boolean
    var
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        exit(DraftBasedFixtures.CreateUploadWorkItemContractScenario(WorkItem, ExpectedResult, UnrelatedResult));
    end;

    internal procedure SeedDraftBasedImporterEnabled()
    var
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        DraftBasedFixtures.SeedImporterEnabled();
    end;

    internal procedure IsDraftBasedImporterEnabled(): Boolean
    var
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        exit(DraftBasedFixtures.IsImporterEnabled());
    end;

    /// <summary>
    /// Loads the stored setup as the configuration to apply, in test mode: the mailbox is never contacted.
    /// </summary>
    /// <param name="CreateAgentUser">Whether applying the configuration creates and configures the agent user in the agent framework. Tests that only exercise the app's own state can skip it.</param>
    internal procedure LoadConfiguration(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; CreateAgentUser: Boolean)
    begin
        Clear(PASetupUpdateParameters);
        PASetupUpdateParameters.SetSkipAgentConfiguration(not CreateAgentUser);
        PASetupUpdateParameters.SetSkipEmailVerification(true);
        PASetupUpdateParameters.InitializeFromStoredSetup();
    end;

    /// <summary>
    /// Sets the desired mailbox configuration. Retained for setup-flow unit tests that exercise individual proposals.
    /// </summary>
    internal procedure SetEmailMonitoring(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; MonitorEmail: Boolean; EmailAccountId: Guid; ReviewPolicy: Enum "PA Email Review Policy")
    var
        DesiredSetup: Codeunit "PA Setup";
    begin
        PASetupUpdateParameters.CopyProposal(DesiredSetup);
        PASetupUpdateParameters.SetEmailMonitoring(MonitorEmail, ReviewPolicy, EmailAccountId, DesiredSetup.GetEmailFolder(), DesiredSetup.GetEmailFolderId());
    end;

    /// <summary>
    /// Applies a unit-test configuration with the agent enabled through the same flow as the setup page.
    /// </summary>
    internal procedure Activate(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
    begin
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Enabled;
        PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
        PASetupUpdate.Update(PASetupUpdateParameters);
    end;

    /// <summary>
    /// Brings the agent back to never having been configured and clears the stored setup.
    /// </summary>
    internal procedure Reset()
    var
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        PASetup: Codeunit "PA Setup";
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
    begin
        if PASetup.TryFindAgent(Agent) then begin
            // Unit-test cleanup must not reconfigure a live framework agent when the service is unavailable.
            LoadConfiguration(PASetupUpdateParameters, false);
            PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
            TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Disabled;
            PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
            PASetupUpdate.Update(PASetupUpdateParameters);
            if Agent.Get(Agent."User Security ID") then
                Agent.Delete();
        end;

        PASetup.LoadOrCreateSetup();
        PASetup.ResetProposal();
        PASetup.ApplySetup(false);
        PASetup.DeleteSetup(CopyStr(CompanyName(), 1, 30));
    end;

    /// <summary>
    /// Hands a received source that does not yet have an Agent Framework task to the intake flow.
    /// </summary>
    internal procedure AdmitWorkItem(var WorkItem: Codeunit "PA Work Item"): Boolean
    var
        Intake: Codeunit "PA Work Item Intake";
    begin
        exit(Intake.Admit(WorkItem));
    end;

    #endregion
}
