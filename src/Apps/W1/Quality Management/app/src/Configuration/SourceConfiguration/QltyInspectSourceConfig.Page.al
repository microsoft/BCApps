// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.QualityManagement.Configuration;
using System.Utilities;

/// <summary>
/// Use this page to configure what will automatically populate from other tables into your quality inspections. This is also used to tell Business Central how to find one record from another, by setting which field in the ''From'' table connects to which field in the ''To'' table.
/// </summary>
page 20410 "Qlty. Inspect. Source Config."
{
    Caption = 'Quality Inspection Source Configuration';
    DataCaptionExpression = GetDataCaptionExpression();
    PageType = ListPlus;
    SourceTable = "Qlty. Inspect. Source Config.";
    RefreshOnActivate = true;
    UsageCategory = None;
    ApplicationArea = QualityManagement;
    AboutTitle = 'Populating data from tables in Business Central';
    AboutText = 'This page defines how data is automatically populated into quality inspections from other tables, including how records are linked between source and target tables. These configurations should not be changed under normal circumstances and should only be modified as part of advanced configuration by users who understand the impact of their changes.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    trigger OnValidate()
                    begin
                        if xRec.Code = '' then
                            CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
            group(Configuration)
            {
                Caption = 'Configuration';

                group(From)
                {
                    Caption = 'From';

                    field(BlankLinePlaceHolder; BlankLineText)
                    {
                        ShowCaption = false;
                    }
                    field("From Table No."; Rec."From Table No.")
                    {
                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    field("From Table Name"; Rec."From Table Caption")
                    {
                    }
                    field("From Table Filter"; Rec."From Table Filter")
                    {
                        AboutTitle = 'Refine when to connect to another table';
                        AboutText = 'Use this filter to define conditions for when to connect to a different table. This can be used when a source table could refer to multiple different tables.';
                    }
                }
                group(To)
                {
                    Caption = 'To';

                    field("To Type"; Rec."To Type")
                    {
                        trigger OnValidate()
                        begin
                            UpdateControls();
                            CurrPage.Update();
                        end;
                    }
                    group(ToTableVisibilityWrapper)
                    {
                        Caption = '';
                        ShowCaption = false;
                        Visible = ShowToTable;

                        field("To Table No."; Rec."To Table No.")
                        {
                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                        field("To Table Name"; Rec."To Table Caption")
                        {
                        }
                    }
                }
            }
            part(Fields; "Qlty. Source Config Line Part")
            {
                Caption = 'Fields';
                SubPageLink = Code = field(Code);
                SubPageView = sorting(Code, "Line No.");
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
            action(ResetDefaultConfiguration)
            {
                AccessByPermission = tabledata "Qlty. Inspect. Source Config." = I;
                ApplicationArea = QualityManagement;
                Caption = 'Reset default configuration';
                ToolTip = 'Resets this default source configuration shipped with Quality Management, discarding any customizations made to it.';
                Image = RefreshText;
                Visible = IsShippedDefault;

                trigger OnAction()
                var
                    QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ResetDefaultConfigurationQst, Rec.Code), false) then
                        exit;

                    QltyAutoConfigure.ResetShippedDefaultSourceConfiguration(Rec.Code);

                    CurrPage.Update(false);
                    Message(StrSubstNo(ResetDefaultConfigurationCompletedMsg, Rec.Code));
                end;
            }
        }
        area(Promoted)
        {
            actionref(ResetDefaultConfiguration_Promoted; ResetDefaultConfiguration)
            {
            }
        }
    }

    var
        ShowToTable: Boolean;
        IsShippedDefault: Boolean;
        BlankLineText: Text;
        DataCaptionExprLbl: Label '%1 - %2 - %3', Locked = true, Comment = '%1=the code for this configuration, %2=The table to connect from, %3=the Table to connect to.';
        ResetDefaultConfigurationQst: Label 'This will reset the default source configuration %1, discarding any customizations you have made to it. This action cannot be undone. Do you want to continue?', Comment = '%1=the code of the source configuration to reset';
        ResetDefaultConfigurationCompletedMsg: Label 'The default source configuration %1 has been reset.', Comment = '%1=the code of the source configuration that was reset';

    trigger OnOpenPage()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        ShowToTable := Rec."To Type" <> Rec."To Type"::Inspection;
        IsShippedDefault := QltyAutoConfigure.IsShippedDefaultSourceConfiguration(Rec.Code);
    end;

    local procedure GetDataCaptionExpression(): Text
    begin
        exit(StrSubstNo(DataCaptionExprLbl, Rec.Code, Rec."From Table Caption", Rec."To Table Caption"));
    end;
}
