// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Vendor;
using System.Agents;

// Version-specific setup and user actions used by the version-neutral Payables Agent test fixture.
codeunit 3347 "PA Draft Based Test Fixtures"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TaskNotDraftBasedErr: Label 'Agent task %1 does not have a draft-based source.', Locked = true;
        VendorNotFoundErr: Label 'Vendor not found for the given name %1', Locked = true;
        AccountNotFoundErr: Label 'Account not found for the given code %1', Locked = true;
        PurchaseLineNotFoundErr: Label 'No E-Document Purchase Lines found for E-Document Entry No. %1.', Locked = true;
        DraftHeaderNotFoundErr: Label 'E-Document Purchase Header not found for E-Document Entry No. %1.', Locked = true;
        DraftLinesNotFoundErr: Label 'E-Document Purchase Lines not found for E-Document Entry No. %1.', Locked = true;

    /// <summary>
    /// Deletes every E-Document and all E-Doc. Vendor Assign. History in the test company,
    /// including records unrelated to Payables Agent. Use only for company-wide evaluation cleanup.
    /// </summary>
    internal procedure DeleteAllEDocumentDataForEvaluation()
    var
        EDocument: Record "E-Document";
        EDocVendorAssignHistory: Record "E-Doc. Vendor Assign. History";
    begin
        if EDocument.FindSet() then
            repeat
                EDocument.CleanupDocument();
                EDocument.Delete(false);
            until EDocument.Next() = 0;
        EDocVendorAssignHistory.DeleteAll(false);
    end;

    internal procedure BuildProposedPurchaseInvoice(Task: Codeunit "Payables Agent Task"; var PurchaseInvoice: JsonObject; var Errors: JsonArray): Boolean
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPOMatchWarning: Record "E-Doc PO Match Warning" temporary;
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        Header: JsonObject;
        Lines: JsonArray;
        Totals: JsonObject;
    begin
        Clear(PurchaseInvoice);
        if not EDocument.GetBySystemId(Task.GetSourceId()) then begin
            AddError(Errors, 'DataCollection', 'The draft-based source no longer exists.', 0);
            exit(false);
        end;
        if not EDocumentPurchaseHeader.Get(EDocument."Entry No") then begin
            AddError(Errors, 'DataCollection', StrSubstNo(DraftHeaderNotFoundErr, EDocument."Entry No"), 0);
            exit(false);
        end;

        AddNull(Header, 'number');
        AddTextOrNull(Header, 'vendorNo', EDocumentPurchaseHeader."[BC] Vendor No.");
        AddTextOrNull(Header, 'vendorName', EDocumentPurchaseHeader."Vendor Company Name");
        AddTextOrNull(Header, 'vendorInvoiceNo', EDocumentPurchaseHeader."Vendor Invoice No.");
        AddDateOrNull(Header, 'documentDate', EDocumentPurchaseHeader."Document Date");
        AddDateOrNull(Header, 'dueDate', EDocumentPurchaseHeader."Due Date");
        Header.Add('currencyCode', EDocumentPurchaseHeader."Currency Code");

        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarning);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                Lines.Add(BuildProposedLine(EDocumentPurchaseLine));
                AddPOMatchWarnings(EDocumentPurchaseLine, TempPOMatchWarning, Errors);
            until EDocumentPurchaseLine.Next() = 0
        else
            AddError(Errors, 'DataCollection', StrSubstNo(DraftLinesNotFoundErr, EDocument."Entry No"), 0);

        Totals.Add('amountExcludingTax', EDocumentPurchaseHeader."Sub Total");
        Totals.Add('taxAmount', EDocumentPurchaseHeader."Total VAT");
        Totals.Add('amountIncludingTax', EDocumentPurchaseHeader.Total);
        PurchaseInvoice.Add('header', Header);
        PurchaseInvoice.Add('lines', Lines);
        PurchaseInvoice.Add('totals', Totals);
        exit(true);
    end;

    internal procedure ReceiveEmail(SenderEmail: Text; Subject: Text; var PATaskSource: Codeunit "PA Task Source"): Boolean
    var
        EDocument: Record "E-Document";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        EDocument.Service := PADraftBasedSetup.GetOrCreateAgentEDocumentService().Code;
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument."Source Details" := CopyStr(SenderEmail, 1, MaxStrLen(EDocument."Source Details"));
        EDocument."Additional Source Details" := CopyStr(Subject, 1, MaxStrLen(EDocument."Additional Source Details"));
        EDocument."Outlook Mail Message Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Outlook Mail Message Id"));
        EDocument.Insert();
        exit(PATaskSource.Load(EDocument.SystemId));
    end;

    internal procedure CreateUploadTaskContractScenario(var PATaskSource: Codeunit "PA Task Source"; var Task: Codeunit "Payables Agent Task"; var ExpectedResult: RecordId; var UnrelatedResult: RecordId): Boolean
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        Document: Record "E-Document";
        OtherDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        Document.Service := PADraftBasedSetup.GetOrCreateAgentEDocumentService().Code;
        Document."Source Details" := 'fixture.pdf';
        Document.Insert();
        EDocumentPurchaseHeader."E-Document Entry No." := Document."Entry No";
        EDocumentPurchaseHeader."Vendor Company Name" := 'Fixture Vendor';
        EDocumentPurchaseHeader."Vendor Invoice No." := 'FIXTURE-INV';
        EDocumentPurchaseHeader."Document Date" := DMY2Date(1, 1, 2026);
        EDocumentPurchaseHeader."Currency Code" := 'EUR';
        EDocumentPurchaseHeader."Sub Total" := 20;
        EDocumentPurchaseHeader."Total VAT" := 5;
        EDocumentPurchaseHeader.Total := 25;
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := Document."Entry No";
        EDocumentPurchaseLine."Line No." := 10000;
        EDocumentPurchaseLine.Description := 'Fixture line';
        EDocumentPurchaseLine.Quantity := 2;
        EDocumentPurchaseLine."Unit Price" := 10;
        EDocumentPurchaseLine."Sub Total" := 20;
        EDocumentPurchaseLine."VAT Rate" := 25;
        EDocumentPurchaseLine.Insert();
        OtherDocument.Insert();
        if not PATaskSource.Load(Document.SystemId) then
            exit(false);

        AgentTask."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AgentTask."Company Name"));
        AgentTask."External ID" := Format(Document."Entry No");
        AgentTask.Insert();
        AgentTaskMessage.ID := CreateGuid();
        AgentTaskMessage."Task ID" := AgentTask.ID;
        AgentTaskMessage."External ID" := Format(Document."Entry No");
        AgentTaskMessage.Insert();
        if not Task.Load(AgentTask.ID) then
            exit(false);

        ExpectedResult := Document.RecordId();
        UnrelatedResult := OtherDocument.RecordId();
        exit(true);
    end;

    internal procedure SeedImporterEnabled()
    var
        Service: Record "E-Document Service";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        Service := PADraftBasedSetup.GetOrCreateAgentEDocumentService();
        Service."Auto Import" := true;
        Clear(Service."Import Recurrent Job Id");
        Service.Modify();
    end;

    internal procedure IsImporterEnabled(): Boolean
    var
        Service: Record "E-Document Service";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        Service := PADraftBasedSetup.GetOrCreateAgentEDocumentService();
        exit(Service."Auto Import");
    end;

    internal procedure SelectVendor(AgentTaskId: BigInteger; VendorName: Text; var ErrorText: Text): Boolean
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        Vendor: Record Vendor;
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        Clear(ErrorText);
        if not GetEDocument(AgentTaskId, EDocument) then begin
            ErrorText := StrSubstNo(TaskNotDraftBasedErr, AgentTaskId);
            exit(false);
        end;
        Vendor.SetRange(Name, VendorName);
        if not Vendor.FindFirst() then begin
            ErrorText := StrSubstNo(VendorNotFoundErr, VendorName);
            exit(false);
        end;

        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        EDocumentPurchaseHeader.Validate("[BC] Vendor No.", Vendor."No.");
        EDocumentPurchaseHeader.Modify(true);
        TempEDocImportParameters."Step to Run" := Enum::"Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        exit(true);
    end;

    internal procedure SelectAccount(AgentTaskId: BigInteger; AccountCode: Text; var ErrorText: Text): Boolean
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        GLAccount: Record "G/L Account";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        Clear(ErrorText);
        if not GetEDocument(AgentTaskId, EDocument) then begin
            ErrorText := StrSubstNo(TaskNotDraftBasedErr, AgentTaskId);
            exit(false);
        end;
        if not GLAccount.Get(AccountCode) then begin
            ErrorText := StrSubstNo(AccountNotFoundErr, AccountCode);
            exit(false);
        end;

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.IsEmpty() then begin
            ErrorText := StrSubstNo(PurchaseLineNotFoundErr, EDocument."Entry No");
            exit(false);
        end;
        EDocumentPurchaseLine.FindSet();
        repeat
            EDocumentPurchaseLine.Validate("[BC] Purchase Line Type", EDocumentPurchaseLine."[BC] Purchase Line Type"::"G/L Account");
            EDocumentPurchaseLine.Validate("[BC] Purchase Type No.", GLAccount."No.");
            EDocumentPurchaseLine.Modify(true);
        until EDocumentPurchaseLine.Next() = 0;

        TempEDocImportParameters."Step to Run" := Enum::"Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        exit(true);
    end;

    local procedure BuildProposedLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"): JsonObject
    var
        Line: JsonObject;
    begin
        Line.Add('lineNo', EDocumentPurchaseLine."Line No.");
        Line.Add('type', Format(EDocumentPurchaseLine."[BC] Purchase Line Type"));
        AddTextOrNull(Line, 'number', EDocumentPurchaseLine."[BC] Purchase Type No.");
        AddTextOrNull(Line, 'description', EDocumentPurchaseLine.Description);
        Line.Add('quantity', EDocumentPurchaseLine.Quantity);
        AddTextOrNull(Line, 'unitOfMeasureCode', EDocumentPurchaseLine."[BC] Unit of Measure");
        Line.Add('directUnitCostExcludingTax', EDocumentPurchaseLine."Unit Price");
        Line.Add('lineAmountExcludingTax', EDocumentPurchaseLine."Sub Total");
        Line.Add('taxPercent', EDocumentPurchaseLine."VAT Rate");
        exit(Line);
    end;

    local procedure AddPOMatchWarnings(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPOMatchWarning: Record "E-Doc PO Match Warning" temporary; var Errors: JsonArray)
    begin
        TempPOMatchWarning.Reset();
        TempPOMatchWarning.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        if TempPOMatchWarning.FindSet() then
            repeat
                AddError(Errors, 'POMatching', TempPOMatchWarning."Warning Message", EDocumentPurchaseLine."Line No.");
            until TempPOMatchWarning.Next() = 0;
    end;

    local procedure AddError(var Errors: JsonArray; ErrorType: Text; Message: Text; LineNo: Integer)
    var
        DiagnosticError: JsonObject;
    begin
        DiagnosticError.Add('type', ErrorType);
        DiagnosticError.Add('message', Message);
        if LineNo <> 0 then
            DiagnosticError.Add('lineNo', LineNo);
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

    local procedure GetEDocument(AgentTaskId: BigInteger; var EDocument: Record "E-Document"): Boolean
    var
        Task: Codeunit "Payables Agent Task";
    begin
        if not Task.Load(AgentTaskId) then
            exit(false);
        if Task.GetVersion() <> "PA Version"::V1 then
            exit(false);
        exit(EDocument.GetBySystemId(Task.GetSourceId()));
    end;
}
