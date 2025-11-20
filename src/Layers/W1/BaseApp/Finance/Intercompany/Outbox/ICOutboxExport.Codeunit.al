// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Company;
using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Email;
using System.Environment;
using System.IO;
using System.Telemetry;
using System.Utilities;
using Microsoft.Intercompany.Inbox;

codeunit 431 "IC Outbox Export"
{
    TableNo = "IC Outbox Transaction";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnRunOnBeforeConfirmGetResponseOrDefault(IsHandled, Rec);
        if not IsHandled then
            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                exit;

        FeatureTelemetry.LogUptake('0000ILC', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000ILE', ICMapping.GetFeatureTelemetryName(), 'IC Outbox Export');
        RunOutboxTransactions(Rec);
    end;

    var
        CompanyInfo: Record "Company Information";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        FileMgt: Codeunit "File Management";
        ClientTypeManagement: Codeunit "Client Type Management";

#pragma warning disable AA0074
        Text003: Label 'Do you want to complete line actions?';
#pragma warning restore AA0074
        FolderPathMissingErr: Label 'Folder Path must have a value in IC Partner: Code=%1. It cannot be zero or empty.', Comment = '%1=Intercompany Code';
        EmailAddressMissingErr: Label 'Email Address must have a value in IC Partner: Code=%1. It cannot be zero or empty.', Comment = '%1=Intercompany Code';

    [Scope('OnPrem')]
    procedure RunOutboxTransactions(var ICOutboxTransaction: Record "IC Outbox Transaction")
    var
        CopyICOutboxTransaction: Record "IC Outbox Transaction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunOutboxTransactions(ICOutboxTransaction, IsHandled);
        if IsHandled then
            exit;

        FeatureTelemetry.LogUptake('0000ILD', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000ILF', ICMapping.GetFeatureTelemetryName(), 'Run Outbox Transaction');

        CompanyInfo.Get();
        CopyICOutboxTransaction.Copy(ICOutboxTransaction);
        CopyICOutboxTransaction.SetRange("Line Action",
          CopyICOutboxTransaction."Line Action"::"Send to IC Partner");
        UpdateICStatus(CopyICOutboxTransaction);
        OnRunOutboxTransactionsOnBeforeSend(CopyICOutboxTransaction);
        SendToExternalPartner(CopyICOutboxTransaction);
        SendToInternalPartner(CopyICOutboxTransaction);
        CopyICOutboxTransaction.SetRange("Line Action",
          CopyICOutboxTransaction."Line Action"::"Return to Inbox");
        ReturnToInbox(CopyICOutboxTransaction);
        CancelTransaction(CopyICOutboxTransaction);
    end;

    local procedure ModifyAndRunOutboxTransactionNo(ICOutboxTransactionNo: Integer)
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        ICOutboxTransaction.SetRange("Transaction No.", ICOutboxTransactionNo);
        if ICOutboxTransaction.FindFirst() then begin
            ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::"Send to IC Partner";
            ICOutboxTransaction.Modify();
            RunOutboxTransactions(ICOutboxTransaction);
        end;
    end;

    procedure ProcessAutoSendOutboxTransactionNo(ICOutboxTransactionNo: Integer)
    var
        ICSetup: Record "IC Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessAutoSendOutboxTransactionNo(ICOutboxTransactionNo, IsHandled);
        if IsHandled then
            exit;

        ICSetup.Get();
        if ICSetup."Auto. Send Transactions" then
            ModifyAndRunOutboxTransactionNo(ICOutboxTransactionNo);
    end;

    procedure SendToExternalPartner(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        ICPartner: Record "IC Partner";
        EmailItem: Record "Email Item";
        DocumentMailing: Codeunit "Document-Mailing";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        InStream: InStream;
        OFile: File;
        FileName: Text;
        ICPartnerFilter: Text[1024];
        i: Integer;
        ToName: Text[100];
        CcName: Text[100];
        OutFileName: Text;
        IsHandled: Boolean;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        IsHandled := false;
        OnBeforeSendToExternalPartner(ICOutboxTrans, IsHandled);
        if IsHandled then
            exit;

        if GenJnlPostPreview.IsActive() then
            exit;

        ICPartner.SetFilter("Inbox Type", '<>%1', ICPartner."Inbox Type"::Database);
        ICPartnerFilter := ICOutboxTrans.GetFilter("IC Partner Code");
        if ICPartnerFilter <> '' then
            ICPartner.SetFilter(Code, ICPartnerFilter);
        OnSendToExternalPartnerOnBeforeICPartnerFindset(ICPartner);
        if ICPartner.Find('-') then
            repeat
                ICOutboxTrans.SetRange("IC Partner Code", ICPartner.Code);
                if ICOutboxTrans.Find('-') then begin
                    if (ICPartner."Inbox Type" = ICPartner."Inbox Type"::"File Location") and not IsWebClient() then begin
                        ICPartner.TestField(Blocked, false);
                        if ICPartner."Inbox Details" = '' then
                            Error(FolderPathMissingErr, ICPartner.Code);
                        i := 1;
                        while i <> 0 do begin
                            FileName :=
                              StrSubstNo('%1\%2_%3_%4.xml', ICPartner."Inbox Details", ICPartner.Code, ICOutboxTrans."Transaction No.", i);
                            if Exists(FileName) then
                                i := i + 1
                            else
                                i := 0;
                        end;
                    end else begin
                        OFile.CreateTempFile();
                        FileName := StrSubstNo('%1.%2.xml', OFile.Name, ICPartner.Code);
                        OFile.Close();
                    end;

                    ExportOutboxTransaction(ICOutboxTrans, FileName);

                    if IsWebClient() then begin
                        OutFileName := StrSubstNo('%1_%2.xml', ICPartner.Code, ICOutboxTrans."Transaction No.");
                        if not AddBatchProcessingArtifact(FileName, CopyStr(OutFileName, 1, 1024)) then
                            Download(FileName, '', '', '', OutFileName)
                    end else
                        FileName := FileMgt.DownloadTempFile(FileName);

                    if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Email then begin
                        ICPartner.TestField(Blocked, false);
                        if ICPartner."Inbox Details" = '' then
                            Error(EmailAddressMissingErr, ICPartner.Code);
                        ToName := ICPartner."Inbox Details";
                        if StrPos(ToName, ';') > 0 then begin
                            CcName := CopyStr(ToName, StrPos(ToName, ';') + 1);
                            ToName := CopyStr(ToName, 1, StrPos(ToName, ';') - 1);
                            if StrPos(CcName, ';') > 0 then
                                CcName := CopyStr(CcName, 1, StrPos(CcName, ';') - 1);
                        end;

                        if IsWebClient() then begin
                            EmailItem."Send to" := ICPartner."Inbox Details";
                            EmailItem.Subject := StrSubstNo('%1 %2', ICOutboxTrans."Document Type", ICOutboxTrans."Document No.");
                            Commit();

                            OFile.Open(FileName);
                            OFile.CreateInStream(InStream);

                            SourceTableIDs.Add(Database::"IC Outbox Transaction");
                            SourceIDs.Add(ICOutboxTrans.SystemId);
                            SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

                            SourceTableIDs.Add(Database::"IC Partner");
                            SourceIDs.Add(ICPartner.SystemId);
                            SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());

                            DocumentMailing.EnqueueEmailFile(
                              InStream,
                              StrSubstNo('%1.xml', ICPartner.Code),
                              ICOutboxTrans."Document No.",
                              EmailItem."Send to",
                              EmailItem.Subject,
                              true,
                              5, // S.Test
                              SourceTableIDs,
                              SourceIDs,
                              SourceRelationTypes);
                        end;
                    end;
                    OnSendToExternalPartnerOnAfterDocWasSent(ICPartner, FileName);
                    ICOutboxTrans.Find('-');
                    repeat
                        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTrans);
                    until ICOutboxTrans.Next() = 0;
                end;
            until ICPartner.Next() = 0;
        ICOutboxTrans.SetRange("IC Partner Code");
        if ICPartnerFilter <> '' then
            ICOutboxTrans.SetFilter("IC Partner Code", ICPartnerFilter);
    end;

    local procedure AddBatchProcessingArtifact(FilePath: Text; ArtifactName: Text[1024]): Boolean
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        BatchProcessingArtifactType: Enum "Batch Processing Artifact Type";
    begin
        if not BatchProcessingMgt.IsActive() then
            exit(false);

        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);

        BatchProcessingMgt.AddArtifact(BatchProcessingArtifactType::"IC Output File", ArtifactName, TempBlob);

        exit(true);
    end;

    procedure DownloadBatchFiles(DownloadFileName: Text)
    var
        TempBatchProcessingArtifact: Record "Batch Processing Artifact" temporary;
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        DataCompression: Codeunit "Data Compression";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        InStreamVar: InStream;
        OutStreamVar: OutStream;
        BatchProcessingArtifactType: Enum "Batch Processing Artifact Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadBatchFiles(IsHandled);
        if IsHandled then
            exit;

        if not BatchProcessingMgt.IsActive() then
            exit;

        if not BatchProcessingMgt.GetArtifacts(BatchProcessingArtifactType::"IC Output File", TempBatchProcessingArtifact) then
            exit;

        DataCompression.CreateZipArchive();

        TempBatchProcessingArtifact.FindSet();
        repeat
            Clear(InStreamVar);
            Clear(TempBlob);
            TempBlob.FromRecord(TempBatchProcessingArtifact, TempBatchProcessingArtifact.FieldNo("Artifact Value"));
            TempBlob.CreateInStream(InStreamVar);
            DataCompression.AddEntry(InStreamVar, TempBatchProcessingArtifact."Artifact Name");
        until TempBatchProcessingArtifact.Next() = 0;


        Clear(InStreamVar);
        Clear(TempBlob);

        TempBlob.CreateOutStream(OutStreamVar);

        DataCompression.SaveZipArchive(OutStreamVar);
        DataCompression.CloseZipArchive();

        TempBlob.CreateInStream(InStreamVar);

        FileManagement.DownloadFromStreamHandler(InStreamVar, '', '', '', DownloadFileName);
    end;

    procedure SendToInternalPartner(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        ICPartner: Record "IC Partner";
        TempAllPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary;
        TempAllPartnerHandledICInboxTrans: Record "Handled IC Inbox Trans." temporary;
        MoveICTransToPartnerCompany: Report "Move IC Trans. to Partner Comp";
        ICPartnerCodeList: List of [Text];
        IsHandled: Boolean;
    begin
        if ICOutboxTrans.Find('-') then
            repeat
                ICPartner.Get(ICOutboxTrans."IC Partner Code");
                ICPartner.TestField(Blocked, false);
                if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then begin
                    ICPartner.TestField("Inbox Details");
                    ICOutboxTrans.SetRange("Transaction No.", ICOutboxTrans."Transaction No.");
                    IsHandled := false;
                    OnSendToInternalPartnerOnBeforeMoveICTransToPartnerCompany(ICOutboxTrans, IsHandled);
                    if not IsHandled then begin
                        MoveICTransToPartnerCompany.Initialize(ICPartnerCodeList, TempAllPartnerICInboxTransaction, TempAllPartnerHandledICInboxTrans);
                        MoveICTransToPartnerCompany.SetTableView(ICOutboxTrans);
                        MoveICTransToPartnerCompany.UseRequestPage := false;
                        MoveICTransToPartnerCompany.Run();
                    end;
                    ICOutboxTrans.SetRange("Transaction No.");
                    if ICOutboxTrans."Line Action" = ICOutboxTrans."Line Action"::"Send to IC Partner" then
                        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTrans);
                end;
            until ICOutboxTrans.Next() = 0;
    end;

    procedure ReturnToInbox(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        ICPartner: Record "IC Partner";
        MoveICTransToPartnerCompany: Report "Move IC Trans. to Partner Comp";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReturnToInbox(ICOutboxTrans, IsHandled);
        if IsHandled then
            exit;

        if ICOutboxTrans.Find('-') then
            repeat
                if ICPartner.Get(ICOutboxTrans."IC Partner Code") then
                    ICPartner.TestField(Blocked, false);
                MoveICTransToPartnerCompany.RecreateInboxTrans(ICOutboxTrans);
                ICOutboxTrans.Delete(true);
            until ICOutboxTrans.Next() = 0;
    end;

    procedure CancelTransaction(var ICOutboxTrans: Record "IC Outbox Transaction")
    begin
        ICOutboxTrans.SetRange("Line Action", ICOutboxTrans."Line Action"::Cancel);
        if ICOutboxTrans.Find('-') then
            repeat
                ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTrans);
            until ICOutboxTrans.Next() = 0;
    end;

    procedure UpdateICStatus(var ICOutboxTransaction: Record "IC Outbox Transaction")
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        if ICOutboxTransaction.FindSet() then
            repeat
                if ICOutboxTransaction."IC Source Type" = ICOutboxTransaction."IC Source Type"::"Purchase Document" then
                    case ICOutboxTransaction."Document Type" of
                        ICOutboxTransaction."Document Type"::Order:
                            if PurchHeader.Get(PurchHeader."Document Type"::Order, ICOutboxTransaction."Document No.") then begin
                                PurchHeader.Validate("IC Status", PurchHeader."IC Status"::Sent);
                                PurchHeader.Modify();
                            end;
                        ICOutboxTransaction."Document Type"::"Return Order":
                            if PurchHeader.Get(PurchHeader."Document Type"::"Return Order", ICOutboxTransaction."Document No.") then begin
                                PurchHeader.Validate("IC Status", PurchHeader."IC Status"::Sent);
                                PurchHeader.Modify();
                            end;
                    end
                else
                    if ICOutboxTransaction."IC Source Type" = ICOutboxTransaction."IC Source Type"::"Sales Document" then
                        case ICOutboxTransaction."Document Type" of
                            ICOutboxTransaction."Document Type"::Order:
                                if SalesHeader.Get(SalesHeader."Document Type"::Order, ICOutboxTransaction."Document No.") then begin
                                    SalesHeader.Validate("IC Status", SalesHeader."IC Status"::Sent);
                                    SalesHeader.Modify();
                                end;
                            ICOutboxTransaction."Document Type"::"Return Order":
                                if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", ICOutboxTransaction."Document No.") then begin
                                    SalesHeader.Validate("IC Status", SalesHeader."IC Status"::Sent);
                                    SalesHeader.Modify();
                                end;
                        end;
                OnUpdateICStatusOnAfterLoopIteration(ICOutboxTransaction);
            until ICOutboxTransaction.Next() = 0
    end;

    local procedure ExportOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; var FileName: Text)
    var
        ICOutboxImpExpXML: XMLport "IC Outbox Imp/Exp";
        OFile: File;
        OStr: OutStream;
        IsHandled: Boolean;
    begin
        OFile.Create(FileName);
        OFile.CreateOutStream(OStr);

        IsHandled := false;
        OnBeforeExportOutboxTransaction(ICOutboxTransaction, OStr, IsHandled);
        if IsHandled then
            exit;

        ICOutboxImpExpXML.SetICOutboxTrans(ICOutboxTransaction);
        ICOutboxImpExpXML.SetDestination(OStr);
        ICOutboxImpExpXML.Export();

        OFile.Close();
        Clear(OStr);
        Clear(ICOutboxImpExpXML);
    end;

    local procedure IsWebClient(): Boolean
    begin
        exit(ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop]);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; OutStr: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnToInbox(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunOutboxTransactions(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendToExternalPartner(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateICStatusOnAfterLoopIteration(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOutboxTransactionsOnBeforeSend(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadBatchFiles(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeConfirmGetResponseOrDefault(var IsHandled: Boolean; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToExternalPartnerOnAfterDocWasSent(ICPartner: Record "IC Partner"; FileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToInternalPartnerOnBeforeMoveICTransToPartnerCompany(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessAutoSendOutboxTransactionNo(var ICOutboxTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToExternalPartnerOnBeforeICPartnerFindset(var ICPartner: Record "IC Partner")
    begin
    end;
}

