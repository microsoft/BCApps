// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Automation;

page 324 "Reservation Wksh. Batch Card"
{
    PageType = Card;
    ApplicationArea = Reservation;
    SourceTable = "Reservation Wksh. Batch";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the reservation worksheet you are creating.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a brief description of the reservation worksheet name you are creating.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';

                field("Demand Type"; Rec."Demand Type")
                {
                    Caption = 'Demand Type';
                    ToolTip = 'Specifies the type of demand that the reservation worksheet will be used for.';
                }
                field("Start Date Formula"; Rec."Start Date Formula")
                {
                    Caption = 'Start Date Formula';
                    ToolTip = 'Specifies the formula that is used to calculate the start date for the reservation worksheet.';
                }
                field("End Date Formula"; Rec."End Date Formula")
                {
                    Caption = 'End Date Formula';
                    ToolTip = 'Specifies the formula that is used to calculate the end date for the reservation worksheet.';
                }
                field("Item Filter"; ItemFilter)
                {
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the filter that is used to select the items that will be included in the reservation worksheet.';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        ItemFilterXMLText: Text;
                    begin
                        ItemFilterXMLText := ItemFilterDrillDown(Rec.GetItemFilterBlobAsText());
                        if ItemFilterXMLText <> '' then begin
                            Rec.SetTextFilterToItemFilterBlob(ItemFilterXMLText);
                            Rec.Modify();
                            ItemFilter := Rec.GetItemFilterAsDisplayText();
                        end;
                    end;
                }
                field("Variant Filter"; VariantFilter)
                {
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies the filter that is used to select the variants that will be included in the reservation worksheet.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupVariantFilter(Text));
                    end;

                    trigger OnValidate()
                    var
                        ItemVariant: Record "Item Variant";
                    begin
                        ItemVariant.SetFilter(Code, VariantFilter);
                        VariantFilter := ItemVariant.GetFilter(Code);
                        Rec.SetTextFilterToVariantFilterBlob(VariantFilter);
                        Rec.Modify();
                    end;
                }
                field("Location Filter"; LocationFilter)
                {
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the filter that is used to select the locations that will be included in the reservation worksheet.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupLocationFilter(Text));
                    end;

                    trigger OnValidate()
                    var
                        Location: Record Location;
                    begin
                        Location.SetFilter(Code, LocationFilter);
                        LocationFilter := Location.GetFilter(Code);
                        Rec.SetTextFilterToLocationFilterBlob(LocationFilter);
                        Rec.Modify();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action("Allocation Policies")
            {
                Caption = 'Allocation Policies';
                Image = Allocations;
                Ellipsis = true;
                ToolTip = 'Set up allocation policies for the batch';

                trigger OnAction();
                var
                    AllocationPolicy: Record "Allocation Policy";
                begin
                    AllocationPolicy.SetRange("Journal Batch Name", Rec.Name);
                    if Page.RunModal(Page::"Allocation Policies", AllocationPolicy) = Action::LookupOK then;
                end;
            }
        }
        area(Promoted)
        {
            actionref("Allocation Policies_Promoted"; "Allocation Policies")
            {

            }
        }
    }

    var
        ItemFilter: Text;
        VariantFilter: Text;
        LocationFilter: Text;

    trigger OnAfterGetRecord()
    begin
        ItemFilter := Rec.GetItemFilterAsDisplayText();
        VariantFilter := Rec.GetVariantFilterBlobAsText();
        LocationFilter := Rec.GetLocationFilterBlobAsText();
    end;

    local procedure ItemFilterDrillDown(ItemFilterBlobText: Text): Text
    var
        Item: Record Item;
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPage: FilterPageBuilder;
        ItemCaptionTxt: Code[20];
    begin
        ItemCaptionTxt := CopyStr(Item.TableCaption(), 1, MaxStrLen(ItemCaptionTxt));
        RequestPageParametersHelper.BuildDynamicRequestPage(FilterPage, ItemCaptionTxt, Database::Item);
        RequestPageParametersHelper.SetViewOnDynamicRequestPage(FilterPage, ItemFilterBlobText, ItemCaptionTxt, Database::Item);
        FilterPage.PageCaption := ItemCaptionTxt;
        if not FilterPage.RunModal() then
            exit;
        exit(RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPage, ItemCaptionTxt, Database::Item));
    end;

    local procedure LookupLocationFilter(var LookupText: Text): Boolean
    var
        Location: Record Location;
        LocationList: Page "Location List";
    begin
        Location.SetRange("Use As In-Transit", false);
        LocationList.SetTableView(Location);
        LocationList.LookupMode(true);
        if LocationList.RunModal() = ACTION::LookupOK then begin
            LookupText := LocationList.GetSelectionFilter();
            exit(true);
        end;

        exit(false);
    end;

    local procedure LookupVariantFilter(var LookupText: Text): Boolean
    var
        ItemVariant: Record "Item Variant";
        ItemVariantList: Page "Item Variants";
    begin
        ItemVariantList.LookupMode(true);
        ItemVariantList.SetTableView(ItemVariant);
        if ItemVariantList.RunModal() = ACTION::LookupOK then begin
            LookupText := ItemVariantList.GetSelectionFilter();
            exit(true);
        end;

        exit(false);
    end;
}
