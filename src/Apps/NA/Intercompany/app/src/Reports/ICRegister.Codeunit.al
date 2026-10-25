// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Intercompany.Partner;

codeunit 8560 "IC Register NA"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Report, Report::"G/L Register", 'OnSetICSourceType', '', false, false)]
    local procedure SetICSourceType(AccountNo: Code[20]; var SourceName: Text; var SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset",Employee,"IC Partner")
    var
        ICPartner: Record "IC Partner";
    begin
        if ICPartner.ReadPermission() then
            if ICPartner.Get(AccountNo) then begin
                SourceName := ICPartner.Name;
                SourceType := SourceType::"IC Partner";
            end;
    end;
}
