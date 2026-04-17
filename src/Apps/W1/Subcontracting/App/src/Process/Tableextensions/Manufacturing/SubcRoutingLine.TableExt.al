// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

tableextension 99001560 "Subc. Routing Line" extends "Routing Line"
{
    AllowInCustomizations = AsReadWrite;
    fields
    {
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the production order parent item (WIP item) is transferred to the subcontractor for this operation.';
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
