#pragma warning disable AA0247
codeunit 104150 "Upgrade - Local App"
{
    Access = internal;
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerDatabase()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdateCashDeskWorkflowTemplate();
        UpdateCreditWorkflowTemplate();
        UpdatePaymentOrderWorkflowTemplate();
        UpdateAdvanceLetterWorkflowTemplate();
        UpdateReplaceMultipleInterestRate();
    end;

    local procedure UpdateCashDeskWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        CashDocApprWorkflowCodeTxt: Label 'MS-CDAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCashDeskWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(CashDocApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCashDeskWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdateCreditWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        CreditDocApprWorkflowCodeTxt: Label 'MS-CRAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCreditWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(CreditDocApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCreditWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdatePaymentOrderWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        PaymentOrderApprWorkflowCodeTxt: Label 'MS-PMTORDAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetPaymentOrderWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(PaymentOrderApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetPaymentOrderWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdateAdvanceLetterWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        SalesAdvanceLetterApprWorkflowCodeTxt: Label 'MS-SALAPW', Locked = true;
        PurchAdvanceLetterApprWorkflowCodeTxt: Label 'MS-PALAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(SalesAdvanceLetterApprWorkflowCodeTxt);
        DeleteWorkflowTemplate(PurchAdvanceLetterApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdateReplaceMultipleInterestRate()
    begin
        UpdateMultipleInterestRateFinanceChargeMemos();
        UpdateMultipleInterestRateReminders();
        UpdateMultipleInterestRateIssuedFinanceChargeMemos();
        UpdateMultipleInterestRateIssuedReminders();
    end;

    local procedure UpdateMultipleInterestRateFinanceChargeMemos()
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        TempFinanceChargeMemoLine: Record "Finance Charge Memo Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateFinanceChargeMemosUpgradeTag()) then
            exit;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", DocumentNo);
            FinanceChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
            if not FinanceChargeMemoLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
        foreach DocumentNo in ListOfDocumentNo do begin
            TempFinanceChargeMemoLine.Reset();
            TempFinanceChargeMemoLine.DeleteAll();
            FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", DocumentNo);
            if FinanceChargeMemoLine.FindSet() then
                repeat
                    TempFinanceChargeMemoLine.Init();
                    TempFinanceChargeMemoLine := FinanceChargeMemoLine;
                    TempFinanceChargeMemoLine.Insert();
                until FinanceChargeMemoLine.Next() = 0;

            FinanceChargeMemoLine.DeleteAll(true);

            LineNo := 0;
            if TempFinanceChargeMemoLine.FindSet() then
                repeat
                    LineNo += 10000;
                    FinanceChargeMemoLine.Init();
                    FinanceChargeMemoLine := TempFinanceChargeMemoLine;
                    FinanceChargeMemoLine."Line No." := LineNo;
                    FinanceChargeMemoLine.SystemId := TempFinanceChargeMemoLine.SystemId;
                    FinanceChargeMemoLine.Insert(false, true);
                until TempFinanceChargeMemoLine.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateFinanceChargeMemosUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateReminders()
    var
        ReminderLine: Record "Reminder Line";
        TempReminderLine: Record "Reminder Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateRemindersUpgradeTag()) then
            exit;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            ReminderLine.SetRange("Reminder No.", DocumentNo);
            ReminderLine.SetRange("Detailed Interest Rates Entry", true);
            if not ReminderLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
        foreach DocumentNo in ListOfDocumentNo do begin
            TempReminderLine.Reset();
            TempReminderLine.DeleteAll();
            ReminderLine.SetRange("Reminder No.", DocumentNo);
            if ReminderLine.FindSet() then
                repeat
                    TempReminderLine.Init();
                    TempReminderLine := ReminderLine;
                    TempReminderLine.Insert();
                until ReminderLine.Next() = 0;

            ReminderLine.DeleteAll(true);

            LineNo := 0;
            if TempReminderLine.FindSet() then
                repeat
                    LineNo += 10000;
                    ReminderLine.Init();
                    ReminderLine := TempReminderLine;
                    ReminderLine."Line No." := LineNo;
                    ReminderLine.SystemId := TempReminderLine.SystemId;
                    ReminderLine.Insert(false, true);
                until TempReminderLine.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateRemindersUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateIssuedFinanceChargeMemos()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        TempIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedFinanceChargeMemosUpgradeTag()) then
            exit;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", DocumentNo);
            IssuedFinChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
            if not IssuedFinChargeMemoLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
        foreach DocumentNo in ListOfDocumentNo do begin
            IssuedFinChargeMemoHeader.Get(DocumentNo);
            FinanceChargeTerms.Get(IssuedFinChargeMemoHeader."Fin. Charge Terms Code");

            TempIssuedFinChargeMemoLine.Reset();
            TempIssuedFinChargeMemoLine.DeleteAll();
            IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
            if IssuedFinChargeMemoLine.FindSet() then
                repeat
                    TempIssuedFinChargeMemoLine.Init();
                    TempIssuedFinChargeMemoLine := IssuedFinChargeMemoLine;
                    TempIssuedFinChargeMemoLine.Insert();

                    IssuedFinChargeMemoLine.Delete();
                until IssuedFinChargeMemoLine.Next() = 0;

            LineNo := 0;
            if TempIssuedFinChargeMemoLine.FindSet() then
                repeat
                    LineNo += 10000;
                    IssuedFinChargeMemoLine.Init();
                    IssuedFinChargeMemoLine := TempIssuedFinChargeMemoLine;
                    IssuedFinChargeMemoLine."Line No." := LineNo;
                    IssuedFinChargeMemoLine.SystemId := TempIssuedFinChargeMemoLine.SystemId;
                    IssuedFinChargeMemoLine.Insert(false, true);
                until TempIssuedFinChargeMemoLine.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedFinanceChargeMemosUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateIssuedReminders()
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        TempIssuedReminderLine: Record "Issued Reminder Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedRemindersUpgradeTag()) then
            exit;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            IssuedReminderLine.SetRange("Reminder No.", DocumentNo);
            IssuedReminderLine.SetRange("Detailed Interest Rates Entry", true);
            if not IssuedReminderLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
        foreach DocumentNo in ListOfDocumentNo do begin
            TempIssuedReminderLine.Reset();
            TempIssuedReminderLine.DeleteAll();
            IssuedReminderLine.SetRange("Reminder No.", DocumentNo);
            if IssuedReminderLine.FindSet() then
                repeat
                    TempIssuedReminderLine.Init();
                    TempIssuedReminderLine := IssuedReminderLine;
                    TempIssuedReminderLine.Insert();

                    IssuedReminderLine.Delete();
                until IssuedReminderLine.Next() = 0;

            LineNo := 0;
            if TempIssuedReminderLine.FindSet() then
                repeat
                    LineNo += 10000;
                    IssuedReminderLine.Init();
                    IssuedReminderLine := TempIssuedReminderLine;
                    IssuedReminderLine."Line No." := LineNo;
                    IssuedReminderLine.SystemId := TempIssuedReminderLine.SystemId;
                    IssuedReminderLine.Insert(false, true);
                until TempIssuedReminderLine.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedRemindersUpgradeTag());
    end;

    internal procedure DeleteWorkflowTemplate(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        if Workflow.Get(WorkflowCode) then begin
            Workflow.TestField(Template, true);
            DeleteWorkflowSteps(Workflow.Code);
            Workflow.Delete(false);
        end;
    end;

    local procedure DeleteWorkflowSteps(WorkflowCode: Code[20])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRule: Record "Workflow Rule";
        ZeroGuid: Guid;
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        if WorkflowStep.FindSet() then
            repeat
                if WorkflowStepArgument.Get(WorkflowStep.Argument) then
                    WorkflowStepArgument.Delete(false);

                WorkflowRule.SetRange("Workflow Code", WorkflowStep."Workflow Code");
                WorkflowRule.SetRange("Workflow Step ID", WorkflowStep.ID);
                WorkflowRule.SetRange("Workflow Step Instance ID", ZeroGuid);
                if not WorkflowRule.IsEmpty() then
                    WorkflowRule.DeleteAll();

                WorkflowStep.Delete(false);
            until WorkflowStep.Next() = 0;
    end;
}
