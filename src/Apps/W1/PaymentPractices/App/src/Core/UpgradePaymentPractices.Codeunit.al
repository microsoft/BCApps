// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

codeunit 683 "Upgrade Payment Practices"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        MigratePaymentPeriods();
        BackfillPaymentPracticeHeaders();
    end;

    local procedure MigratePaymentPeriods()
    var
        PaymentPeriod: Record "Payment Period";
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodLine: Record "Payment Period Line";
        TempDefaultLine: Record "Payment Period Line" temporary;
        PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
        ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
        DefaultPeriods: Interface PaymentPracticeDefaultPeriods;
        DefaultCode: Code[20];
        DefaultDesc: Text[250];
        LineNo: Integer;
        OldMatchesDefault: Boolean;
    begin
        if PaymentPeriodHeader.FindFirst() then
            exit; // Already migrated

        ReportingScheme := PaymentPeriodMgt.DetectReportingScheme();

        // Get defaults for detected scheme
        DefaultPeriods := ReportingScheme;
        DefaultPeriods.GetDefaultPaymentPeriods(DefaultCode, DefaultDesc, TempDefaultLine);

        // Compare old periods to defaults
        OldMatchesDefault := CompareOldPeriodsToDefaults(TempDefaultLine);

        // Create default template
        CreatePeriodTemplate(DefaultCode, DefaultDesc, ReportingScheme, true, TempDefaultLine);

        // If old periods differ, create MIGRATED template
        if not OldMatchesDefault then
            if not PaymentPeriod.IsEmpty() then begin
                PaymentPeriodHeader.Init();
                PaymentPeriodHeader.Code := 'MIGRATED';
                PaymentPeriodHeader.Description := 'Migrated Payment Periods';
                PaymentPeriodHeader."Reporting Scheme" := ReportingScheme;
                PaymentPeriodHeader.Default := false;
                PaymentPeriodHeader.Insert();

                LineNo := 10000;
                PaymentPeriod.SetCurrentKey("Days From");
                PaymentPeriod.SetAscending("Days From", true);
                if PaymentPeriod.FindSet() then
                    repeat
                        PaymentPeriodLine.Init();
                        PaymentPeriodLine."Period Header Code" := 'MIGRATED';
                        PaymentPeriodLine."Line No." := LineNo;
                        PaymentPeriodLine."Days From" := PaymentPeriod."Days From";
                        PaymentPeriodLine."Days To" := PaymentPeriod."Days To";
                        PaymentPeriodLine.Description := PaymentPeriod.Description;
                        PaymentPeriodLine.Insert();
                        LineNo += 10000;
                    until PaymentPeriod.Next() = 0;
            end;
    end;

    local procedure BackfillPaymentPracticeHeaders()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPeriodHeader: Record "Payment Period Header";
        DisputeRetData: Record "Paym. Prac. Dispute Ret. Data";
        PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
        ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
        BackfillCode: Code[20];
    begin
        ReportingScheme := PaymentPeriodMgt.DetectReportingScheme();

        // Use MIGRATED if it exists, otherwise use the default template
        PaymentPeriodHeader.SetRange(Code, 'MIGRATED');
        if PaymentPeriodHeader.FindFirst() then
            BackfillCode := 'MIGRATED'
        else begin
            PaymentPeriodHeader.Reset();
            PaymentPeriodHeader.SetRange("Reporting Scheme", ReportingScheme);
            PaymentPeriodHeader.SetRange(Default, true);
            if PaymentPeriodHeader.FindFirst() then
                BackfillCode := PaymentPeriodHeader.Code;
        end;

        PaymentPracticeHeader.SetRange("Payment Period Code", '');
        if PaymentPracticeHeader.FindSet() then
            repeat
                PaymentPracticeHeader."Reporting Scheme" := ReportingScheme;
                if BackfillCode <> '' then
                    PaymentPracticeHeader."Payment Period Code" := BackfillCode;
                PaymentPracticeHeader.Modify();

                if not DisputeRetData.Get(PaymentPracticeHeader."No.") then begin
                    DisputeRetData.Init();
                    DisputeRetData."Header No." := PaymentPracticeHeader."No.";
                    DisputeRetData.Insert();
                end;
            until PaymentPracticeHeader.Next() = 0;
    end;

    local procedure CompareOldPeriodsToDefaults(var TempDefaultLine: Record "Payment Period Line" temporary): Boolean
    var
        PaymentPeriod: Record "Payment Period";
        OldCount: Integer;
        DefaultCount: Integer;
    begin
        PaymentPeriod.SetCurrentKey("Days From");
        PaymentPeriod.SetAscending("Days From", true);
        OldCount := PaymentPeriod.Count();

        TempDefaultLine.Reset();
        DefaultCount := TempDefaultLine.Count();

        if OldCount <> DefaultCount then
            exit(false);

        if not PaymentPeriod.FindSet() then
            exit(DefaultCount = 0);

        if not TempDefaultLine.FindSet() then
            exit(false);

        repeat
            if (PaymentPeriod."Days From" <> TempDefaultLine."Days From") or
               (PaymentPeriod."Days To" <> TempDefaultLine."Days To") then
                exit(false);
        until (PaymentPeriod.Next() = 0) or (TempDefaultLine.Next() = 0);

        exit(true);
    end;

    local procedure CreatePeriodTemplate(TemplateCode: Code[20]; TemplateDesc: Text[250]; ReportingScheme: Enum "Paym. Prac. Reporting Scheme"; IsDefault: Boolean; var TempLines: Record "Payment Period Line" temporary)
    var
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodLine: Record "Payment Period Line";
    begin
        PaymentPeriodHeader.Init();
        PaymentPeriodHeader.Code := TemplateCode;
        PaymentPeriodHeader.Description := TemplateDesc;
        PaymentPeriodHeader."Reporting Scheme" := ReportingScheme;
        PaymentPeriodHeader.Default := IsDefault;
        PaymentPeriodHeader.Insert();

        TempLines.Reset();
        if TempLines.FindSet() then
            repeat
                PaymentPeriodLine.Init();
                PaymentPeriodLine."Period Header Code" := TemplateCode;
                PaymentPeriodLine."Line No." := TempLines."Line No.";
                PaymentPeriodLine."Days From" := TempLines."Days From";
                PaymentPeriodLine."Days To" := TempLines."Days To";
                PaymentPeriodLine.Description := TempLines.Description;
                PaymentPeriodLine.Insert();
            until TempLines.Next() = 0;
    end;
}
