// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;

codeunit 11420 "Data Class. Eval. Data NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"CBG Statement");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"CBG Statement Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Reporting ICP");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Freely Transferable Maximum");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Post Code Range");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Post Code Update Log Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Elec. Tax Declaration Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Elec. Tax Declaration Header");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Elec. Tax Declaration Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Elec. Tax Decl. VAT Category");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Elec. Tax Decl. Error Log");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Elec. Tax Decl. Response Msg.");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Proposal Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payment History");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payment History Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Detail Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Transaction Mode");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Export Protocol");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"CBG Statement Line Add. Info.");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Import Protocol");
    end;
}
