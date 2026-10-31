// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Intercompany.Partner;
using System.Utilities;

/// <summary>
/// Handles Intercompany-specific where-used logic for G/L account checks.
/// </summary>
codeunit 8433 "IC Calc. G/L Acc. Where-Used"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", OnAfterFillTableBuffer, '', false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    begin
        if not TableBuffer.Get(Database::"IC Partner") then begin
            TableBuffer.Number := Database::"IC Partner";
            TableBuffer.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", OnShowExtensionPage, '', false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    var
        ICPartner: Record "IC Partner";
    begin
        if GLAccountWhereUsed."Table ID" <> Database::"IC Partner" then
            exit;

        ICPartner.Code := CopyStr(GLAccountWhereUsed."Key 1", 1, MaxStrLen(ICPartner.Code));
        Page.Run(0, ICPartner);
    end;
}
