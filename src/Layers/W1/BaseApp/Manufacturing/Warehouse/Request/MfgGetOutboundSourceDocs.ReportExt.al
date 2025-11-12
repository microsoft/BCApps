// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Manufacturing.Document;


reportextension 99000836 "Mfg. Get Outbound Source Docs" extends "Get Outbound Source Documents"
{
    dataset
    {
        addafter("Whse. Internal Pick Header")
        {
            dataitem("Production Order"; "Production Order")
            {
                DataItemLink = Status = field("Document Subtype"), "No." = field("Document No.");
                DataItemTableView = sorting(Status, "No.") where(Status = const(Released));
                dataitem("Prod. Order Component"; "Prod. Order Component")
                {
                    DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.") where("Planning Level Code" = const(0));

                    trigger OnAfterGetRecord()
                    var
                        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
                        ToBinCode: Code[20];
                    begin
                        if ("Flushing Method" = "Flushing Method"::"Pick + Forward") and ("Routing Link Code" = '') then
                            CurrReport.Skip();

                        this.GetLocation("Location Code");
                        ToBinCode := "Bin Code";

                        CalcFields("Pick Qty.");
                        if "Expected Quantity" > "Qty. Picked" + "Pick Qty." then
                            if ProdOrderWarehouseMgt.FromProdOrderCompLine(
                                 PickWkshTemplate, PickWkshName, Location.Code, ToBinCode, "Prod. Order Component")
                            then
                                LineCreated := true;
                    end;

                    trigger OnPreDataItem()
#if not CLEAN26
                    var
                        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
                    begin
#if not CLEAN26
                        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
                            SetFilter(
                              "Flushing Method", '%1|%2|%3|%4',
                              "Flushing Method"::Manual,
                              "Flushing Method"::"Pick + Manual",
                              "Flushing Method"::"Pick + Forward",
                              "Flushing Method"::"Pick + Backward")
                        else
#endif
                            SetFilter(
                              "Flushing Method", '%1|%2|%3',
                              "Flushing Method"::"Pick + Manual",
                              "Flushing Method"::"Pick + Forward",
                              "Flushing Method"::"Pick + Backward");
                        SetRange("Location Code", "Whse. Pick Request"."Location Code");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::Production then
                        CurrReport.Break();
                end;
            }
        }
    }
}
