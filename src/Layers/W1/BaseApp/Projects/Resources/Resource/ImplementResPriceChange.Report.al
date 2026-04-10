// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Projects.Resources.Pricing;

report 1193 "Implement Res. Price Change"
{
    Caption = 'Implement Res. Price Change';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Resource Price Change"; "Resource Price Change")
        {
            DataItemTableView = sorting(Type, Code, "Work Type Code", "Currency Code");
            RequestFilterFields = Type, "Code", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Type);
                Window.Update(2, Code);
                Window.Update(3, "Work Type Code");
                Window.Update(4, "Currency Code");
                ResPrice.Type := Type;
                ResPrice.Code := Code;
                ResPrice."Work Type Code" := "Work Type Code";
                ResPrice."Currency Code" := "Currency Code";
                ResPrice."Unit Price" := "New Unit Price";
                if not ResPrice.Insert() then
                    ResPrice.Modify();
                ConfirmDeletion := true;
            end;

            trigger OnPostDataItem()
            begin
                if ConfirmDeletion then begin
                    Commit();
                    if Confirm(Text006) then
                        DeleteAll();
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text000 +
                  Text001 +
                  Text002 +
                  Text003 +
                  Text004 +
                  Text005);
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
        ResPrice: Record "Resource Price";
        Window: Dialog;
        ConfirmDeletion: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Updating Resource Prices...\\';
#pragma warning disable AA0470
        Text001: Label 'Type                #1##########\';
        Text002: Label 'Code                #2##########\';
        Text003: Label 'Work Type Code      #3##########\';
        Text004: Label 'Project No.             #4##########\';
        Text005: Label 'Currency Code       #5##########\';
#pragma warning restore AA0470
        Text006: Label 'The resource prices have now been updated in accordance with the suggested price changes.\\Do you want to delete the suggested price changes?';
#pragma warning restore AA0074
}
