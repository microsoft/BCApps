// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.IO;
using System.Reflection;
using System.Utilities;

page 9820 "Control Add-ins"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Control Add-ins';
    PageType = List;
    SourceTable = "Add-in";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Add-in Name"; Rec."Add-in Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Client Control Add-in that is registered on the Business Central Server.';
                }
                field("Public Key Token"; Rec."Public Key Token")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the public key token that is associated with the Add-in.';

                    trigger OnValidate()
                    begin
                        Rec."Public Key Token" := DelChr(Rec."Public Key Token", '<>', ' ');
                    end;
                }
                field(Version; Rec.Version)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the Client Control Add-in that is registered on a Business Central Server.';
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the add-in. There are four categories: DotNet Control Add-in, DotNet Interoperability, Javascript Control Add-in and Language Resource.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the Client Control Add-in.';
                }
                field("Resource.HASVALUE"; Rec.Resource.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource', Locked = true;
                    ToolTip = 'Specifies if the add-in has a resource. The resource can be used to stream the add-in to the Business Central Server instance.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Control Add-in Resource")
            {
                Caption = 'Control Add-in Resource';
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    ToolTip = 'Import a control add-in definition from a file.';

                    trigger OnAction()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                        RecordRef: RecordRef;
                        ResourceName: Text;
                    begin
                        if Rec.Resource.HasValue() then
                            if not Confirm(ImportQst) then
                                exit;

                        ResourceName := FileManagement.BLOBImportWithFilter(
                            TempBlob, ImportTitleTxt, '',
                            ImportFileTxt + ' (*.zip)|*.zip|' + AllFilesTxt + ' (*.*)|*.*', '*.*');

                        if ResourceName <> '' then begin
                            RecordRef.GetTable(Rec);
                            TempBlob.ToRecordRef(RecordRef, Rec.FieldNo(Resource));
                            RecordRef.SetTable(Rec);
                            CurrPage.SaveRecord();

                            Message(ImportDoneMsg);
                        end;
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = Export;
                    ToolTip = 'Export a control add-in definition to a file.';

                    trigger OnAction()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                    begin
                        TempBlob.FromRecord(Rec, Rec.FieldNo(Resource));
                        if TempBlob.HasValue() then
                            FileManagement.BLOBExport(TempBlob, Rec."Add-in Name" + '.zip', true)
                        else
                            Message(NoResourceMsg);
                    end;
                }
                action(Clear)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear';
                    Image = Cancel;
                    ToolTip = 'Clear the resource from the selected control add-in.';

                    trigger OnAction()
                    begin
                        if not Rec.Resource.HasValue() then
                            exit;

                        Clear(Rec.Resource);
                        CurrPage.SaveRecord();

                        Message(RemoveDoneMsg);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Control Add-in Resource', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Import_Promoted; Import)
                {
                }
                actionref(Export_Promoted; Export)
                {
                }
                actionref(Clear_Promoted; Clear)
                {
                }
            }
        }
    }

    var
        AllFilesTxt: Label 'All Files';
        ImportFileTxt: Label 'Control Add-in Resource';
        ImportDoneMsg: Label 'The control add-in resource has been imported.';
        ImportQst: Label 'The control add-in resource is already specified.\Do you want to overwrite it?';
        ImportTitleTxt: Label 'Import Control Add-in Resource';
        NoResourceMsg: Label 'There is no resource for the control add-in.';
        RemoveDoneMsg: Label 'The control add-in resource has been removed.';
}

