// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Document;

pageextension 99000802 "Mfg. Capacity Ledger Entries" extends "Capacity Ledger Entries"
{
    DataCaptionExpression = GetCaption();

    layout
    {
        addafter("Order No.")
        {
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the routing number belonging to the entry.';
                Visible = false;
            }
            field("Routing Reference No."; Rec."Routing Reference No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies that the routing reference number corresponding to the routing reference number of the line.';
                Visible = false;
            }
            field("Work Center No."; Rec."Work Center No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the work center number of the journal line.';
                Visible = false;
            }
        }
        addafter("Document No.")
        {
            field("Operation No."; Rec."Operation No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the operation associated with the entry.';
            }
        }
        addafter(Description)
        {
            field("Work Shift Code"; Rec."Work Shift Code")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the work shift that this machine center was planned at, or in which work shift the related production operation took place.';
                Visible = false;
            }
            field("Starting Time"; Rec."Starting Time")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the starting time of the capacity posted with this entry.';
                Visible = false;
            }
            field("Ending Time"; Rec."Ending Time")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the ending time of the capacity posted with this entry.';
                Visible = false;
            }
            field("Concurrent Capacity"; Rec."Concurrent Capacity")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies how many people have worked concurrently on this entry.';
                Visible = false;
            }
            field("Setup Time"; Rec."Setup Time")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies how long it takes to set up the machines for this entry.';
                Visible = false;
            }
            field("Run Time"; Rec."Run Time")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the run time of this entry.';
                Visible = false;
            }
            field("Stop Time"; Rec."Stop Time")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the stop time of this entry.';
                Visible = false;
            }
        }
        addafter(Quantity)
        {
            field("Output Quantity"; Rec."Output Quantity")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the output quantity, in base units of measure.';
            }
            field("Scrap Quantity"; Rec."Scrap Quantity")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the scrap quantity, in base units of measure.';
            }
        }
        addafter("Global Dimension 2 Code")
        {
            field("Stop Code"; Rec."Stop Code")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the stop code.';
                Visible = false;
            }
            field("Scrap Code"; Rec."Scrap Code")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies why an item has been scrapped.';
                Visible = false;
            }
        }
    }
    actions
    {
        addafter("&Navigate")
        {
            action("Reverse")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Reverse Production Entry';
                Image = ReverseLines;
                ToolTip = 'Reverse a production capacity ledger entry for the selected lines.';
                Ellipsis = true;

                trigger OnAction()
                var
                    CapacityLedgEntry: Record "Capacity Ledger Entry";
                    UndoProdPostingMgmt: Codeunit Microsoft.Manufacturing.Journal."Undo Prod. Posting Mgmt.";
                begin
                    CurrPage.SetSelectionFilter(CapacityLedgEntry);
                    UndoProdPostingMgmt.ReverseCapacityLedgerEntry(CapacityLedgEntry);
                end;
            }
        }
    }

    local procedure GetCaption(): Text
    var
        ObjTransl: Record System.Globalization."Object Translation";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrder: Record "Production Order";
        SourceTableName: Text[250];
        SourceFilter: Text;
        Description: Text[100];
    begin
        Description := '';

        case true of
            Rec.GetFilter("Work Center No.") <> '':
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, Database::"Work Center");
                    SourceFilter := Rec.GetFilter("Work Center No.");
                    if MaxStrLen(WorkCenter."No.") >= StrLen(SourceFilter) then
                        if WorkCenter.Get(SourceFilter) then
                            Description := WorkCenter.Name;
                end;
            (Rec.GetFilter("No.") <> '') and (Rec.GetFilter(Type) = MachineCenter.TableCaption()):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, Database::"Machine Center");
                    SourceFilter := Rec.GetFilter("No.");
                    if MaxStrLen(MachineCenter."No.") >= StrLen(SourceFilter) then
                        if MachineCenter.Get(SourceFilter) then
                            Description := MachineCenter.Name;
                end;
            (Rec.GetFilter("Order No.") <> '') and (Rec."Order Type" = Rec."Order Type"::Production):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, Database::"Production Order");
                    SourceFilter := Rec.GetFilter("Order No.");
                    if MaxStrLen(ProdOrder."No.") >= StrLen(SourceFilter) then
                        if ProdOrder.Get(ProdOrder.Status::Released, SourceFilter) or
                           ProdOrder.Get(ProdOrder.Status::Finished, SourceFilter)
                        then begin
                            SourceTableName := StrSubstNo('%1 %2', ProdOrder.Status, SourceTableName);
                            Description := ProdOrder.Description;
                        end;
                end;
        end;
        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, Description));
    end;
}
