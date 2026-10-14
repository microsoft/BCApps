// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Telemetry;

codeunit 6954 "EA KPI Track"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure UpdateExpenseEntry(var Expense: Record Expense)
    begin
        UpdateEntry(BlankEAKPIEntry."Record Type"::Expense, Expense."No.", 0, false, Expense."Created By Exp. User Id");
    end;

    internal procedure UpdateExpenseReportEntry(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        UpdateEntry(BlankEAKPIEntry."Record Type"::"Expense Report", ExpenseReportHeader."No.", 0, false, ExpenseReportHeader."Created By Exp. User Id");
    end;

    internal procedure UpdateExpenseReportLineEntry(var ExpenseReportLine: Record "Expense Report Line")
    begin
        UpdateEntry(BlankEAKPIEntry."Record Type"::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", ExistItemizationInExpenseReportLine(ExpenseReportLine), ExpenseReportLine."Created By Exp. User Id");
    end;

    internal procedure UpdateAttachmentKPIs(AttachmentCount: Integer)
    var
        EAKPI: Record "EA KPI";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if AttachmentCount <= 0 then
            exit;

        // Note: identity check is intentionally NOT done here because this runs
        // from the EA Agent Dispatcher under the task scheduler, whose session
        // identity is the user who scheduled the task, not the agent's AAD app.
        EAKPI.GetSafe();
        EAKPI."File Received" += AttachmentCount;
        EAKPI."Last Updated DateTime" := CurrentDateTime();
        EAKPI.Modify();

        TelemetryDimensions.Add('AttachmentCount', Format(AttachmentCount));
        FeatureTelemetry.LogUptake('0000UCC', ExpenseAgentSetup.GetFeatureName(), Enum::"Feature Uptake Status"::Used, TelemetryDimensions);
        FeatureTelemetry.LogUsage('0000UCE', ExpenseAgentSetup.GetFeatureName(), AttachmentsProcessedLbl, TelemetryDimensions);
    end;

    local procedure UpdateEntry(TableType: Option; "No.": Code[20]; LineNo: Integer; HasItemization: Boolean; ExpenseUserSystemId: Guid)
    var
        EAKPI: Record "EA KPI";
        EAKPIEntry: Record "EA KPI Entry";
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        TelemetryDimensions: Dictionary of [Text, Text];
        EntryExist: Boolean;
        ExpenseAgentUserId: Guid;
    begin
        if not ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then
            exit;

        TelemetryDimensions.Add('TableType', Format(TableType));
        TelemetryDimensions.Add('No', "No.");
        TelemetryDimensions.Add('LineNo', Format(LineNo));
        TelemetryDimensions.Add('HasItemization', Format(HasItemization));
        FeatureTelemetry.LogUptake('0000UCD', ExpenseAgentSetup.GetFeatureName(), Enum::"Feature Uptake Status"::Used, TelemetryDimensions);

        EntryExist := EAKPIEntry.Get(TableType, "No.", LineNo);
        if not EntryExist then begin
            EAKPIEntry."Record Type" := TableType;
            EAKPIEntry."No." := "No.";
            EAKPIEntry."Line No." := LineNo;
            EAKPIEntry."Created by User ID" := UserSecurityId();
            EAKPIEntry."Created By Exp. User Id" := ExpenseUserSystemId;

            if ExpenseAgentAPIValidation.TryGetExpenseAgentUserId(ExpenseAgentUserId) then
                EAKPIEntry."Created By Entra App Id" := ExpenseAgentUserId;

            EAKPIEntry."Has Itemization" := HasItemization;
            EAKPIEntry.Insert(true);
            EAKPI.UpdateEntryKPIs(EAKPIEntry, true);
        end else begin
            EAKPIEntry.Modify(true);
            EAKPI.UpdateEntryKPIs(EAKPIEntry, false);
        end;

        FeatureTelemetry.LogUsage('0000UCF', ExpenseAgentSetup.GetFeatureName(), GetRecordCreatedMessage(TableType), TelemetryDimensions);
    end;

    local procedure ExistItemizationInExpenseReportLine(ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        ExpenseReportLineItemization: Record "Expense Report Line Item";
    begin
        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");

        exit(not ExpenseReportLineItemization.IsEmpty());
    end;

    local procedure GetRecordCreatedMessage(TableType: Option): Text
    begin
        case TableType of
            BlankEAKPIEntry."Record Type"::Expense:
                exit(ExpenseCreatedLbl);
            BlankEAKPIEntry."Record Type"::"Expense Report":
                exit(ExpenseReportCreatedLbl);
            BlankEAKPIEntry."Record Type"::"Expense Report Line":
                exit(ExpenseReportLineCreatedLbl);
        end;
    end;

    var
        BlankEAKPIEntry: Record "EA KPI Entry";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ExpenseCreatedLbl: Label 'Agent created an expense.', Locked = true;
        ExpenseReportCreatedLbl: Label 'Agent created an expense report.', Locked = true;
        ExpenseReportLineCreatedLbl: Label 'Agent created an expense report line.', Locked = true;
        AttachmentsProcessedLbl: Label 'Agent processed expense attachments.', Locked = true;
}