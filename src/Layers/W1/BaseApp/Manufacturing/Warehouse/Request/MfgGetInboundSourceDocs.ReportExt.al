// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Manufacturing.Document;


reportextension 99000835 "Mfg. Get Inbound Source Docs" extends "Get Inbound Source Documents"
{
    dataset
    {
        addafter("Whse. Internal Put-away Header")
        {
            dataitem("Production Order"; "Production Order")
            {
                DataItemLink = "No." = field("Document No.");
                DataItemTableView = sorting("No.");
                dataitem("Prod. Order Line"; "Prod. Order Line")
                {
                    DataItemLink = "Prod. Order No." = field("No.");
                    DataItemTableView = sorting("Prod. Order No.", "Line No.");
                    CalcFields = "Put-away Qty.", "Put-away Qty. (Base)";

                    trigger OnPreDataItem()
                    begin
                    end;

                    trigger OnAfterGetRecord()
                    var
                        ProdOrderWhseMgmt: Codeunit "Prod. Order Warehouse Mgt.";
                    begin
                        if "Finished Qty. (Base)" > "Qty. Put Away (Base)" + "Put-away Qty. (Base)" then
                            if ProdOrderWhseMgmt.FromProdOrderLine(
                                 WhseWkshTemplateName, WhseWkshName, "Location Code", "Bin Code", "Prod. Order Line")
                            then
                                LineCreated := true;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if not ("Whse. Put-away Request"."Document Type" in ["Whse. Put-away Request"."Document Type"::Receipt, "Whse. Put-away Request"."Document Type"::Production]) then
                        CurrReport.Break();
                end;
            }
        }
    }
}
