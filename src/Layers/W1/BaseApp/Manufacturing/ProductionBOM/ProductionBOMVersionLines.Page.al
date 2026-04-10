// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;

page 99000789 "Production BOM Version Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DataCaptionFields = "Production BOM No.";
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Production BOM Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
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
                field("Calculation Formula"; Rec."Calculation Formula")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
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
            action(SelectMultiItems)
            {
                AccessByPermission = TableData Item = R;
                ApplicationArea = Manufacturing;
                Caption = 'Select items';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more items from the list of your inventory items.';

                trigger OnAction()
                begin
                    Rec.SelectMultipleItems();
                end;
            }
            group("&Component")
            {
                Caption = '&Component';
                Image = Components;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        ShowComment();
                    end;
                }
                action("Where-Used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    begin
                        ShowWhereUsed();
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Production BOM No.")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Production BOM No.", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Version Code")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Version Code", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(CopyStr(CurrPage.ObjectId(false), 1, 240), Page::"Production BOM Version Lines", EditinExcelFilters, StrSubstNo(ExcelFileNameTxt, Rec."Production BOM No.", Rec."Version Code"));
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
    end;

    local procedure ShowComment()
    var
        ProdOrderCompComment: Record "Production BOM Comment Line";
    begin
        ProdOrderCompComment.SetRange("Production BOM No.", Rec."Production BOM No.");
        ProdOrderCompComment.SetRange("BOM Line No.", Rec."Line No.");
        ProdOrderCompComment.SetRange("Version Code", Rec."Version Code");

        PAGE.Run(PAGE::"Prod. Order BOM Cmt. Sheet", ProdOrderCompComment);
    end;

    local procedure ShowWhereUsed()
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
    begin
        if Rec.Type = Rec.Type::" " then
            exit;

        ProdBOMVersion.Get(Rec."Production BOM No.", Rec."Version Code");
        case Rec.Type of
            Rec.Type::Item:
                begin
                    Item.Get(Rec."No.");
                    ProdBOMWhereUsed.SetItem(Item, ProdBOMVersion."Starting Date");
                end;
            Rec.Type::"Production BOM":
                begin
                    ProdBOMHeader.Get(Rec."No.");
                    ProdBOMWhereUsed.SetProdBOM(ProdBOMHeader, ProdBOMVersion."Starting Date");
                end;
        end;
        ProdBOMWhereUsed.Run();
    end;

    var
        IsSaaSExcelAddinEnabled: Boolean;
        ExcelFileNameTxt: Label 'Production BOM Version Lines - %1 - %2', Comment = '%1 = Production BOM No., %2 = Version Code';
}

