// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System;
using System.IO;
using System.Security.Encryption;
using System.Utilities;

report 11408 "Receive Response Messages"
{
    Caption = 'Receive Response Messages';
    Permissions = TableData "Elec. Tax Decl. Response Msg." = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Elec. Tax Declaration Header"; "Elec. Tax Declaration Header")
        {

            trigger OnAfterGetRecord()
            var
                ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
                ErrorLog: Record "Elec. Tax Decl. Error Log";
                ElecTaxDeclarationMgt: Codeunit "Elec. Tax Declaration Mgt.";
                DotNet_SecureString: Codeunit DotNet_SecureString;
                DigipoortCommunication: Codeunit "Digipoort Communication";
                Request: DotNet getStatussenProcesRequest;
                StatusResultatQueue: DotNet Queue;
                StatusResultat: DotNet StatusResultaat;
                MessageBLOB: OutStream;
                ClientCertificateBase64: Text;
                ServiceCertificateBase64: Text;
                NextNo: Integer;
                FoundXmlContent: Boolean;
                StatusDetails: Text;
                StatusErrorDescription: Text;
            begin
                if "Message ID" = '' then
                    CurrReport.Skip();

                Session.LogMessage('0000CJG', ReceiveResponseMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);

                Window.Update(1, WindowStatusDeletingMsg);
                ElecTaxDeclResponseMsg.SetRange("Declaration Type", "Declaration Type");
                ElecTaxDeclResponseMsg.SetRange("Declaration No.", "No.");
                ElecTaxDeclResponseMsg.DeleteAll();
                ElecTaxDeclResponseMsg.Reset();

                ErrorLog.SetRange("Declaration Type", "Declaration Type");
                ErrorLog.SetRange("Declaration No.", "No.");
                ErrorLog.DeleteAll();

                Window.Update(1, WindowStatusRequestingMsg);
                Request := Request.getStatussenProcesRequest();
                Request.kenmerk := "Elec. Tax Declaration Header"."Message ID";
                Request.autorisatieAdres := 'http://geenausp.nl';

                if ElecTaxDeclarationSetup."Use Certificate Setup" then
                    ElecTaxDeclarationMgt.InitCertificatesWithPassword(ClientCertificateBase64, DotNet_SecureString, ServiceCertificateBase64);

                DigipoortCommunication.GetStatus(Request,
                    StatusResultatQueue,
                    ElecTaxDeclarationSetup."Digipoort Status URL",
                    ClientCertificateBase64,
                    DotNet_SecureString,
                    ServiceCertificateBase64,
                    30,
                    ElecTaxDeclarationSetup."Use Certificate Setup");

                Window.Update(1, WindowStatusProcessingMsg);
                ElecTaxDeclResponseMsg.Reset();
                if not ElecTaxDeclResponseMsg.FindLast() then
                    ElecTaxDeclResponseMsg."No." := 0;
                NextNo := ElecTaxDeclResponseMsg."No." + 1;

                while StatusResultatQueue.Count > 0 do begin
                    StatusResultat := StatusResultatQueue.Dequeue();
                    if StatusResultat.statuscode <> '-1' then begin
                        ElecTaxDeclResponseMsg.Init();
                        ElecTaxDeclResponseMsg."No." := NextNo;
                        NextNo += 1;
                        ElecTaxDeclResponseMsg."Declaration Type" := "Elec. Tax Declaration Header"."Declaration Type";
                        ElecTaxDeclResponseMsg."Declaration No." := "Elec. Tax Declaration Header"."No.";
                        ElecTaxDeclResponseMsg.Subject := CopyStr(StatusResultat.statusomschrijving, 1, MaxStrLen(ElecTaxDeclResponseMsg.Subject));
                        ElecTaxDeclResponseMsg."Status Code" := CopyStr(StatusResultat.statuscode, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Code"));

                        FoundXmlContent := false;
                        ElecTaxDeclResponseMsg.Message.CreateOutStream(MessageBLOB);

                        StatusErrorDescription := StatusResultat.statusFoutcode.foutbeschrijving;
                        if StatusErrorDescription <> '' then
                            if StatusErrorDescription[1] = '<' then begin
                                MessageBLOB.WriteText(StatusErrorDescription);
                                FoundXmlContent := true;
                            end;

                        StatusDetails := StatusResultat.statusdetails;
                        if StatusDetails <> '' then
                            if StatusDetails[1] = '<' then begin
                                MessageBLOB.WriteText(StatusDetails);
                                FoundXmlContent := true;
                            end;

                        if FoundXmlContent then begin
                            ElecTaxDeclResponseMsg."Status Description" := CopyStr(BlobContentStatusMsg, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Description"));
                            Session.LogMessage('0000CJH', ReceiveResponseSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                        end else begin
                            Session.LogMessage('0000CJI', ReceiveResponseErrMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                            if StatusErrorDescription <> '' then
                                ElecTaxDeclResponseMsg."Status Description" := CopyStr(StatusErrorDescription, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Description"))
                            else
                                ElecTaxDeclResponseMsg."Status Description" := CopyStr(StatusDetails, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Description"));
                        end;

                        ElecTaxDeclResponseMsg."Date Sent" := Format(StatusResultat.tijdstempelStatus);
                        ElecTaxDeclResponseMsg.Status := ElecTaxDeclResponseMsg.Status::Received;
                        ElecTaxDeclResponseMsg.Insert(true);
                    end else begin
                        Session.LogMessage('0000CEJ', UnknownStatusCodeErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                        Error(StatusResultat.statusFoutcode.foutbeschrijving);
                    end;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field("Client Certificate"; ClientCertificateFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Certificate';
                    ToolTip = 'Specifies Client Certificate.';

                    trigger OnAssistEdit()
                    begin
                        ClientCertificateFileName :=
                          FileManagement.BLOBImportWithFilter(ClientCertificateTempBlob, ImportFileTxt, '', 'P12 Files (*.p12)|*.p12', '.p12');
                    end;
                }
                field("Client Certificate Password"; ClientCertificatePassword)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Certificate Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies a password for accessing the Client Certificate file.';
                }
                field("Service Certificate"; ServiceCertificateFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Certificate';
                    ToolTip = 'Specifies Service Certificate.';

                    trigger OnAssistEdit()
                    begin
                        ServiceCertificateFileName :=
                          FileManagement.BLOBImportWithFilter(
                            ServiceCertificateTempBlob, ImportFileTxt, '',
                            'DER Files (*.der)|*.der|CER Files (*.cer)|*.cer|CRT Files (*.crt)|*.crt|PEM Files (*.pem)|*.pem', '.crt,.cer,.der,.pem');
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Window.Close();
    end;

    trigger OnPreReport()
    begin
        Window.Open(DialogTxt);

        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup.CheckDigipoortSetup();
    end;

    var
        DialogTxt: Label 'Receiving Electronic Tax Declaration Responses...\\Status          #1##################';
        WindowStatusRequestingMsg: Label 'Requesting status information';
        WindowStatusProcessingMsg: Label 'Processing data';
        WindowStatusDeletingMsg: Label 'Removing old status data';
        BlobContentStatusMsg: Label 'Extended content';
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        ClientCertificateTempBlob: Codeunit "Temp Blob";
        ServiceCertificateTempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        Window: Dialog;
        ClientCertificateFileName: Text;
        ServiceCertificateFileName: Text;
        ClientCertificatePassword: Text;
        ImportFileTxt: Label 'Select a file to import.';
        // fault model labels
        DigipoortTok: Label 'DigipoortTelemetryCategoryTok', Locked = true;
        ReceiveResponseMsg: Label 'Receiving response', Locked = true;
        ReceiveResponseSuccessMsg: Label 'Response successfully received', Locked = true;
        ReceiveResponseErrMsg: Label 'The response contains a error', Locked = true;
        UnknownStatusCodeErr: Label 'Unknown response status code', Locked = true;
}

