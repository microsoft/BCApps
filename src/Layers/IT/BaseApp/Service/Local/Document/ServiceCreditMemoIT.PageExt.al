// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.PaymentTerms;

pageextension 12444 "Service Credit Memo IT" extends "Service Credit Memo"
{
    layout
    {
        addafter("External Document No.")
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
        addafter("Prices Including VAT")
        {
            field("Fattura Document Type"; Rec."Fattura Document Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value to export in TipoDocument XML node of the Fattura document.';
            }
            field("Fattura Project Code"; Rec."Fattura Project Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the code for the Fattura project.';
            }
            field("Fattura Tender Code"; Rec."Fattura Tender Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the code for the Fattura tender.';
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
        addafter("Area")
        {
            field("Service Tariff No."; Rec."Service Tariff No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the service tariff that is associated with the service order or service invoice.';
            }
        }
        addafter("Applies-to Doc. No.")
        {
            field("Applies-to Occurrence No."; Rec."Applies-to Occurrence No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the occurrence that applies to the transaction.';
            }
        }
        addafter("Applies-to ID")
        {
            field("Refers to Period"; Rec."Refers to Period")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the period of time that is used to group and filter the transaction.';

                trigger OnValidate()
                begin
                    ReferstoPeriodOnAfterValidate();
                end;
            }
        }
        addafter(Application)
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
    }
    actions
    {
        addbefore("Calculate Invoice Discount")
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
        addafter("Post &Batch")
        {
            action(GenerateSplitVATLines)
            {
                ApplicationArea = Service;
                Caption = 'Generate Split VAT Lines';
                Ellipsis = true;
                Image = Splitlines;
                ToolTip = 'Create split VAT lines based on the split sales lines.';

                trigger OnAction()
                begin
                    Rec.GenerateSplitVATLines();
                end;
            }
        }
        addafter(Dimensions_Promoted)
        {
            actionref(GenerateSplitVATLines_Promoted; GenerateSplitVATLines)
            {
            }
        }
    }

    local procedure OperationOccurredDateOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ReferstoPeriodOnAfterValidate()
    begin
        CurrPage.Update();
    end;

}
