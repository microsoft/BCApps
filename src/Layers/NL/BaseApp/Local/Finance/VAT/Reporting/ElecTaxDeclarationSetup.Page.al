// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment;
using System.Telemetry;

page 11410 "Elec. Tax Declaration Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Elec. Tax Declaration Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Elec. Tax Declaration Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Part of Fiscal Entity"; Rec."Part of Fiscal Entity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the electronic declarations must be created for a subsidiary company that is part of a fiscal entity.';
                }
                field("VAT Contact Type"; Rec."VAT Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the contact person for the electronic VAT declaration is the tax payer or an agent.';

                    trigger OnValidate()
                    begin
                        VATContactTypeOnAfterValidate();
                    end;
                }
                field("ICP Contact Type"; Rec."ICP Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the contact person for the electronic ICP declaration is the tax payer or an agent.';

                    trigger OnValidate()
                    begin
                        ICPContactTypeOnAfterValidate();
                    end;
                }
                field("Tax Payer Contact Name"; Rec."Tax Payer Contact Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Tax Payer Contact NameEnable";
                    ToolTip = 'Specifies the name of the contact person of the taxpayer.';
                }
                field("Tax Payer Contact Phone No."; Rec."Tax Payer Contact Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = TaxPayerContactPhoneNoEnable;
                    ToolTip = 'Specifies the phone number of the contact person of the tax payer.';
                }
                field("Agent Contact ID"; Rec."Agent Contact ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact IDEnable";
                    ToolTip = 'Specifies the BECON-number of the agent.';
                }
                field("Agent Contact Name"; Rec."Agent Contact Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact NameEnable";
                    ToolTip = 'Specifies the name of the contact person of the agent.';
                }
                field("Agent Contact Address"; Rec."Agent Contact Address")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact AddressEnable";
                    ToolTip = 'Specifies the address of the agent.';
                }
                field("Agent Contact Post Code"; Rec."Agent Contact Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact Post CodeEnable";
                    ToolTip = 'Specifies the postal code of the agent.';
                }
                field("Agent Contact City"; Rec."Agent Contact City")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact CityEnable";
                    ToolTip = 'Specifies the city where the agent is located.';
                }
                field("Agent Contact Phone No."; Rec."Agent Contact Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact Phone No.Enable";
                    ToolTip = 'Specifies the phone number of the contact person of the agent.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("VAT Declaration Nos."; Rec."VAT Declaration Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign numbers to an electronic VAT declaration.';
                }
                field("ICP Declaration Nos."; Rec."ICP Declaration Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign numbers to an electronic ICP declaration.';
                }
            }
            group(Digipoort)
            {
                Caption = 'Digipoort';
                field("Digipoort Client Cert. Name"; Rec."Digipoort Client Cert. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the certificate, which was set when you requested the certificate.';
                    Visible = not IsSoftwareAsAService;
                }
                field("Digipoort Service Cert. Name"; Rec."Digipoort Service Cert. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the service with which you are communicating.';
                    Visible = not IsSoftwareAsAService;
                }
                field("Digipoort Delivery URL"; Rec."Digipoort Delivery URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL for the delivery service.';
                }
                field("Digipoort Status URL"; Rec."Digipoort Status URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL for the status information service.';
                }
                field("Use Certificate Setup"; Rec."Use Certificate Setup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that certificates codes determined below must be considered to transfer data to the information service.';

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                field("Client Certificate Code"; Rec."Client Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = UseCertificateSetup;
                    ToolTip = 'Specifies the client certificate code.';
                }
                field("Service Certificate Code"; Rec."Service Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = UseCertificateSetup;
                    ToolTip = 'Specifies the service certificate code.';
                }
            }
            group(Endpoints)
            {
                Caption = 'Endpoints';
                field("Tax Decl. Schema Version"; Rec."Tax Decl. Schema Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the schema version for the electronic tax declaration.';
                }
                field("Tax Decl. BD Data Endpoint"; Rec."Tax Decl. BD Data Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BD data endpoint for the electronic tax declaration.';
                }
                field("Tax Decl. BD Tuples Endpoint"; Rec."Tax Decl. BD Tuples Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BD tuples endpoint for the electronic tax declaration.';
                }
                field("Tax Decl. Schema Endpoint"; Rec."Tax Decl. Schema Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the schema endpoint for the electronic tax declaration.';
                }
                field("ICP Decl. Schema Endpoint"; Rec."ICP Decl. Schema Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the schema endpoint for the ICP declaration.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
        AfterGetCurrentRecord();
    end;

    trigger OnInit()
    begin
        "Agent Contact Phone No.Enable" := true;
        "Agent Contact CityEnable" := true;
        "Agent Contact Post CodeEnable" := true;
        "Agent Contact AddressEnable" := true;
        "Agent Contact NameEnable" := true;
        "Agent Contact IDEnable" := true;
        TaxPayerContactPhoneNoEnable := true;
        "Tax Payer Contact NameEnable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FeatureTelemetry.LogUptake('1000HS7', NLElecVATICPTok, Enum::"Feature Uptake Status"::"Set up");
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        FeatureTelemetry.LogUptake('1000HS6', NLElecVATICPTok, Enum::"Feature Uptake Status"::Discovered);
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS();

        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        UpdateControls();
        OnActivateForm();
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NLElecVATICPTok: Label 'NL Submit Elec. VAT & ICP Declarations', Locked = true;
        "Tax Payer Contact NameEnable": Boolean;
        TaxPayerContactPhoneNoEnable: Boolean;
        "Agent Contact IDEnable": Boolean;
        "Agent Contact NameEnable": Boolean;
        "Agent Contact AddressEnable": Boolean;
        "Agent Contact Post CodeEnable": Boolean;
        "Agent Contact CityEnable": Boolean;
        "Agent Contact Phone No.Enable": Boolean;
        IsSoftwareAsAService: Boolean;
        UseCertificateSetup: Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        "Tax Payer Contact NameEnable" := TaxpayerActive();
        TaxPayerContactPhoneNoEnable := TaxpayerActive();

        "Agent Contact IDEnable" := AgentActive();
        "Agent Contact NameEnable" := AgentActive();
        "Agent Contact AddressEnable" := AgentActive();
        "Agent Contact Post CodeEnable" := AgentActive();
        "Agent Contact CityEnable" := AgentActive();
        "Agent Contact Phone No.Enable" := AgentActive();
        UseCertificateSetup := Rec."Use Certificate Setup";
    end;

    local procedure AgentActive(): Boolean
    begin
        exit((Rec."VAT Contact Type" = Rec."VAT Contact Type"::Agent) or
          (Rec."ICP Contact Type" = Rec."ICP Contact Type"::Agent));
    end;

    local procedure TaxpayerActive(): Boolean
    begin
        exit((Rec."VAT Contact Type" = Rec."VAT Contact Type"::"Tax Payer") or
          (Rec."ICP Contact Type" = Rec."ICP Contact Type"::"Tax Payer"));
    end;

    local procedure VATContactTypeOnAfterValidate()
    begin
        UpdateControls();
    end;

    local procedure ICPContactTypeOnAfterValidate()
    begin
        UpdateControls();
    end;

    local procedure AfterGetCurrentRecord()
    begin
    end;

    local procedure OnActivateForm()
    begin
        UpdateControls();
    end;
}

