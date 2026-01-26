// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment;
using System.Telemetry;

page 11411 "Elec. Tax Declaration Card"
{
    Caption = 'Elec. Tax Declaration Card';
    PageType = Document;
    SourceTable = "Elec. Tax Declaration Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Declaration Type"; Rec."Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Declaration TypeEditable";
                    ToolTip = 'Specifies whether the electronic declaration concerns a VAT or ICP declaration.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the electronic declaration that you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Declaration Period"; Rec."Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Declaration PeriodEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the declaration period.';
                }
                field("Declaration Year"; Rec."Declaration Year")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Declaration YearEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the declaration year.';
                }
                field("Message ID"; Rec."Message ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the response message from the Tax authority.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the electronic declaration.';
                }
                field("Our Reference"; Rec."Our Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Our ReferenceEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the unique identification for the electronic declaration.';
                }
                field("Date Created"; Rec."Date Created")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the electronic declaration is created by the user.';
                }
                field("Date Submitted"; Rec."Date Submitted")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the electronic declaration is submitted to the tax authority.';
                }
                field("Date Received"; Rec."Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the response message from the tax authority for an electronic declaration is processed.';
                }
            }
            part(Control1000017; "Elec. Tax Decl. Line Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Declaration Type" = field("Declaration Type"),
                              "Declaration No." = field("No.");
                SubPageView = sorting("Declaration Type", "Declaration No.", "Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Declaration")
            {
                Caption = '&Declaration';
                Image = VATStatement;
                separator(Action1000024)
                {
                }
                action(DownloadSubmissionMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Submission Message';
                    Image = MoveDown;
                    ToolTip = 'Download the XBRL message without the actual submission. For example, this can be helpful for troubleshooting submissions.';

                    trigger OnAction()
                    begin
                        Rec.DownloadSubmissionMessage();
                    end;
                }
                action("Response Messages")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Response Messages';
                    Enabled = ResponseMessageEnabled;
                    Image = Alerts;
                    RunObject = Page "Elec. Tax Decl. Response Msgs.";
                    RunPageLink = "Declaration Type" = field("Declaration Type"),
                                  "Declaration No." = field("No.");
                    RunPageView = sorting("Declaration Type", "Declaration No.");
                    ToolTip = 'View the response messages from the tax authorities.';
                }
                action("Error Log")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Log';
                    Image = ErrorLog;
                    RunObject = Page "Elec. Tax Decl. Error Log";
                    RunPageLink = "Declaration Type" = field("Declaration Type"),
                                  "Declaration No." = field("No.");
                    RunPageView = sorting("Declaration Type", "Declaration No.", "No.");
                    ToolTip = 'View all the errors for each electronic tax declaration with the status Error. The error information is obtained from the response messages of the tax authorities.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateElectronicTaxDeclaration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Electronic Tax Declaration';
                    Ellipsis = true;
                    Image = ElectronicDoc;
                    ToolTip = 'Create electronic VAT and ICP declarations, which you can submit them to the tax authorities.';

                    trigger OnAction()
                    var
                        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
                    begin
                        if Rec.Status > Rec.Status::Created then
                            Error(StatusErr);
                        Rec.TestField("Our Reference");

                        if (Rec."Declaration Year" = 0) or (Rec."Declaration Period" = Rec."Declaration Period"::" ") then
                            Error(Text000, Rec.FieldCaption("Declaration Period"), Rec.FieldCaption("Declaration Year"));

                        ElecTaxDeclarationHeader := Rec;
                        ElecTaxDeclarationHeader.SetRecFilter();

                        case Rec."Declaration Type" of
                            Rec."Declaration Type"::"VAT Declaration":
                                REPORT.RunModal(REPORT::"Create Elec. VAT Declaration", true, false, ElecTaxDeclarationHeader);
                            Rec."Declaration Type"::"ICP Declaration":
                                REPORT.RunModal(REPORT::"Create Elec. ICP Declaration", true, false, ElecTaxDeclarationHeader);
                        end;
                    end;
                }
                action(GenerateSubmissionMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Generate submission message.';
                    Ellipsis = true;
                    Enabled = SubmitEnabled;
                    Image = TestFile;
                    ToolTip = 'Generate the xbrl request without the actual submission.';

                    trigger OnAction()
                    begin
                        Rec.DownloadGeneratedSubmissionMessage();
                    end;
                }
                action(SubmitElectronicTaxDeclaration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Submit Electronic Tax Declaration';
                    Ellipsis = true;
                    Enabled = SubmitEnabled;
                    Image = TransmitElectronicDoc;
                    ToolTip = 'Send the VAT and ICP declarations to the tax authorities.';

                    trigger OnAction()
                    var
                        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
                        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
                        EnvironmentInfo: Codeunit "Environment Information";
                        UseReqWindow: Boolean;
                    begin
                        FeatureTelemetry.LogUptake('1000HS8', NLElecVATICPTok, Enum::"Feature Uptake Status"::"Used");
                        ElecTaxDeclarationHeader := Rec;
                        ElecTaxDeclarationHeader.SetRecFilter();
                        ElecTaxDeclarationSetup.Get();
                        if ElecTaxDeclarationSetup."Use Certificate Setup" then
                            UseReqWindow := false
                        else
                            UseReqWindow := EnvironmentInfo.IsSaaS();
                        REPORT.RunModal(
                          REPORT::"Submit Elec. Tax Declaration", UseReqWindow, false, ElecTaxDeclarationHeader);
                        FeatureTelemetry.LogUsage('1000HS9', NLElecVATICPTok, 'NL Elec. VAT and ICP Declarations Sent to the Tax Authorities');
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateElectronicTaxDeclaration_Promoted; CreateElectronicTaxDeclaration)
                {
                }
                actionref(GenerateSubmissionMessage_Promoted; GenerateSubmissionMessage)
                {
                }
                actionref(SubmitElectronicTaxDeclaration_Promoted; SubmitElectronicTaxDeclaration)
                {
                }
                actionref("Response Messages_Promoted"; "Response Messages")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnInit()
    begin
        "Our ReferenceEditable" := true;
        "Declaration YearEditable" := true;
        "Declaration PeriodEditable" := true;
        "Declaration TypeEditable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateControls();
    end;

    trigger OnOpenPage()
    begin
        UpdateControls();
        OnActivateForm();
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NLElecVATICPTok: Label 'NL Submit Elec. VAT & ICP Declarations', Locked = true;
        Text000: Label '%1 and %2 must be filled before the declaration can be created.';
        "Declaration TypeEditable": Boolean;
        "Declaration PeriodEditable": Boolean;
        "Declaration YearEditable": Boolean;
        "Our ReferenceEditable": Boolean;
        StatusErr: Label 'The report must have the status of " " or Created before you can create the report content.';
        SubmitEnabled: Boolean;
        ResponseMessageEnabled: Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        "Declaration TypeEditable" := (Rec.Status = Rec.Status::" ");
        "Declaration PeriodEditable" := (Rec.Status = Rec.Status::" ");
        "Declaration YearEditable" := (Rec.Status = Rec.Status::" ");
        "Our ReferenceEditable" := (Rec.Status = Rec.Status::" ");
        SubmitEnabled := (Rec.Status >= Rec.Status::Created);
        ResponseMessageEnabled := (Rec."Message ID" <> '');
    end;

    local procedure OnActivateForm()
    begin
        UpdateControls();
    end;
}

