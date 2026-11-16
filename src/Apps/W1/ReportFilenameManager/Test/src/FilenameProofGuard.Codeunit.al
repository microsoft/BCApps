// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting.FileNaming;
using System.Environment;

codeunit 149511 "Filename Proof Guard"
{
    // The proofs delete every Report Filename Pattern (a customer's setup, never restored), so on
    // the service the suite refuses to run outside a sandbox.

    Access = Internal;

    internal procedure AssertSafeEnvironment()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // On the service only a sandbox is accepted. Off the service (IsSaaSInfrastructure is false,
        // also in a Docker container) nothing is checked.
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            if EnvironmentInformation.IsProduction() then
                Error(ProductionErr);
            if not EnvironmentInformation.IsSandbox() then
                Error(NotSandboxErr);
        end;
    end;

    // Deletes every pattern, after the environment check.
    internal procedure ClearPatterns()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        AssertSafeEnvironment();
        Pattern.DeleteAll(false);
        SwitchFeatureOn();
    end;

    // The feature starts switched off in a company; the proofs assume it on, at the default length.
    internal procedure SwitchFeatureOn()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        DefaultSetup: Record "Report Filename Setup";
    begin
        AssertSafeEnvironment();
        DefaultSetup.Init();
        if not ReportFilenameSetup.Get() then begin
            ReportFilenameSetup.Init();
            ReportFilenameSetup.Insert();
        end;
        ReportFilenameSetup.Enabled := true;
        ReportFilenameSetup."Max. File Name Length" := DefaultSetup."Max. File Name Length";
        ReportFilenameSetup.Modify();
    end;

    internal procedure SetMaxFileNameLength(MaxLength: Integer)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        SwitchFeatureOn();
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Validate("Max. File Name Length", MaxLength);
        ReportFilenameSetup.Modify();
    end;

    internal procedure SwitchFeatureOff()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        SwitchFeatureOn();
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Enabled := false;
        ReportFilenameSetup.Modify();
    end;

    // Logs which branch of the guard applied.
    internal procedure LogEnvironment()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.LogProofLine('0 Environment: is production', Format(EnvironmentInformation.IsProduction()));
        FilenameProofLogMgt.LogProofLine('0 Environment: is sandbox', Format(EnvironmentInformation.IsSandbox()));
        FilenameProofLogMgt.LogProofLine('0 Environment: is SaaS infrastructure', Format(EnvironmentInformation.IsSaaSInfrastructure()));
        FilenameProofLogMgt.LogProofLine('0 Environment: is on-premises', Format(EnvironmentInformation.IsOnPrem()));
    end;

    var
        ProductionErr: Label 'This is a production environment. The filename proof suite deletes every configured filename pattern to isolate its own, so it will not run here.';
        NotSandboxErr: Label 'This environment is neither a sandbox nor an on-premises installation. The filename proof suite deletes every configured filename pattern to isolate its own, so it will not run here.';
}
