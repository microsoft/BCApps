// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Reporting;
Using System.Utilities;
using System.Environment;

codeunit 8812 "Customer Statement Subscr"
{
    EventSubscriberInstance = Manual;
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, database::"Report Selections", 'OnBeforeSaveReportAsPDF', '', true, true)]
    local procedure OnBeforeSaveReportAsPDF(var ReportID: Integer; RecordVariant: Variant; var LayoutCode: Code[20]; var IsHandled: Boolean; FilePath: Text[250]; ReportUsage: Enum "Report Selection Usage"; SaveToBlob: Boolean; var TempBlob: Codeunit "Temp Blob"; var ReportSelections: Record "Report Selections");
    var
        StandardStatement: Report "Standard Statement";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ClientTypeManagement: Codeunit "Client Type Management";
        RecRef: RecordRef;
        NewDateChoice: Option "Due Date","Posting Date";
        OutStream: OutStream;
        LastUsedParameters: Text;
        StartDate, EndDate : Date;
    begin
        if ReportID <> Report::"Standard Statement" then
            exit;

        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, ClientType::Api]) then
            exit;

        IsHandled := true;

        if RecordVariant.IsRecord() then
            RecRef.GetTable(RecordVariant)
        else
            if RecordVariant.IsRecordRef() then
                RecRef := RecordVariant;

        StartDate := CalcDate('<-3M-CM>', Today);
        EndDate := Today;
        LastUsedParameters := CustomLayoutReporting.GetReportRequestPageParameters(ReportID);
        TempBlob.CreateOutStream(OutStream);

        StandardStatement.InitializeRequest(true, true, true, true, false, false, '', NewDateChoice::"Due Date", false, StartDate, EndDate);
        StandardStatement.SaveAs(LastUsedParameters, ReportFormat::Pdf, OutStream, RecRef);
    end;
}
