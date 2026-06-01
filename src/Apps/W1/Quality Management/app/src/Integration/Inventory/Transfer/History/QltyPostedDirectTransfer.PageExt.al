// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer.History;

using Microsoft.Inventory.Transfer;

pageextension 20424 "Qlty. Posted Direct Transfer" extends "Posted Direct Transfer"
{
    layout
    {
        addlast(General)
        {
            group(Qlty_QualityManagement)
            {
                ShowCaption = false;
                Visible = (Rec."Qlty. Inspection No." <> '');

                field("Qlty. Inspection No."; Rec."Qlty. Inspection No.")
                {
                    ApplicationArea = QualityManagement;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.QltyShowRelatedInspection();
                    end;
                }
                field("Qlty. Re-inspection No."; Rec."Qlty. Re-inspection No.")
                {
                    ApplicationArea = QualityManagement;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.QltyShowRelatedInspection();
                    end;
                }
            }
        }
    }
}
