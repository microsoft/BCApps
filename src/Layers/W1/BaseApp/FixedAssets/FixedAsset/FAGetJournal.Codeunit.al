// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;

codeunit 5639 "FA Get Journal"
{

    trigger OnRun()
    begin
    end;

    var
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        TemplateName2: Code[10];
        BatchName2: Code[10];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot duplicate using the current journal. Check the table %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure JnlName(DeprBookCode: Code[10]; BudgetAsset: Boolean; FAPostingType: Enum "FA Journal Line FA Posting Type"; var GLIntegration: Boolean; var TemplateName: Code[10]; var BatchName: Code[10])
    var
        GLIntegration2: Boolean;
    begin
        DeprBook.Get(DeprBookCode);
        if not FAJnlSetup.Get(DeprBookCode, UserId) then
            FAJnlSetup.Get(DeprBookCode, '');
        GLIntegration2 := GLIntegration;
        GLIntegration := CalcGLIntegration(BudgetAsset, FAPostingType);
        BatchName2 := BatchName;
        TemplateName2 := TemplateName;
        if GLIntegration then begin
            FAJnlSetup.TestField("Gen. Jnl. Template Name");
            FAJnlSetup.TestField("Gen. Jnl. Batch Name");
            TemplateName := FAJnlSetup."Gen. Jnl. Template Name";
            BatchName := FAJnlSetup."Gen. Jnl. Batch Name";
            GenJnlTemplate.Get(TemplateName);
            GenJnlBatch.Get(TemplateName, BatchName);
        end else begin
            FAJnlSetup.TestField("FA Jnl. Batch Name");
            FAJnlSetup.TestField("FA Jnl. Template Name");
            TemplateName := FAJnlSetup."FA Jnl. Template Name";
            BatchName := FAJnlSetup."FA Jnl. Batch Name";
            FAJnlTemplate.Get(TemplateName);
            FAJnlBatch.Get(TemplateName, BatchName);
        end;
        if (GLIntegration = GLIntegration2) and
           (BatchName = BatchName2) and
           (TemplateName = TemplateName2)
        then
            Error(Text000, FAJnlSetup.TableCaption());
    end;

    procedure InsuranceJnlName(DeprBookCode: Code[10]; var TemplateName: Code[10]; var BatchName: Code[10])
    begin
        DeprBook.Get(DeprBookCode);
        if not FAJnlSetup.Get(DeprBookCode, UserId) then
            FAJnlSetup.Get(DeprBookCode, '');
        FAJnlSetup.TestField("Insurance Jnl. Template Name");
        FAJnlSetup.TestField("Insurance Jnl. Batch Name");
        BatchName := FAJnlSetup."Insurance Jnl. Batch Name";
        TemplateName := FAJnlSetup."Insurance Jnl. Template Name";
        InsuranceJnlTempl.Get(TemplateName);
        InsuranceJnlBatch.Get(TemplateName, BatchName);
    end;

    procedure SetGenJnlRange(var GenJnlLine: Record "Gen. Journal Line"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        GenJnlLine.Reset();
        GenJnlLine."Journal Template Name" := TemplateName;
        GenJnlLine."Journal Batch Name" := BatchName;
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", BatchName);
        if GenJnlLine.Find('+') then;
        GenJnlLine.Init();
    end;

    procedure SetFAJnlRange(var FAJnlLine: Record "FA Journal Line"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        FAJnlLine.Reset();
        FAJnlLine."Journal Template Name" := TemplateName;
        FAJnlLine."Journal Batch Name" := BatchName;
        FAJnlLine.SetRange("Journal Template Name", TemplateName);
        FAJnlLine.SetRange("Journal Batch Name", BatchName);
        if FAJnlLine.Find('+') then;
        FAJnlLine.Init();
    end;

    procedure SetInsuranceJnlRange(var InsuranceJnlLine: Record "Insurance Journal Line"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        InsuranceJnlLine.Reset();
        InsuranceJnlLine."Journal Template Name" := TemplateName;
        InsuranceJnlLine."Journal Batch Name" := BatchName;
        InsuranceJnlLine.SetRange("Journal Template Name", TemplateName);
        InsuranceJnlLine.SetRange("Journal Batch Name", BatchName);
        if InsuranceJnlLine.Find('+') then;
        InsuranceJnlLine.Init();
    end;

    local procedure CalcGLIntegration(BudgetAsset: Boolean; FAPostingType: Enum "FA Journal Line FA Posting Type") Result: Boolean
    begin
        if BudgetAsset then
            exit(false);
        case FAPostingType of
            FAPostingType::"Acquisition Cost":
                exit(DeprBook."G/L Integration - Acq. Cost");
            FAPostingType::Depreciation:
                exit(DeprBook."G/L Integration - Depreciation");
            FAPostingType::"Write-Down":
                exit(DeprBook."G/L Integration - Write-Down");
            FAPostingType::Appreciation:
                exit(DeprBook."G/L Integration - Appreciation");
            FAPostingType::"Custom 1":
                exit(DeprBook."G/L Integration - Custom 1");
            FAPostingType::"Custom 2":
                exit(DeprBook."G/L Integration - Custom 2");
            FAPostingType::Disposal:
                exit(DeprBook."G/L Integration - Disposal");
            FAPostingType::Maintenance:
                exit(DeprBook."G/L Integration - Maintenance");
            FAPostingType::"Salvage Value":
                exit(false);
        end;

        OnAfterCalcGLIntegration(DeprBook, FAPostingType, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcGLIntegration(DeprBook: Record "Depreciation Book"; var FAPostingType: Enum "FA Journal Line FA Posting Type"; var Result: Boolean)
    begin
    end;
}

