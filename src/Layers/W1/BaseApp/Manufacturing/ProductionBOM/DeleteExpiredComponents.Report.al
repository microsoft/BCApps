// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

report 99001041 "Delete Expired Components"
{
    Caption = 'Delete Expired Components';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Production BOM Header"; "Production BOM Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");

                ProdBOMLine.SetRange("Production BOM No.", "No.");
                ProdBOMLine.SetFilter("Ending Date", '<>%1&..%2', 0D, StartingDate - 1);
                if not ProdBOMLine.IsEmpty() then
                    ProdBOMLine.DeleteAll();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeleteBefore; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Delete Before';
                        ToolTip = 'Specifies a date, that will define the date range for the BOM lines you want to delete.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if StartingDate = 0D then
            Error(Text000);

        Window.Open(
          Text001 +
          Text002);
    end;

    var
        ProdBOMLine: Record "Production BOM Line";
        Window: Dialog;
        StartingDate: Date;

#pragma warning disable AA0074
        Text000: Label 'You must enter the date to delete before.';
        Text001: Label 'Deleting...\';
#pragma warning disable AA0470
        Text002: Label 'Production BOM No. #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

