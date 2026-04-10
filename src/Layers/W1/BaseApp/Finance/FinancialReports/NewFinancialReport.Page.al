// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Dialog interface for creating new financial reports with template selection.
/// Provides wizard-style creation process for financial report, account schedule, and column layout setup.
/// </summary>
/// <remarks>
/// Standard dialog page for guided financial report creation. Supports selection of existing
/// templates for financial reports, account schedules, and column layouts with validation
/// for duplicate names and dependency management.
/// </remarks>
page 8747 "New Financial Report"
{
    Caption = 'New Financial Report';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(FinancialReportGroup)
            {
                Caption = 'Financial Report';
                Visible = ShowFinancialReportNames;
                field(SourceFinancialReport; OldName[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Financial Report';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing financial report in the package.';
                }
                field(NewFinancialReport; NewName[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Financial Report';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new financial report after importing.';
                    trigger OnValidate()
                    begin
                        CheckFinancialReportAlreadyExists();
                        CurrPage.Update();
                    end;
                }
                field(AlreadyExistsText; AlreadyExistsFinancialReportTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }

            group(AccountSheduleGroup)
            {
                Caption = 'Row Definition';
                Visible = ShowRowNames;
                field(SourceAccountScheduleName; OldName[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Row Definition Name';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing row definition in the package.';
                }
                field(NewAccountScheduleName; NewName[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Row Definition Name';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new row definition after importing.';
                    trigger OnValidate()
                    begin
                        CheckAccScheduleAlreadyExists();
                        CurrPage.Update();
                    end;
                }
                field(AlreadyAccountScheduleExistsText; AlreadyExistsAccountScheduleTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
            group(ColumnLayoutGroup)
            {
                Caption = 'Column Definition';
                Visible = ShowColumnLayout;
                field(SourceColumnLayoutName; OldName[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Column Definition';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing column layout in the package.';
                }
                field(NewColumnLayoutName; NewName[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Column Definition';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new column definition after importing.';
                    trigger OnValidate()
                    begin
                        CheckColumnLayoutAlreadyExists();
                        CurrPage.Update();
                    end;
                }
                field(AlreadyExistsColumnLayoutText; AlreadyExistsColumnLayoutTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
        }
    }

    var
        OldName: array[3] of Code[10];
        NewName: array[3] of Code[10];
        ShowFinancialReportNames, ShowRowNames, ShowColumnLayout : Boolean;
        AlreadyExistsFinancialReportTxt: Text;
        AlreadyExistsAccountScheduleTxt: Text;
        AlreadyExistsColumnLayoutTxt: Text;
        AlreadyExistsFinancialReportErr: Label 'Financial report %1 will be overwritten.', Comment = '%1 - name of the financial report.';
        AlreadyExistsAccountScheduleErr: Label 'Row definition %1 will be overwritten.', Comment = '%1 - name of the row definition.';
        AlreadyExistsColumnLayoutErr: Label 'Column definition %1 will be overwritten.', Comment = '%1 - name of the column definition.';

    /// <summary>
    /// Sets the initial values for financial report creation dialog.
    /// Configures the source names for financial report, account schedule, and column layout.
    /// </summary>
    /// <param name="FinancialReportName">Initial financial report name</param>
    /// <param name="AccSchedName">Initial account schedule name</param>
    /// <param name="ColumnLayout">Initial column layout name</param>
    procedure Set(FinancialReportName: Code[10]; AccSchedName: Code[10]; ColumnLayout: Code[10])
    begin
        OldName[1] := FinancialReportName;
        NewName[1] := FinancialReportName;
        OldName[2] := AccSchedName;
        NewName[2] := AccSchedName;
        OldName[3] := ColumnLayout;
        NewName[3] := ColumnLayout;
        ShowFinancialReportNames := FinancialReportName <> '';
        ShowRowNames := AccSchedName <> '';
        ShowColumnLayout := ColumnLayout <> '';
        CheckAlreadyExists();
    end;

    /// <summary>
    /// Returns the financial report name selected in the dialog.
    /// Provides access to the user-entered financial report name for creation.
    /// </summary>
    /// <returns>Financial report name from dialog input</returns>
    procedure GetFinancialReportName(): Code[10]
    begin
        exit(NewName[1]);
    end;

    /// <summary>
    /// Returns the account schedule name selected in the dialog.
    /// Provides access to the user-entered account schedule name for creation.
    /// </summary>
    /// <returns>Account schedule name from dialog input</returns>
    procedure GetAccSchedName(): Code[10]
    begin
        exit(NewName[2]);
    end;

    /// <summary>
    /// Returns the column layout name selected in the dialog.
    /// Provides access to the user-entered column layout name for creation.
    /// </summary>
    /// <returns>Column layout name from dialog input, or empty if not applicable</returns>
    procedure GetColumnLayoutName(): Code[10]
    begin
        if ShowColumnLayout then
            exit(NewName[3]);
    end;

    local procedure CheckAlreadyExists()
    begin
        CheckFinancialReportAlreadyExists();
        CheckAccScheduleAlreadyExists();
        CheckColumnLayoutAlreadyExists();
    end;

    local procedure CheckFinancialReportAlreadyExists()
    var
        FinancialReport: Record "Financial Report";
    begin
        AlreadyExistsFinancialReportTxt := '';
        if FinancialReport.Get(NewName[1]) then
            AlreadyExistsFinancialReportTxt := StrSubstNo(AlreadyExistsFinancialReportErr, NewName[1]);
    end;

    local procedure CheckAccScheduleAlreadyExists()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AlreadyExistsAccountScheduleTxt := '';
        if AccScheduleName.Get(NewName[2]) then
            AlreadyExistsAccountScheduleTxt := StrSubstNo(AlreadyExistsAccountScheduleErr, NewName[2]);
    end;

    local procedure CheckColumnLayoutAlreadyExists()
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        AlreadyExistsColumnLayoutTxt := '';
        if ShowColumnLayout then
            if ColumnLayoutName.Get(NewName[3]) then
                AlreadyExistsColumnLayoutTxt := StrSubstNo(AlreadyExistsColumnLayoutErr, NewName[3]);
    end;
}
