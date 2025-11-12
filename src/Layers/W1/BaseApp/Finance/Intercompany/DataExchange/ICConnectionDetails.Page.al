// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Setup;
using System.Environment;

page 566 "IC Connection Details"
{
    ApplicationArea = Intercompany;
    Caption = 'Connection Details';
    PageType = StandardDialog;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(CompanyConnectionDetails)
            {
                Caption = 'Your connection details';

                field(ConnectionUrl; CompanyConnectionUrl)
                {
                    Caption = 'Connection URL';
                    ToolTip = 'Specifies the URL to share with intercompany partners that want to share data with the current company across environments.';
                    Editable = false;
                    Enabled = false;
                    ApplicationArea = Intercompany;
                }
                field(CompanyId; CompanyCompanyId)
                {
                    Caption = 'Company ID';
                    ToolTip = 'Specifies the unique GUID that identifies the current company.';
                    Editable = false;
                    Enabled = false;
                    ApplicationArea = Intercompany;
                }
                field(IntercompanyId; CompanyIntercompanyId)
                {
                    Caption = 'Intercompany ID';
                    ToolTip = 'Specifies the intercompany ID that intercompany partners should use when they share data with the current company.';
                    Editable = false;
                    Enabled = false;
                    ApplicationArea = Intercompany;
                }
                field(CompanyName; CompanyName)
                {
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company name of the current company.';
                    Editable = false;
                    Enabled = false;
                    ApplicationArea = Intercompany;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ICSetup: Record "IC Setup";
        Company: Record Company;
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
    begin
        CompanyConnectionUrl := GetUrl(ClientType::Api);

        Company.Get(CompanyName());
        CompanyCompanyId := CrossIntercompanyConnector.RemoveCurlyBracketsAndUpperCases(Company.Id);

        ICSetup.Get();
        CompanyIntercompanyId := ICSetup."IC Partner Code";

        CompanyName := CompanyName();
    end;

    var
        CompanyConnectionUrl, CompanyCompanyId, CompanyIntercompanyId, CompanyName : Text;
}
