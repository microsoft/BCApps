// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 946 "Time Sheet Line List"
{
    AutoSplitKey = true;
    Caption = 'Time Sheet Lines';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Time Sheet Line";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                FreezeColumn = Status;
                ShowCaption = false;
                field("Time Sheet No."; Rec."Time Sheet No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the time sheet.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of time sheet line.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information about the status of a time sheet line.';
                    Style = Unfavorable;
                    StyleExpr = Rec."Total Quantity" = 0;
                    Width = 4;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the time sheet line.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number for the project that is associated with the time sheet line.';
                    Visible = JobFieldsVisible;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';
                    Visible = JobFieldsVisible;
                }
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a list of standard absence codes, from which you may select one.';
                    Visible = AbsenceCauseVisible;
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                    Visible = ChargeableVisible;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = WorkTypeCodeVisible;
                }
                field("Assembly Order No."; Rec."Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the assembly order number that is associated with the time sheet line.';
                    Visible = false;
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    DrillDown = false;
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    DecimalPlaces = 0 : 2;
                    Width = 3;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenTimeSheet)
            {
                ApplicationArea = Jobs;
                Scope = Repeater;
                Caption = 'Open Time Sheet Card';
                Image = OpenWorksheet;
                RunObject = page "Time Sheet Card";
                RunPageLink = "No." = field("Time Sheet No.");
                ToolTip = 'Open Time Sheet Card for the record.';
            }
        }
    }


    trigger OnOpenPage()
    begin
        TimeSheetMgt.CheckTimeSheetLineFieldsVisible(WorkTypeCodeVisible, JobFieldsVisible, ChargeableVisible, ServiceOrderNoVisible, AbsenceCauseVisible, AssemblyOrderNoVisible);
    end;


    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        WorkTypeCodeVisible, JobFieldsVisible, ChargeableVisible, AbsenceCauseVisible, AssemblyOrderNoVisible : Boolean;

    protected var
        ServiceOrderNoVisible: Boolean;
}
