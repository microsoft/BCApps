// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Loaner;
using Microsoft.Service.Setup;

page 6272 "Service Order Archive Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Item Line Archive";
    SourceTableView = where("Document Type" = const(Order));

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field(ServiceItemNo; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    Visible = true;
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
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Service;
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
                field("Repair Status Code"; Rec."Repair Status Code")
                {
                    ApplicationArea = Service;
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
                    ToolTip = 'Specifies the starting date of the spare parts warranty for this item.';
                    Visible = false;
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the spare parts warranty for this item.';
                    Visible = false;
                }
                field("Warranty % (Parts)"; Rec."Warranty % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of spare parts costs covered by the warranty for this item.';
                    Visible = false;
                }
                field("Warranty % (Labor)"; Rec."Warranty % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of labor costs covered by the warranty for this item.';
                    Visible = false;
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the labor warranty for this item.';
                    Visible = false;
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the labor warranty for this item.';
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
                }
                field("Adjustment Type"; Rec."Adjustment Type")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Base Amount to Adjust"; Rec."Base Amount to Adjust")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    Visible = SymptomCodeVisible;
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    Visible = FaultCodeVisible;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    Visible = ResolutionCodeVisible;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated hours from order creation, to the time when the repair status of the item line changes from Initial, to In Process.';
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
                    LookupPageID = "Available Loaners";
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
                action("Resource &Allocations")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource &Allocations';
                    Image = ResourcePlanning;
                    ToolTip = 'View or allocate resources, such as technicians or resource groups to service items. The allocation can be made by resource number or resource group number, allocation date and allocated hours.';

                    trigger OnAction()
                    var
                        ServiceOrderAllocatArchive: Record "Service Order Allocat. Archive";
                        ServiceOrderAllocatArchivePage: Page "Service Order Allocat. Archive";
                    begin
                        ServiceOrderAllocatArchive.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
                        ServiceOrderAllocatArchive.FilterGroup(2);
                        ServiceOrderAllocatArchive.SetRange("Document Type", Rec."Document Type");
                        ServiceOrderAllocatArchive.SetRange("Document No.", Rec."Document No.");
                        ServiceOrderAllocatArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
                        ServiceOrderAllocatArchive.SetRange("Version No.", Rec."Version No.");
                        ServiceOrderAllocatArchive.FilterGroup(0);
                        ServiceOrderAllocatArchive.SetRange("Service Item Line No.", Rec."Line No.");
                        if ServiceOrderAllocatArchive.FindFirst() then;
                        ServiceOrderAllocatArchive.SetRange("Service Item Line No.");

                        ServiceOrderAllocatArchivePage.SetRecord(ServiceOrderAllocatArchive);
                        ServiceOrderAllocatArchivePage.SetTableView(ServiceOrderAllocatArchive);
                        ServiceOrderAllocatArchivePage.SetRecord(ServiceOrderAllocatArchive);
                        ServiceOrderAllocatArchivePage.Run();
                    end;
                }
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
                        ToolTip = 'View different fault codes that you assigned to service items. You can use fault codes to identify the different service item faults or the actions taken on service items for each combination of fault area and symptom codes.';

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
                        ToolTip = 'View different resolution codes that assigned to service items. You can use resolution codes to identify methods used to solve typical service problems.';

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
                        ToolTip = 'View internal comments for the service item. Internal comments are for internal use only and are not printed on reports.';

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
                        ToolTip = 'View comments for the accessories to the service item.';

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
            }
            group("&Order")
            {
                Caption = 'Order';
                Image = Quote;
                action(ServiceArchiveLines)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Archive Lines';
                    Image = ServiceLines;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'View the related service archived lines.';

                    trigger OnAction()
                    begin
                        ShowServiceArchiveLines();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.SetLoadFields("Fault Reporting Level");
        ServiceMgtSetup.Get();
        case ServiceMgtSetup."Fault Reporting Level" of
            ServiceMgtSetup."Fault Reporting Level"::None:
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := false;
                    FaultCodeVisible := false;
                    ResolutionCodeVisible := false;
                end;
            ServiceMgtSetup."Fault Reporting Level"::Fault:
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := false;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
            ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom":
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := true;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
            ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)":
                begin
                    FaultAreaCodeVisible := true;
                    SymptomCodeVisible := true;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
        end;
    end;

    var
        FaultAreaCodeVisible: Boolean;
        SymptomCodeVisible: Boolean;
        FaultCodeVisible: Boolean;
        ResolutionCodeVisible: Boolean;

    local procedure ShowServiceArchiveLines()
    var
        ServiceLineArchive: Record "Service Line Archive";
        ServiceOrderArchiveLines: Page "Service Order Archive Lines";
    begin
        ServiceLineArchive.FilterGroup(2);
        ServiceLineArchive.SetRange("Document Type", Rec."Document Type");
        ServiceLineArchive.SetRange("Document No.", Rec."Document No.");
        ServiceLineArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
        ServiceLineArchive.SetRange("Version No.", Rec."Version No.");
        ServiceLineArchive.FilterGroup(0);
        ServiceOrderArchiveLines.Initialize(Rec."Line No.");
        ServiceOrderArchiveLines.SetTableView(ServiceLineArchive);
        ServiceOrderArchiveLines.RunModal();
    end;
}