// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System;
using System.IO;
using System.Utilities;

page 9623 "Finish Up Design"
{
    Caption = 'Finish Up Design';
    PageType = NavigatePage;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                Visible = SaveVisible;
                field(AppName; AppName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    Editable = NameAndPublisherEnabled;
                    Enabled = NameAndPublisherEnabled;
                    NotBlank = true;
                }
                field(Publisher; Publisher)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Publisher';
                    Editable = NameAndPublisherEnabled;
                    Enabled = NameAndPublisherEnabled;
                    NotBlank = true;
                }
                field(DownloadCode; DownloadCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Code';
                    Enabled = DownloadCodeEnabled;
                }
                label(DisclaimerLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Do not add personal data to the designer extension as this is not treated as restricted data';
                    Visible = NameAndPublisherEnabled;
                }
                label(InformationLabel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extensions that have been created using Designer are removed when the environment is updated or relocated within our service. However, the data of the app is not removed, so you only have to re-publish and install the app to make it available. For more information, see this article on sandbox environments https://go.microsoft.com/fwlink/?linkid=2153804 .';
                    Visible = NameAndPublisherEnabled;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Save)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Save';
                Image = Approve;
                InFooterBar = true;
                Visible = SaveVisible;

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    NvOutStream: OutStream;
                    Designer: DotNet NavDesignerALFunctions;
                    FileName: Text;
                    CleanFileName: Text;
                    TrimmedAppName: Text;
                    TrimmedAppPublisher: Text;
                begin
                    TrimmedAppName := AppName.Trim();
                    TrimmedAppPublisher := Publisher.Trim();

                    if StrLen(TrimmedAppName) = 0 then
                        Error(BlankNameErr);

                    if StrLen(TrimmedAppPublisher) = 0 then
                        Error(BlankPublisherErr);

                    if not Designer.ExtensionNameAndPublisherIsValid(TrimmedAppName, TrimmedAppPublisher) then
                        Error(DuplicateNameAndPublisherErr);

                    SaveVisible := false;

                    Designer.SaveDesignerExtension(TrimmedAppName, TrimmedAppPublisher);

                    if DownloadCode and DownloadCodeEnabled then begin
                        TempBlob.CreateOutStream(NvOutStream);
                        Designer.GenerateDesignerPackageZipStream(NvOutStream, TrimmedAppPublisher, TrimmedAppName);
                        FileName := StrSubstNo(ExtensionFileNameTxt, TrimmedAppName, TrimmedAppPublisher);
                        CleanFileName := Designer.SanitizeDesignerFileName(FileName, '_');
                        FileManagement.BLOBExport(TempBlob, CleanFileName, true);
                    end;

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        Designer: DotNet NavDesignerALFunctions;
    begin
        SaveVisible := true;
        DownloadCode := true;
        AppName := Designer.GetDesignerExtensionName();
        Publisher := Designer.GetDesignerExtensionPublisher();
        DownloadCodeEnabled := Designer.GetDesignerExtensionShowMyCode();
        if AppName = '' then
            NameAndPublisherEnabled := true
        else
            NameAndPublisherEnabled := false;
    end;

    var
        SaveVisible: Boolean;
        ExtensionFileNameTxt: Label '%1_%2_1.0.0.0.zip', Comment = '%1=Name, %2=Publisher', Locked = true;
        AppName: Text[250];
        Publisher: Text[250];
        DownloadCode: Boolean;
        BlankNameErr: Label 'Name cannot be blank.', Comment = 'Specifies that field cannot be blank.';
        BlankPublisherErr: Label 'Publisher cannot be blank.', Comment = 'Specifies that field cannot be blank.';
        NameAndPublisherEnabled: Boolean;
        DownloadCodeEnabled: Boolean;
        DuplicateNameAndPublisherErr: Label 'The specified name and publisher are already used in another extension. Please specify another name or publisher.', Comment = 'An extension with the same name and publisher already exists.';
}

