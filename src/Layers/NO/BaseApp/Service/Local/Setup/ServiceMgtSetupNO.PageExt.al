// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

pageextension 10621 "Service Mgt. Setup NO" extends "Service Mgt. Setup"
{
    layout
    {
        addafter("Journal Templates")
        {
            group("E-Invoice")
            {
                Caption = 'E-Invoice';
                group("Output Paths")
                {
                    Caption = 'Output Paths';
                    field("E-Invoice Service Invoice Path"; Rec."E-Invoice Service Invoice Path")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Invoice Path';
                        ToolTip = 'Specifies the path and name of the folder where you want to store the files for electronic service invoices.';
                    }
                    field("E-Invoice Serv. Cr. Memo Path"; Rec."E-Invoice Serv. Cr. Memo Path")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Cr. Memo Path';
                        ToolTip = 'Specifies the path and name of the folder where you want to store the files for electronic service credit memos.';
                    }
                }
            }
        }
    }
}
