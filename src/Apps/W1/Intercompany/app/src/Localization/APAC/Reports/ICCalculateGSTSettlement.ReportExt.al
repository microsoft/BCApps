#if INTERCOMPANY_APAC
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Intercompany.Partner;

reportextension 8558 "IC Calculate GST Settlement" extends "Calculate GST Settlement"
{
    requestpage
    {
        layout
        {
            addafter(InterCompany)
            {
                field(ICPartnerCode; ICPartnerCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'IC Partner Code';
                    TableRelation = "IC Partner";
                    ToolTip = 'Specifies the intercompany partner.';
                }
            }
        }
    }
}
#endif
