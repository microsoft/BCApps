// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Utilities;

table 689 "Paym. Prac. Dispute Ret. Data"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Integer)
        {
            TableRelation = "Payment Practice Header"."No.";
        }
        field(30; "Offers E-Invoicing"; Boolean)
        {
            ToolTip = 'Specifies whether the company offers e-invoicing.';
        }
        field(31; "Offers Supply Chain Finance"; Boolean)
        {
            ToolTip = 'Specifies whether the company offers supply chain finance.';
        }
        field(32; "Policy Covers Deduct. Charges"; Boolean)
        {
            ToolTip = 'Specifies whether the policy covers deduction charges.';
        }
        field(33; "Has Deducted Charges in Period"; Boolean)
        {
            ToolTip = 'Specifies whether the company has deducted charges in the reporting period.';
        }
        field(34; "Is Payment Code Member"; Boolean)
        {
            ToolTip = 'Specifies whether the company is a payment code member.';
        }
        field(40; "Has Constr. Contract Retention"; Boolean)
        {
            ToolTip = 'Specifies whether the company has construction contract retention.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if "Has Constr. Contract Retention" then
                    exit;

                if not ConfirmManagement.GetResponseOrDefault(ClearRetentionFieldsQst, true) then begin
                    "Has Constr. Contract Retention" := true;
                    exit;
                end;

                ClearRetentionChildFields();
            end;
        }
        field(41; "Ret. Clause Used in Contracts"; Boolean)
        {
            ToolTip = 'Specifies whether retention clauses are used in contracts.';
        }
        field(42; "Retention in Specific Circs."; Boolean)
        {
            ToolTip = 'Specifies whether retention is withheld in specific circumstances.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if "Retention in Specific Circs." then
                    exit;

                if "Retention Circs. Desc." = '' then
                    exit;

                if not ConfirmManagement.GetResponseOrDefault(ClearDependentFieldQst, true) then begin
                    "Retention in Specific Circs." := true;
                    exit;
                end;

                "Retention Circs. Desc." := '';
            end;
        }
        field(43; "Retention Circs. Desc."; Text[1024])
        {
            ToolTip = 'Specifies the circumstances under which retention is withheld.';
        }
        field(44; "Withholds Retent. from Subcon"; Boolean)
        {
            ToolTip = 'Specifies whether the company withholds retention from subcontractors.';
        }
        field(45; "Contract Sum Threshold"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the contract sum threshold for retention.';
        }
        field(47; "Standard Retention Pct"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the standard retention percentage.';
        }
        field(49; "Terms Fairness Practice"; Boolean)
        {
            ToolTip = 'Specifies whether terms fairness practice is applied.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if "Terms Fairness Practice" then
                    exit;

                if "Terms Fairness Desc." = '' then
                    exit;

                if not ConfirmManagement.GetResponseOrDefault(ClearDependentFieldQst, true) then begin
                    "Terms Fairness Practice" := true;
                    exit;
                end;

                "Terms Fairness Desc." := '';
            end;
        }
        field(50; "Terms Fairness Desc."; Text[1024])
        {
            ToolTip = 'Specifies a description of the terms fairness practice.';
        }
        field(51; "Release Mechanism Desc."; Text[1024])
        {
            ToolTip = 'Specifies a description of the retention release mechanism.';
        }
        field(52; "Release Within Prescribed Days"; Boolean)
        {
            ToolTip = 'Specifies whether retention is released within the prescribed number of days.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if "Release Within Prescribed Days" then
                    exit;

                if "Prescribed Days Desc." = '' then
                    exit;

                if not ConfirmManagement.GetResponseOrDefault(ClearDependentFieldQst, true) then begin
                    "Release Within Prescribed Days" := true;
                    exit;
                end;

                "Prescribed Days Desc." := '';
            end;
        }
        field(53; "Prescribed Days Desc."; Text[1024])
        {
            ToolTip = 'Specifies a description of the prescribed days for retention release.';
        }
        field(54; "Retent. Withheld from Suppls."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the total retention withheld from suppliers.';

            trigger OnValidate()
            begin
                CalculateRetentionPercentages();
            end;
        }
        field(55; "Retention Withheld by Clients"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the total retention withheld by clients.';

            trigger OnValidate()
            begin
                CalculateRetentionPercentages();
            end;
        }
        field(56; "Gross Payments Constr. Contr."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the gross payments under construction contracts.';

            trigger OnValidate()
            begin
                CalculateRetentionPercentages();
            end;
        }
        field(57; "Pct Retention vs Client Ret."; Decimal)
        {
            Editable = false;
            AutoFormatType = 0;
            ToolTip = 'Specifies the retention as a percentage of client retention. This value is automatically calculated from the retention withheld from suppliers and retention withheld by clients.';
        }
        field(58; "Pct Retent. vs Gross Payments"; Decimal)
        {
            Editable = false;
            AutoFormatType = 0;
            ToolTip = 'Specifies the retention as a percentage of gross payments. This value is automatically calculated from the retention withheld from suppliers and gross payments under construction contracts.';
        }
        field(60; "Qualifying Contracts in Period"; Boolean)
        {
            ToolTip = 'Specifies whether there are qualifying contracts in the reporting period.';
        }
        field(61; "Payments Made in Period"; Boolean)
        {
            ToolTip = 'Specifies whether payments were made in the reporting period.';
        }
        field(62; "Qual. Constr. Contr. in Period"; Boolean)
        {
            ToolTip = 'Specifies whether there are qualifying construction contracts in the reporting period.';
        }
        field(63; "Shortest Standard Pmt. Period"; Integer)
        {
            ToolTip = 'Specifies the shortest standard payment period in days.';
        }
        field(64; "Longest Standard Pmt. Period"; Integer)
        {
            ToolTip = 'Specifies the longest standard payment period in days.';
        }
        field(65; "Standard Payment Terms Desc."; Text[2048])
        {
            ToolTip = 'Specifies a description of the standard payment terms.';
        }
        field(66; "Payment Terms Have Changed"; Boolean)
        {
            ToolTip = 'Specifies whether payment terms have changed since the last reporting period.';

            trigger OnValidate()
            begin
                if not "Payment Terms Have Changed" then
                    "Suppliers Notified of Changes" := false;
            end;
        }
        field(67; "Suppliers Notified of Changes"; Boolean)
        {
            ToolTip = 'Specifies whether suppliers were notified of payment term changes.';
        }
        field(68; "Max Contractual Pmt. Period"; Integer)
        {
            ToolTip = 'Specifies the maximum contractual payment period in days.';
        }
        field(69; "Max Contr. Pmt. Period Info"; Text[1024])
        {
            ToolTip = 'Specifies information about the maximum contractual payment period.';
        }
        field(70; "Other Pmt. Terms Information"; Text[1024])
        {
            ToolTip = 'Specifies other information about payment terms.';
        }
        field(71; "Dispute Resolution Process"; Text[2048])
        {
            ToolTip = 'Specifies the dispute resolution process.';
        }
        field(72; "Retention in Std Pmt. Terms"; Boolean)
        {
            ToolTip = 'Specifies whether retention clauses are included in standard payment terms.';
        }
        field(73; "Std Retention Pct Used"; Boolean)
        {
            ToolTip = 'Specifies whether a standard retention percentage is used.';

            trigger OnValidate()
            begin
                if not "Std Retention Pct Used" then
                    "Standard Retention Pct" := 0;
            end;
        }
    }

    keys
    {
        key(Key1; "Header No.")
        {
            Clustered = true;
        }
    }

    local procedure CalculateRetentionPercentages()
    begin
        if "Retention Withheld by Clients" <> 0 then
            "Pct Retention vs Client Ret." := "Retent. Withheld from Suppls." / "Retention Withheld by Clients" * 100
        else
            "Pct Retention vs Client Ret." := 0;

        if "Gross Payments Constr. Contr." <> 0 then
            "Pct Retent. vs Gross Payments" := "Retent. Withheld from Suppls." / "Gross Payments Constr. Contr." * 100
        else
            "Pct Retent. vs Gross Payments" := 0;
    end;

    procedure CopyFromPrevious()
    var
        PreviousDisputeRetData: Record "Paym. Prac. Dispute Ret. Data";
        CurrentHeader: Record "Payment Practice Header";
        PreviousHeader: Record "Payment Practice Header";
        ConfirmManagement: Codeunit "Confirm Management";
        BestEndingDate: Date;
        Found: Boolean;
    begin
        CurrentHeader.Get("Header No.");

        PreviousDisputeRetData.SetFilter("Header No.", '<>%1', "Header No.");
        if not PreviousDisputeRetData.FindSet() then begin
            Message(NoPreviousPeriodMsg);
            exit;
        end;

        // Find the most recent previous record by header Ending Date with same reporting scheme
        BestEndingDate := 0D;
        Found := false;
        repeat
            if PreviousHeader.Get(PreviousDisputeRetData."Header No.") then
                if PreviousHeader."Reporting Scheme" = CurrentHeader."Reporting Scheme" then
                    if (PreviousHeader."Ending Date" <> 0D) and (PreviousHeader."Ending Date" > BestEndingDate) then
                        if (CurrentHeader."Ending Date" = 0D) or (PreviousHeader."Ending Date" < CurrentHeader."Ending Date") then begin
                            BestEndingDate := PreviousHeader."Ending Date";
                            Found := true;
                        end;
        until PreviousDisputeRetData.Next() = 0;

        if not Found then begin
            Message(NoPreviousPeriodMsg);
            exit;
        end;

        if not ConfirmManagement.GetResponseOrDefault(CopyFromPreviousQst, true) then
            exit;

        // Re-find the record with the best ending date and same reporting scheme
        PreviousDisputeRetData.Reset();
        PreviousDisputeRetData.SetFilter("Header No.", '<>%1', "Header No.");
        PreviousDisputeRetData.FindSet();
        repeat
            if PreviousHeader.Get(PreviousDisputeRetData."Header No.") then
                if (PreviousHeader."Reporting Scheme" = CurrentHeader."Reporting Scheme") and (PreviousHeader."Ending Date" = BestEndingDate) then begin
                    // Copy standing-policy fields
                    "Offers E-Invoicing" := PreviousDisputeRetData."Offers E-Invoicing";
                    "Offers Supply Chain Finance" := PreviousDisputeRetData."Offers Supply Chain Finance";
                    "Policy Covers Deduct. Charges" := PreviousDisputeRetData."Policy Covers Deduct. Charges";
                    "Is Payment Code Member" := PreviousDisputeRetData."Is Payment Code Member";
                    "Has Constr. Contract Retention" := PreviousDisputeRetData."Has Constr. Contract Retention";
                    "Ret. Clause Used in Contracts" := PreviousDisputeRetData."Ret. Clause Used in Contracts";
                    "Retention in Std Pmt. Terms" := PreviousDisputeRetData."Retention in Std Pmt. Terms";
                    "Retention in Specific Circs." := PreviousDisputeRetData."Retention in Specific Circs.";
                    "Retention Circs. Desc." := PreviousDisputeRetData."Retention Circs. Desc.";
                    "Withholds Retent. from Subcon" := PreviousDisputeRetData."Withholds Retent. from Subcon";
                    "Contract Sum Threshold" := PreviousDisputeRetData."Contract Sum Threshold";
                    "Std Retention Pct Used" := PreviousDisputeRetData."Std Retention Pct Used";
                    "Standard Retention Pct" := PreviousDisputeRetData."Standard Retention Pct";
                    "Terms Fairness Practice" := PreviousDisputeRetData."Terms Fairness Practice";
                    "Terms Fairness Desc." := PreviousDisputeRetData."Terms Fairness Desc.";
                    "Release Mechanism Desc." := PreviousDisputeRetData."Release Mechanism Desc.";
                    "Release Within Prescribed Days" := PreviousDisputeRetData."Release Within Prescribed Days";
                    "Prescribed Days Desc." := PreviousDisputeRetData."Prescribed Days Desc.";
                    "Qualifying Contracts in Period" := PreviousDisputeRetData."Qualifying Contracts in Period";
                    "Qual. Constr. Contr. in Period" := PreviousDisputeRetData."Qual. Constr. Contr. in Period";
                    "Shortest Standard Pmt. Period" := PreviousDisputeRetData."Shortest Standard Pmt. Period";
                    "Longest Standard Pmt. Period" := PreviousDisputeRetData."Longest Standard Pmt. Period";
                    "Standard Payment Terms Desc." := PreviousDisputeRetData."Standard Payment Terms Desc.";
                    "Max Contractual Pmt. Period" := PreviousDisputeRetData."Max Contractual Pmt. Period";
                    "Max Contr. Pmt. Period Info" := PreviousDisputeRetData."Max Contr. Pmt. Period Info";
                    "Other Pmt. Terms Information" := PreviousDisputeRetData."Other Pmt. Terms Information";
                    "Dispute Resolution Process" := PreviousDisputeRetData."Dispute Resolution Process";

                    // Clear period-specific fields
                    "Payment Terms Have Changed" := false;
                    "Suppliers Notified of Changes" := false;
                    "Has Deducted Charges in Period" := false;
                    "Payments Made in Period" := false;
                    "Retent. Withheld from Suppls." := 0;
                    "Retention Withheld by Clients" := 0;
                    "Gross Payments Constr. Contr." := 0;
                    "Pct Retention vs Client Ret." := 0;
                    "Pct Retent. vs Gross Payments" := 0;

                    Modify();
                    exit;
                end;
        until PreviousDisputeRetData.Next() = 0;
    end;

    var
        NoPreviousPeriodMsg: Label 'No previous period with the same reporting scheme was found to copy from.';
        CopyFromPreviousQst: Label 'Do you want to copy standing-policy fields from the most recent previous period? Period-specific fields will be cleared.';
        ClearRetentionFieldsQst: Label 'Turning off construction contract retention will clear all retention detail fields. Do you want to continue?';
        ClearDependentFieldQst: Label 'The related field will be cleared. Do you want to continue?';

    local procedure ClearRetentionChildFields()
    begin
        "Ret. Clause Used in Contracts" := false;
        "Retention in Std Pmt. Terms" := false;
        "Retention in Specific Circs." := false;
        "Retention Circs. Desc." := '';
        "Withholds Retent. from Subcon" := false;
        "Contract Sum Threshold" := 0;
        "Std Retention Pct Used" := false;
        "Standard Retention Pct" := 0;
        "Terms Fairness Practice" := false;
        "Terms Fairness Desc." := '';
        "Release Mechanism Desc." := '';
        "Release Within Prescribed Days" := false;
        "Prescribed Days Desc." := '';
        "Retent. Withheld from Suppls." := 0;
        "Retention Withheld by Clients" := 0;
        "Gross Payments Constr. Contr." := 0;
        "Pct Retention vs Client Ret." := 0;
        "Pct Retent. vs Gross Payments" := 0;
    end;
}
