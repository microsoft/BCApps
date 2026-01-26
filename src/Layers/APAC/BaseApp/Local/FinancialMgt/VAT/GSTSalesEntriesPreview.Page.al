// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

page 28167 "GST Sales Entries Preview"
{
    Caption = 'GST Sales Entries Preview';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "GST Sales Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an auto-generated unique key for every transaction in this table.';
                    Visible = false;
                }
                field("GST Entry No."; Rec."GST Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number from the VAT Entry table.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST sales entry posting date.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the GST sales entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the GST sales entry belongs to.';
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line that the GST sales entry belongs to.';
                    Visible = false;
                }
                field("Document Line Type"; Rec."Document Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the line that the entry belongs to.';
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer account that is linked to the GST sales entry.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer account that is linked to the GST sales entry.';
                }
                field("Document Line Description"; Rec."Document Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item or G/L account that is associated with the fixed asset number.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group code that was used when the entry was posted.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group code that was used when the entry was posted.';
                }
                field(GSTPercentage; GSTPercentage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST %';
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the relevant GST rate for the particular combination of GST business posting group and GST product posting group.';
                }
                field("GST Entry Type"; Rec."GST Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the GST entry.';
                    Visible = false;
                }
                field("GST Base"; Rec."GST Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the GST amount (the amount shown in the Amount field) is calculated from.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the GST entry in LCY.';
                }
                field(GSTTotalAmount; GSTTotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Sale';
                    ToolTip = 'Specifies the sum of the values in the GST Base and Amount fields on the GST sales entry line.';
                }
                field("Document Line Code"; Rec."Document Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the item or G/L account that is associated with the fixed asset number.';
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT calculation type that was used when this entry was posted.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GSTTotalAmount := Rec."GST Base" + Rec.Amount;
        if Rec."GST Base" <> 0 then
            GSTPercentage := Rec.Amount / Rec."GST Base" * 100
        else
            GSTPercentage := 0;
    end;

    var
        GSTTotalAmount: Decimal;
        GSTPercentage: Decimal;
}

