// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

/// <summary>
/// Page for PEPPOL 3.0 Setup to configure e-document format settings.
/// Provides a user interface for selecting electronic document formats for sales and service documents.
/// </summary>
page 37202 "PEPPOL 3.0 Setup"
{
    Caption = 'PEPPOL 3.0 Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "PEPPOL 3.0 Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("PEPPOL 3.0 Sales Format"; Rec."PEPPOL 3.0 Sales Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PEPPOL 3.0 format to be used for electronic documents of type sales.';
                }
                field("PEPPOL 3.0 Service Format"; Rec."PEPPOL 3.0 Service Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PEPPOL 3.0 format to be used for electronic documents of type service.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
