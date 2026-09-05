// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Environment;

page 5267 "Audit File Export Doc. Card"
{
    PageType = Card;
    SourceTable = "Audit File Export Header";
    Caption = 'Audit File Export Document';
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(AuditFileExportFormat; Rec."Audit File Export Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format which is used for exporting the audit file.';
                }
                field(GLAccountMappingCode; Rec."G/L Account Mapping Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account mapping code that represents the reporting period.';
                    Visible = GLAccountMappingCodeVisible;
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date of the reporting period.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending date of the reporting period.';
                }
                field(SplitByMonth; Rec."Split By Month")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if multiple audit files will be generated per month.';
                    Visible = SplitByMonthVisible;
                }
                field(SplitByDate; Rec."Split By Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether multiple audit files will be generated for each day.';
                    Visible = SplitByDateVisible;
                }
                field("Header Comment"; Rec."Header Comment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment that is exported to the header of the audit file';
                    Visible = HeaderCommentVisible;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact that is exported to the header of the audit file';
                    Visible = ContactVisible;
                }
                field(ZipFileGeneration; Rec."Archive to Zip")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all files will be packed into a Zip archive.';
                    Visible = ZipFileGenerationVisible and not IsSaaS;
                }
                field(CreateMultipleZipFiles; Rec."Create Multiple Zip Files")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that multiple Zip files will be generated.';
                    Visible = CreateMultipleZipFilesVisible;
                }
            }
            group(Processing)
            {
                Caption = 'Processing';

                field(ParallelProcessing; Rec."Parallel Processing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the audit file generation will be processed by parallel background jobs.';
                    Enabled = IsParallelProcessingAllowed;

                    trigger OnValidate()
                    begin
                        CalcParallelProcessingEnabled();
                        CurrPage.Update();
                    end;
                }
                field("Max No. Of Jobs"; Rec."Max No. Of Jobs")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum number of background jobs that can be run at the same time.';
                    Enabled = IsParallelProcessingEnabled;
                }
                field(EarliestStartDateTime; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date and time when the background job must be run.';
                    Enabled = IsParallelProcessingEnabled;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the overall status of one or more audit files being generated.';
                }
                field(ExecutionStartDateTime; Rec."Execution Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the audit file generation was started.';
                }
                field(ExecutionEndDateTime; Rec."Execution End Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the audit file generation was completed.';
                }
                field(LatestDataCheckDateTime; Rec."Latest Data Check Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the most recent data check was run.';
                    Visible = LatestDataCheckDateTimeVisible;
                }
                field(DataCheckStatus; Rec."Data check status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the most recent data check.';
                    Visible = DataCheckStatusVisible;
                }
            }
            part(ExportLines; "Audit File Export Subpage")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = ID = field(ID);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DataCheck)
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = CheckRulesSyntax;
                Caption = 'Data check';
                ToolTip = 'Check that data is ready to be exported to the audit file.';
                Visible = DataCheckActionVisible;

                trigger OnAction()
                var
                    IAuditFileExportDataCheck: Interface "Audit File Export Data Check";
                begin
                    IAuditFileExportDataCheck := Rec."Audit File Export Format";
                    IAuditFileExportDataCheck.CheckDataToExport(Rec);
                end;
            }
            action(Start)
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Start;
                Caption = 'Start';
                ToolTip = 'Start the generation of the audit file.';

                trigger OnAction()
                var
                    AuditFileExportMgt: Codeunit "Audit File Export Mgt.";
                begin
                    AuditFileExportMgt.StartExport(Rec);
                    CurrPage.Update();
                end;
            }
            action(CreateAuditFiles)
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = UpdateXML;
                Caption = 'Recreate Audit Files';
                ToolTip = 'Recreate the files using the already collected audit data.';

                trigger OnAction()
                var
                    AuditFileExportMgt: Codeunit "Audit File Export Mgt.";
                begin
                    AuditFileExportMgt.GenerateAuditFileWithCheck(Rec);
                end;
            }
            action(DownloadFile)
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = ExportFile;
                Caption = 'Download Files';
                ToolTip = 'Download the generated audit files.';
                RunObject = page "Audit Files";
                RunPageLink = "Export ID" = field("ID");
            }
        }
    }

    var
        IsParallelProcessingAllowed: Boolean;
        IsParallelProcessingEnabled: Boolean;
        IsSaaS: Boolean;
        GLAccountMappingCodeVisible: Boolean;
        SplitByMonthVisible: Boolean;
        SplitByDateVisible: Boolean;
        HeaderCommentVisible: Boolean;
        ContactVisible: Boolean;
        ZipFileGenerationVisible: Boolean;
        CreateMultipleZipFilesVisible: Boolean;
        LatestDataCheckDateTimeVisible: Boolean;
        DataCheckStatusVisible: Boolean;
        DataCheckActionVisible: Boolean;

    trigger OnOpenPage()
    var
        AuditFileExportMgt: Codeunit "Audit File Export Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsParallelProcessingAllowed := TaskScheduler.CanCreateTask();
        if not IsParallelProcessingAllowed then
            AuditFileExportMgt.ThrowNoParallelExecutionNotification();
        IsSaaS := EnvironmentInformation.IsSaaS();
        UpdateVisibility();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        IsParallelProcessingEnabled := TaskScheduler.CanCreateTask();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalcParallelProcessingEnabled();
        UpdateVisibility();
    end;

    local procedure CalcParallelProcessingEnabled()
    begin
        IsParallelProcessingEnabled := Rec."Parallel Processing";
    end;

    local procedure UpdateVisibility()
    var
        IAuditFileExportPageVisibility: Interface "Audit File Export Page Visibility";
        FieldVisibility: Dictionary of [Text, Boolean];
        ActionVisibility: Dictionary of [Text, Boolean];
    begin
        InitializeVisibility(FieldVisibility, ActionVisibility);
        IAuditFileExportPageVisibility := Rec."Audit File Export Format";
        IAuditFileExportPageVisibility.GetUIVisibility(FieldVisibility, ActionVisibility);
        ApplyVisibility(FieldVisibility, ActionVisibility);
        CurrPage.Update();
    end;

    local procedure InitializeVisibility(var FieldVisibility: Dictionary of [Text, Boolean]; var ActionVisibility: Dictionary of [Text, Boolean])
    begin
        // Initialize all field visibility to true
        FieldVisibility.Set('GLAccountMappingCode', true);
        FieldVisibility.Set('SplitByMonth', true);
        FieldVisibility.Set('SplitByDate', true);
        FieldVisibility.Set('HeaderComment', true);
        FieldVisibility.Set('Contact', true);
        FieldVisibility.Set('ZipFileGeneration', true);
        FieldVisibility.Set('CreateMultipleZipFiles', true);
        FieldVisibility.Set('LatestDataCheckDateTime', true);
        FieldVisibility.Set('DataCheckStatus', true);

        // Initialize all action visibility to true
        ActionVisibility.Set('DataCheck', true);
    end;

    local procedure ApplyVisibility(FieldVisibility: Dictionary of [Text, Boolean]; ActionVisibility: Dictionary of [Text, Boolean])
    begin
        // Apply field visibility
        if FieldVisibility.ContainsKey('GLAccountMappingCode') then
            GLAccountMappingCodeVisible := FieldVisibility.Get('GLAccountMappingCode');
        if FieldVisibility.ContainsKey('SplitByMonth') then
            SplitByMonthVisible := FieldVisibility.Get('SplitByMonth');
        if FieldVisibility.ContainsKey('SplitByDate') then
            SplitByDateVisible := FieldVisibility.Get('SplitByDate');
        if FieldVisibility.ContainsKey('HeaderComment') then
            HeaderCommentVisible := FieldVisibility.Get('HeaderComment');
        if FieldVisibility.ContainsKey('Contact') then
            ContactVisible := FieldVisibility.Get('Contact');
        if FieldVisibility.ContainsKey('ZipFileGeneration') then
            ZipFileGenerationVisible := FieldVisibility.Get('ZipFileGeneration');
        if FieldVisibility.ContainsKey('CreateMultipleZipFiles') then
            CreateMultipleZipFilesVisible := FieldVisibility.Get('CreateMultipleZipFiles');
        if FieldVisibility.ContainsKey('LatestDataCheckDateTime') then
            LatestDataCheckDateTimeVisible := FieldVisibility.Get('LatestDataCheckDateTime');
        if FieldVisibility.ContainsKey('DataCheckStatus') then
            DataCheckStatusVisible := FieldVisibility.Get('DataCheckStatus');

        // Apply action visibility
        if ActionVisibility.ContainsKey('DataCheck') then
            DataCheckActionVisible := ActionVisibility.Get('DataCheck');
    end;
}
