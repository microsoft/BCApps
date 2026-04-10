// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;

page 5976 "Posted Service Shpt. Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Shipment Item Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Comment"; Rec."Fault Comment")
                {
                    ApplicationArea = Service;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowComments(1);
                    end;
                }
                field("Resolution Comment"; Rec."Resolution Comment")
                {
                    ApplicationArea = Service;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowComments(2);
                    end;
                }
                field("Service Shelf No."; Rec."Service Shelf No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the warranty starts on the service item spare parts.';
                    Visible = false;
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the spare parts warranty expires for this service item.';
                    Visible = false;
                }
                field("Warranty % (Parts)"; Rec."Warranty % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of spare parts costs covered by the warranty for this service item.';
                    Visible = false;
                }
                field("Warranty % (Labor)"; Rec."Warranty % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of labor costs covered by the warranty on this service item.';
                    Visible = false;
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the labor warranty for the posted service item starts.';
                    Visible = false;
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the labor warranty expires on the posted service item.';
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated hours between the creation of the service order, to the time when the repair status changes from Initial, to In Process.';
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                }
                field("Loaner No."; Rec."Loaner No.")
                {
                    ApplicationArea = Service;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                group("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    action(Faults)
                    {
                        ApplicationArea = Service;
                        Caption = 'Faults';
                        Image = Error;
                        ToolTip = 'View or edit the different fault codes that you can assign to service items. You can use fault codes to identify the different service item faults or the actions taken on service items for each combination of fault area and symptom codes.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments(1);
                        end;
                    }
                    action(Resolutions)
                    {
                        ApplicationArea = Service;
                        Caption = 'Resolutions';
                        Image = Completed;
                        ToolTip = 'View or edit the different resolution codes that you can assign to service items. You can use resolution codes to identify methods used to solve typical service problems.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments(2);
                        end;
                    }
                    action(Internal)
                    {
                        ApplicationArea = Service;
                        Caption = 'Internal';
                        Image = Comment;
                        ToolTip = 'View or reregister internal comments for the service item. Internal comments are for internal use only and are not printed on reports.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments(4);
                        end;
                    }
                    action(Accessories)
                    {
                        ApplicationArea = Service;
                        Caption = 'Accessories';
                        Image = ServiceAccessories;
                        ToolTip = 'View or register comments for the accessories to the service item.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments(3);
                        end;
                    }
                    action("Lent Loaners")
                    {
                        ApplicationArea = Service;
                        Caption = 'Lent Loaners';
                        ToolTip = 'View the loaners that have been lend out temporarily to replace the service item.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments(5);
                        end;
                    }
                }
                action("Service Item &Log")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item &Log';
                    Image = Log;
                    ToolTip = 'View a list of the service item changes that have been logged, for example, when the warranty has changed or a component has been added. This window displays the field that was changed, the old value and the new value, and the date and time that the field was changed.';

                    trigger OnAction()
                    begin
                        ShowServItemEventLog();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Receive Loaner")
                {
                    ApplicationArea = Service;
                    Caption = '&Receive Loaner';
                    Image = ReceiveLoaner;
                    ToolTip = 'Record that the loaner is received at your company.';

                    trigger OnAction()
                    begin
                        ReceiveLoaner();
                    end;
                }
            }
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action(ServiceShipmentLines)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Shipment Lines';
                    Image = ShipmentLines;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'View the related shipment line.';

                    trigger OnAction()
                    begin
                        ShowServShipmentLines();
                    end;
                }
            }
        }
    }

    var
        ServLoanerMgt: Codeunit ServLoanerManagement;
#pragma warning disable AA0074
        Text000: Label 'You can view the Service Item Log only for service item lines with the specified Service Item No.';
#pragma warning restore AA0074

    local procedure ShowServShipmentLines()
    var
        ServShipmentLine: Record "Service Shipment Line";
        ServShipmentLines: Page "Posted Service Shipment Lines";
    begin
        Rec.TestField("No.");
        Clear(ServShipmentLine);
        ServShipmentLine.SetRange("Document No.", Rec."No.");
        ServShipmentLine.FilterGroup(2);
        Clear(ServShipmentLines);
        ServShipmentLines.Initialize(Rec."Line No.");
        ServShipmentLines.SetTableView(ServShipmentLine);
        ServShipmentLines.RunModal();
        ServShipmentLine.FilterGroup(0);
    end;

    procedure ReceiveLoaner()
    begin
        ServLoanerMgt.ReceiveLoanerShipment(Rec);
    end;

    local procedure ShowServItemEventLog()
    var
        ServItemLog: Record "Service Item Log";
    begin
        if Rec."Service Item No." = '' then
            Error(Text000);
        Clear(ServItemLog);
        ServItemLog.SetRange("Service Item No.", Rec."Service Item No.");
        PAGE.RunModal(PAGE::"Service Item Log", ServItemLog);
    end;
}

