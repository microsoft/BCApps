// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Journal;

tableextension 11710 "Job Journal Line CZL" extends "Job Journal Line"
{
    fields
    {
        field(31079; "Invt. Movement Template CZL"; Code[10])
        {
            Caption = 'Inventory Movement Template';
            TableRelation = "Invt. Movement Template CZL";
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                InvtMovementTemplateCZL: Record "Invt. Movement Template CZL";
            begin
                if InvtMovementTemplateCZL.Get("Invt. Movement Template CZL") then begin
                    InvtMovementTemplateCZL.TestField("Entry Type", InvtMovementTemplateCZL."Entry Type"::"Negative Adjmt.");
                    Validate("Gen. Bus. Posting Group", InvtMovementTemplateCZL."Gen. Bus. Posting Group");
                end;
            end;
        }
        field(11764; "Correction CZL"; Boolean)
        {
            Caption = 'Correction';
            DataClassification = CustomerContent;
        }
    }
}
