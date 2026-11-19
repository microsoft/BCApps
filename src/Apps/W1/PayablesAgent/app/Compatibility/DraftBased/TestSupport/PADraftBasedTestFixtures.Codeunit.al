// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Document;
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

    internal procedure BuildProposedPurchaseInvoice(WorkItem: Codeunit "PA Work Item"; var PurchaseInvoice: JsonObject; var Errors: JsonArray): Boolean
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
        if not EDocument.GetBySystemId(WorkItem.GetId()) then begin
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

    internal procedure GetTaskInfotipSources(WorkItem: Codeunit "PA Work Item"; var Sources: JsonArray)
    var
        EDocument: Record "E-Document";
        DraftHeader: Record "E-Document Purchase Header";
        DraftLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        TempMatchedLine: Record "Purchase Line" temporary;
        TempTarget: Record "Purchase Line" temporary;
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        Context: JsonObject;
    begin
        EDocument.GetBySystemId(WorkItem.GetId());
        DraftHeader.Get(EDocument."Entry No");
        Context.Add('eDocumentEntryNo', DraftHeader."E-Document Entry No.");
        Context.Add('invoiceNo', DraftHeader."Sales Invoice No.");
        AddInfotipSource(DraftHeader, Context, Sources);
        if DraftHeader."[BC] Vendor No." <> '' then begin
            Vendor.Get(DraftHeader."[BC] Vendor No.");
            Clear(Context);
            Context.Add('no', Vendor."No.");
            Context.Add('name', Vendor.Name);
            AddInfotipSource(Vendor, Context, Sources);
        end;
        DraftLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not DraftLine.FindSet() then
            Error(DraftLinesNotFoundErr, EDocument."Entry No");
        repeat
            Clear(Context);
            Context.Add('eDocumentEntryNo', DraftLine."E-Document Entry No.");
            Context.Add('lineNo', DraftLine."Line No.");
            Context.Add('description', DraftLine.Description);
            AddInfotipSource(DraftLine, Context, Sources);
            EDocPOMatching.LoadPOLinesMatchedToEDocumentLine(DraftLine, TempMatchedLine);
            if TempMatchedLine.FindSet() then
                repeat
                    if PurchaseLine.Get(TempMatchedLine."Document Type", TempMatchedLine."Document No.", TempMatchedLine."Line No.") then
                        if not TempTarget.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then begin
                            TempTarget := PurchaseLine;
                            TempTarget.Insert(false, true);
                        end;
                until TempMatchedLine.Next() = 0;
        until DraftLine.Next() = 0;
        if TempTarget.FindSet() then
            repeat
                PurchaseLine.Get(TempTarget."Document Type", TempTarget."Document No.", TempTarget."Line No.");
                Clear(Context);
                Context.Add('documentType', Format(PurchaseLine."Document Type"));
                Context.Add('documentNo', PurchaseLine."Document No.");
                Context.Add('lineNo', PurchaseLine."Line No.");
                Context.Add('description', PurchaseLine.Description);
                AddInfotipSource(PurchaseLine, Context, Sources);
            until TempTarget.Next() = 0;
    end;

    local procedure AddInfotipSource(SourceRecord: RecordRef; Context: JsonObject; var Sources: JsonArray)
    var
        Descriptor: JsonObject;
        SourceSystemId: Guid;
    begin
        SourceSystemId := SourceRecord.Field(SourceRecord.SystemIdNo()).Value;
        Descriptor.Add('tableId', SourceRecord.Number());
        Descriptor.Add('systemId', SourceSystemId);
        Descriptor.Add('context', Context);
        Sources.Add(Descriptor);
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

    internal procedure CreateMatchedDraftForTest(AgentTaskId: BigInteger; VendorNo: Code[20]; PurchaseLineSystemId: Guid)
    var
        EDocument: Record "E-Document";
        DraftHeader: Record "E-Document Purchase Header";
        DraftLine: Record "E-Document Purchase Line";
        WorkingMatch: Record "E-Doc. Purchase Line PO Match";
        AgentTask: Record "Agent Task";
        DraftBasedSetupStore: Codeunit "PA Draft Based Setup Store";
        LineNo: Integer;
    begin
        EDocument.Service := DraftBasedSetupStore.GetOrCreateService().Code;
        EDocument.Insert();
        DraftHeader."E-Document Entry No." := EDocument."Entry No";
        DraftHeader."[BC] Vendor No." := VendorNo;
        DraftHeader."Sales Invoice No." := 'SOURCE-INVOICE';
        DraftHeader.Insert();
        for LineNo := 1 to 2 do begin
            DraftLine.Init();
            DraftLine."E-Document Entry No." := EDocument."Entry No";
            DraftLine."Line No." := LineNo * 10000;
            DraftLine.Description := 'Actual draft source';
            DraftLine.Insert();
            Clear(WorkingMatch);
            WorkingMatch."E-Doc. Purchase Line SystemId" := DraftLine.SystemId;
            WorkingMatch."Purchase Line SystemId" := PurchaseLineSystemId;
            WorkingMatch.Insert();
            WorkingMatch."Receipt Line SystemId" := CreateGuid();
            WorkingMatch.Insert();
        end;
        AgentTask.Get(AgentTaskId);
        AgentTask."External ID" := Format(EDocument."Entry No");
        AgentTask.Modify();
    end;

    internal procedure FinalizeDraftMatchesForTest(AgentTaskId: BigInteger)
    var
        EDocument: Record "E-Document";
        DraftLine: Record "E-Document Purchase Line";
        WorkingMatch: Record "E-Doc. Purchase Line PO Match";
        FinalizedMatch: Record "E-Doc. Finalized PO Match";
    begin
        if not GetEDocument(AgentTaskId, EDocument) then
            Error(TaskNotDraftBasedErr, AgentTaskId);
        DraftLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        DraftLine.FindSet();
        repeat
            WorkingMatch.SetRange("E-Doc. Purchase Line SystemId", DraftLine.SystemId);
            if WorkingMatch.FindSet() then
                repeat
                    FinalizedMatch.Init();
                    FinalizedMatch."E-Doc. Purchase Line SystemId" := WorkingMatch."E-Doc. Purchase Line SystemId";
                    FinalizedMatch."Purchase Line SystemId" := WorkingMatch."Purchase Line SystemId";
                    FinalizedMatch."Receipt Line SystemId" := WorkingMatch."Receipt Line SystemId";
                    FinalizedMatch.Insert();
                until WorkingMatch.Next() = 0;
            WorkingMatch.DeleteAll();
        until DraftLine.Next() = 0;
        EDocument.Status := EDocument.Status::Processed;
        EDocument.Modify();
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
        DraftBasedWorkItem: Codeunit "PA Draft Based Work Item";
    begin
        if not DraftBasedWorkItem.LoadForAgentTask(AgentTaskId) then
            exit(false);
        exit(EDocument.GetBySystemId(DraftBasedWorkItem.GetId()));
    end;
}
