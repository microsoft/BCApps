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
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    Style = Unfavorable;
                    StyleExpr = Rec."Total Quantity" = 0;
                    Width = 4;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = JobFieldsVisible;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Visible = JobFieldsVisible;
                }
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = Jobs;
                    Visible = AbsenceCauseVisible;
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    Visible = ChargeableVisible;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Visible = WorkTypeCodeVisible;
                }
                field("Assembly Order No."; Rec."Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    DrillDown = false;
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
