
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Utilities;
using System.Privacy;

codeunit 6950 "Expense Agent Privacy Subs."
{
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", OnCreateEvaluationDataOnAfterClassifyTablesToNormal, '', true, true)]
    local procedure CreateEvaluationDataForExpenseAgent()
    begin
        ClassifyExpenseAgent();
    end;

    local procedure ClassifyExpenseAgent()
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpRepLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"EA Email");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"EA Email Attachment");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"EA Scheduler Task");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::Expense);
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Comment Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Itemization");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Rule Violation");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Participant");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Per Diem");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Header");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Line Particip.");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Line Per Diem");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Rule Violation");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Line Item");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Report Line VAT Spec.");
        DataClassificationMgt.SetFieldToPersonal(
            Database::"Expense Report Line VAT Spec.", ExpenseReportLineVATSpec.FieldNo("Reclaim Approved By"));
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Ledger Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Payment Method");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Category");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense User");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Group");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Location");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Rule Condition");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Rule Header");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Policy");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Policy Evaluation");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Posting Group");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Subcategory");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense VAT Specification");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Agent Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Agent Status");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Team");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Approval Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Agent Access Control");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Activity Log Entry");
        DataClassificationMgt.SetFieldToPersonal(
            Database::"Expense Activity Log Entry", ExpenseActivityLogEntry.FieldNo("Actor Record System ID"));
        DataClassificationMgt.SetFieldToPersonal(
            Database::"Expense Activity Log Entry", ExpenseActivityLogEntry.FieldNo("Actor Display Name"));
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Vendor");
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Agent Consumption");
#pragma warning restore AL0432
#endif
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Agent Env. Consumption");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"EA Outbox Email");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Expense Report Header");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Expense Report Line");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Exp. Rep. Line Particip");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Exp. Rep. Line Item");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Exp. Rep. Line Per Diem");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Exp. Rep. Line VAT Spec");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Posted Exp. Policy Evaluation");
        DataClassificationMgt.SetFieldToPersonal(
            Database::"Posted Exp. Rep. Line VAT Spec", PostedExpRepLineVATSpec.FieldNo("Reclaim Approved By"));
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Tenant Feedback Setting");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"EA KPI");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"EA KPI Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::Traveler);
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Mileage Rate Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Expense Vehicle Type");
    end;
}