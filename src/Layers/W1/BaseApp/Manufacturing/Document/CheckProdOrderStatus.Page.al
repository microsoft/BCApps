// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Setup;
using Microsoft.Sales.Document;

page 99000833 "Check Prod. Order Status"
{
    Caption = 'Check Prod. Order Status';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'This sales line is currently planned. Your changes will not cause any replanning, so you must manually update the production order if necessary. Do you still want to record the changes?';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies a description of the item.';
                }
                field(LastStatus; LastStatus)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Last Status';
                    Editable = false;
                }
                field(LastOrderType; LastOrderType)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Last Order Type';
                    Editable = false;
                    OptionCaption = 'Production,Purchase';
                }
                field(LastOrderNo; LastOrderNo)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Last Order No.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    var
        MfgSetup: Record "Manufacturing Setup";
        LastStatus: Enum "Production Order Status";
        LastOrderType: Option Production,Purchase;
        LastOrderNo: Code[20];

    [InherentPermissions(PermissionObjectType::TableData, Database::"Manufacturing Setup", 'r')]
    procedure SalesLineShowWarning(SalesLine: Record "Sales Line"): Boolean
    var
        SalesLine2: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if SalesLine."Drop Shipment" then
            exit(false);

        MfgSetup.Get();
        if not MfgSetup."Planning Warning" then
            exit(false);

        if not SalesLine2.Get(
             SalesLine."Document Type",
             SalesLine."Document No.",
             SalesLine."Line No.")
        then
            exit;

        if (SalesLine2.Type <> SalesLine2.Type::Item) or
           (SalesLine2."No." = '') or
           (SalesLine2."Outstanding Quantity" <= 0)
        then
            exit;

        ReservEntry."Source Type" := DATABASE::"Sales Line";
        ReservEntry."Source Subtype" := SalesLine2."Document Type".AsInteger();
        ReservEntry."Item No." := SalesLine2."No.";
        ReservEntry."Variant Code" := SalesLine2."Variant Code";
        ReservEntry."Location Code" := SalesLine2."Location Code";
        ReservEntry."Expected Receipt Date" := SalesLine2."Shipment Date";

        ReservEntry.InitSortingAndFilters(true);
        SalesLine2.SetReservationFilters(ReservEntry);

        if ReservEntry.FindSet() then
            repeat
                if ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                    case ReservEntry2."Source Type" of
                        Database::"Prod. Order Line":
                            if (ReservEntry2."Source Subtype" <> 1) or
                                ((ReservEntry2."Source Subtype" = 1) and (ReservEntry2."Reservation Status" = ReservEntry2."Reservation Status"::Reservation))
                            then begin
                                ProdOrderLine.Get(
                                    ReservEntry2."Source Subtype", ReservEntry2."Source ID", ReservEntry2."Source Prod. Order Line");
                                LastStatus := ProdOrderLine.Status;
                                LastOrderNo := ProdOrderLine."Prod. Order No.";
                                LastOrderType := LastOrderType::Production;
                                exit(true);
                            end;
                    end;
            until ReservEntry.Next() = 0;

        exit(false);
    end;
}

