// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

pageextension 11386 "General Ledger Setup NL" extends "General Ledger Setup"
{
    layout
    {
        addafter(SEPAExportWoBankAccData)
        {
            field("Local SEPA Instr. Priority"; Rec."Local SEPA Instr. Priority")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if you want to use the local SEPA functionality to generate the InstrPrty XML element in documents. Otherwise, the generic functionality will be used';
            }
        }
        addafter(Application)
        {
            group(Telebanking)
            {
                Caption = 'Telebanking';
                field("Local Currency"; Rec."Local Currency")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies whether Euro currency is used as the local currency (LCY).';
                }
                field("Currency Euro"; Rec."Currency Euro")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies what currency in the Currency table represents the Euro currency.';
                }
            }
        }
    }
}

