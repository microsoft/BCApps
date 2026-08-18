// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Wizard;

pageextension 99001564 SubcTempProdOrderCompExt extends "Temp Prod. Order Comp. List"
{
    layout
    {
        addafter("Location Code")
        {
            field(SubcComponentSupplyMethod; Rec."Component Supply Method")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Type';
                ToolTip = 'Specifies the subcontracting type for this production order component.';

                trigger OnValidate()
                begin
                    if Rec."Component Supply Method" = Rec."Component Supply Method"::"Vendor-Supplied" then
                        Rec.FieldError("Component Supply Method");

                    if (Rec."Routing Link Code" = '') and (Rec."Component Supply Method" <> Rec."Component Supply Method"::Empty) then begin
                        GetManufacturingSetup();
                        Rec."Routing Link Code" := ManufacturingSetup."Rtng. Link Code Purch. Prov.";
                    end;

                    if Rec."Component Supply Method" = Rec."Component Supply Method"::"Transfer to Vendor" then
                        Rec.Validate("Location Code", Rec."Subc. Original Location Code")
                    else
                        OnAfterSubcontractingTypeChangedToNonTransfer(Rec);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Component Supply Method" := xRec."Component Supply Method";
        Rec."Subc. Original Location Code" := xRec."Subc. Original Location Code";
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupRead: Boolean;

    local procedure GetManufacturingSetup()
    begin
        if not ManufacturingSetupRead then begin
            ManufacturingSetup.SetLoadFields("Rtng. Link Code Purch. Prov.");
            ManufacturingSetup.Get();
            ManufacturingSetupRead := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterSubcontractingTypeChangedToNonTransfer(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;
}