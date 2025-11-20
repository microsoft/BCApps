// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Reports;

page 7372 "Bin Creation Worksheet"
{
    AccessByPermission = TableData Bin = R;
    ApplicationArea = Warehouse;
    AutoSplitKey = true;
    Caption = 'Bin Creation Worksheet';
    DataCaptionFields = Name;
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Bin Creation Worksheet Line";
    SourceTableView = sorting("Worksheet Template Name", Name, "Location Code", "Line No.")
                      where(Type = const(Bin));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Warehouse;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the bin creation worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    BinCreateLine.LookupBinCreationName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    BinCreateLine.CheckName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Location;
                Caption = 'Location Code';
                Editable = false;
                Lookup = true;
                TableRelation = Location;
                ToolTip = 'Specifies the location where the bins exist.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone where the bin on the worksheet will be located.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description for the bin that should be created.';
                }
                field("Bin Type Code"; Rec."Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin type or bin content that should be created.';
                    Visible = false;
                }
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Block Movement"; Rec."Block Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how the movement of a particular item, or bin content, into or out of this bin, is blocked.';
                    Visible = false;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the special equipment code of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Bin Ranking"; Rec."Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ranking of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Maximum Cubage"; Rec."Maximum Cubage")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum cubage of the bin that should be created.';
                    Visible = false;
                }
                field("Maximum Weight"; Rec."Maximum Weight")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum weight of the bin that should be created.';
                    Visible = false;
                }
                field("Cross-Dock Bin"; Rec."Cross-Dock Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies new cross-dock bins.';
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateBins)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate &Bins';
                    Ellipsis = true;
                    Image = SuggestBin;
                    ToolTip = 'Generate bin replenishment lines.';

                    trigger OnAction()
                    begin
                        BinCreateWksh.SetTemplAndWorksheet(Rec."Worksheet Template Name", Rec.Name, CurrentLocationCode);
                        BinCreateWksh.RunModal();
                        Clear(BinCreateWksh);
                    end;
                }
                action("&Create Bins")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Create Bins';
                    Image = CreateBins;
                    ShortCutKey = 'F9';
                    ToolTip = 'Create the bins that you have defined in the worksheet.';

                    trigger OnAction()
                    begin
                        BinCreateLine.Copy(Rec);
                        Rec.SetFilter("Bin Code", '<>%1', '');
                        CODEUNIT.Run(CODEUNIT::"Bin Create", Rec);
                        BinCreateLine.Reset();
                        Rec.Copy(BinCreateLine);
                        Rec.FilterGroup(2);
                        Rec.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                        Rec.SetRange(Name, Rec.Name);
                        Rec.SetRange("Location Code", CurrentLocationCode);
                        Rec.FilterGroup(0);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    BinCreateLine.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                    BinCreateLine.SetRange(Name, Rec.Name);
                    BinCreateLine.SetRange("Location Code", Rec."Location Code");
                    BinCreateLine.SetRange(Type, BinCreateLine.Type::Bin);
                    REPORT.Run(Report::"Bin Creation Wksh. Report", true, false, BinCreateLine);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CalculateBins_Promoted; CalculateBins)
                {
                }
                actionref("&Create Bins_Promoted"; "&Create Bins")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(Rec.GetRangeMax("Worksheet Template Name"));
    end;

    trigger OnOpenPage()
    var
        WkshSelected: Boolean;
    begin
        OpenedFromBatch := (Rec.Name <> '') and (Rec."Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec.Name;
            CurrentLocationCode := Rec."Location Code";
            BinCreateLine.OpenWksh(CurrentJnlBatchName, CurrentLocationCode, Rec);
            exit;
        end;
        BinCreateLine.TemplateSelection(PAGE::"Bin Creation Worksheet", 0, Rec, WkshSelected);
        if not WkshSelected then
            Error('');
        BinCreateLine.OpenWksh(CurrentJnlBatchName, CurrentLocationCode, Rec);
    end;

    var
        BinCreateLine: Record "Bin Creation Worksheet Line";
        BinCreateWksh: Report "Calculate Bins";
        CurrentLocationCode: Code[10];
        CurrentJnlBatchName: Code[10];
        OpenedFromBatch: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        BinCreateLine.SetName(CurrentJnlBatchName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;
}

