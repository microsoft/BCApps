// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Utilities;
using System.Utilities;

report 6699 "Move Negative Sales Lines"
{
    Caption = 'Move Negative Sales Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Order && Invoice")
                    {
                        Caption = 'Order && Invoice';
                        field(DropDownForOrderAndInvoice; ToDocType)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'To Document Type';
                            Editable = DropDownForOrderAndInvoiceEdit;
                            OptionCaption = ',,,,Return Order,Credit Memo';
                            ToolTip = 'Specifies which document type you want to move the negative sales lines to.';
                        }
                    }
                    group("Return Order && Credit Memo ")
                    {
                        Caption = 'Return Order && Credit Memo ';
                        field(DropDownForRetOrderAndCrMemo; ToDocType2)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'To Document Type';
                            Editable = DropDownForRetOrderAndCrMemoEd;
                            OptionCaption = ',,Order,Invoice';
                            ToolTip = 'Specifies which document type you want to move the negative sales lines to.';
                        }
                    }
                    label(Control4)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19037468;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DropDownForOrderAndInvoiceEdit := true;
            DropDownForRetOrderAndCrMemoEd := true;
        end;

        trigger OnOpenPage()
        begin
            case FromSalesHeader."Document Type" of
                FromSalesHeader."Document Type"::Order:
                    begin
                        ToDocType := ToDocType::"Return Order";
                        ToDocType2 := ToDocType2::Order;
                        FromDocType := FromDocType::Order;
                        DropDownForRetOrderAndCrMemoEd := false;
                    end;
                FromSalesHeader."Document Type"::Invoice:
                    begin
                        ToDocType := ToDocType::"Credit Memo";
                        ToDocType2 := ToDocType2::Invoice;
                        FromDocType := FromDocType::Invoice;
                        DropDownForRetOrderAndCrMemoEd := false;
                    end;
                FromSalesHeader."Document Type"::"Return Order":
                    begin
                        ToDocType2 := ToDocType2::Order;
                        ToDocType := ToDocType::"Return Order";
                        FromDocType := FromDocType::"Return Order";
                        DropDownForOrderAndInvoiceEdit := false;
                    end;
                FromSalesHeader."Document Type"::"Credit Memo":
                    begin
                        ToDocType2 := ToDocType2::Invoice;
                        ToDocType := ToDocType::"Credit Memo";
                        FromDocType := FromDocType::"Credit Memo";
                        DropDownForOrderAndInvoiceEdit := false;
                    end;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport(CopyDocMgt);
        CopyDocMgt.SetProperties(true, false, true, true, true, false, false);
        if (FromDocType = FromDocType::"Return Order") or (FromDocType = FromDocType::"Credit Memo") then
            ToDocType := ToDocType2;
        ToSalesHeader."Document Type" := CopyDocMgt.GetSalesDocumentType("Sales Document Type From".FromInteger(ToDocType));
        OnBeforeCopySalesDoc(FromDocType, FromSalesHeader, ToSalesHeader);
        CopyDocMgt.CopySalesDoc("Sales Document Type From".FromInteger(FromDocType), FromSalesHeader."No.", ToSalesHeader);
    end;

    var
        ToSalesHeader: Record "Sales Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ToDocType: Option ,,"Order",Invoice,"Return Order","Credit Memo";
        FromDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 %2 has been created. Do you want to view the created document?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DropDownForRetOrderAndCrMemoEd: Boolean;
        DropDownForOrderAndInvoiceEdit: Boolean;
#pragma warning disable AA0074
        Text19037468: Label 'When you move a negative sales line to your selected document type, the quantity of the line on the selected document becomes positive.';
#pragma warning restore AA0074

    protected var
        FromSalesHeader: Record "Sales Header";
        ToDocType2: Option ,,"Order",Invoice,"Return Order","Credit Memo";

    procedure SetSalesHeader(var NewFromSalesHeader: Record "Sales Header")
    begin
        FromSalesHeader := NewFromSalesHeader;
    end;

    procedure ShowDocument()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Commit();
        if ToSalesHeader.Find() then
            if ConfirmManagement.GetResponse(
                 StrSubstNo(Text001, ToSalesHeader."Document Type", ToSalesHeader."No."), true)
            then
                CopyDocMgt.ShowSalesDoc(ToSalesHeader);
    end;

    procedure InitializeRequest(NewFromDocType: Option; NewToDocType: Option; NewToDocType2: Option)
    begin
        FromDocType := NewFromDocType;
        ToDocType := NewToDocType;
        ToDocType2 := NewToDocType2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(var CopyDocumentMgt: Codeunit "Copy Document Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDoc(FromDocType: Option; FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header");
    begin
    end;
}

