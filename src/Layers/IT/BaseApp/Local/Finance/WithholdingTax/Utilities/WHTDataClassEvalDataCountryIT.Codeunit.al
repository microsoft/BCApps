// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Utilities;

codeunit 12108 "WHTDataClassEvalDataCountryIT"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Withhold Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Withhold Code Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Computed Withholding Tax");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tmp Withholding Contribution");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Withholding Tax Payment");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Withholding Tax");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Purch. Withh. Contribution");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Withholding Tax Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Withholding Exceptional Event");
    end;
}
