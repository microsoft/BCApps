// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.EServices.EDocument;
using System.Privacy;

codeunit 7000100 "SII DataClass EvalData Country"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII History");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII Doc. Upload State");
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"SII Doc. Upload State", 80);
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII Session");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII Sales Document Scheme Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII Purch. Doc. Scheme Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SII Missing Entries State");
    end;
}