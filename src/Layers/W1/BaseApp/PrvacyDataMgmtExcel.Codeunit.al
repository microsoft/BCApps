// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Privacy;

using Microsoft.EServices.EDocument;
using System.IO;

codeunit 1181 "Prvacy Data Mgmt Excel"
{
    TableNo = "Config. Package Table";

    trigger OnRun()
    var
        ReportInbox: Record "Report Inbox";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
        FileManagement: Codeunit "File Management";
        InputFile: File;
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('.xlsx');
        ConfigExcelExchange.SetFileOnServer(true);
        if ConfigExcelExchange.ExportExcel(FileName, Rec, false, false) then
            if FileManagement.ServerFileExists(FileName) then begin
                InputFile.Open(FileName);
                InputFile.CreateInStream(InStr);
                ReportInbox."Report Output".CreateOutStream(OutStr);
                CopyStream(OutStr, InStr);

                ReportInbox."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID"));
                ReportInbox.Validate("Output Type", ReportInbox."Output Type"::Excel);
                ReportInbox.Description := StrSubstNo(PrivacyDataTxt, Rec."Package Code");
                ReportInbox."Report Name" := StrSubstNo(PrivacyDataTxt, Rec."Package Code");
                ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
                if not ReportInbox.Insert(true) then
                    ReportInbox.Modify(true);

                // IF STRPOS(Rec."Package Code",'*') > 0 THEN BEGIN
                // ConfigPackage.SETRANGE(Code,Rec."Package Code");
                // ConfigPackage.DELETE(TRUE);
                // END;
            end;
    end;

    var
        PrivacyDataTxt: Label 'Privacy Data for %1', Comment = '%1=The name of the package code.';
}

