// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Finance.VAT.Registration;

tableextension 11310 "Location BE" extends Location
{
    fields
    {
        field(11311; "Branch No."; Text[20])
        {
            Caption = 'Branch No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                BranchNoMgt: Codeunit VATLogicalTests;
            begin
                if "Branch No." <> '' then
                    if not BranchNoMgt.MOD97Check("Branch No.") then
                        Error(LabelNotValidErr, FieldCaption("Branch No."));
            end;
        }
    }

    var
        LabelNotValidErr: Label '%1 is not valid.', Comment = '%1 - field caption';
}