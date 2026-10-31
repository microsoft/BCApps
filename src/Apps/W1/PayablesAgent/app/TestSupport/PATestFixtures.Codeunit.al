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
    Permissions = tabledata Agent = RD, tabledata "Agent Task" = R, tabledata "Payables Agent Task" = D;

    #region AI evaluation fixtures

    /// <summary>
    /// Ensures the product agent is activated through its normal setup flow and hands the PDF to intake.
    /// Test-environment Copilot capability activation and waiting for the runtime remain owned by the AI test app.
    /// </summary>
    var
        PASetupUpdate: Codeunit "PA Setup Update";
#if DEVELOPMENT
        DevelopmentSettings: Codeunit "PA Development Settings";
#endif
        TaskNotFoundErr: Label 'Agent task %1 does not work on a Payables Agent task.', Locked = true;
        VendorNotFoundErr: Label 'Vendor not found for the given name %1', Locked = true;
        AccountNotFoundErr: Label 'Account not found for the given code %1', Locked = true;
        PurchaseInvoiceOutcomeRequiredErr: Label 'Agent task %1 must have an existing purchase invoice registered as its outcome.', Locked = true;
        PurchaseLinesNotFoundErr: Label 'No purchase invoice lines were found for purchase invoice %1.', Locked = true;
        UnexpectedOutcomeErr: Label 'The task outcome %1 is not an existing purchase invoice.', Locked = true;
        UnknownEvaluationVersionErr: Label 'An evaluation must select version 1 or version 2 of the Payables Agent.';
#if not DEVELOPMENT
        EvaluationVersionUnavailableErr: Label 'Payables Agent version %1 is not available in this build.', Comment = '%1 = Payables Agent version';
#endif

    internal procedure EnsureActivatedAndCreateTaskFromPdf(FileName: Text; PdfInStream: InStream; var PATask: Codeunit "Payables Agent Task"): Boolean
    var
        PATaskIntake: Codeunit "PA Task Intake";
        AlreadyActivated: Boolean;
    begin
        PASetupUpdate.EnsureActivated(AlreadyActivated);
        exit(PATaskIntake.CreateTask(FileName, PdfInStream, PATask));
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
        Task: Codeunit "Payables Agent Task";
    begin
        Clear(ErrorText);
        if not Task.Load(AgentTaskId) then begin
            ErrorText := StrSubstNo(TaskNotFoundErr, AgentTaskId);
            exit(false);
        end;
        if Task.GetVersion() = "PA Version"::V1 then
            exit(DraftBasedFixtures.SelectVendor(AgentTaskId, VendorName, ErrorText));

        Vendor.SetRange(Name, VendorName);
        if not Vendor.FindFirst() then begin
            ErrorText := StrSubstNo(VendorNotFoundErr, VendorName);
            exit(false);
        end;
        if not TryGetOutcomePurchaseInvoice(Task, PurchaseHeader, ErrorText) then
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
        Task: Codeunit "Payables Agent Task";
        LineDeferralCode: Code[10];
        LineUnitOfMeasureCode: Code[10];
        LineDescription: Text[100];
        LineDirectUnitCost, LineQuantity : Decimal;
    begin
        Clear(ErrorText);
        if not Task.Load(AgentTaskId) then begin
            ErrorText := StrSubstNo(TaskNotFoundErr, AgentTaskId);
            exit(false);
        end;
        if Task.GetVersion() = "PA Version"::V1 then
            exit(DraftBasedFixtures.SelectAccount(AgentTaskId, AccountCode, ErrorText));

        if not GLAccount.Get(AccountCode) then begin
            ErrorText := StrSubstNo(AccountNotFoundErr, AccountCode);
            exit(false);
        end;
        if not TryGetOutcomePurchaseInvoice(Task, PurchaseHeader, ErrorText) then
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
        PATask: Codeunit "Payables Agent Task";
    begin
        if ReviewRecordId.TableNo() = 0 then
            exit(false);
        if not PATask.Load(AgentTaskId) then
            exit(false);
        exit(PATask.IsResultRecord(ReviewRecordId));
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

    local procedure TryGetOutcomePurchaseInvoice(Task: Codeunit "Payables Agent Task"; var PurchaseHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        Outcome: RecordId;
    begin
        Outcome := Task.GetOutcome();
        if Outcome.TableNo <> Database::"Purchase Header" then begin
            ErrorText := StrSubstNo(PurchaseInvoiceOutcomeRequiredErr, Task.GetAgentTaskId());
            exit(false);
        end;
        if not PurchaseHeader.Get(Outcome) then begin
            ErrorText := StrSubstNo(PurchaseInvoiceOutcomeRequiredErr, Task.GetAgentTaskId());
            exit(false);
        end;
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then begin
            ErrorText := StrSubstNo(PurchaseInvoiceOutcomeRequiredErr, Task.GetAgentTaskId());
            exit(false);
        end;
        exit(true);
    end;

    #endregion

    #region Evaluation diagnostics and cleanup

    /// <summary>
    /// Selects the Payables Agent version for the evaluation run. The persisted override is visible to the agent's separate runtime sessions.
    /// </summary>
    internal procedure PrepareEvaluationVersion(Version: Enum "PA Version")
    begin
        if Version = Version::Unknown then
            Error(UnknownEvaluationVersionErr);
#if DEVELOPMENT
        DevelopmentSettings.SetEvaluationVersionOverride(Version);
#else
        if Version <> Version::V1 then
            Error(EvaluationVersionUnavailableErr, Version);
#endif
    end;

    /// <summary>
    /// Gets the version explicitly prepared by the evaluation harness, or Unknown when no override is active.
    /// </summary>
    internal procedure GetPreparedEvaluationVersion(): Enum "PA Version"
    begin
#if DEVELOPMENT
        exit(DevelopmentSettings.GetEvaluationVersionOverride());
#else
        exit("PA Version"::Unknown);
#endif
    end;

    /// <summary>
    /// Clears evaluation state in the test company before configuring the next run.
    /// This also deletes every E-Document and all E-Doc. Vendor Assign. History in that company.
    /// </summary>
    internal procedure ResetEvaluationState()
    begin
        DeleteAllTaskAndEDocumentDataForEvaluation();
#if DEVELOPMENT
        DevelopmentSettings.ClearEvaluationVersionOverride();
#endif
    end;

    /// <summary>
    /// Deletes V2 tasks, plus every E-Document and all E-Doc. Vendor Assign. History in the test company.
    /// Use only where company-wide E-Document cleanup is intended; this is not limited to Payables Agent documents.
    /// </summary>
    internal procedure DeleteAllTaskAndEDocumentDataForEvaluation()
    var
        StoredTask: Record "Payables Agent Task";
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        StoredTask.DeleteAll(false);
        DraftBasedFixtures.DeleteAllEDocumentDataForEvaluation();
    end;

    /// <summary>
    /// Builds version-neutral failure diagnostics for one Payables Agent task.
    /// Returns false only when the Agent Framework task cannot be resolved as a Payables Agent task.
    /// </summary>
    internal procedure GetTaskDiagnosticEvidence(AgentTaskId: BigInteger; var Diagnostics: JsonObject): Boolean
    var
        Task: Codeunit "Payables Agent Task";
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
        Outcome: RecordId;
        Errors: JsonArray;
        PurchaseInvoice: JsonObject;
        OutcomeStatus: Text;
        HasPurchaseInvoice: Boolean;
    begin
        Clear(Diagnostics);
        if not Task.Load(AgentTaskId) then
            exit(false);

        Diagnostics.Add('schemaVersion', 1);
        Diagnostics.Add('paVersion', Format(Task.GetVersion()));
        Outcome := Task.GetOutcome();
        if Outcome.TableNo <> 0 then begin
            HasPurchaseInvoice := BuildCreatedPurchaseInvoice(Outcome, PurchaseInvoice);
            if HasPurchaseInvoice then
                OutcomeStatus := 'InvoiceCreated'
            else begin
                OutcomeStatus := 'Unexpected';
                AddDiagnosticError(Errors, 'Outcome', StrSubstNo(UnexpectedOutcomeErr, Format(Outcome)));
            end;
        end else
            if Task.GetVersion() = "PA Version"::V1 then begin
                OutcomeStatus := 'InvoiceProposed';
                HasPurchaseInvoice := DraftBasedFixtures.BuildProposedPurchaseInvoice(Task, PurchaseInvoice, Errors);
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
    /// The fixture owns the integration-specific backing representation.
    /// </summary>
    internal procedure ReceiveEmail(SenderEmail: Text; Subject: Text; var PATaskSource: Codeunit "PA Task Source"): Boolean
    var
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        exit(DraftBasedFixtures.ReceiveEmail(SenderEmail, Subject, PATaskSource));
    end;

    /// <summary>
    /// Creates the semantic scenario used to verify the wrapper contract over a draft-based upload.
    /// Backing records and framework correlation details remain inside the compatibility fixture.
    /// </summary>
    internal procedure CreateDraftBasedUploadContractScenario(var PATaskSource: Codeunit "PA Task Source"; var Task: Codeunit "Payables Agent Task"; var ExpectedResult: RecordId; var UnrelatedResult: RecordId): Boolean
    var
        DraftBasedFixtures: Codeunit "PA Draft Based Test Fixtures";
    begin
        exit(DraftBasedFixtures.CreateUploadTaskContractScenario(PATaskSource, Task, ExpectedResult, UnrelatedResult));
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
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        PASetupUpdateParameters.SetMonitorEmail(MonitorEmail);
        PASetupUpdateParameters.SetEmailReviewPolicy(ReviewPolicy);
        PASetupUpdateParameters.SetMailboxSelection(EmailAccountId, DesiredSetup.GetEmailFolder(), DesiredSetup.GetEmailFolderId());
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
            LoadConfiguration(PASetupUpdateParameters, true);
            PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
            TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Disabled;
            PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
            PASetupUpdate.Update(PASetupUpdateParameters);
            if Agent.Get(Agent."User Security ID") then
                Agent.Delete();
        end;

        PASetup.GetSetup();
        PASetup.ResetProposal();
        PASetup.ApplySetup(false);
        PASetup.DeleteSetup(CopyStr(CompanyName(), 1, 30));
    end;

    /// <summary>
    /// Hands a received source that does not yet have an Agent Framework task to the intake flow.
    /// </summary>
    internal procedure StartSource(var PATaskSource: Codeunit "PA Task Source"; var PATask: Codeunit "Payables Agent Task"): Boolean
    var
        PATaskIntake: Codeunit "PA Task Intake";
    begin
        exit(PATaskIntake.CreateTask(PATaskSource, PATask));
    end;

    #endregion
}
