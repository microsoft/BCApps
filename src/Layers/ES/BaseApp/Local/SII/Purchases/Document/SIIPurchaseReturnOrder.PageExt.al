// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Document;

pageextension 7000103 "SII Purchase Return Order" extends "Purchase Return Order"
{
    layout
    {
        addafter("Tax Area Code")
        {
            group("SII Information")
            {
                Caption = 'SII Information';
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation Description';
                    MultiLine = true;
                    ToolTip = 'Specifies the Operation Description.';

                    trigger OnValidate()
                    var
                        SIIManagement: Codeunit "SII Management";
                    begin
                        SIIManagement.SplitOperationDescription(OperationDescription, Rec."Operation Description", Rec."Operation Description 2");
                        Rec.Validate("Operation Description");
                        Rec.Validate("Operation Description 2");
                        Rec.Modify(true);
                    end;
                }
                field("Special Scheme Code"; Rec."Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Invoice Type"; Rec."Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Invoice Type.';
                }
                field("Correction Type"; Rec."Correction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Correction Type.';
                }
                field("ID Type"; Rec."ID Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID Type.';
                }
                field("Succeeded Company Name"; Rec."Succeeded Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
                }
                field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
    end;

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
    end;

    var
        OperationDescription: Text[500];
}
