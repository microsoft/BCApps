// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Utilities;
using System.Utilities;

report 6698 "Move Negative Purchase Lines"
{
    Caption = 'Move Negative Purchase Lines';
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
                            ApplicationArea = Basic, Suite;
                            Caption = 'To Document Type';
                            Editable = DropDownForOrderAndInvoiceEdit;
                            OptionCaption = ',,,,Return Order,Credit Memo';
                            ToolTip = 'Specifies which document type you want to move the negative purchase lines to.';
                        }
                    }
                    group("Return Order && Credit Memo")
                    {
                        Caption = 'Return Order && Credit Memo';
                        field(DropDownForRetOrderAndCrMemo; ToDocType2)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'To Document Type';
                            Editable = DropDownForRetOrderAndCrMemoEd;
                            OptionCaption = ',,Order,Invoice';
                            ToolTip = 'Specifies which document type you want to move the negative purchase lines to.';
                        }
                    }
                    label(Control5)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19012737;
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
            case FromPurchHeader."Document Type" of
                FromPurchHeader."Document Type"::Order:
                    begin
                        ToDocType := ToDocType::"Return Order";
                        ToDocType2 := ToDocType2::Order;
                        FromDocType := FromDocType::Order;
                        DropDownForRetOrderAndCrMemoEd := false;
                    end;
                FromPurchHeader."Document Type"::Invoice:
                    begin
                        ToDocType := ToDocType::"Credit Memo";
                        ToDocType2 := ToDocType2::Invoice;
                        FromDocType := FromDocType::Invoice;
                        DropDownForRetOrderAndCrMemoEd := false;
                    end;
                FromPurchHeader."Document Type"::"Return Order":
                    begin
                        ToDocType2 := ToDocType2::Order;
                        ToDocType := ToDocType::"Return Order";
                        FromDocType := FromDocType::"Return Order";
                        DropDownForOrderAndInvoiceEdit := false;
                    end;
                FromPurchHeader."Document Type"::"Credit Memo":
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
        ToPurchHeader."Document Type" := CopyDocMgt.GetPurchaseDocumentType(Enum::"Purchase Document Type From".FromInteger(ToDocType));
        CopyDocMgt.CopyPurchDoc(Enum::"Purchase Document Type From".FromInteger(FromDocType), FromPurchHeader."No.", ToPurchHeader);

        OnAfterPreReport(CopyDocMgt);
    end;

    var
        FromPurchHeader: Record "Purchase Header";
        ToPurchHeader: Record "Purchase Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ToDocType: Option ,,"Order",Invoice,"Return Order","Credit Memo";
        ToDocType2: Option ,,"Order",Invoice,"Return Order","Credit Memo";
        FromDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 %2 has been created. Do you want to view the created document?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DropDownForRetOrderAndCrMemoEd: Boolean;
        DropDownForOrderAndInvoiceEdit: Boolean;
#pragma warning disable AA0074
        Text19012737: Label 'When you move a negative purchase line to your selected document type, the quantity of the line on the selected document will become positive.';
#pragma warning restore AA0074

    procedure SetPurchHeader(var NewFromPurchHeader: Record "Purchase Header")
    begin
        FromPurchHeader := NewFromPurchHeader;
    end;

    procedure ShowDocument()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Commit();
        if ToPurchHeader.Find() then
            if ConfirmManagement.GetResponse(
                 StrSubstNo(Text001, ToPurchHeader."Document Type", ToPurchHeader."No."), true)
            then
                CopyDocMgt.ShowPurchDoc(ToPurchHeader);
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
    local procedure OnAfterPreReport(var CopyDocumentMgt: Codeunit "Copy Document Mgt.")
    begin
    end;
}

