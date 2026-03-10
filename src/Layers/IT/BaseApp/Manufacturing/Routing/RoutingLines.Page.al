// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Manufacturing.Capacity;
#if not CLEAN27
using Microsoft.Manufacturing.Document;
#endif

page 99000765 "Routing Lines"
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

                    trigger OnValidate()
                    begin
                        SetEditable();
                    end;
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
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
                    Editable = UnitCostPerEditable;
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
#if not CLEAN27
                field("WIP Item"; Rec."WIP Item")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the item is a work in process (WIP) item.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
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
                action("&Tools")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Tools';
                    Image = Tools;
                    ToolTip = 'View or edit information about tools that are assigned to the operation.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowTools();
                    end;
                }
                action("&Personnel")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Personnel';
                    Image = User;
                    ToolTip = 'View or edit the personnel that are assigned to the operation.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowPersonnel();
                    end;
                }
                action("&Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Quality Measures';
                    ToolTip = 'View or edit the quality details that are assigned to the operation.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowQualityMeasures();
                    end;
                }
#if not CLEAN27
                action("Subcontracting Prices")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Prices';
                    Image = Price;
                    ToolTip = 'View the related subcontracting prices.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnAction()
                    begin
                        ShowSubcPrices();
                    end;
                }
#endif
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowRelatedDataEnabled := Rec."Operation No." <> '';
        SetEditable();
    end;

    trigger OnInit()
    begin
        UnitCostPerEditable := true;
    end;

    var
        RtngComment: Record "Routing Comment Line";
        ShowRelatedDataEnabled: Boolean;
        UnitCostPerEditable: Boolean;

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

#if not CLEAN27
    [Obsolete('Preparation for replacement by Subcontracting app', '27.0')]
    [Scope('OnPrem')]
    procedure ShowSubcPrices()
    var
        SubcPrice: Record "Subcontractor Prices";
    begin
        Rec.TestField(Type, Rec.Type::"Work Center");
        SubcPrice.SetRange("Work Center No.", Rec."No.");
        if Rec."Standard Task Code" <> '' then
            SubcPrice.SetRange("Standard Task Code", Rec."Standard Task Code")
        else
            SubcPrice.SetRange("Standard Task Code");

        PAGE.Run(PAGE::"Subcontracting Prices", SubcPrice);
    end;
#endif

    local procedure SetEditable()
    begin
        UnitCostPerEditable := Rec.Type = "Capacity Type Routing"::"Work Center";
    end;
}

