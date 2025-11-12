// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using System.IO;
using System.Telemetry;

codeunit 435 "IC Inbox Import"
{
    TableNo = "IC Inbox Transaction";

    trigger OnRun()
    var
        ICSetup: Record "IC Setup";
        TempICOutboxTrans: Record "IC Outbox Transaction" temporary;
        TempICOutboxJnlLine: Record "IC Outbox Jnl. Line" temporary;
        TempICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary;
        TempICOutboxSalesHeader: Record "IC Outbox Sales Header" temporary;
        TempICOutboxSalesLine: Record "IC Outbox Sales Line" temporary;
        TempICOutboxPurchaseHeader: Record "IC Outbox Purchase Header" temporary;
        TempICOutboxPurchaseLine: Record "IC Outbox Purchase Line" temporary;
        TempICDocDim: Record "IC Document Dimension" temporary;
        TempAllPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary;
        TempAllPartnerHandledICInboxTrans: Record "Handled IC Inbox Trans." temporary;
        ICInboxJnlLine: Record "IC Inbox Jnl. Line";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
        ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICInboxDocDim: Record "IC Document Dimension";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        FileMgt: Codeunit "File Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        FileName: Text;
        FromICPartnerCode: Code[20];
        NewTableID: Integer;
        ICPartnerCodeList: List of [Text];
    begin
        FeatureTelemetry.LogUptake('0000IKQ', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKR', ICMapping.GetFeatureTelemetryName(), 'IC Inbox Import');

        ICSetup.Get();
        ICSetup.TestField("IC Partner Code");

        if ClientFileName <> '' then
            FileName := ClientFileName
        else
            FileName := FileMgt.UploadFile(ChooseFileTitleMsg, '');

        if FileName = '' then
            Error(EnterFileNameErr);

        ImportInboxTransaction(
          ICSetup,
          TempICOutboxTrans, TempICOutboxJnlLine, TempICInboxOutboxJnlLineDim, TempICOutboxSalesHeader, TempICOutboxSalesLine,
          TempICOutboxPurchaseHeader, TempICOutboxPurchaseLine, TempICDocDim, FromICPartnerCode, FileName);

        if TempICOutboxTrans.Find('-') then
            repeat
                ICInboxOutboxMgt.OutboxTransToInboxOptimized(TempICOutboxTrans, Rec, FromICPartnerCode, ICPartnerCodeList, TempAllPartnerICInboxTransaction, TempAllPartnerHandledICInboxTrans);

                TempICOutboxJnlLine.SetRange("Transaction No.", TempICOutboxTrans."Transaction No.");
                TempICOutboxJnlLine.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                TempICOutboxJnlLine.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                if TempICOutboxJnlLine.Find('-') then
                    repeat
                        ICInboxOutboxMgt.OutboxJnlLineToInbox(Rec, TempICOutboxJnlLine, ICInboxJnlLine);
                        TempICInboxOutboxJnlLineDim.SetRange("Transaction No.", TempICOutboxTrans."Transaction No.");
                        TempICInboxOutboxJnlLineDim.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                        TempICInboxOutboxJnlLineDim.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                        TempICInboxOutboxJnlLineDim.SetRange("Line No.", ICInboxJnlLine."Line No.");
                        if TempICInboxOutboxJnlLineDim.Find('-') then
                            repeat
                                ICInboxOutboxMgt.OutboxJnlLineDimToInbox(
                                  ICInboxJnlLine, TempICInboxOutboxJnlLineDim, ICInboxOutboxJnlLineDim, DATABASE::"IC Inbox Jnl. Line");
                            until TempICInboxOutboxJnlLineDim.Next() = 0;
                    until TempICOutboxJnlLine.Next() = 0;

                TempICOutboxSalesHeader.SetRange("IC Transaction No.", TempICOutboxTrans."Transaction No.");
                TempICOutboxSalesHeader.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                TempICOutboxSalesHeader.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                if TempICOutboxSalesHeader.Find('-') then
                    repeat
                        ICInboxOutboxMgt.OutboxSalesHdrToInbox(Rec, TempICOutboxSalesHeader, ICInboxPurchaseHeader);
                    until TempICOutboxSalesHeader.Next() = 0;

                TempICOutboxSalesLine.SetRange("IC Transaction No.", TempICOutboxTrans."Transaction No.");
                TempICOutboxSalesLine.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                TempICOutboxSalesLine.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                if TempICOutboxSalesLine.Find('-') then
                    repeat
                        ICInboxOutboxMgt.OutboxSalesLineToInbox(Rec, TempICOutboxSalesLine, ICInboxPurchaseLine);
                    until TempICOutboxSalesLine.Next() = 0;

                TempICOutboxPurchaseHeader.SetRange("IC Transaction No.", TempICOutboxTrans."Transaction No.");
                TempICOutboxPurchaseHeader.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                TempICOutboxPurchaseHeader.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                if TempICOutboxPurchaseHeader.Find('-') then
                    repeat
                        ICInboxOutboxMgt.OutboxPurchHdrToInbox(Rec, TempICOutboxPurchaseHeader, ICInboxSalesHeader);
                    until TempICOutboxPurchaseHeader.Next() = 0;

                TempICOutboxPurchaseLine.SetRange("IC Transaction No.", TempICOutboxTrans."Transaction No.");
                TempICOutboxPurchaseLine.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                TempICOutboxPurchaseLine.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                if TempICOutboxPurchaseLine.Find('-') then
                    repeat
                        ICInboxOutboxMgt.OutboxPurchLineToInbox(Rec, TempICOutboxPurchaseLine, ICInboxSalesLine);
                    until TempICOutboxPurchaseLine.Next() = 0;

                TempICDocDim.SetRange("Transaction No.", TempICOutboxTrans."Transaction No.");
                TempICDocDim.SetRange("IC Partner Code", TempICOutboxTrans."IC Partner Code");
                TempICDocDim.SetRange("Transaction Source", TempICOutboxTrans."Transaction Source");
                if TempICDocDim.Find('-') then
                    repeat
                        case TempICDocDim."Table ID" of
                            DATABASE::"IC Outbox Sales Header":
                                NewTableID := DATABASE::"IC Inbox Purchase Header";
                            DATABASE::"IC Outbox Sales Line":
                                NewTableID := DATABASE::"IC Inbox Purchase Line";
                            DATABASE::"IC Outbox Purchase Header":
                                NewTableID := DATABASE::"IC Inbox Sales Header";
                            DATABASE::"IC Outbox Purchase Line":
                                NewTableID := DATABASE::"IC Inbox Sales Line";
                        end;
                        ICInboxOutboxMgt.OutboxDocDimToInbox(
                          TempICDocDim, ICInboxDocDim, NewTableID, FromICPartnerCode, Rec."Transaction Source");
                    until TempICDocDim.Next() = 0;

                OnRunOnAfterTempICOutboxTransLoop(Rec, TempICOutboxTrans);
            until TempICOutboxTrans.Next() = 0;

    end;

    var
#pragma warning disable AA0470
        WrongCompanyErr: Label 'The selected xml file contains data sent to %1 %2. Current company''s %3 is %4.', Comment = 'The selected xml file contains data sent to IC Partner 001. Current company''s IC Partner Code is 002.';
#pragma warning restore AA0470
        EnterFileNameErr: Label 'Enter the file name.';
        ChooseFileTitleMsg: Label 'Choose the file to upload.';
        ClientFileName: Text;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        ClientFileName := NewFileName;
    end;

    local procedure ImportInboxTransaction(ICSetup: Record "IC Setup"; var TempICOutboxTransaction: Record "IC Outbox Transaction" temporary; var TempICOutboxJnlLine: Record "IC Outbox Jnl. Line" temporary; var TempICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary; var TempICOutboxSalesHeader: Record "IC Outbox Sales Header" temporary; var TempICOutboxSalesLine: Record "IC Outbox Sales Line" temporary; var TempICOutboxPurchaseHeader: Record "IC Outbox Purchase Header" temporary; var TempICOutboxPurchaseLine: Record "IC Outbox Purchase Line" temporary; var TempICDocDim: Record "IC Document Dimension" temporary; var FromICPartnerCode: Code[20]; FileName: Text)
    var
        ICPartner: Record "IC Partner";
        ICOutboxImpExpXML: XMLport "IC Outbox Imp/Exp";
        IStream: InStream;
        IFile: File;
        ToICPartnerCode: Code[20];
        IsHandled: Boolean;
    begin
        IFile.Open(FileName);
        IFile.CreateInStream(IStream);

        IsHandled := false;
        OnBeforeImportInboxTransactionProcedure(
          ICSetup, IStream,
          TempICOutboxTransaction, TempICOutboxJnlLine, TempICInboxOutboxJnlLineDim, TempICOutboxSalesHeader, TempICOutboxSalesLine,
          TempICOutboxPurchaseHeader, TempICOutboxPurchaseLine, TempICDocDim, FromICPartnerCode, IsHandled);
        if IsHandled then
            exit;

        ICOutboxImpExpXML.SetSource(IStream);
        ICOutboxImpExpXML.Import();
        IFile.Close();

        FromICPartnerCode := ICOutboxImpExpXML.GetFromICPartnerCode();
        ToICPartnerCode := ICOutboxImpExpXML.GetToICPartnerCode();
        if ToICPartnerCode <> ICSetup."IC Partner Code" then
            Error(
              WrongCompanyErr, ICPartner.TableCaption(), ToICPartnerCode,
              ICSetup.FieldCaption("IC Partner Code"), ICSetup."IC Partner Code");

        ICOutboxImpExpXML.GetICOutboxTrans(TempICOutboxTransaction);
        ICOutboxImpExpXML.GetICOutBoxJnlLine(TempICOutboxJnlLine);
        ICOutboxImpExpXML.GetICIOBoxJnlDim(TempICInboxOutboxJnlLineDim);
        ICOutboxImpExpXML.GetICOutBoxSalesHdr(TempICOutboxSalesHeader);
        ICOutboxImpExpXML.GetICOutBoxSalesLine(TempICOutboxSalesLine);
        ICOutboxImpExpXML.GetICOutBoxPurchHdr(TempICOutboxPurchaseHeader);
        ICOutboxImpExpXML.GetICOutBoxPurchLine(TempICOutboxPurchaseLine);
        ICOutboxImpExpXML.GetICSalesDocDim(TempICDocDim);
        ICOutboxImpExpXML.GetICSalesDocLineDim(TempICDocDim);
        ICOutboxImpExpXML.GetICPurchDocDim(TempICDocDim);
        ICOutboxImpExpXML.GetICPurchDocLineDim(TempICDocDim);
        FromICPartnerCode := ICOutboxImpExpXML.GetFromICPartnerCode();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportInboxTransactionProcedure(ICSetup: Record "IC Setup"; var IStream: InStream; var TempICOutboxTransaction: Record "IC Outbox Transaction" temporary; var TempICOutboxJnlLine: Record "IC Outbox Jnl. Line" temporary; var TempICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary; var TempICOutboxSalesHeader: Record "IC Outbox Sales Header" temporary; var TempICOutboxSalesLine: Record "IC Outbox Sales Line" temporary; var TempICOutboxPurchaseHeader: Record "IC Outbox Purchase Header" temporary; var TempICOutboxPurchaseLine: Record "IC Outbox Purchase Line" temporary; var TempICDocDim: Record "IC Document Dimension" temporary; var FromICPartnerCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterTempICOutboxTransLoop(var IcInboxTransaction: Record "IC Inbox Transaction"; var IcOutBoxTransaction: Record "IC Outbox Transaction")
    begin
    end;
}

