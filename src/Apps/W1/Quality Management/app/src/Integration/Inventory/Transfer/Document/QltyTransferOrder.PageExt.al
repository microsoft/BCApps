// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer.Document;

using Microsoft.Inventory.Transfer;

pageextension 20423 "Qlty. Transfer Order" extends "Transfer Order"
{
    layout
    {
        addlast(General)
        {
            group(Qlty_Management)
            {
                ShowCaption = false;
                Visible = (Rec."Qlty. Inspection Test No." <> '');

                field("Qlty. Inspection Test No."; Rec."Qlty. Inspection Test No.")
                {
                    ApplicationArea = QualityManagement;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.QltyShowRelatedInspectionTest();
                    end;
                }
                field("Qlty. Inspection Retest No."; Rec."Qlty. Inspection Retest No.")
                {
                    ApplicationArea = QualityManagement;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.QltyShowRelatedInspectionTest();
                    end;
                }
            }
        }
    }
}
