namespace System.TestTools.CodeCoverage;

page 9991 "Code Coverage Setup"
{
    Caption = 'Code Coverage Setup';
    SaveValues = true;

    layout
    {
        area(content)
        {
            field("<TimeInterval>"; TimeInterval)
            {
                ApplicationArea = All;
                Caption = 'Time Interval (minutes)';
                ToolTip = 'Specifies the time interval in minutes.';

                trigger OnValidate()
                var
                    DefaultTimeIntervalInt: Integer;
                begin
                    Evaluate(DefaultTimeIntervalInt, DefaultTimeIntervalInMinutesTxt);
                    if TimeInterval < DefaultTimeIntervalInt then
                        Error(TimeIntervalErr);

                    CodeCoverageMgt.UpdateAutomaticBackupSettings(TimeInterval, BackupPath, SummaryPath);
                    Message(AppliedSettingsSuccesfullyMsg);
                end;
            }
            field("<BackupPath>"; BackupPath)
            {
                ApplicationArea = All;
                Caption = 'Backup Path';
                ToolTip = 'Specifies where the backup file is saved.';

                trigger OnValidate()
                begin
                    if BackupPath = '' then
                        Error(BackupPathErr);

                    CodeCoverageMgt.UpdateAutomaticBackupSettings(TimeInterval, BackupPath, SummaryPath);
                    Message(AppliedSettingsSuccesfullyMsg);
                end;
            }
            field("<SummaryPath>"; SummaryPath)
            {
                ApplicationArea = All;
                Caption = 'Summary Path';
                ToolTip = 'Specifies the summary path, when tracking which part of the application code has been exercised during test activity.';

                trigger OnValidate()
                begin
                    if SummaryPath = '' then
                        Error(SummaryPathErr);

                    CodeCoverageMgt.UpdateAutomaticBackupSettings(TimeInterval, BackupPath, SummaryPath);
                    Message(AppliedSettingsSuccesfullyMsg);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        SetDefaultValues();
        CodeCoverageMgt.StartAutomaticBackup(TimeInterval, BackupPath, SummaryPath);
    end;

    var
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        TimeInterval: Integer;
        BackupPath: Text[1024];
        SummaryPath: Text[1024];
        AppliedSettingsSuccesfullyMsg: Label 'Automatic Backup settings applied successfully.';
        BackupPathErr: Label 'Backup Path must have a value.';
        DefaultTimeIntervalInMinutesTxt: Label '10';
        SummaryPathErr: Label 'Summary Path must have a value.';
        TimeIntervalErr: Label 'The time interval must be greater than or equal to 10.';

    procedure SetDefaultValues()
    begin
        // Set default values for automatic backups settings, in case they don't exist
        if TimeInterval < 10 then
            Evaluate(TimeInterval, DefaultTimeIntervalInMinutesTxt);
        if BackupPath = '' then
            BackupPath := ApplicationPath;
        if SummaryPath = '' then
            SummaryPath := ApplicationPath;
    end;
}

