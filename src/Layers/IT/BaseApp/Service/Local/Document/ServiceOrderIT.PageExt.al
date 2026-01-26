// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.PaymentTerms;

pageextension 12451 "Service Order IT" extends "Service Order"
{
    layout
    {
        addafter("Responsibility Center")
        {
            field("Operation Occurred Date"; Rec."Operation Occurred Date")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the date when the VAT operation occurred on the transaction.';

                trigger OnValidate()
                begin
                    OperationOccurredDateOnAfterValidate();
                end;
            }
            field("Operation Type"; Rec."Operation Type")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the operation type that is assigned to the posted service shipment.';
            }
            field("Activity Code"; Rec."Activity Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the code for the company''s primary activity.';
            }
        }
        addafter("VAT Bus. Posting Group")
        {
            field("Customer Purchase Order No."; Rec."Customer Purchase Order No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the number of the customer''s purchase order.';
            }
            field("Fattura Project Code"; Rec."Fattura Project Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the Fattura project.';
            }
            field("Fattura Tender Code"; Rec."Fattura Tender Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the Fattura tender.';
            }
            field("Fattura Document Type"; Rec."Fattura Document Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value to export in TipoDocument XML node of the Fattura document.';
            }
            field("Fattura Stamp"; Rec."Fattura Stamp")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the value to export in BolloVirtuale XML node of the Fattura document.';
            }
            field("Fattura Stamp Amount"; Rec."Fattura Stamp Amount")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the value to export in ImportoBollo XML node of the Fattura document.';
            }
        }
        addafter("Ship-to E-Mail")
        {
            field("Additional Information"; Rec."Additional Information")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies additional declaration information that is needed for this shipment.';
            }
            field("Additional Notes"; Rec."Additional Notes")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies additional notes that are needed for this shipment.';
            }
            field("Additional Instructions"; Rec."Additional Instructions")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies additional instructions that are needed for this shipment.';
            }
            field("TDD Prepared By"; Rec."TDD Prepared By")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the service order.';
            }
        }
        addafter("Shipping Time")
        {
            field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
            }
            field("3rd Party Loader No."; Rec."3rd Party Loader No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
            }
        }
        addafter("Area")
        {
            field("Service Tariff No."; Rec."Service Tariff No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the service tariff that is associated with the service order or service invoice.';
            }
        }
        addafter(" Foreign Trade")
        {
            group(Individual)
            {
                Caption = 'Individual';
                field("Individual Person"; Rec."Individual Person")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the customer is an individual person.';
                }
                field(Resident; Rec.Resident)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the individual is a resident or non-resident of Italy.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the first name of the individual person.';
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the last name of the individual person.';
                }
                field("Date of Birth"; Rec."Date of Birth")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of birth of the individual person.';
                }
                field("Fiscal Code"; Rec."Fiscal Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fiscal identification code that is assigned by the government to interact with state and public offices and tax authorities.';
                }
            }
        }
        modify("Due Date")
        {
            Visible = false;
        }
        modify("Pmt. Discount Date")
        {
            Visible = false;
        }
        addafter("Payment Method Code")
        {
            field("Bank Account"; Rec."Bank Account")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the customer''s bank account that is associated with the service order.';
            }
            field("Cumulative Bank Receipts"; Rec."Cumulative Bank Receipts")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if the customer bill entry is included in a cumulative bank receipt.';
            }
        }
    }
    actions
    {
        addbefore("Create Customer")
        {
            action("Pa&yments")
            {
                ApplicationArea = Service;
                Caption = 'Pa&yments';
                Image = Payment;
                RunObject = Page "Payment Date Lines";
                RunPageLink = "Sales/Purchase" = const(Service),
                                Type = field("Document Type"),
                                Code = field("No.");
                ToolTip = 'View the related payments.';
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.CheckCreditMaxBeforeInsert(false);
    end;

    local procedure OperationOccurredDateOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}
