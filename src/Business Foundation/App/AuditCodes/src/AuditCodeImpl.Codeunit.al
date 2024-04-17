// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;
codeunit 223 "Audit Code Impl."
{
    procedure LookupReasonCode(var ReasonCode: Record "Reason Code"): Boolean
    begin
        exit(Action::LookupOK = Page.RunModal(0, ReasonCode))
    end;

    procedure LookupReasonCode(var ReasonCode: Code[10]): Boolean
    var
        Description: Text[100];
    begin
        exit(LookupReasonCode(ReasonCode, Description))
    end;

    procedure LookupReasonCode(var ReasonCode: Code[10]; var Description: Text[100]): Boolean
    var
        ReasonCodeRec: Record "Reason Code";
    begin
        ReasonCodeRec.Code := ReasonCode;
        if Action::LookupOK = Page.RunModal(0, ReasonCodeRec) then begin
            ReasonCode := ReasonCodeRec.Code;
            Description := ReasonCodeRec.Description;
            exit(true);
        end;
    end;

}