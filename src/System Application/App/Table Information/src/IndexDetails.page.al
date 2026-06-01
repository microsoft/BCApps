// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DataAdministration;

using System.Diagnostics;

/// <summary>
/// Displays additional details for a specific index.
/// </summary>
page 8706 "Index Details"
{
    Caption = 'Index Details';

    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Database Index";
    Permissions = tabledata "Database Index" = r;

    layout
    {
        area(Content)
        {
            group(Fields)
            {
                Caption = 'Key Fields';

                field(FieldNames; Rec."Column Names")
                {
                    Caption = 'Fields in Index';
                    ToolTip = 'Specifies the fields that are part of this index.';
                    MultiLine = true;
                }
                field("Included Fields"; Rec."Included Fields")
                {
                    Caption = 'Included Fields';
                    ToolTip = 'Specifies the fields that are included in this index but not part of the key.';
                    MultiLine = true;
                }
            }
        }
    }
}
