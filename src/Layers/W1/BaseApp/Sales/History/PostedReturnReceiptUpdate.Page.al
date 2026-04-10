// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Foundation.Address;

/// <summary>
/// Provides editing capabilities for specific fields on posted sales return receipts that can be modified after posting.
/// </summary>
page 1353 "Posted Return Receipt - Update"
{
    Caption = 'Posted Return Receipt - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Return Receipt Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer';
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                group(BillToCounty)
                {
                    ShowCaption = false;
                    Visible = IsBillToCountyVisible;
                    field("Bill-to County"; Rec."Bill-to County")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Editable = true;
                    }
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = true;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Agent';
                    Editable = true;
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ActivateFields();
    end;

    trigger OnOpenPage()
    begin
        xReturnReceiptHeader := Rec;
        ActivateFields();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Return Receipt Header - Edit", Rec);
    end;

    var
        xReturnReceiptHeader: Record "Return Receipt Header";
        FormatAddress: Codeunit "Format Address";
        IsBillToCountyVisible: Boolean;

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
            (Rec."Bill-to County" <> xReturnReceiptHeader."Bill-to County") or
            (Rec."Bill-to Country/Region Code" <> xReturnReceiptHeader."Bill-to Country/Region Code") or
            (Rec."Shipping Agent Code" <> xReturnReceiptHeader."Shipping Agent Code") or
            (Rec."Package Tracking No." <> xReturnReceiptHeader."Package Tracking No.");

        OnAfterRecordChanged(Rec, xRec, IsChanged, xReturnReceiptHeader);
    end;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
    end;

    /// <summary>
    /// Sets the record for this page to edit.
    /// </summary>
    /// <param name="ReturnReceiptHeader">The return receipt header to edit.</param>
    procedure SetRec(ReturnReceiptHeader: Record "Return Receipt Header")
    begin
        Rec := ReturnReceiptHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var ReturnReceiptHeader: Record "Return Receipt Header"; xReturnReceiptHeader: Record "Return Receipt Header"; var IsChanged: Boolean; xReturnReceiptHeaderGlobal: Record "Return Receipt Header");
    begin
    end;
}

