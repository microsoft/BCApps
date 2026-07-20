// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.QualityManagement.Configuration;
using System.Utilities;

/// <summary>
/// This page is intended to help with advanced configuration scenarios. If you are exploring the system we recommend that you do not make alterations on this page unless instructed by a qualified support representative or technician. 
/// </summary>
page 20412 "Qlty. Ins. Source Config. List"
{
    Caption = 'Quality Inspection Source Configurations';
    PageType = List;
    SourceTable = "Qlty. Inspect. Source Config.";
    CardPageId = "Qlty. Inspect. Source Config.";
    Editable = false;
    UsageCategory = None;
    ApplicationArea = QualityManagement;
    AboutTitle = 'Populating data from tables in Business Central';
    AboutText = 'This page defines how data is automatically populated into quality inspections from other tables, including how records are linked between source and target tables. It is read-only in most scenarios and intended for advanced configuration.';

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                ShowCaption = false;

                field("Code"; Rec.Code)
                {
                    ToolTip = 'Specifies there is typically one mapping per code.';
                    StyleExpr = RowStyleText;
                }
                field(Description; Rec.Description)
                {
                    StyleExpr = RowStyleText;
                }
                field(Enabled; Rec.Enabled)
                {
                    StyleExpr = RowStyleText;
                }
                field("From Table No."; Rec."From Table No.")
                {
                    StyleExpr = RowStyleText;
                }
                field("From Table Name"; Rec."From Table Caption")
                {
                    StyleExpr = RowStyleText;
                }
                field("From Table Filter"; Rec."From Table Filter")
                {
                    AboutTitle = 'Refine when to connect to another table';
                    AboutText = 'Use this filter to define conditions for when to connect to a different table. This can be used when a source table could refer to multiple different tables.';
                    AssistEdit = true;
                    StyleExpr = RowStyleText;
                }
                field("To Type"; Rec."To Type")
                {
                    StyleExpr = RowStyleText;
                }
                field("To Table No."; Rec."To Table No.")
                {
                    StyleExpr = RowStyleText;
                }
                field("To Table Name"; Rec."To Table Caption")
                {
                    StyleExpr = RowStyleText;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(RestoreDefaults)
            {
                Caption = 'Restore defaults';
                Image = Restore;
                ToolTip = 'Restore the default source configurations shipped with Quality Management.';

                action(RecreateMissingDefaultConfigurations)
                {
                    AccessByPermission = tabledata "Qlty. Inspect. Source Config." = I;
                    ApplicationArea = QualityManagement;
                    Caption = 'Recreate missing default configurations';
                    ToolTip = 'Recreates any missing default source configurations shipped with Quality Management. Existing default configurations remain unchanged, even if they were customized.';
                    Image = ApplyTemplate;

                    trigger OnAction()
                    var
                        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(RecreateMissingDefaultConfigurationsQst, false) then
                            exit;

                        QltyAutoConfigure.EnsureAtLeastOneSourceConfigurationExist(true);

                        CurrPage.Update(false);
                        Message(RecreateMissingDefaultConfigurationsCompletedMsg);
                    end;
                }
                action(ResetOnlyDefaultConfigurations)
                {
                    AccessByPermission = tabledata "Qlty. Inspect. Source Config." = I;
                    ApplicationArea = QualityManagement;
                    Caption = 'Reset only default configurations';
                    ToolTip = 'Deletes and recreates the default source configurations shipped with Quality Management, discarding any customizations made to them. Custom source configurations that you have added are preserved.';
                    Image = RefreshText;

                    trigger OnAction()
                    var
                        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(ResetOnlyDefaultConfigurationsQst, false) then
                            exit;

                        QltyAutoConfigure.DeleteShippedDefaultSourceConfigurations();
                        QltyAutoConfigure.EnsureAtLeastOneSourceConfigurationExist(true);

                        CurrPage.Update(false);
                        Message(ResetOnlyDefaultConfigurationsCompletedMsg);
                    end;
                }
                action(ResetAllConfigurations)
                {
                    AccessByPermission = tabledata "Qlty. Inspect. Source Config." = I;
                    ApplicationArea = QualityManagement;
                    Caption = 'Reset all configurations';
                    ToolTip = 'Deletes every source configuration, including custom ones that you have added, and then recreates the defaults shipped with Quality Management.';
                    Image = CheckDuplicates;

                    trigger OnAction()
                    var
                        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(ResetAllConfigurationsQst, false) then
                            exit;

                        QltyAutoConfigure.DeleteAllSourceConfigurations();
                        QltyAutoConfigure.EnsureAtLeastOneSourceConfigurationExist(true);

                        CurrPage.Update(false);
                        Message(ResetAllConfigurationsCompletedMsg);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Category4)
                {
                    Caption = 'Restore defaults';
                    ShowAs = SplitButton;

                    actionref(RecreateMissingDefaultConfigurations_Promoted; RecreateMissingDefaultConfigurations)
                    {
                    }
                    actionref(ResetOnlyDefaultConfigurations_Promoted; ResetOnlyDefaultConfigurations)
                    {
                    }
                    actionref(ResetAllConfigurations_Promoted; ResetAllConfigurations)
                    {
                    }
                }
            }
        }
    }

    var
        RowStyleText: Text;
        RecreateMissingDefaultConfigurationsQst: Label 'This will recreate any missing default source configurations shipped with Quality Management. Existing configurations, including customizations, will not be changed. This action cannot be undone. Do you want to continue?';
        RecreateMissingDefaultConfigurationsCompletedMsg: Label 'The missing default source configurations have been recreated.';
        ResetOnlyDefaultConfigurationsQst: Label 'This will delete and recreate the default source configurations shipped with Quality Management, discarding any customizations you have made to them. Custom source configurations that you have added will be preserved. This action cannot be undone. Do you want to continue?';
        ResetOnlyDefaultConfigurationsCompletedMsg: Label 'The default source configurations have been reset.';
        ResetAllConfigurationsQst: Label 'This will delete every source configuration, including custom ones that you have added, and then recreate the defaults shipped with Quality Management. This action cannot be undone. Do you want to continue?';
        ResetAllConfigurationsCompletedMsg: Label 'All source configurations have been reset to defaults.';

    trigger OnInit()
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        QltyAutoConfigure.EnsureAtLeastOneSourceConfigurationExist(false);
    end;

    trigger OnAfterGetRecord()
    var
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
    begin
        RowStyle := RowStyle::None;

        if not Rec.Enabled then
            RowStyle := RowStyle::Subordinate;

        RowStyleText := Format(RowStyle);
    end;
}
