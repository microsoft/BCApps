// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Sales.Customer;
using Microsoft.Service.History;

page 5968 "Service Document Registers"
{
    Caption = 'Service Document Registers';
    DataCaptionFields = "Source Document Type", "Source Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Document Register";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order or service contract.';
                }
                field("Destination Document Type"; Rec."Destination Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of document created from the service order or contract specified in the Source Document No.';
                }
                field("Destination Document No."; Rec."Destination Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the invoice or credit memo, based on the contents of the Destination Document Type field.';
                }
                field(CustNo; CustNo)
                {
                    ApplicationArea = Service;
                    Caption = 'Bill-to Customer No.';
                    Editable = false;
                    TableRelation = Customer;
                    ToolTip = 'Specifies the number of the customer relating to the service document.';
                }
                field(CustName; CustName)
                {
                    ApplicationArea = Service;
                    Caption = 'Bill-to Customer Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer relating to the service document.';
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
            group("&Document")
            {
                Caption = '&Document';
                Image = Document;
                action(ShowDocument)
                {
                    ApplicationArea = Service;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenRelatedCard();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec."Destination Document Type" of
            Rec."Destination Document Type"::Invoice:
                if ServHeader.Get(ServHeader."Document Type"::Invoice, Rec."Destination Document No.") then begin
                    CustNo := ServHeader."Bill-to Customer No.";
                    CustName := ServHeader."Bill-to Name";
                end;
            Rec."Destination Document Type"::"Credit Memo":
                if ServHeader.Get(ServHeader."Document Type"::"Credit Memo", Rec."Destination Document No.") then begin
                    CustNo := ServHeader."Bill-to Customer No.";
                    CustName := ServHeader."Bill-to Name";
                end;
            Rec."Destination Document Type"::"Posted Invoice":
                if ServInvHeader.Get(Rec."Destination Document No.") then begin
                    CustNo := ServInvHeader."Bill-to Customer No.";
                    CustName := ServInvHeader."Bill-to Name";
                end;
            Rec."Destination Document Type"::"Posted Credit Memo":
                if ServCrMemoHeader.Get(Rec."Destination Document No.") then begin
                    CustNo := ServCrMemoHeader."Bill-to Customer No.";
                    CustName := ServCrMemoHeader."Bill-to Name";
                end;
        end;
    end;

    var
        ServHeader: Record "Service Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        CustNo: Code[20];
        CustName: Text[100];

    local procedure OpenRelatedCard()
    begin
        case Rec."Destination Document Type" of
            Rec."Destination Document Type"::Invoice:
                begin
                    ServHeader.Get(ServHeader."Document Type"::Invoice, Rec."Destination Document No.");
                    PAGE.Run(PAGE::"Service Invoice", ServHeader);
                end;
            Rec."Destination Document Type"::"Credit Memo":
                begin
                    ServHeader.Get(ServHeader."Document Type"::"Credit Memo", Rec."Destination Document No.");
                    PAGE.Run(PAGE::"Service Credit Memo", ServHeader);
                end;
            Rec."Destination Document Type"::"Posted Invoice":
                begin
                    ServInvHeader.Get(Rec."Destination Document No.");
                    PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader);
                end;
            Rec."Destination Document Type"::"Posted Credit Memo":
                begin
                    ServCrMemoHeader.Get(Rec."Destination Document No.");
                    PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader);
                end;
        end;
    end;
}

