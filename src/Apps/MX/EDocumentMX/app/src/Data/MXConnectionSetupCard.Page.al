// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

page 3303 "Interfactura Connection Setup"
{
    PageType = Card;
    Caption = 'Interfactura Connection Setup';
    DataCaptionExpression = '';
    SourceTable = "MX Connection Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Interfactura connection is enabled.';
                }
                field("PAC Certificate"; Rec."PAC Certificate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PAC certificate used for Interfactura integration.';
                }
                field("SAT Certificate"; Rec."SAT Certificate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SAT certificate used for Mexican electronic invoicing.';
                }
                field("Send Mode"; Rec."Send Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the send mode used for Interfactura requests. Test mode should run with simulated responses (mock) and not rely on a separate endpoint.';
                }
                field("Send PDF Report"; Rec."Send PDF Report")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if you want to include a PDF when you email electronic invoices to customers or vendors. Electronic invoices are always sent as an XML file, this option allows you to include a PDF with the XML file.';
                }
                field("Disable CFDI Payment Details"; Rec."Disable CFDI Payment Details")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if tax information is disabled in payment reports to Mexican SAT authorities.';
                }
                field("USD Currency Code"; Rec."USD Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for USD currency that is used to calculate exchange rate to report foreign trade electronic invoices to Mexican SAT authorities.';
                }
                field("Cancel on Time Expiration"; Rec."Cancel on Time Expiration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if users cancel documents when requesting cancellation before 24 hours of issue, or if no response is received for cancellation after 72 hours.';
                }
                field("Multiple SAT Certificates"; Rec."Multiple SAT Certificates")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the SAT certificate can be linked to different records. It allows to set the SAT certificate on the location card to verify the identity of the company branch when sending electronic invoices.';
                }
            }
            group("PAC Web Service Details")
            {
                part(PACWSDetails; "MX PAC Web Service Details")
                {
                    ApplicationArea = All;
                    SubPageLink = "Setup Id" = field(Id);
                    UpdatePropagation = Both;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;

}