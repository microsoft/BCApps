// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.QualityManagement.Configuration;

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

    var
        RowStyleText: Text;

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
