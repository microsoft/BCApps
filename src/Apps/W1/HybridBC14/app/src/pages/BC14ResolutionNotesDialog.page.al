// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

page 50176 "BC14 Resolution Notes Dialog"
{
    PageType = StandardDialog;
    Caption = 'Resolution Notes';
    SourceTable = "BC14 Migration Errors";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Resolution Details';

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message for reference.';
                    Editable = false;
                    MultiLine = true;
                }

                field("Resolution Notes"; Rec."Resolution Notes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the notes about how the error was resolved.';
                    MultiLine = true;
                }
            }
        }
    }
}
