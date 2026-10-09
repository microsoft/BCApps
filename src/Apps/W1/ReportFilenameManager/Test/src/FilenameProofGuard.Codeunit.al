// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50161 "Filename Proof Guard"
{
    // Every proof in this app clears the Report Filename Pattern table so that its own rows are
    // the only ones competing. That is fine in a throwaway container and catastrophic anywhere
    // else: the table is a customer's naming setup, and nothing here puts it back.
    //
    // So the suite refuses to run unless it can positively establish that this is not a
    // production environment. Refusing is the only complete answer - a warning in a document is
    // not one, because the app is publishable and depends on nothing that would stop it being
    // installed in a tenant by mistake.

    Access = Internal;

    /// <summary>
    /// Raises an error unless this environment is safe to wipe setup data in. Called by every
    /// entry point that deletes patterns.
    /// </summary>
    internal procedure AssertSafeEnvironment()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // On the service, only a sandbox is acceptable. A container or an on-premises install is
        // acceptable because neither is a customer's live environment - and it is where this
        // suite is meant to run. IsProduction is not asked on its own: on-premises it reports
        // every server as production, including the build servers this suite runs on.
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            if EnvironmentInformation.IsProduction() then
                Error(ProductionErr);
            if not EnvironmentInformation.IsSandbox() then
                Error(NotSandboxErr);
        end;
    end;

    /// <summary>
    /// Clears the pattern table so a proof's own rows are the only ones competing - and refuses
    /// to do it anywhere that could be somebody's real configuration. Every proof goes through
    /// here, so there is exactly one place that deletes and exactly one place that decides.
    /// </summary>
    internal procedure ClearPatterns()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        AssertSafeEnvironment();
        Pattern.DeleteAll(false);
        SwitchFeatureOn();
    end;

    /// <summary>
    /// Puts the setup in the state every proof assumes: the feature switched on, and the default
    /// maximum length. The feature starts switched off in a company, so without this every proof
    /// would measure a feature that is deliberately doing nothing.
    /// </summary>
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

    /// <summary>
    /// Sets the one maximum length every pattern is cut to, for a proof about truncation.
    /// </summary>
    /// <param name="MaxLength">The maximum length.</param>
    internal procedure SetMaxFileNameLength(MaxLength: Integer)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        SwitchFeatureOn();
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Validate("Max. File Name Length", MaxLength);
        ReportFilenameSetup.Modify();
    end;

    /// <summary>
    /// Switches the whole feature off, for the proof that the switch works.
    /// </summary>
    internal procedure SwitchFeatureOff()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        SwitchFeatureOn();
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Enabled := false;
        ReportFilenameSetup.Modify();
    end;

    /// <summary>
    /// Writes what the platform says about this environment into the proof log, so a reader can
    /// see which branch of the guard applied rather than taking it on trust.
    /// </summary>
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
