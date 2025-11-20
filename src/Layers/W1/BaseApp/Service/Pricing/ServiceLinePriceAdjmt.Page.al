// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Service.Document;

page 6084 "Service Line Price Adjmt."
{
    Caption = 'Service Line Price Adjmt.';
    DataCaptionFields = "Document Type", "Document No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Service Line Price Adjmt.";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service item that is registered in the Service Item table.';
                }
                field("ServItemLine.Description"; ServItemLine.Description)
                {
                    ApplicationArea = Service;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the service item for which the price is going to be adjusted.';
                }
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Price Group Code';
                    Editable = false;
                    ToolTip = 'Specifies the code of the service price adjustment group associated with the service item on this line.';
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the service price adjustment group that applies to the posted service line.';
                }
                field("Adjustment Type"; Rec."Adjustment Type")
                {
                    ApplicationArea = Service;
                    Caption = 'Adjustment Type';
                    Editable = false;
                    ToolTip = 'Specifies the adjustment type for this line.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this line, which can be item, resource, cost, or general ledger Account.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item, resource, or service cost, of which the price is going to be adjusted.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value of the service line that will be adjusted.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("New Unit Price"; Rec."New Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the unit price of the item, resource, or cost specified on the service line.';

                    trigger OnValidate()
                    begin
                        NewUnitPriceOnAfterValidate();
                    end;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage you want to provide on the amount on the corresponding service line.';
                }
                field("Discount Amount"; Rec."Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount you want to provide on the amount on this service line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total net amount on the service line.';
                }
                field("New Amount"; Rec."New Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount to invoice.';

                    trigger OnValidate()
                    begin
                        NewAmountOnAfterValidate();
                    end;
                }
                field("Amount incl. VAT"; Rec."Amount incl. VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total amount that the service line is going to be adjusted, including VAT.';
                }
                field("New Amount incl. VAT"; Rec."New Amount incl. VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a new amount, including VAT.';

                    trigger OnValidate()
                    begin
                        NewAmountinclVATOnAfterValidat();
                    end;
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                fixed(Control1900116601)
                {
                    ShowCaption = false;
                    group(Total)
                    {
                        Caption = 'Total';
                        field(TotalAmount; TotalAmount)
                        {
                            ApplicationArea = Service;
                            Caption = 'Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount that the service lines will be adjusted to.';
                        }
                    }
                    group("To Adjust")
                    {
                        Caption = 'To Adjust';
                        field(AmountToAdjust; AmountToAdjust)
                        {
                            ApplicationArea = Service;
                            Caption = 'To Adjust';
                            Editable = false;
                            ToolTip = 'Specifies the total value of the service lines that need to be adjusted.';
                        }
                    }
                    group(Remaining)
                    {
                        Caption = 'Remaining';
                        field(Control3; Remaining)
                        {
                            ApplicationArea = Service;
                            Caption = 'Remaining';
                            Editable = false;
                            ToolTip = 'Specifies the difference between the total amount that the service lines will be adjusted to, and actual total value of the service lines.';
                        }
                    }
                    group("Incl. VAT")
                    {
                        Caption = 'Incl. VAT';
                        field(InclVat; InclVat)
                        {
                            ApplicationArea = Service;
                            Caption = 'Incl. VAT';
                            Editable = false;
                            ToolTip = 'Specifies that the amount of the service lines includes VAT.';
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
                action("Adjust Service Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Adjust Service Price';
                    Image = PriceAdjustment;
                    ToolTip = 'Adjust existing service prices according to changed costs, spare parts, and resource hours. Note that prices are not adjusted for service items that belong to service contracts, service items with a warranty, items service on lines that are partially or fully invoiced. When you run the service price adjustment, all discounts in the order are replaced by the values of the service price adjustment.';

                    trigger OnAction()
                    var
                        ServHeader: Record "Service Header";
                        ServPriceGrSetup: Record "Serv. Price Group Setup";
                        ServInvLinePriceAdjmt: Record "Service Line Price Adjmt.";
                        ServPriceMgmt: Codeunit "Service Price Management";
                    begin
                        ServHeader.Get(Rec."Document Type", Rec."Document No.");
                        ServItemLine.Get(Rec."Document Type", Rec."Document No.", Rec."Service Item Line No.");
                        ServPriceMgmt.GetServPriceGrSetup(ServPriceGrSetup, ServHeader, ServItemLine);
                        ServInvLinePriceAdjmt := Rec;
                        ServPriceMgmt.AdjustLines(ServInvLinePriceAdjmt, ServPriceGrSetup);
                        UpdateAmounts();
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateAmounts();
    end;

    trigger OnOpenPage()
    begin
        OKPressed := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush();
        if not OKPressed then
            if not Confirm(Text001, false) then
                exit(false);
        exit(true);
    end;

    var
        ServItemLine: Record "Service Item Line";
        ServInvLinePriceAdjmt: Record "Service Line Price Adjmt.";
        TotalAmount: Decimal;
        AmountToAdjust: Decimal;
        Remaining: Decimal;
        InclVat: Boolean;
        OKPressed: Boolean;
#pragma warning disable AA0074
        Text001: Label 'Cancel price adjustment?';
#pragma warning restore AA0074

    procedure SetVars(SetTotalAmount: Decimal; SetInclVat: Boolean)
    begin
        TotalAmount := SetTotalAmount;
        InclVat := SetInclVat;
    end;

    procedure UpdateAmounts()
    begin
        if not ServItemLine.Get(Rec."Document Type", Rec."Document No.", Rec."Service Item Line No.") then
            Clear(ServItemLine);
        ServInvLinePriceAdjmt := Rec;
        ServInvLinePriceAdjmt.Reset();
        ServInvLinePriceAdjmt.SetRange("Document Type", Rec."Document Type");
        ServInvLinePriceAdjmt.SetRange("Document No.", Rec."Document No.");
        ServInvLinePriceAdjmt.SetRange("Service Item Line No.", Rec."Service Item Line No.");
        ServInvLinePriceAdjmt.CalcSums("New Amount", "New Amount incl. VAT", "New Amount Excl. VAT");
        if InclVat then begin
            AmountToAdjust := ServInvLinePriceAdjmt."New Amount incl. VAT";
            Remaining := TotalAmount - ServInvLinePriceAdjmt."New Amount incl. VAT";
        end else begin
            AmountToAdjust := ServInvLinePriceAdjmt."New Amount Excl. VAT";
            Remaining := TotalAmount - ServInvLinePriceAdjmt."New Amount Excl. VAT";
        end;
    end;

    local procedure NewUnitPriceOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure NewAmountOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure NewAmountinclVATOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure OKOnPush()
    begin
        OKPressed := true;
    end;
}

