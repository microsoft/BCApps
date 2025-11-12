// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

page 364 "Select Sending Options"
{
    Caption = 'Send Document to';
    DataCaptionExpression = '';
    PageType = StandardDialog;
    SourceTable = "Document Sending Profile";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';
                group(Control10)
                {
                    ShowCaption = false;
                    field(Printer; Rec.Printer)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if and how the document is printed when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is printed according to settings that you must make on the printer setup dialog.';

                        trigger OnValidate()
                        begin
                            SetSendMethodToCustom();
                        end;
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if and how the document is attached as a PDF file to an email to the involved customer when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is attached to an email according to settings that you must make in the Send Email window.';

                        trigger OnValidate()
                        begin
                            SetSendMethodToCustom();
                        end;
                    }
                    group(Control12)
                    {
                        ShowCaption = false;
                        Visible = Rec."E-Mail" <> Rec."E-Mail"::No;
                        field("E-Mail Attachment"; Rec."E-Mail Attachment")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies if the document is attached to an email when you choose the Post and Send button.';

                            trigger OnValidate()
                            begin
                                Rec.VerifySelectedOptionsValid();
                                Rec."E-Mail Format" := GetFormat();
                            end;
                        }
                        group(Control14)
                        {
                            ShowCaption = false;
                            Visible = Rec."E-Mail Attachment" <> Rec."E-Mail Attachment"::PDF;
                            field("E-Mail Format"; Rec."E-Mail Format")
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Format';
                                ToolTip = 'Specifies the format of the file that is saved to disk.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    Rec."E-Mail Format" := LookupFormat();
                                end;

                                trigger OnValidate()
                                begin
                                    SetSendMethodToCustom();
                                    LastFormat := Rec."E-Mail Format";
                                end;
                            }
                        }
                        group(Control19)
                        {
                            ShowCaption = false;
                            Visible = Rec."E-Mail" = Rec."E-Mail"::"Yes (Prompt for Settings)";
                            field("Combine PDF Documents"; Rec."Combine Email Documents")
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Combine PDF Documents';
                                ToolTip = 'Combine email documents into one document when sending/printing.';
                            }
                        }
                    }
                    field(Disk; Rec.Disk)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the document is saved as a PDF file when you choose the Post and Send button.';

                        trigger OnValidate()
                        begin
                            Rec.VerifySelectedOptionsValid();
                            SetSendMethodToCustom();
                            Rec."Disk Format" := GetFormat();
                        end;
                    }
                    group(Control16)
                    {
                        ShowCaption = false;
                        Visible = (Rec.Disk <> Rec.Disk::No) and (Rec.Disk <> Rec.Disk::PDF);
                        field("Disk Format"; Rec."Disk Format")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Format';
                            ToolTip = 'Specifies the format of the electronic document.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Rec."Disk Format" := LookupFormat();
                            end;

                            trigger OnValidate()
                            begin
                                SetSendMethodToCustom();
                                LastFormat := Rec."Disk Format";
                            end;
                        }
                    }
                }
                group(Control2)
                {
                    ShowCaption = false;
                    Visible = SendElectronicallyVisible;
                    field("Electronic Document"; Rec."Electronic Document")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the document is sent as an electronic document that the customer can import into their system when you choose the Post and Send button. To use this option, you must also fill the Electronic Format field. Alternatively, the file can be saved to disk.';

                        trigger OnValidate()
                        begin
                            Rec.VerifySelectedOptionsValid();
                            SetSendMethodToCustom();
                            Rec."Electronic Format" := GetFormat();
                        end;
                    }
                    group(Control18)
                    {
                        ShowCaption = false;
                        Visible = Rec."Electronic Document" <> Rec."Electronic Document"::No;
                        field("Electronic Format"; Rec."Electronic Format")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Format';
                            ToolTip = 'Specifies which format to use for electronic document sending. You must fill this field if you selected the Silent option in the Electronic Document field.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Rec."Electronic Format" := LookupFormat();
                            end;

                            trigger OnValidate()
                            begin
                                SetSendMethodToCustom();
                                LastFormat := Rec."Electronic Format";
                            end;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        SendElectronicallyVisible := not ElectronicDocumentFormat.IsEmpty() and Rec."One Related Party Selected";

        if DocumentSendingProfile.Get(Rec.Code) then
            Rec.Copy(DocumentSendingProfile);
    end;

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        SendElectronicallyVisible: Boolean;

    protected var
        CustomTxt: Label 'Custom';
        LastFormat: Code[20];

    procedure SetSendMethodToCustom()
    begin
        Rec.Code := CustomTxt;
    end;

    procedure LookupFormat(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ElectronicDocumentFormats: Page "Electronic Document Formats";
    begin
        ElectronicDocumentFormat.SetRange(Usage, Rec.Usage);
        ElectronicDocumentFormats.SetTableView(ElectronicDocumentFormat);
        ElectronicDocumentFormats.LookupMode := true;

        if ElectronicDocumentFormats.RunModal() = ACTION::LookupOK then begin
            ElectronicDocumentFormats.GetRecord(ElectronicDocumentFormat);
            LastFormat := ElectronicDocumentFormat.Code;
            exit(ElectronicDocumentFormat.Code);
        end;

        exit(GetFormat());
    end;

    procedure GetFormat(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FindNewFormat: Boolean;
    begin
        FindNewFormat := false;

        if LastFormat = '' then
            FindNewFormat := true
        else begin
            ElectronicDocumentFormat.SetRange(Code, LastFormat);
            ElectronicDocumentFormat.SetRange(Usage, Rec.Usage);
            if not ElectronicDocumentFormat.FindFirst() then
                FindNewFormat := true;
        end;

        if FindNewFormat then begin
            ElectronicDocumentFormat.SetRange(Code);
            ElectronicDocumentFormat.SetRange(Usage, Rec.Usage);
            if not ElectronicDocumentFormat.FindFirst() then
                LastFormat := ''
            else
                LastFormat := ElectronicDocumentFormat.Code;
        end;

        exit(LastFormat);
    end;
}

