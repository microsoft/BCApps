// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 10751 "SII Setup"
{
    ApplicationArea = All;
    Caption = 'SII Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "SII Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the service for immediate information supply to the tax authorities is activated.';
                }
                field("Enable Batch Submissions"; Rec."Enable Batch Submissions")
                {
                    ApplicationArea = All;
                    Enabled = Rec.Enabled;
                    ToolTip = 'Specifies that the batch submission is used for the service for immediate information supply to the tax authorities.';
                }
                field("Job Batch Submission Threshold"; Rec."Job Batch Submission Threshold")
                {
                    ApplicationArea = All;
                    Enabled = Rec.Enabled and Rec."Enable Batch Submissions";
                    ToolTip = 'Specifies the minimal number of pending history records for the batch submission.';

                    trigger OnValidate()
                    var
                        SIIJobManagement: Codeunit "SII Job Management";
                        JobType: Option HandlePending,HandleCommError,InitialUpload;
                    begin
                        if Rec.Enabled and Rec."Enable Batch Submissions" then
                            SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
                    end;
                }
                field("Show Advanced Actions"; Rec."Show Advanced Actions")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to show advanced actions.';
                }
                field("Invoice Amount Threshold"; Rec."Invoice Amount Threshold")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which value to include in the Macrodato node in the XML file that is exported to SII. If the invoice amount on the document is under the threshold, then value ''N'' will be exported. Otherwise, value ''S'' will be exported.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the company starts to send entries to the SII system.';
                }
                field("Auto Missing Entries Check"; Rec."Auto Missing Entries Check")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the system will detect whether SII entries are missing.';
                }
                field("Include ImporteTotal"; Rec."Include ImporteTotal")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the ImporteTotal XML node must be exported to the XML file.';
                }
                field("Do Not Export Negative Lines"; Rec."Do Not Export Negative Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if you want to exclude lines that are negative from the export to the SII file.';
                }
                field("Do Not Schedule JQ Entry"; Rec."Do Not Schedule JQ Entry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the automatic scheduling of the background job for the SII Service is disabled. If you enable this option, you must upload documents manually from the SII History page by the Upload Pending Documents action';
                }
                field("Operation Date"; Rec."Operation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether you want to use the posting date of the shipment or the document date of the entry for the FechaOperacion XML node.';
                }
                field("New Automatic Sending Exp."; Rec."New Automatic Sending Exp.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the new automatic sending experience is enabled. The new sending experience allows you to track sending status for job queue entries.';
                }
                field("Tax Period"; Rec."Tax Period")
                {
                    ApplicationArea = All;
                }
            }
            group(Certificate)
            {
                field("Certificate Code"; Rec."Certificate Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of certificate.';
                }
            }
            group(Endpoints)
            {
                field(InvoicesIssuedEndpointUrl; Rec.InvoicesIssuedEndpointUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Invoices Issued Endpoint';
                    NotBlank = true;
                    ToolTip = 'Specifies the target URL for issued invoices.';
                }
                field(InvoicesReceivedEndpointUrl; Rec.InvoicesReceivedEndpointUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Invoices Received Endpoint';
                    NotBlank = true;
                    ToolTip = 'Specifies the target URL for received invoices.';
                }
                field(PaymentsIssuedEndpointUrl; Rec.PaymentsIssuedEndpointUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Payments Issued Endpoint';
                    NotBlank = true;
                    ToolTip = 'Specifies the target URL for issued payments.';
                }
                field(PaymentsReceivedEndpointUrl; Rec.PaymentsReceivedEndpointUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Payments Received Endpoint';
                    NotBlank = true;
                    ToolTip = 'Specifies the target URL for received payments.';
                }
                field(CollectionInCashEndpointUrl; Rec.CollectionInCashEndpointUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Collection In Cash Endpoint';
                    ToolTip = 'Specifies the target URL for the collections in cash.';
                }
                field("SuministroInformacion Schema"; Rec."SuministroInformacion Schema")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the target URL to the SuministroInformacion XSD schema.';
                }
                field("SuministroLR Schema"; Rec."SuministroLR Schema")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the target URL to the SuministroLR XSD schema.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(InitialSend)
            {
                ApplicationArea = All;
                Caption = 'Schedule Initial Upload';
                Image = SendElectronicDocument;
                Scope = Repeater;
                ToolTip = 'Transmits all documents from the 1st of January 2017 to the 30th of June 2017.';

                trigger OnAction()
                var
                    SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
                begin
                    if Confirm(InitialUploadQst, true) then
                        SIIInitialDocUpload.ScheduleInitialUpload();
                end;
            }
        }
        area(navigation)
        {
            action(ShowRequestHistory)
            {
                ApplicationArea = All;
                Caption = 'Show SII History';
                Image = History;
                RunObject = Page "SII History";
                ToolTip = 'Show history of all SII communication.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(InitialSend_Promoted; InitialSend)
                {
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
        Rec.SetDefaults();
    end;

    var
        InitialUploadQst: Label 'Do you want to transmit all documents from the 1st of Janurary 2017 to the 30th of June 2017?';
}

