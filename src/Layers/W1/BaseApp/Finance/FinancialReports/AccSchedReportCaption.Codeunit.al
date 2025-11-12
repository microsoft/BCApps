// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System;
using System.Threading;
using System.Xml;

codeunit 583 "Acc. Sched. Report Caption"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Schedule a Report", 'OnGetReportDescription', '', false, false)]
    local procedure OnGetReportDescription(var ReportDescription: Text[250]; RequestPageXml: Text; ReportId: Integer; var IsHandled: Boolean)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
    begin
        if not IsHandled then
            if ReportId in [REPORT::"Account Schedule"] then
                if XMLDOMManagement.LoadXMLDocumentFromText(RequestPageXml, XMLDocument) then begin
                    XMLNode := XMLDocument.SelectSingleNode('//Field[@name="AccSchedName"]');
                    if AccScheduleName.Get(CopyStr(XMLNode.InnerText, 1, MaxStrLen(AccScheduleName.Name))) then begin
                        ReportDescription := AccScheduleName.Description;
                        IsHandled := true;
                    end;
                end;
    end;
}

