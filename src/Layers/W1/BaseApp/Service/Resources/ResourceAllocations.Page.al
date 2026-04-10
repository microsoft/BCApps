// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Analysis;
using Microsoft.Service.Document;

page 6005 "Resource Allocations"
{
    Caption = 'Resource Allocations';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Service Order Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Jobs;
                    Visible = true;
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Service Item Description"; Rec."Service Item Description")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;

                    trigger OnValidate()
                    begin
                        ResourceNoOnAfterValidate();
                    end;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Allocation Date"; Rec."Allocation Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Jobs;
                    DecimalPlaces = 1 : 2;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action(ResourceAvailability)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Resource Availability';
                    Image = Calendar;
                    ToolTip = 'View the work calendar of the selected resource.';

                    trigger OnAction()
                    begin
                        Clear(ResAvailability);
                        ResAvailability.SetData(
                          Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Service Item Line No.", Rec."Entry No.");
                        if Rec."Resource No." <> '' then begin
                            Res.Get(Rec."Resource No.");
                            ResAvailability.SetRecord(Res);
                        end;
                        ResAvailability.RunModal();
                    end;
                }
                action(ResGroupAvailability)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Res. &Group Availability';
                    Image = Calendar;
                    ToolTip = 'View allocations per resource group, such as the entire capacity, the quantity allocated to projects on order, the quantity available after quotes, the quantity assigned to projects on quote, and the remaining capacity after all projects on quote or order.';

                    trigger OnAction()
                    begin
                        Clear(ResGrAvailability);
                        ResGrAvailability.SetData(Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Entry No.");
                        if Rec."Resource Group No." <> '' then begin
                            ResGr.Get(Rec."Resource Group No.");
                            ResGrAvailability.SetRecord(ResGr);
                        end;
                        ResGrAvailability.RunModal();
                    end;
                }
                action("Canceled Allocation &Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Canceled Allocation &Entries';
                    Image = CancelledEntries;
                    ToolTip = 'View the list of service order allocation entries that have been canceled.';

                    trigger OnAction()
                    begin
                        Clear(CanceledAllocEntries);
                        ServOrderAlloc.Reset();
                        ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", Status);
                        ServOrderAlloc.SetRange("Document Type", Rec."Document Type");
                        ServOrderAlloc.SetRange("Document No.", Rec."Document No.");
                        ServOrderAlloc.SetFilter(Status, '%1', ServOrderAlloc.Status::Canceled);
                        CanceledAllocEntries.SetTableView(ServOrderAlloc);
                        CanceledAllocEntries.SetRecord(ServOrderAlloc);
                        CanceledAllocEntries.Run();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Cancel Allocation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Cancel Allocation';
                    Image = Cancel;
                    ToolTip = 'Remove the current allocation of the resource.';

                    trigger OnAction()
                    var
                        ServOrderAllocMgt: Codeunit ServAllocationManagement;
                    begin
                        Clear(ServOrderAllocMgt);
                        ServOrderAllocMgt.CancelAllocation(Rec);
                    end;
                }
                action("Allocate to &all Service Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Allocate to &all Service Items';
                    Image = Allocate;
                    ToolTip = 'Allocate the same resource, for example, a technician, or resource group to all the service items in a service order.';

                    trigger OnAction()
                    begin
                        Clear(ServOrderAllocMgt);
                        ServOrderAllocMgt.SplitAllocation(Rec);
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Service Item Line No." = 0 then begin
            ServItemLine.Reset();
            ServItemLine.SetRange("Document Type", Rec."Document Type");
            ServItemLine.SetRange("Document No.", Rec."Document No.");
            if ServItemLine.Count = 1 then begin
                ServItemLine.FindFirst();
                Rec."Service Item Line No." := ServItemLine."Line No.";
            end;
        end;
    end;

    var
        ServItemLine: Record "Service Item Line";
        ServOrderAlloc: Record "Service Order Allocation";
        Res: Record Resource;
        ResGr: Record "Resource Group";
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        ResAvailability: Page "Res. Availability (Service)";
        ResGrAvailability: Page "Res.Gr. Availability (Service)";
        CanceledAllocEntries: Page "Cancelled Allocation Entries";

    local procedure ResourceNoOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

