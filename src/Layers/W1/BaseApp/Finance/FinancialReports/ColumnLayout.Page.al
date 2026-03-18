// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CostAccounting.Account;
using System.Utilities;


/// <summary>
/// Provides worksheet interface for creating and editing financial report column definitions.
/// Enables detailed setup of column layouts including data sources, formulas, dimensions, and display options.
/// </summary>
/// <remarks>
/// Primary functionality: Column definition creation, formula management, dimension filtering setup.
/// Integration: Links with Account Schedule reporting and Analysis View functionality.
/// Extensibility: Standard page extension patterns for additional column types and calculation methods.
/// </remarks>
page 489 "Column Layout"
{
    AboutTitle = 'About (Financial Report) Column Definition';
    AboutText = 'Use a column definition to specify the columns to include in a report. For example, you can design a report layout to compare net change and balance for the same period this year and last year. You can have up to 15 columns in a column definition. For example, multiple columns are useful for displaying budgets for 12 months with a column that shows the total.';
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = '(Financial Report) Column Definitions';
    DataCaptionFields = "Column Layout Name";
    PageType = Worksheet;
    SourceTable = "Column Layout";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(General)
            {
                ShowCaption = false;
                Visible = not HeaderHidden;
                field(CurrentColumnName; CurrentColumnName)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Name';
                    ToolTip = 'Specifies the unique name (code) of the column definition.';

                    trigger OnValidate()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                        ConfirmMgt: Codeunit "Confirm Management";
                        OldName: Code[10];
                        RenameQst: Label 'Your change might update related records, which can take a while. Do you want to continue?';
                    begin
                        Rec.FilterGroup(2);
                        if Rec.GetFilter("Column Layout Name") <> '' then
                            OldName := Rec.GetRangeMin("Column Layout Name");
                        Rec.FilterGroup(0);
                        if (OldName = CurrentColumnName) or (OldName = '') then
                            Error('');
                        if not ColumnLayoutName.Get(OldName) then
                            Error('');
                        if not ConfirmMgt.GetResponse(RenameQst) then
                            Error('');
                        CurrPage.SaveRecord();
                        ColumnLayoutName.Rename(CurrentColumnName);
                        CurrentColumnName := ColumnLayoutName.Name;
                        AccSchedManagement.SetColumnName(CurrentColumnName, Rec);
                        if Rec.FindFirst() then
                            CurrPage.Update(false)
                        else begin
                            Clear(Rec);
                            Rec.Init();
                        end;
                    end;
                }
                field(CurrentDescription; CurrentDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the column definition. The description is not shown on the final report but is used to provide more context when using the definition.';

                    trigger OnValidate()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                    begin
                        ColumnLayoutName.Get(CurrentColumnName);
                        ColumnLayoutName.Description := CurrentDescription;
                        ColumnLayoutName.Modify();
                    end;
                }
                field(DefinitionStatus; DefinitionStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    TableRelation = "Financial Report Status";
                    ToolTip = 'Specifies the status code for the column definition. The status code helps you organize the lifecycle of your column definitions.';

                    trigger OnValidate()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                    begin
                        ColumnLayoutName.Get(CurrentColumnName);
                        ColumnLayoutName.Status := DefinitionStatus;
                        ColumnLayoutName.Modify();
                    end;
                }
                field(InternalDescription; InternalDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Internal Description';
                    MultiLine = true;
                    ToolTip = 'Specifies the internal description of the column definition. The internal description is not shown on the final report but is used to provide more context when using the definition.';

                    trigger OnValidate()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                    begin
                        ColumnLayoutName.Get(CurrentColumnName);
                        ColumnLayoutName."Internal Description" := InternalDescription;
                        ColumnLayoutName.Modify();
                    end;
                }

            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Column Header"; Rec."Column Header")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(IncludeDateInHeader; Rec."Include Date In Header")
                {
                    Width = 10;
                }
                field("Column Type"; Rec."Column Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ledger Entry Type"; Rec."Ledger Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Formula; Rec.Formula)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Show Opposite Sign"; Rec."Show Opposite Sign")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Comparison Date Formula"; Rec."Comparison Date Formula")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Comparison Period Formula"; Rec."Comparison Period Formula")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Show; Rec.Show)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Show Indented Lines"; Rec."Show Indented Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Rounding Factor"; Rec."Rounding Factor")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Business Unit Totaling"; Rec."Business Unit Totaling")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Dimension 1 Totaling"; Rec."Dimension 1 Totaling")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(1, Text));
                    end;
                }
                field("Dimension 2 Totaling"; Rec."Dimension 2 Totaling")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(2, Text));
                    end;
                }
                field("Dimension 3 Totaling"; Rec."Dimension 3 Totaling")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(3, Text));
                    end;
                }
                field("Dimension 4 Totaling"; Rec."Dimension 4 Totaling")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(4, Text));
                    end;
                }
                field("Cost Center Totaling"; Rec."Cost Center Totaling")
                {
                    ApplicationArea = CostAccounting;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostCenter: Record "Cost Center";
                    begin
                        exit(CostCenter.LookupCostCenterFilter(Text));
                    end;
                }
                field("Cost Object Totaling"; Rec."Cost Object Totaling")
                {
                    ApplicationArea = CostAccounting;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostObject: Record "Cost Object";
                    begin
                        exit(CostObject.LookupCostObjectFilter(Text));
                    end;
                }
                field(GLAccountTotaling; Rec."G/L Account Totaling")
                {
                }
                field(HideCurrencySymbol; Rec."Hide Currency Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Show in ACY"; Rec."Show in ACY")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Internal Description"; Rec."Internal Description")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
#if not CLEAN28
            action(CopyColumnLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Column Layout';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current column layout.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This action will be removed in a future release, use the same action on the Column Layout Names page instead.';
                ObsoleteTag = '28.0';
                Visible = false;

                trigger OnAction()
                var
                    ColLayoutName: Record "Column Layout Name";
                begin
                    ColLayoutName.Get(CurrentColumnName);
                    ColLayoutName.SetRecFilter();
                    Report.RunModal(Report::"Copy Column Layout", true, true, ColLayoutName);
                end;
            }
#endif
            action(WhereUsed)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Where-Used';
                ToolTip = 'View or edit financial reports in which the column definition is used.';
                Image = Track;

                trigger OnAction()
                var
                    FinancialReport: Record "Financial Report";
                begin
                    FinancialReport.SetRange("Financial Report Column Group", CurrentColumnName);
                    Page.Run(0, FinancialReport);
                end;
            }
            action(HideHeader)
            {
                Caption = 'Hide Header';
                Image = ListPage;
                ToolTip = 'Hide the page header.';
                Visible = not HeaderHidden;

                trigger OnAction()
                begin
                    HeaderHidden := true;
                    CurrPage.Update(false);
                end;
            }
            action(ShowHeader)
            {
                Caption = 'Show Header';
                Image = TaskPage;
                ToolTip = 'Show the page header.';
                Visible = HeaderHidden;

                trigger OnAction()
                begin
                    HeaderHidden := false;
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

#if not CLEAN28
                actionref(CopyColumnLayout_Promoted; CopyColumnLayout)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed in a future release, use the same action on the Column Layout Names page instead.';
                    ObsoleteTag = '28.0';
                }
#endif
                actionref(WhereUsed_Promoted; WhereUsed) { }
                actionref(HideHeader_Promoted; HideHeader) { }
                actionref(ShowHeader_Promoted; ShowHeader) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not DimCaptionsInitialized then
            DimCaptionsInitialized := true;
    end;

    trigger OnOpenPage()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        CurrentPageCaption: Text;
    begin
        FinancialReportMgt.LaunchEditColumnsWarningNotification();
        AccSchedManagement.OpenColumns(CurrentColumnName, Rec);
        CurrentPageCaption := AccSchedManagement.GetColumnLayoutCaption(CurrentColumnName);
        if CurrentPageCaption <> '' then
            CurrPage.Caption(CurrentPageCaption);

        GetDescriptions();
    end;

    var
        AccSchedManagement: Codeunit AccSchedManagement;
        CurrentColumnName: Code[10];
        DefinitionStatus: Code[10];
        DimCaptionsInitialized: Boolean;
        CurrentDescription: Text[80];
        InternalDescription: Text[500];
        HeaderHidden: Boolean;

    local procedure GetDescriptions()
    var
        ColumnLayoutName: Record "Column Layout Name";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        CurrentDescription := '';
        InternalDescription := '';
        if ColumnLayoutName.Get(CurrentColumnName) then begin
            DefinitionStatus := ColumnLayoutName.Status;
            CurrentDescription := ColumnLayoutName.Description;
            InternalDescription := ColumnLayoutName."Internal Description";
            FinancialReportMgt.CheckStatus(ColumnLayoutName.TableCaption(), ColumnLayoutName.Status);
        end;
    end;

    /// <summary>
    /// Sets the current column layout name for the page to display the associated column definitions.
    /// </summary>
    /// <param name="NewColumnName">Column layout name to display in the worksheet</param>
    procedure SetColumnLayoutName(NewColumnName: Code[10])
    begin
        CurrentColumnName := NewColumnName;
    end;
}
