// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 6129 "E-Doc Service Supported Types"
{
    Caption = 'E-Document Service Supported Source Document Types';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "E-Doc. Service Supported Type";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document Type"; Rec."Source Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the supported source document type. A document type without a row is not permitted for incoming or outgoing processing.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this document type is permitted for outgoing, incoming, or both directions.';
                }
            }
        }
    }
}