// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Manufacturing.Setup;

page 99001026 "Refresh Prod. Order Warning"
{
    Caption = 'Refresh Production Order Without a Location';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'This production order has no Location Code. Do you want to continue refreshing it without a location?';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = "Production Order";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                ToolTip = 'Specifies the production order that has no location.';
            }
            group(MissingDefault)
            {
                ShowCaption = false;
                Visible = DefaultLocationMissing;

                field(SetupInstructions; SetupInstructionsTxt)
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies how to configure a default location for new production orders.';
                }
                field(OpenManufacturingSetup; OpenManufacturingSetupTxt)
                {
                    ApplicationArea = Manufacturing;
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Stop this refresh without changing any selected orders and open Manufacturing Setup.';

                    trigger OnDrillDown()
                    begin
                        SetupRequested := true;
                        CurrPage.Close();
                    end;
                }
            }
        }
    }

    var
        DefaultLocationMissing: Boolean;
        SetupRequested: Boolean;
        SetupInstructionsTxt: Label 'Default Location Code is not set in Manufacturing Setup. In the Planning group, set Default Location Code to default locations on new production orders. This does not update this order. Set its Location Code before refreshing, or continue without one.';
        OpenManufacturingSetupTxt: Label 'Open Manufacturing Setup';

    internal procedure SetProductionOrder(ProductionOrder: Record "Production Order")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        Rec := ProductionOrder;
        Rec.Insert();
        DefaultLocationMissing := true;
        if ManufacturingSetup.Get() then
            DefaultLocationMissing := ManufacturingSetup."Default Location Code" = '';
    end;

    internal procedure IsSetupRequested(): Boolean
    begin
        exit(SetupRequested);
    end;
}
