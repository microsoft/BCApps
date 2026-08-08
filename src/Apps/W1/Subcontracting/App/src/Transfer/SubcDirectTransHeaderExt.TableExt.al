// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;

tableextension 8148 "Subc. DirectTransHeader Ext." extends "Direct Trans. Header"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(8154; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8155; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8160; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            DataClassification = CustomerContent;
            trigger OnLookup()
#if not CLEAN29
            var
#pragma warning disable AL0432
                SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
            begin
#if not CLEAN29
#pragma warning disable AL0432
                if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
                    exit;
#endif
                HandleSubcontractingSourceLookup(Rec);
            end;
        }
        field(8161; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
            DataClassification = CustomerContent;
        }
        field(8164; "Source Type"; Enum "Transfer Source Type")
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
        }
        field(8165; "Return Order"; Boolean)
        {
            Caption = 'Return Order';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(Key99001500; "Subcontr. Purch. Order No.") { }
        key(Key99001501; "Source ID", "Source Type") { }
    }

    local procedure HandleSubcontractingSourceLookup(var DirectTransHeader: Record "Direct Trans. Header")
    var
        Vendor: Record Vendor;
    begin
        if DirectTransHeader."Source Type" = DirectTransHeader."Source Type"::Subcontracting then begin
            Vendor.SetRange("No.", DirectTransHeader."Source ID");
            Page.RunModal(0, Vendor);
        end;
    end;

}