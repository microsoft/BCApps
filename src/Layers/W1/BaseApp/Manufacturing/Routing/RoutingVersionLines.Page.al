// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000767 "Routing Version Lines"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Routing Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Run Time"; Rec."Run Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Run Time Unit of Meas. Code"; Rec."Run Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit cost for this operation if it is different than the unit cost on the work center or machine center card.';
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Operation")
            {
                Caption = '&Operation';
                Image = Task;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowComment();
                    end;
                }
                action(Tools)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Tools';
                    Image = Tools;
                    ToolTip = 'View or edit information about tools that apply to operations that represent the standard task.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowTools();
                    end;
                }
                action(Personnel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Personnel';
                    Image = User;
                    ToolTip = 'View or edit information about personnel that applies to operations that represent the standard task.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowPersonnel();
                    end;
                }
                action("Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Quality Measures';
                    ToolTip = 'View or edit information about quality measures that apply to operations that represent the standard task.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowQualityMeasures();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowRelatedDataEnabled := Rec."Operation No." <> '';
    end;

    var
        RtngComment: Record "Routing Comment Line";
        ShowRelatedDataEnabled: Boolean;

    local procedure ShowComment()
    begin
        RtngComment.SetRange("Routing No.", Rec."Routing No.");
        RtngComment.SetRange("Operation No.", Rec."Operation No.");
        RtngComment.SetRange("Version Code", Rec."Version Code");

        PAGE.Run(PAGE::"Routing Comment Sheet", RtngComment);
    end;

    local procedure ShowTools()
    var
        RtngTool: Record "Routing Tool";
    begin
        RtngTool.SetRange("Routing No.", Rec."Routing No.");
        RtngTool.SetRange("Version Code", Rec."Version Code");
        RtngTool.SetRange("Operation No.", Rec."Operation No.");

        PAGE.Run(PAGE::"Routing Tools", RtngTool);
    end;

    local procedure ShowPersonnel()
    var
        RtngPersonnel: Record "Routing Personnel";
    begin
        RtngPersonnel.SetRange("Routing No.", Rec."Routing No.");
        RtngPersonnel.SetRange("Version Code", Rec."Version Code");
        RtngPersonnel.SetRange("Operation No.", Rec."Operation No.");

        PAGE.Run(PAGE::"Routing Personnel", RtngPersonnel);
    end;

    local procedure ShowQualityMeasures()
    var
        RtngQltyMeasure: Record "Routing Quality Measure";
    begin
        RtngQltyMeasure.SetRange("Routing No.", Rec."Routing No.");
        RtngQltyMeasure.SetRange("Version Code", Rec."Version Code");
        RtngQltyMeasure.SetRange("Operation No.", Rec."Operation No.");

        PAGE.Run(PAGE::"Routing Quality Measures", RtngQltyMeasure);
    end;
}

