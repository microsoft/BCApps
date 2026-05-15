// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99001560 "Subc. Routing Line" extends "Routing Line"
{
    AllowInCustomizations = AsReadWrite;
    fields
    {
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                if Type = xRec.Type then
                    exit;

                if Type <> "Capacity Type"::"Work Center" then
                    "Transfer WIP Item" := false;
            end;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                WorkCenter: Record "Work Center";
            begin
                if "No." = xRec."No." then
                    exit;
                if Type <> "Capacity Type"::"Work Center" then begin
                    "Transfer WIP Item" := false;
                    exit;
                end;
                WorkCenter.SetLoadFields("Subcontractor No.");
                WorkCenter.Get("No.");
                if WorkCenter."Subcontractor No." = '' then
                    "Transfer WIP Item" := false;
            end;
        }
        field(99001551; Subcontracting; Boolean)
        {
            AllowInCustomizations = AsReadOnly;
            CalcFormula = exist("Work Center" where("No." = field("Work Center No."),
                                                    "Subcontractor No." = filter(<> '')));
            Caption = 'Subcontracting';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies whether the Work Center Group is set up with a Vendor for Subcontracting.';
        }
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the production order parent item (WIP item) is transferred to the subcontractor for this operation.';

            trigger OnValidate()
            begin
                if "Transfer WIP Item" then begin
                    CalcFields(Subcontracting);
                    TestField(Subcontracting, true);
                end;
            end;
        }
        field(99001561; "Transfer Description"; Text[100])
        {
            Caption = 'Transfer Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the operation-specific description used on transfer orders for the semi-finished item as it is shipped to the subcontracting location. If empty, the standard description is used.';
        }
        field(99001562; "Transfer Description 2"; Text[50])
        {
            Caption = 'Transfer Description 2';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an additional operation-specific description line used on transfer orders for the semi-finished item as it is shipped to the subcontracting location.';
        }
    }
}
