// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

/// <summary>
/// Overview page displaying dimension values available for dimension correction operations.
/// </summary>
page 2587 "Dim Corr Values Overview"
{
    PageType = List;
    SourceTable = "Dimension Value";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    Caption = 'Dimension Values';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(DimCode; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies the identifier of Dimension Value.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of dimension value.';
                }
            }
        }
    }
}
