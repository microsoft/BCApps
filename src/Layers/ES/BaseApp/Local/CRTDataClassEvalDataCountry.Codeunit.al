// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000101 "CRT DataClass EvalData Country"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', true, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payment Day");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Non-Payment Period");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Cartera Doc.");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Cartera Doc.");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Closed Cartera Doc.");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Bill Group");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Bill Group");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Closed Bill Group");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"BG/PO Comment Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Operation Fee");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Cartera Report Selections");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Cartera Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::Installment);
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Fee Range");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payment Order");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Payment Order");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Closed Payment Order");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Customer Rating");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::Suffix);
    end;
}