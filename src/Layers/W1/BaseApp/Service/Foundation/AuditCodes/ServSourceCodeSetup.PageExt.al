// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

pageextension 6467 "Serv. Source Code Setup" extends "Source Code Setup"
{
    layout
    {
        addafter("Fixed Assets")
        {
            group(Service)
            {
                Caption = 'Service';
                field("Service Management"; Rec."Service Management")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from the Service Management application area.';
                }
            }
        }
    }
}
