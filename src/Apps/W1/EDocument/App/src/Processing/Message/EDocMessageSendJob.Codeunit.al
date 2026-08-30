// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using System.Threading;

codeunit 6535 "E-Doc. Message Send Job"
{
    Access = Internal;
    TableNo = "Job Queue Entry";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocumentMessage: Record "E-Document Message";
        LastErrorInfo: ErrorInfo;
        LastErrorText: Text;
    begin
        EDocumentMessage.Get(Rec."Record ID to Process");
        if Codeunit.Run(Codeunit::"E-Doc. Message Send Runner", EDocumentMessage) then
            exit;

        LastErrorInfo := GetLastErrorObject();
        LastErrorText := LastErrorInfo.Message;
        EDocumentMessage.Get(EDocumentMessage."Entry No.");
        EDocumentMessage.Status := EDocumentMessage.Status::Error;
        EDocumentMessage."Last Attempt At" := CurrentDateTime();
        EDocumentMessage."Retry Count" += 1;
        EDocumentMessage."Last Error" := CopyStr(LastErrorText, 1, MaxStrLen(EDocumentMessage."Last Error"));
        EDocumentMessage.Modify();
        Commit();
        Error(LastErrorInfo);
    end;
}