// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System;
using System.Xml;

report 11406 "Process Response Messages"
{
    Caption = 'Process Response Messages';
    Permissions = TableData "Elec. Tax Decl. Error Log" = i,
                  TableData "Elec. Tax Decl. Response Msg." = m;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Elec. Tax Decl. Response Msg."; "Elec. Tax Decl. Response Msg.")
        {
            DataItemTableView = sorting("No.") order(ascending) where(Status = const(Received));

            trigger OnAfterGetRecord()
            var
                ErrorLog: Record "Elec. Tax Decl. Error Log";
                XMLDOMManagement: Codeunit "XML DOM Management";
                XMLDoc: DotNet XmlDocument;
                InStream: InStream;
                NodeList: DotNet XmlNodeList;
                XmlNode: DotNet XmlNode;
                Index: Integer;
                NextErrorNo: Integer;
            begin
                Session.LogMessage('0000CED', ProcessingResponseMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);

                if not ElecTaxDeclHeader.Get("Declaration Type", "Declaration No.") then begin
                    Session.LogMessage('0000CEE', StrSubstNo(HeaderNotFoundErrMsg, "Declaration Type"), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                    Error(HeaderNotFoundErr, "Declaration Type", "Declaration No.");
                end;

                ErrorLog.Reset();
                ErrorLog.SetRange("Declaration Type", "Declaration Type");
                ErrorLog.SetRange("Declaration No.", "Declaration No.");
                if not ErrorLog.FindLast() then
                    ErrorLog."No." := 0;
                NextErrorNo := ErrorLog."No." + 1;

                CalcFields(Message);
                if Message.HasValue and ("Status Code" in ['311']) then begin
                    Message.CreateInStream(InStream);
                    XMLDOMManagement.LoadXMLDocumentFromInStream(InStream, XMLDoc);

                    NodeList := XMLDoc.GetElementsByTagName('msg');
                    for Index := 0 to NodeList.Count - 1 do begin
                        XmlNode := NodeList.ItemOf(Index);

                        ErrorLog.Init();
                        ErrorLog."No." := NextErrorNo;
                        ErrorLog."Declaration Type" := "Declaration Type";
                        ErrorLog."Declaration No." := "Declaration No.";
                        ErrorLog."Error Class" := CopyStr(GetAttributeValue(XmlNode, 'level'), 1, MaxStrLen(ErrorLog."Error Class"));
                        ErrorLog."Error Description" := CopyStr(XmlNode.InnerXml, 1, MaxStrLen(ErrorLog."Error Description"));

                        ErrorLog.Insert(true);
                        NextErrorNo += 1;
                    end;
                end;

                case "Status Code" of
                    '210', '220', '311', '410', '510', '710':
                        begin
                            ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Error;
                            Session.LogMessage('0000CEF', StrSubstNo(ErrorStatusCodeMsg, "Declaration Type", "Status Code"), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                        end;
                    '230', '321', '420', '720':
                        if ElecTaxDeclHeader.Status <> ElecTaxDeclHeader.Status::Error then begin
                            ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Warning;
                            Session.LogMessage('0000CEG', StrSubstNo(WarningStatusCodeMsg, "Declaration Type", "Status Code"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                        end;
                    '100':
                        if not (ElecTaxDeclHeader.Status in [ElecTaxDeclHeader.Status::Error, ElecTaxDeclHeader.Status::Warning]) then begin
                            ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Acknowledged;
                            Session.LogMessage('0000CEH', StrSubstNo(AcknowledgeStatusCodeMsg, "Declaration Type", "Status Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                        end;
                end;

                ElecTaxDeclHeader."Date Received" := Today;
                ElecTaxDeclHeader."Time Received" := Time;

                Status := Status::Processed;
                Modify(true);

                ElecTaxDeclHeader.Modify(true);

                Session.LogMessage('0000CEI', ResponseProcessedSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        HeaderNotFoundErr: Label 'Elec. Tax Declaration header %1,%2 could not be found.';
        // fault model labels
        DigipoortTok: Label 'DigipoortTelemetryCategoryTok', Locked = true;
        ProcessingResponseMsg: Label 'Processing response message', Locked = true;
        ResponseProcessedSuccessMsg: Label 'Response message succesfully processed', Locked = true;
        HeaderNotFoundErrMsg: Label 'Error while processing response: Elec. Tax Declaration header %1 could not be found.', Locked = true;
        ErrorStatusCodeMsg: Label 'Error for declaration type %1, status code %2', Locked = true;
        WarningStatusCodeMsg: Label 'Warning for declaration type %1, status code %2', Locked = true;
        AcknowledgeStatusCodeMsg: Label 'Declaration type %1 acknowledged, status code: %2', Locked = true;

    local procedure GetAttributeValue(var XMLNode: DotNet XmlNode; "Key": Text): Text
    var
        XmlAttNode: DotNet XmlNode;
        XmlAttributes: DotNet XmlAttributeCollection;
    begin
        XmlAttributes := XMLNode.Attributes;
        XmlAttNode := XmlAttributes.GetNamedItem(Key);
        exit(XmlAttNode.Value);
    end;
}

