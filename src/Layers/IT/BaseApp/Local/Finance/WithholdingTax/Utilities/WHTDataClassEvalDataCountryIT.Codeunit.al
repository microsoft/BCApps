// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Utilities;

codeunit 12108 "WHTDataClassEvalDataCountryIT"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Contribution Code");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Contribution Code Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Contribution Bracket");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Contribution Bracket Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Computed Contribution");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Contribution Payment");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::Contributions);
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Withhold Code");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Withhold Code Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Computed Withholding Tax");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Tmp Withholding Contribution");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Withholding Tax Payment");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Withholding Tax");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Purch. Withh. Contribution");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Withholding Tax Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Withholding Exceptional Event");
    end;
}
