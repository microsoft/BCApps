// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Threading;

/// <summary>
/// Provides custom report captions for account schedule reports in the report scheduling system.
/// Enhances report descriptions by retrieving account schedule names from XML request parameters.
/// </summary>
/// <remarks>
/// Integrates with Schedule a Report page to display meaningful report descriptions
/// instead of generic report names when scheduling account schedule reports.
/// </remarks>
codeunit 583 "Acc. Sched. Report Caption"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Schedule a Report", 'OnGetReportDescription', '', false, false)]
    local procedure OnGetReportDescription(var ReportDescription: Text[250]; RequestPageXml: Text; ReportId: Integer; var IsHandled: Boolean)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        RequestPageXmlDocument: XmlDocument;
        AccSchedNameXmlNode: XmlNode;
        ByteOrderMark: Char;
    begin
        if not IsHandled then
            if ReportId in [REPORT::"Account Schedule"] then begin
                ByteOrderMark := 65279;
                if RequestPageXml <> '' then
                    if RequestPageXml[1] = ByteOrderMark then
                        RequestPageXml := CopyStr(RequestPageXml, 2);
                if XmlDocument.ReadFrom(RequestPageXml, RequestPageXmlDocument) then
                    if RequestPageXmlDocument.SelectSingleNode('//Field[@name="AccSchedName"]', AccSchedNameXmlNode) then
                        if AccScheduleName.Get(CopyStr(AccSchedNameXmlNode.AsXmlElement().InnerText(), 1, MaxStrLen(AccScheduleName.Name))) then begin
                            ReportDescription := AccScheduleName.Description;
                            IsHandled := true;
                        end;
            end;
    end;
}

