// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Activity.History;

report 5755 "Delete Registered Whse. Docs."
{
    Caption = 'Delete Registered Whse. Docs.';
    ProcessingOnly = true;
    Permissions = TableData "Registered Whse. Activity Hdr." = rimd;

    dataset
    {
        dataitem("Registered Whse. Activity Hdr."; "Registered Whse. Activity Hdr.")
        {
            DataItemTableView = sorting(Type, "No.");
            RequestFilterFields = Type, "No.";
            RequestFilterHeading = 'Registered Whse. Docs.';

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Type);
                Window.Update(2, "No.");

                Delete(true);
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text000 +
                  Text001 +
                  Text002);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label 'Processing registered documents...\\';
#pragma warning disable AA0470
        Text001: Label 'Type             #1##########\';
        Text002: Label 'No.              #2##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Window: Dialog;
}

