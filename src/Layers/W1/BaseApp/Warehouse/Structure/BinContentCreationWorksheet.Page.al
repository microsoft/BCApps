// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Reports;

page 7371 "Bin Content Creation Worksheet"
{
    AccessByPermission = TableData Bin = R;
    ApplicationArea = Warehouse;
    AutoSplitKey = true;
    Caption = 'Bin Content Creation Worksheet';
    DataCaptionFields = Name;
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Bin Creation Worksheet Line";
    SourceTableView = sorting("Worksheet Template Name", Name, "Location Code", "Line No.")
                      where(Type = const("Bin Content"));
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
                ToolTip = 'Specifies the name of the worksheet that outlines bin content for a number of bins. You use this worksheet when you want to plan for content of empty bins.';

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
                ToolTip = 'Specifies the location where the warehouse activity takes place. ';
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

                    trigger OnValidate()
                    begin
                        BinCodeOnAfterValidate();
                    end;
                }
                field("Bin Type Code"; Rec."Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the bin type or bin content that should be created.';
                    Visible = false;
                }
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the warehouse class of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Bin Ranking"; Rec."Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the ranking of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number for which bin content should be created.';

                    trigger OnValidate()
                    begin
                        BinCreateLine.GetItemDescr(Rec."Item No.", Rec."Variant Code", ItemDescription);
                        BinCreateLine.GetUnitOfMeasureDescr(Rec."Unit of Measure Code", UOMDescription);
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        VariantCodeOnAfterValidate();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        BinCreateLine.GetUnitOfMeasureDescr(Rec."Unit of Measure Code", UOMDescription);
                    end;
                }
                field("Min. Qty."; Rec."Min. Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the minimum quantity for the bin content that should be created.';
                    Visible = false;
                }
                field("Max. Qty."; Rec."Max. Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum quantity for the bin content that should be created.';
                    Visible = false;
                }
                field("Block Movement"; Rec."Block Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how the movement of a particular item, or bin content, into or out of this bin, is blocked.';
                    Visible = false;
                }
                field("Fixed"; Rec.Fixed)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether the bin content that is to be created will be fixed for the item.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is to be the default bin for the item on the bin worksheet line.';
                }
                field("Cross-Dock Bin"; Rec."Cross-Dock Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies new cross-dock bins.';
                    Visible = false;
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                fixed(Control1900116601)
                {
                    ShowCaption = false;
                    group(Control1901742101)
                    {
                        Caption = 'Bin Code';
                        field(BinCode; BinCode)
                        {
                            ApplicationArea = Warehouse;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Item Description';
                            Editable = false;
                            ToolTip = 'Specifies a description of the item in the bin.';
                        }
                    }
                    group("Unit Of Measure Description")
                    {
                        Caption = 'Unit Of Measure Description';
                        field(UOMDescription; UOMDescription)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Unit Of Measure Description';
                            Editable = false;
                            ToolTip = 'Specifies the descriptions for the units of measure that are associated and used with the different items in your inventory.';
                        }
                    }
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
                action(CreateBinContent)
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Create Bin Content';
                    Image = CreateBinContent;
                    ShortCutKey = 'F9';
                    ToolTip = 'View the bin content that you have created in the bin content creation worksheet and view a report listing the bin contents before you actually create the bins.';

                    trigger OnAction()
                    begin
                        BinCreateLine.Copy(Rec);
                        CODEUNIT.Run(CODEUNIT::"Bin Content Create", Rec);
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
                    BinCreateLine.SetRange(Type, BinCreateLine.Type::"Bin Content");
                    REPORT.Run(Report::"Bin Content Create Wksh Report", true, false, BinCreateLine);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateBinContent_Promoted; CreateBinContent)
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BinCreateLine.GetItemDescr(Rec."Item No.", Rec."Variant Code", ItemDescription);
        BinCreateLine.GetUnitOfMeasureDescr(Rec."Unit of Measure Code", UOMDescription);
        BinCode := Rec."Bin Code";
    end;

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
        BinCreateLine.TemplateSelection(PAGE::"Bin Content Creation Worksheet", 1, Rec, WkshSelected);
        if not WkshSelected then
            Error('');
        BinCreateLine.OpenWksh(CurrentJnlBatchName, CurrentLocationCode, Rec);
    end;

    var
        BinCreateLine: Record "Bin Creation Worksheet Line";
        CurrentLocationCode: Code[10];
        CurrentJnlBatchName: Code[10];
        BinCode: Code[20];
        ItemDescription: Text[100];
        UOMDescription: Text[50];
        OpenedFromBatch: Boolean;

    local procedure BinCodeOnAfterValidate()
    begin
        BinCreateLine.GetItemDescr(Rec."Item No.", Rec."Variant Code", ItemDescription);
        BinCreateLine.GetUnitOfMeasureDescr(Rec."Unit of Measure Code", UOMDescription);
        BinCode := Rec."Bin Code";
    end;

    local procedure VariantCodeOnAfterValidate()
    begin
        BinCreateLine.GetItemDescr(Rec."Item No.", Rec."Variant Code", ItemDescription);
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        BinCreateLine.SetName(CurrentJnlBatchName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;
}

