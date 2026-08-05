// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6939 "EA Email Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure GetMaxNoOfEmails(): Integer
    begin
        exit(50);
    end;

    internal procedure GetEmailCountProcessedWithin24hrs(): Integer
    var
        EAEmail: Record "EA Email";
        StartFromDT: DateTime;
    begin
        StartFromDT := CreateDateTime(CalcDate('<-1D>', CurrentDateTime().Date), 0T);

        EAEmail.SetRange(Processed, true);
        EAEmail.SetFilter(SystemModifiedAt, '>=%1', StartFromDT);
        exit(EAEmail.Count());
    end;

    procedure RemoveProcessedEmailsOutsideLast24hrs()
    var
        EAEmail: Record "EA Email";
        Limit: DateTime;
    begin
        Limit := CreateDateTime(CalcDate('<-1D>', CurrentDateTime().Date), 0T);

        EAEmail.SetRange(Processed, true);
        EAEmail.SetFilter(SystemModifiedAt, '<%1', Limit);
        EAEmail.ReadIsolation := IsolationLevel::ReadCommitted;

        if not EAEmail.FindSet() then
            exit;

        repeat
            EAEmail.Delete(true);
        until EAEmail.Next() = 0;
        Commit();
    end;

    procedure SupportedAttachmentContentType(FileMIMEType: Text): Boolean
    begin
        if FileMIMEType in ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'] then
            exit(true)
        else
            exit(false);
    end;
}