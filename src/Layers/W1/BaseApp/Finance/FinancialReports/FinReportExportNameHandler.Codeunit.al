// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;
using Microsoft.Foundation.Reporting;
using System.IO;

codeunit 8362 FinReportExportNameHandler
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        OutputFilename: Text;

    procedure Init(NewOutputFilename: Text)
    begin
        BindSubscription(this);
        OutputFilename := NewOutputFilename;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnGetFilename, '', false, false)]
    local procedure ReportManagement_OnGetFilename(ReportID: Integer; var Filename: Text; var Success: Boolean)
    var
        FileMgt: Codeunit "File Management";
    begin
        if ReportID = Report::"Account Schedule" then begin
            Filename := FileMgt.CreateFileNameWithExtension(OutputFilename, FileMgt.GetExtension(Filename));
            Filename := FileMgt.StripNotsupportChrInFileName(Filename);
            Success := true;
        end;
    end;
}