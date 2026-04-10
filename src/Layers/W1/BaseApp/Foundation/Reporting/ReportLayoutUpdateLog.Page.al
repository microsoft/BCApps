// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

page 9656 "Report Layout Update Log"
{
    Caption = 'Report Layout Update Log';
    Editable = false;
    PageType = List;
    SourceTable = "Report Layout Update Log";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report ID';
                }
                field("Layout Description"; Rec."Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Description';
                }
                field("Layout Type"; Rec."Layout Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Type';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Message';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
#if not CLEAN28
            action(Edit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
                ToolTip = 'Edit a report layout.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by system page "Report Layouts". This action will be removed in a future version.';
                ObsoleteTag = '28.0';

                trigger OnAction()
                var
                    CustomReportLayout: Record "Custom Report Layout";
                begin
                    CustomReportLayout.SetFilter("Report ID", Format(Rec."Report ID"));
                    CustomReportLayout.SetFilter(Description, Rec."Layout Description");
                    if CustomReportLayout.FindFirst() then
#pragma warning disable AL0432
                        PAGE.Run(PAGE::"Custom Report Layouts", CustomReportLayout);
#pragma warning restore AL0432
                end;
            }
#endif
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
#if not CLEAN28
                actionref(Edit_Promoted; Edit)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by system page "Report Layouts". This action will be removed in a future version.';
                    ObsoleteTag = '28.0';
                }
#endif
            }
        }
    }
}

