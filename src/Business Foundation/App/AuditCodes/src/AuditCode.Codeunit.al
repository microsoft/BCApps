// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

codeunit 222 "Audit Code"
{
    /// <summary>
    /// Opens the Reason Code page and returns the selected Reason Code and Description.
    /// </summary>
    /// <param name="ReasonCode">The selected Reason Code.</param>
    /// <param name="Description">The description of the selected Reason Code.</param>
    /// <returns></returns>
    procedure LookupReasonCode(var ReasonCode: Code[10]; var Description: Text[100]): Boolean
    var
        AuditCodeImpl: Codeunit "Audit Code Impl.";
    begin
        exit(AuditCodeImpl.LookupReasonCode(ReasonCode, Description))
    end;

    procedure LookupReasonCode(var ReasonCodeText: Text): Boolean
    var
        AuditCodeImpl: Codeunit "Audit Code Impl.";
    begin
        exit(AuditCodeImpl.LookupReasonCode(ReasonCodeText))
    end;

    procedure LookupReasonCode(var ReasonCode: Code[10]): Boolean
    var
        AuditCodeImpl: Codeunit "Audit Code Impl.";
    begin
        exit(AuditCodeImpl.LookupReasonCode(ReasonCode))
    end;
}