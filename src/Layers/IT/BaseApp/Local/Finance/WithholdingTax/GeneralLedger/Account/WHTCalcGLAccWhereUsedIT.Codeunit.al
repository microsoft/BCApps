// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Account;
using System.Utilities;

codeunit 12107 "WHTCalcGLAccWhereUsedIT"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnAfterFillTableBuffer', '', false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    var
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
    begin
        CalcGLAccWhereUsed.AddTable(TableBuffer, Database::"Contribution Code");
        CalcGLAccWhereUsed.AddTable(TableBuffer, Database::"Withhold Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnShowExtensionPage', '', false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    var
        ContributionCode: Record "Contribution Code";
        WithholdCode: Record "Withhold Code";
    begin
        case GLAccountWhereUsed."Table ID" of
            Database::"Withhold Code":
                begin
                    WithholdCode.Code := CopyStr(GLAccountWhereUsed."Key 1", 1, MaxStrLen(WithholdCode.Code));
                    Page.Run(0, WithholdCode);
                end;
            Database::"Contribution Code":
                begin
                    ContributionCode.Code := CopyStr(GLAccountWhereUsed."Key 1", 1, MaxStrLen(ContributionCode.Code));
                    Evaluate(ContributionCode."Contribution Type", GLAccountWhereUsed."Key 2");
                    if ContributionCode."Contribution Type" = ContributionCode."Contribution Type"::INAIL then
                        PAGE.Run(PAGE::"Contribution Codes-INAIL", ContributionCode)
                    else
                        PAGE.Run(PAGE::"Contribution Codes-INPS", ContributionCode);
                end;
        end;
    end;
}
