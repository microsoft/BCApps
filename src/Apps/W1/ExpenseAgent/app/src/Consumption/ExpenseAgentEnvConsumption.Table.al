// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Environment.Consumption;

table 6969 "Expense Agent Env. Consumption"
{
    Access = Internal;
    Caption = 'Expense Agent Environment Consumption';
    DataClassification = CustomerContent;
    InherentEntitlements = RIX;
    InherentPermissions = RIX;
    ReplicateData = false;
    DataPerCompany = false;

    fields
    {
        field(1; "Consumption Unique ID"; Text[1024])
        {
            Caption = 'User AI Consumption Data Unique ID';
            TableRelation = "User AI Consumption Data"."Unique Id";
            ValidateTableRelation = false;
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(3; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(4; "Consumption Source Type"; Enum "Expense Agent Cons. Source")
        {
            Caption = 'Consumption Source Type';
            DataClassification = SystemMetadata;
        }
        field(5; "Consumption Source System ID"; Guid)
        {
            Caption = 'Consumption Source System ID';
            DataClassification = SystemMetadata;
            TableRelation =
            if ("Consumption Source Type" = const(Expense)) "Expense".SystemID else
            if ("Consumption Source Type" = const("Expense Report")) "Expense Report Header".SystemID;
            ValidateTableRelation = false; // Source could belong to a different company than the current one
        }
        field(6; "Consumption Source Operation"; Code[50])
        {
            Caption = 'Consumption Source Operation';
            DataClassification = SystemMetadata;
        }
        field(7; "Is Feature Trial"; Boolean)
        {
            Caption = 'Is Feature Trial';
            DataClassification = SystemMetadata;
        }
        field(8; "Source Company Name"; Text[30])
        {
            Caption = 'Source Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
#if not CLEANSCHEMA30
        field(101; "Consumption DateTime"; DateTime)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Consumption DateTime" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Consumption DateTime';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(102; "User Id"; Guid)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."User Id" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'User Id';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(106; "App Version"; Text[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."App Version" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'App Version';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(108; "Feature Name"; Text[256])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Feature Name" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Feature Name';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(109; "Actions"; Text[1024])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Actions" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Actions';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(110; "Copilot Studio Feature"; Text[1024])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Studio Feature" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Studio Feature';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(111; "Copilot Credits"; Decimal)
        {
            FieldClass = FlowField;
            AutoFormatType = 0;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Credits" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Credits';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(113; "Company Name"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Company Name" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Company Name';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(115; "Processed For Billing"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Processed For Billing" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Processed For Billing';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(116; "CS Feature Quantity"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Studio Feature Quantity" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Studio Feature Quantity';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
        field(117; "CS Feature Display Name"; Text[1024])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Studio Feature Display Name" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Studio Feature Display Name';
#if not CLEAN30
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Use GetBillingDetails instead to read from the active consumption ledger.';
            ObsoleteTag = '30.0';
        }
#endif

    }
    keys
    {
        key(PK; "Consumption Unique ID")
        {
            Clustered = true;
        }
        key(ExpenseUser; "Expense User No.")
        {
        }
        key(Source; "Consumption Source Type", "Consumption Source System ID", "Consumption Source Operation")
        {
        }
    }

    var
        DifferentCompanyRecordTxt: Label 'Record belongs to company %1', Comment = '%1: a company name, such as "CRONUS W1"';
        DeletedRecordTxt: Label 'Deleted %1', Comment = '%1: a record caption, such as "Expense Report"';
        DeletedExpenseOrInvalidReceiptTxt: Label 'Deleted expense or invalid receipt';
        RecordIdStringPatternTxt: Label '%1 %2', Comment = '%1: a record caption, such as "Expense Report"; %2: a record number, such as "ER123"';

    [NonDebuggable]
    procedure GetTaskDisplayName(var TaskShortName: Text[30]; var TaskLongName: Text)
    var
        TempUserAIConsumptionData: Record "User AI Consumption Data" temporary;
    begin
        GetBillingDetails(TempUserAIConsumptionData);
        GetTaskDisplayName(TempUserAIConsumptionData."Company Name", TaskShortName, TaskLongName);
    end;

    [NonDebuggable]
    procedure GetTaskDisplayName(SourceCompany: Text[30]; var TaskShortName: Text[30]; var TaskLongName: Text)
    var
        DestinationCompany: Text[30];
    begin
        if SourceCompany <> CompanyName() then
            DestinationCompany := SourceCompany;
        case Rec."Consumption Source Type" of
            Rec."Consumption Source Type"::Expense:
                TaskLongName := GetTaskDisplayNameForExpense(DestinationCompany, Rec."Consumption Source System ID");
            Rec."Consumption Source Type"::"Expense Report":
                TaskLongName := GetTaskDisplayNameForExpenseReport(DestinationCompany, Rec."Consumption Source System ID");
        end;

        TaskShortName := CopyStr(TaskLongName, 1, 30);
    end;

    [NonDebuggable]
    procedure GetBillingDetails(var TempUserAIConsumptionData: Record "User AI Consumption Data" temporary): Boolean
    var
        UserAIConsumptionData: Record "User AI Consumption Data";
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
    begin
        Clear(TempUserAIConsumptionData);
        if not AIConsumptionLogEntry.ReadPermission() then
            exit(false);

        TempUserAIConsumptionData."Company Name" := Rec."Source Company Name";
        AIConsumptionLogEntry.SetLoadFields("Consumption DateTime", "Executing User Security Id", "App Version", "Resource Name", "AI Credits", "Company Name", "Reporting State");
        if AIConsumptionLogEntry.GetBySystemId(Rec.SystemId) then begin
            TempUserAIConsumptionData."Consumption DateTime" := AIConsumptionLogEntry."Consumption DateTime";
            TempUserAIConsumptionData."User Id" := AIConsumptionLogEntry."Executing User Security Id";
            TempUserAIConsumptionData."App Version" := AIConsumptionLogEntry."App Version";
            TempUserAIConsumptionData."Feature Name" := AIConsumptionLogEntry."Resource Name";
            TempUserAIConsumptionData."Copilot Credits" := AIConsumptionLogEntry."AI Credits";
            TempUserAIConsumptionData."Company Name" := AIConsumptionLogEntry."Company Name";
            TempUserAIConsumptionData."Processed For Billing" := AIConsumptionLogEntry."Reporting State" = Enum::"AI Consumption Reporting State"::Completed;
            exit(true);
        end;

        UserAIConsumptionData.SetRange("Unique Id", Rec."Consumption Unique ID");
        UserAIConsumptionData.SetLoadFields("Consumption DateTime", "Actions", "Copilot Studio Feature", "Copilot Studio Feature Quantity", "Copilot Studio Feature Display Name", "Copilot Credits", "Company Name", "Processed For Billing");
        if not UserAIConsumptionData.FindFirst() then
            exit(false);

        TempUserAIConsumptionData := UserAIConsumptionData;
        exit(true);
    end;

    [NonDebuggable]
    procedure GetBillingDescription(var DescriptionInStream: InStream): Boolean
    var
        UserAIConsumptionData: Record "User AI Consumption Data";
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
    begin
        Clear(DescriptionInStream);
        if not AIConsumptionLogEntry.ReadPermission() then
            exit(false);

        if AIConsumptionLogEntry.GetBySystemId(Rec.SystemId) then begin
            AIConsumptionLogEntry.CalcFields(Description);
            AIConsumptionLogEntry.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
            exit(true);
        end;

        UserAIConsumptionData.SetRange("Unique Id", Rec."Consumption Unique ID");
        if not UserAIConsumptionData.FindFirst() then
            exit(false);

        UserAIConsumptionData.CalcFields(Description);
        UserAIConsumptionData.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
        exit(true);
    end;

    local procedure GetTaskDisplayNameForExpense(DestinationCompany: Text[30]; SourceSystemId: Guid): Text
    var
        Expense: Record Expense;
    begin
        if DestinationCompany <> '' then
            if not Expense.ChangeCompany(DestinationCompany) or not Expense.ReadPermission() then
                exit(StrSubstNo(DifferentCompanyRecordTxt, DestinationCompany));

        Expense.SetLoadFields("No.");
        if Expense.GetBySystemId(SourceSystemId) then
            exit(StrSubstNo(RecordIdStringPatternTxt, Expense.TableCaption(), Expense."No."));
        exit(DeletedExpenseOrInvalidReceiptTxt);
    end;

    local procedure GetTaskDisplayNameForExpenseReport(DestinationCompany: Text[30]; SourceSystemId: Guid): Text
    var
        ExpenseReport: Record "Expense Report Header";
    begin
        if DestinationCompany <> '' then
            if not ExpenseReport.ChangeCompany(DestinationCompany) or not ExpenseReport.ReadPermission() then
                exit(StrSubstNo(DifferentCompanyRecordTxt, DestinationCompany));

        ExpenseReport.SetLoadFields("No.");
        if ExpenseReport.GetBySystemId(SourceSystemId) then
            exit(StrSubstNo(RecordIdStringPatternTxt, ExpenseReport.TableCaption(), ExpenseReport."No."));
        exit(StrSubstNo(DeletedRecordTxt, ExpenseReport.TableCaption()));
    end;

}
