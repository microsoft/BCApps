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
                    ToolTip = 'Specifies the ID of the report object that uses the custom report layout.';
                }
                field("Layout Description"; Rec."Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Description';
                    ToolTip = 'Specifies a description of the report layout.';
                }
                field("Layout Type"; Rec."Layout Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Type';
                    ToolTip = 'Specifies the file type of the report layout. The following table includes the types that are available:';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the report layout update.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the field or element in the report layout that the update pertains to.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Message';
                    ToolTip = 'Specifies detailed information about the update to the report layout. This information is useful when an error occurs to help you fix the error.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
                ToolTip = 'Edit a report layout.';

                trigger OnAction()
                var
                    CustomReportLayout: Record "Custom Report Layout";
                begin
                    CustomReportLayout.SetFilter("Report ID", Format(Rec."Report ID"));
                    CustomReportLayout.SetFilter(Description, Rec."Layout Description");
                    if CustomReportLayout.FindFirst() then
                        PAGE.Run(PAGE::"Custom Report Layouts", CustomReportLayout);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Edit_Promoted; Edit)
                {
                }
            }
        }
    }
}

